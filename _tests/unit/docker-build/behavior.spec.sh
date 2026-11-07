#!/usr/bin/env shellspec
# Behavior test for docker-build comma-split parsers: glob chars in values
# must not expand against the runner's working directory.

Describe "docker-build parse-build-args (behavior)"
ACTION_DIR="${PROJECT_ROOT}/docker-build"

before() {
  shellspec_setup_test_env "docker-build-behavior-$$"
  harness_reset
}
BeforeEach 'before'

after() {
  shellspec_cleanup_test_env "docker-build-behavior-$$"
  harness_reset
}
AfterEach 'after'

It "does not glob-expand build-arg values containing * against \$PWD"
# Pre-populate workspace with files that WILL be globbed if noglob
# is not set. Value is a bare `*.go` — this IS a shell glob that
# matches the created files, so reverting `set -f` in the action
# produces two extra `--build-arg a.go` / `--build-arg b.go` entries.
: >a.go
: >b.go
export INPUT_BUILD_ARGS="*.go,NAME=app"

When call run_step "${ACTION_DIR}" "build-args"
The status should be success
# Literal *.go preserved; filenames must NOT appear in args output.
Assert expect_output args " --build-arg *.go --build-arg NAME=app"
End

It "produces expected flags for normal comma-separated values"
export INPUT_BUILD_ARGS="KEY=value,FOO=bar"

When call run_step "${ACTION_DIR}" "build-args"
The status should be success
Assert expect_output args " --build-arg KEY=value --build-arg FOO=bar"
End
End

# The build step's argv is checked through mock order: an invocation carrying a
# rejected flag reaches a failing mock, as it would reach a failing buildx, and any
# other unexpected argv is an unregistered call (exit 127).
Describe "docker-build build step attestation flags (behavior)"
ACTION_DIR="${PROJECT_ROOT}/docker-build"

before() {
  shellspec_setup_test_env "docker-build-attestation-$$"
  harness_reset
  export INPUT_MAX_RETRIES="1"
  export INPUT_TAG="1.0.0"
  export INPUT_ARCHITECTURES="linux/amd64"
  export INPUT_DOCKERFILE="Dockerfile"
  export INPUT_CONTEXT="."
  export INPUT_SBOM_FORMAT="spdx-json"
}
BeforeEach 'before'

after() {
  shellspec_cleanup_test_env "docker-build-attestation-$$"
  harness_reset
}
AfterEach 'after'

It "attaches provenance and an SBOM when pushing, without a format flag"
export INPUT_PUSH="true"
mock_command docker "*--sbom-format*" "unknown flag: --sbom-format" 125
mock_command docker "buildx build *--push*--provenance=true*--sbom=true*" ""
mock_command docker "buildx imagetools inspect *" '{"manifests":[]}'
mock_command jq "*" "sha256:fixture"

When call run_step "${ACTION_DIR}" "build"
The status should be success
The stdout should include "Build attempt 1 of 1"
Assert expect_output digest "sha256:fixture"
End

It "omits attestations from a local load, which the docker exporter rejects"
export INPUT_PUSH="false"
mock_command docker "*--sbom*" "docker exporter does not currently support exporting manifest lists" 1
mock_command docker "*--provenance*" "docker exporter does not currently support exporting manifest lists" 1
mock_command docker "buildx build *--load*" ""
mock_command docker "inspect *" "sha256:fixture"

When call run_step "${ACTION_DIR}" "build"
The status should be success
The stdout should include "Build attempt 1 of 1"
Assert expect_output digest "sha256:fixture"
End

Context "with build metadata written"
# The step reads a fixed path; the mocked docker writes nothing, so the fixture
# stands in for the keys buildx does write.
write_metadata() { printf '%s\n' '{"containerimage.digest":"sha256:fixture"}' >/tmp/build-metadata.json; }
remove_metadata() { rm -f /tmp/build-metadata.json; }
Before 'write_metadata'
After 'remove_metadata'

It "emits no SBOM location, because buildx metadata has none to read"
export INPUT_PUSH="false"
mock_command docker "buildx build *--load*" ""
mock_command docker "inspect *" "sha256:fixture"

When call run_step "${ACTION_DIR}" "build"
The status should be success
The stdout should include "Build attempt 1 of 1"
The contents of file "$GITHUB_OUTPUT" should include "containerimage.digest"
The contents of file "$GITHUB_OUTPUT" should not include "sbom-location"
End
End
End
