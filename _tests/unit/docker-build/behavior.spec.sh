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

Describe "docker-build registry cache scope (behavior)"
ACTION_DIR="${PROJECT_ROOT}/docker-build"
CACHE_IMAGE="ghcr.io/ivuorinen/actions/cache"

before() {
  shellspec_setup_test_env "docker-build-cache-$$"
  harness_reset
  printf '%s' '{"repository":{"default_branch":"main"}}' >event.json
  export GITHUB_EVENT_PATH="${PWD}/event.json"
  export GITHUB_REPOSITORY="ivuorinen/actions"
  export GITHUB_REF="refs/heads/main"
  export INPUT_PUSH="true"
  export INPUT_CACHE_MODE="max"
}
BeforeEach 'before'

after() {
  shellspec_cleanup_test_env "docker-build-cache-$$"
  harness_reset
}
AfterEach 'after'

It "reads and writes the reserved tag on the default branch"
When call run_step "${ACTION_DIR}" "cache"
The status should be success
Assert expect_output from " --cache-from type=registry,ref=${CACHE_IMAGE}:default-branch"
Assert expect_output to "--cache-to type=registry,ref=${CACHE_IMAGE}:default-branch,mode=max"
End

It "lets a branch read the default branch's tag but write only its own"
export GITHUB_REF="refs/heads/feature/x"

When call run_step "${ACTION_DIR}" "cache"
The status should be success
Assert expect_output from " --cache-from type=registry,ref=${CACHE_IMAGE}:default-branch --cache-from type=registry,ref=${CACHE_IMAGE}:refs-heads-feature-x"
Assert expect_output to "--cache-to type=registry,ref=${CACHE_IMAGE}:refs-heads-feature-x,mode=max"
End

It "keeps a pull request build on its own tag"
export GITHUB_REF="refs/pull/7/merge"

When call run_step "${ACTION_DIR}" "cache"
The status should be success
Assert expect_output to "--cache-to type=registry,ref=${CACHE_IMAGE}:refs-pull-7-merge,mode=max"
End

It "does not let a branch named after the reserved tag write it"
export GITHUB_REF="refs/heads/default-branch"

When call run_step "${ACTION_DIR}" "cache"
The status should be success
Assert expect_output to "--cache-to type=registry,ref=${CACHE_IMAGE}:refs-heads-default-branch,mode=max"
End

It "never writes the reserved tag when the event does not name the default branch"
printf '%s' '{}' >event.json

When call run_step "${ACTION_DIR}" "cache"
The status should be success
Assert expect_output to "--cache-to type=registry,ref=${CACHE_IMAGE}:refs-heads-main,mode=max"
End

It "reduces a ref to tag characters, so it cannot add cache attributes"
export GITHUB_REF="refs/heads/fix,mode=min/#1"

When call run_step "${ACTION_DIR}" "cache"
The status should be success
Assert expect_output to "--cache-to type=registry,ref=${CACHE_IMAGE}:refs-heads-fix-mode-min--1,mode=max"
End

It "keeps a long ref within the registry's 128-character tag limit"
long_name=$(printf 'a%.0s' $(seq 1 200))
export GITHUB_REF="refs/heads/${long_name}"
tag="refs-heads-$(printf 'a%.0s' $(seq 1 117))"

When call run_step "${ACTION_DIR}" "cache"
The status should be success
Assert expect_output to "--cache-to type=registry,ref=${CACHE_IMAGE}:${tag},mode=max"
End

It "skips the registry cache when no ref is available"
unset GITHUB_REF

When call run_step "${ACTION_DIR}" "cache"
The status should be success
Assert expect_output from ""
Assert expect_output to ""
End

It "skips the registry cache without a push, because the login step has not run"
export INPUT_PUSH="false"
export INPUT_TOKEN="ghp""_fixture_0000000000000000000000000000000000"

When call run_step "${ACTION_DIR}" "cache"
The status should be success
Assert expect_output from ""
Assert expect_output to ""
End

It "keeps the caller's cache export"
export INPUT_CACHE_EXPORT="type=gha,mode=max"

When call run_step "${ACTION_DIR}" "cache"
The status should be success
Assert expect_output to "--cache-to type=gha,mode=max"
End
End

Describe "docker-build build metadata (behavior)"
ACTION_DIR="${PROJECT_ROOT}/docker-build"

