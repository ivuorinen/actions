#!/usr/bin/env shellspec
# The digest of a pushed image and the steps that address the image by it. A tag can
# move between steps and a digest cannot, so scan, sign and verify use the digest.
#
# The JSON fixtures are cut down from a real buildx v0.38 push to a local registry:
# with attestations attached, buildx records the digest of an OCI index, and that
# index lists each attestation as platform unknown/unknown.

Describe "docker-build image digest (behavior)"
ACTION_DIR="${PROJECT_ROOT}/docker-build"
ACTION_FILE="${ACTION_DIR}/action.yml"
IMAGE="ghcr.io/acme/app"
DIGEST="sha256:a12cfa64b63cde1131659bdaffc159ed67d71bedf4cf0e881af77a703197df9a"
INDEX='{"schemaVersion":2,"mediaType":"application/vnd.oci.image.index.v1+json","manifests":[
  {"digest":"sha256:01","platform":{"architecture":"amd64","os":"linux"}},
  {"digest":"sha256:02","platform":{"architecture":"arm64","os":"linux"}},
  {"digest":"sha256:03","platform":{"architecture":"arm","os":"linux","variant":"v7"}},
  {"digest":"sha256:04","platform":{"architecture":"unknown","os":"unknown"}},
  {"digest":"sha256:05","platform":{"architecture":"unknown","os":"unknown"}},
  {"digest":"sha256:06","platform":{"architecture":"unknown","os":"unknown"}}]}'
PLAIN_MANIFEST='{"schemaVersion":2,"mediaType":"application/vnd.oci.image.manifest.v1+json","config":{},"layers":[]}'

before() {
  shellspec_setup_test_env "docker-build-digest-$$"
  harness_reset
  export INPUT_MAX_RETRIES="1"
  export INPUT_TAG="1.0.0"
  export INPUT_ARCHITECTURES="linux/amd64"
  export INPUT_DOCKERFILE="Dockerfile"
  export INPUT_CONTEXT="."
}
BeforeEach 'before'

after() {
  shellspec_cleanup_test_env "docker-build-digest-$$"
  harness_reset
}
AfterEach 'after'

Describe "build step"
# The mocked docker writes this fixture at the --metadata-file the step names, as buildx
# writes it, with no trailing newline.
write_metadata() {
  export HARNESS_MOCK_WRITES_OPTION="--metadata-file"
  HARNESS_MOCK_WRITES_CONTENT=$(
    printf '{"buildx.build.ref":"b/b0/abc",'
    printf '"containerimage.descriptor":{"mediaType":"application/vnd.oci.image.index.v1+json","digest":"%s","size":1609},' "$DIGEST"
    printf '"containerimage.digest":"%s","image.name":"%s:1.0.0"}' "$DIGEST" "$IMAGE"
  )
  export HARNESS_MOCK_WRITES_CONTENT
}
seed_image_name() { export HARNESS_STEP_OUTPUTS='{"image-name":{"outputs":{"name":"ghcr.io/acme/app"}}}'; }
Before 'write_metadata' 'seed_image_name'

# The runner fails the step unless a line equal to the delimiter closes the value.
metadata_output_is_closed() {
  delimiter=$(sed -En 's/^metadata<<//p' "$GITHUB_OUTPUT")
  [ -n "$delimiter" ] && grep -Fxq "$delimiter" "$GITHUB_OUTPUT"
}

It "reports the digest buildx recorded for a push, without asking the registry about the tag"
export INPUT_PUSH="true"
mock_command docker "buildx build *--push*" ""

When call run_step "${ACTION_DIR}" "build"
The status should be success
The stdout should include "Build attempt 1 of 1"
Assert expect_output digest "$DIGEST"
Assert expect_output image-ref "${IMAGE}@${DIGEST}"
End

It "closes the metadata output on a line of its own"
export INPUT_PUSH="true"
mock_command docker "buildx build *--push*" ""

When call run_step "${ACTION_DIR}" "build"
The status should be success
The stdout should include "Build attempt 1 of 1"
Assert metadata_output_is_closed
End

# A fixed path could be linked elsewhere by another job on the machine first, and buildx
# would write through the link.
It "never writes the metadata through a link at a fixed path"
export INPUT_PUSH="true"
mock_command docker "buildx build *--push*" ""
printf 'untouched' >"${SHELLSPEC_TEST_TEMP_DIR}/victim"
ln -s "${SHELLSPEC_TEST_TEMP_DIR}/victim" "${RUNNER_TEMP}/docker-build-metadata.json"

When call run_step "${ACTION_DIR}" "build"
The status should be success
The stdout should include "Build attempt 1 of 1"
Assert expect_output digest "$DIGEST"
The contents of file "${SHELLSPEC_TEST_TEMP_DIR}/victim" should equal "untouched"
End

no_metadata_left() {
  [ -z "$(find "$RUNNER_TEMP" -name 'docker-build-metadata.*' -print)" ]
}

It "removes its metadata directory when the step ends"
export INPUT_PUSH="true"
mock_command docker "buildx build *--push*" ""

