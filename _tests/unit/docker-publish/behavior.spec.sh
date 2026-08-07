#!/usr/bin/env shellspec
# Behavior-level tests for docker-publish's `meta` step.
#
# The push itself is docker/build-push-action (a `uses:` step) which the
# harness cannot execute — but `meta` is what decides *what* gets pushed:
# the registry host, the base image name, and the full image:tag list that
# build-push-action consumes. A defect here publishes to the wrong registry or
# under the wrong tag, and it was entirely untested; docker-publish had
# validation specs only (see docs/audit/findings, tests-94a13648).
#
# `meta` reads only env and writes only GITHUB_OUTPUT, so no command mocks are
# needed. `tags` is emitted as a heredoc-delimited multi-line value, so the
# assertions below check the rendered stdout as well as individual output lines.

Describe "docker-publish meta (behavior)"
ACTION_DIR="${PROJECT_ROOT}/docker-publish"

before() {
  shellspec_setup_test_env "docker-publish-behavior-$$"
  harness_reset
}
BeforeEach 'before'

after() {
  shellspec_cleanup_test_env "docker-publish-behavior-$$"
  harness_reset
}
AfterEach 'after'

Describe "registry routing"
# The registry input selects the host prefix. `both` must emit the image twice,
# once per host — inverting or dropping a branch here silently publishes to the
# wrong registry, which no validation spec can catch.
Parameters
"dockerhub" "docker.io/acme/app:1.0.0" "ghcr.io"
"github" "ghcr.io/acme/app:1.0.0" "docker.io"
End

It "routes registry=$1 to $2"
export INPUT_REGISTRY="$1"
export INPUT_IMAGE_NAME="acme/app"
export INPUT_TAGS="1.0.0"

When call run_step "${ACTION_DIR}" "meta"
The status should be success
The stdout should include "$2"
# the other registry must NOT appear
The stdout should not include "$3"
Assert expect_output image-name "acme/app"
End
End

It "emits both registries when registry=both"
export INPUT_REGISTRY="both"
export INPUT_IMAGE_NAME="acme/app"
export INPUT_TAGS="1.0.0"

When call run_step "${ACTION_DIR}" "meta"
The status should be success
The stdout should include "docker.io/acme/app:1.0.0"
The stdout should include "ghcr.io/acme/app:1.0.0"
End

It "produces the full image x tag cross product"
# 2 registries x 3 tags = 6 entries. A nesting bug that iterates only the
# outer loop would still emit a plausible-looking subset, so every one of the
# six is asserted rather than just the count.
export INPUT_REGISTRY="both"
export INPUT_IMAGE_NAME="acme/app"
export INPUT_TAGS="1.0.0,latest,sha-abc1234"

When call run_step "${ACTION_DIR}" "meta"
The status should be success
The stdout should include "docker.io/acme/app:1.0.0"
The stdout should include "docker.io/acme/app:latest"
The stdout should include "docker.io/acme/app:sha-abc1234"
The stdout should include "ghcr.io/acme/app:1.0.0"
The stdout should include "ghcr.io/acme/app:latest"
The stdout should include "ghcr.io/acme/app:sha-abc1234"
End

It "falls back to the lowercased repository when image-name is empty"
# GitHub repository names are case-preserving but Docker image names must be
# lowercase, so the fallback has to fold case or the push fails on a repo with
# capitals.
export INPUT_REGISTRY="github"
export INPUT_IMAGE_NAME=""
export INPUT_TAGS="1.0.0"
export GITHUB_REPOSITORY="Acme/MixedCase-App"

When call run_step "${ACTION_DIR}" "meta"
The status should be success
The stdout should include "ghcr.io/acme/mixedcase-app:1.0.0"
Assert expect_output image-name "acme/mixedcase-app"
End

It "rejects a tag containing whitespace"
# A tag with a space would be split by the consumer into two bogus refs.
export INPUT_REGISTRY="dockerhub"
export INPUT_IMAGE_NAME="acme/app"
export INPUT_TAGS="1.0.0,bad tag"

When call run_step "${ACTION_DIR}" "meta"
The status should be failure
The stdout should include "::error::Invalid tag"
End

It "does not glob-expand a tag against the working directory"
# The tag loop runs under `set -f`. Reverting that would let a tag like `*`
# expand against $PWD, so files are planted here that WOULD match.
: >1.0.0
: >latest
export INPUT_REGISTRY="dockerhub"
export INPUT_IMAGE_NAME="acme/app"
export INPUT_TAGS="*"

When call run_step "${ACTION_DIR}" "meta"
The status should be success
The stdout should include "docker.io/acme/app:*"
The stdout should not include "docker.io/acme/app:1.0.0"
End
End
