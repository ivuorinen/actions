#!/usr/bin/env shellspec
# Behavior test for the platform matrix output of the build step: platforms split
# on commas only, and glob characters stay literal.

Describe "docker-build platform matrix (behavior)"
ACTION_DIR="${PROJECT_ROOT}/docker-build"

before() {
  shellspec_setup_test_env "docker-build-platform-matrix-$$"
  harness_reset
  export INPUT_PUSH="true"
  export INPUT_MAX_RETRIES="1"
  export INPUT_TAG="latest"
  export INPUT_DOCKERFILE="Dockerfile"
  export INPUT_CONTEXT="."
  mock_command docker "buildx build*" ""
  write_docker_build_metadata
}
BeforeEach 'before'

after() {
  shellspec_cleanup_test_env "docker-build-platform-matrix-$$"
  harness_reset
}
AfterEach 'after'

It "does not glob-expand a platform against the working directory"
# The decoy files make the glob match, so an unguarded split reports them as
# built platforms.
mkdir linux
: >linux/amd64
: >linux/arm64
export INPUT_ARCHITECTURES="linux/*"

When call run_step "${ACTION_DIR}" "build"
The status should be success
The stdout should include "Build attempt 1 of 1"
Assert expect_output platform-matrix '{"linux/*":"success"}'
End

It "keeps one matrix entry per comma-separated platform"
export INPUT_ARCHITECTURES="linux/amd64,linux/arm64"

When call run_step "${ACTION_DIR}" "build"
The status should be success
The stdout should include "Build attempt 1 of 1"
Assert expect_output platform-matrix '{"linux/amd64":"success","linux/arm64":"success"}'
End
End