before() {
  shellspec_setup_test_env "docker-build-metadata-$$"
  harness_reset
  export RUNNER_TEMP="${PWD}/runner-temp"
  mkdir -p "$RUNNER_TEMP"
  export INPUT_PUSH="false"
  export INPUT_TAG="v1"
  export INPUT_ARCHITECTURES="linux/amd64"
  export INPUT_MAX_RETRIES="1"
  export INPUT_DOCKERFILE="Dockerfile"
  export INPUT_CONTEXT="."
}
BeforeEach 'before'

after() {
  shellspec_cleanup_test_env "docker-build-metadata-$$"
  harness_reset
}
AfterEach 'after'

It "writes and reads the metadata file under RUNNER_TEMP"
metadata="${RUNNER_TEMP}/docker-build-metadata.json"
printf '%s' '{}' >"$metadata"
# Mocks match only the expected path, so any other path fails the step.
mock_command docker "buildx build *--metadata-file=${metadata} *" ""
mock_command docker "inspect *" "sha256:fixture"
mock_command jq "-r .sbom.location // \"\" ${metadata}" "location-from-runner-temp"

When call run_step "${ACTION_DIR}" "build"
The status should be success
The output should include "Build attempt 1 of 1"
Assert expect_output sbom-location "location-from-runner-temp"
End
End

Describe "docker-build builder setup (static)"
ACTION_FILE="${PROJECT_ROOT}/docker-build/action.yml"

default_buildkit_is_pinned_and_patched() {
  tag=$(sed -nE "s/^ +DEFAULT_BUILDKIT_IMAGE_TAG: '(.*)'$/\1/p" "$ACTION_FILE")
  printf '%s\n' "$tag" | grep -Eq '^v[0-9]+\.[0-9]+\.[0-9]+@sha256:[0-9a-f]{64}$' || return 1
  version="${tag%%@*}"
  # 0.12.5 is the first release with the CVE-2024-23651 fix.
  [ "$(printf '%s\n' 0.12.5 "${version#v}" | sort -V | head -n 1)" = "0.12.5" ]
}

# customManagers:githubActionsVersions has no digest group, so this repo's own
# manager has to read the BuildKit pin. A renamed key would silently stop updates.
renovate_manager_reads_buildkit_pin() {
  python3 - "${PROJECT_ROOT}/.github/renovate.json" "$ACTION_FILE" <<'PY'
import json
import re
import sys

with open(sys.argv[1], encoding="utf-8") as f:
    managers = json.load(f)["customManagers"]
with open(sys.argv[2], encoding="utf-8") as f:
    action = f.read()
found = [
    match.groupdict()
    for manager in managers
    for pattern in manager["matchStrings"]
    for match in re.finditer(pattern.replace("(?<", "(?P<"), action)
]
assert [dep["depName"] for dep in found] == ["moby/buildkit"], found
assert found[0]["datasource"] == "docker", found
assert found[0]["currentValue"].startswith("v"), found
assert found[0]["currentDigest"].startswith("sha256:"), found
PY
}

It "keeps no build state at fixed /tmp paths"
The contents of file "$ACTION_FILE" should not include "/tmp/"
End

It "leaves removing its builder to setup-buildx"
The contents of file "$ACTION_FILE" should not include "docker buildx rm"
End

It "pins the default BuildKit image by digest, at or above the CVE-2024-23651 fix"
When call default_buildkit_is_pinned_and_patched
The status should be success
End

It "keeps the BuildKit pin readable by Renovate"
When call renovate_manager_reads_buildkit_pin
The status should be success
End

It "pins the default Buildx version"
The contents of file "$ACTION_FILE" should match pattern "*DEFAULT_BUILDX_VERSION: 'v[0-9]*"
The contents of file "$ACTION_FILE" should not include "default: 'latest'"
End

It "lets a caller's explicit versions win over the pins"
The contents of file "$ACTION_FILE" should include "inputs.buildx-version || env.DEFAULT_BUILDX_VERSION"
The contents of file "$ACTION_FILE" should include "inputs.buildkit-version || env.DEFAULT_BUILDKIT_IMAGE_TAG"
End

It "enables BuildKit debug logs only on request, without restoring setup-buildx's default flags"
The contents of file "$ACTION_FILE" should not include "buildkitd-flags: --debug"
The contents of file "$ACTION_FILE" should include "inputs.verbose == 'true' && '--debug' || '--oci-worker=auto'"
End

It "documents the permissions the action needs"
The contents of file "$ACTION_FILE" should not include "none required"
The contents of file "$ACTION_FILE" should include "packages: write"
The contents of file "$ACTION_FILE" should include "id-token: write"
End
End