When call run_step "${ACTION_DIR}" "build"
The status should be success
The stdout should include "Build attempt 1 of 1"
Assert no_metadata_left
End

It "fails a push when buildx recorded no digest, rather than reporting one it does not have"
export INPUT_PUSH="true"
mock_command docker "buildx build *--push*" ""
export HARNESS_MOCK_WRITES_CONTENT='{"buildx.build.ref":"b/b0/abc"}'

When call run_step "${ACTION_DIR}" "build"
The status should be failure
The stdout should include "::error::buildx reported no digest for the pushed image"
The contents of file "$GITHUB_OUTPUT" should not include "image-ref="
End

# Validation rejects 0, so this runs the step past it: the loop never starts and no build runs.
It "fails when no build attempt runs, instead of leaving scan and sign an empty reference"
export INPUT_PUSH="true"
export INPUT_MAX_RETRIES="0"

When call run_step "${ACTION_DIR}" "build"
The status should be failure
The stdout should include "::error::No build attempted: max-retries is not a usable number"
The contents of file "$GITHUB_OUTPUT" should not include "image-ref="
End

It "keeps a local load addressed by its tag, because it has no registry digest"
export INPUT_PUSH="false"
mock_command docker "buildx build *--load*" ""
mock_command docker "inspect ${IMAGE}:1.0.0 *" "sha256:localimageid"

When call run_step "${ACTION_DIR}" "build"
The status should be success
The stdout should include "Build attempt 1 of 1"
Assert expect_output digest "sha256:localimageid"
Assert expect_output image-ref "${IMAGE}:1.0.0"
End

It "fails a local load when the image ID cannot be read, rather than reporting unknown"
export INPUT_PUSH="false"
mock_command docker "buildx build *--load*" ""
mock_command docker "inspect ${IMAGE}:1.0.0 *" "" 1

When call run_step "${ACTION_DIR}" "build"
The status should be failure
The stdout should include "::error::could not read the ID of the loaded image"
The contents of file "$GITHUB_OUTPUT" should not include "digest="
The contents of file "$GITHUB_OUTPUT" should not include "image-ref="
End
End

Describe "scan step"
# tool-pins.spec.sh runs the step with a stand-in Trivy.
It "scans the reference the build step resolved"
When call step_value "${ACTION_DIR}" "scan" env.IMAGE_REF
The output should equal '${{ steps.build.outputs.image-ref }}'
End
End

Describe "sign step"
It "signs the pushed digest and reports that reference"
export HARNESS_STEP_OUTPUTS="{\"image-name\":{\"outputs\":{\"name\":\"${IMAGE}\"}},\"build\":{\"outputs\":{\"digest\":\"${DIGEST}\"}}}"
mock_command cosign "sign --yes ${IMAGE}@${DIGEST}" ""

When call run_step "${ACTION_DIR}" "sign"
The status should be success
Assert expect_output signature "${IMAGE}@${DIGEST}"
End
End

Describe "verify step"
Context "after a push"
seed_image_ref() { export HARNESS_STEP_OUTPUTS="{\"build\":{\"outputs\":{\"image-ref\":\"${IMAGE}@${DIGEST}\"}}}"; }
Before 'seed_image_ref'

It "lists the built platforms by digest, leaving out attestations and keeping the variant"
export INPUT_PUSH="true"
mock_command docker "buildx imagetools inspect ${IMAGE}@${DIGEST} --raw" "$INDEX"

When call run_step "${ACTION_DIR}" "verify"
The status should be success
Assert expect_output built "linux/amd64,linux/arm64,linux/arm/v7"
End

It "fails when the pushed image cannot be found"
export INPUT_PUSH="true"
mock_command docker "buildx imagetools inspect ${IMAGE}@${DIGEST} --raw" "" 1

When call run_step "${ACTION_DIR}" "verify"
The status should be failure
The stdout should include "::error::Built image not found"
End

It "fails when the pushed manifest lists no platforms, rather than reporting none"
export INPUT_PUSH="true"
mock_command docker "buildx imagetools inspect ${IMAGE}@${DIGEST} --raw" "$PLAIN_MANIFEST"

When call run_step "${ACTION_DIR}" "verify"
The status should be failure
The stdout should include "::error::Built image lists no platforms"
End
End

Context "after a local load"
seed_image_ref() { export HARNESS_STEP_OUTPUTS="{\"build\":{\"outputs\":{\"image-ref\":\"${IMAGE}:1.0.0\"}}}"; }
Before 'seed_image_ref'

It "reports the platform with its variant"
export INPUT_PUSH="false"
mock_command docker "image inspect ${IMAGE}:1.0.0" "[]"
mock_command docker "image inspect --format *.Variant* ${IMAGE}:1.0.0" "linux/arm/v7"

When call run_step "${ACTION_DIR}" "verify"
The status should be success
Assert expect_output built "linux/arm/v7"
End

It "fails when the loaded image cannot be found"
export INPUT_PUSH="false"
mock_command docker "image inspect ${IMAGE}:1.0.0" "" 1

When call run_step "${ACTION_DIR}" "verify"
The status should be failure
The stdout should include "::error::Built image not found locally"
End
End
End
End
