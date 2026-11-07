#!/usr/bin/env shellspec
# Input values that used to pass validation and then skip the build or misread a flag.

Describe "docker-build input checks"
ACTION_DIR="${PROJECT_ROOT}/docker-build"

Context "when validating max-retries"
It "rejects a blank value"
When call validate_input_python "docker-build" "max-retries" ""
The status should be failure
End

It "rejects a whitespace-only value"
When call validate_input_python "docker-build" "max-retries" "  "
The status should be failure
End

It "rejects a value int() takes but a shell integer test does not"
When call validate_input_python "docker-build" "max-retries" "1_0"
The status should be failure
End

It "accepts the documented default"
When call validate_input_python "docker-build" "max-retries" "3"
The status should be success
End
End

Context "when validating boolean inputs"
It "rejects dry-run True, which a shell test reads as a real build"
When call validate_input_python "docker-build" "dry-run" "True"
The status should be failure
End

It "rejects push TRUE, which logs in but does not push"
When call validate_input_python "docker-build" "push" "TRUE"
The status should be failure
End

It "rejects a blank push"
When call validate_input_python "docker-build" "push" ""
The status should be failure
End

It "accepts lowercase true"
When call validate_input_python "docker-build" "dry-run" "true"
The status should be success
End
End

Context "when validating tag against the Docker tag grammar"
Parameters
"_leading-underscore" success
"trailing-dash-" success
"trailing.dot." success
"1.0.0-rc.1" success
"v2025.04.05-rc.1" success
"1.0.0+build" failure
"2025.4.5+sha.abc1234" failure
"registry.example.com:5000" failure
"path/tag" failure
"tag@sha256" failure
".leading-dot" failure
"-leading-dash" failure
End

It "treats $1 as $2"
When call validate_input_python "docker-build" "tag" "$1"
The status should be "$2"
End
End

Describe "build step"
before() {
  shellspec_setup_test_env "docker-build-input-checks-$$"
  harness_reset
  export INPUT_TAG="latest" INPUT_ARCHITECTURES="linux/amd64" INPUT_PUSH="false"
  export INPUT_DRY_RUN="false" INPUT_DOCKERFILE="Dockerfile" INPUT_CONTEXT="."
  mock_command docker "*" "DOCKER-RAN"
}
BeforeEach 'before'

after() {
  shellspec_cleanup_test_env "docker-build-input-checks-$$"
  harness_reset
  unset INPUT_TAG INPUT_ARCHITECTURES INPUT_PUSH INPUT_DRY_RUN INPUT_DOCKERFILE INPUT_CONTEXT
  unset INPUT_MAX_RETRIES
}
AfterEach 'after'

It "builds once and stops with a usable retry count"
export INPUT_MAX_RETRIES="3"
When call run_step "${ACTION_DIR}" "build"
The status should be success
The output should include "Build attempt 1 of 3"
The output should not include "Build attempt 2 of 3"
End

It "fails instead of succeeding without a build when the retry count is blank"
export INPUT_MAX_RETRIES=""
When call run_step "${ACTION_DIR}" "build"
The status should be failure
The output should include "::error::"
The output should not include "Build attempt"
The stderr should be present
End

It "fails the same way for a value only the expression bypass lets through"
export INPUT_MAX_RETRIES='${{ inputs.unresolved }}'
When call run_step "${ACTION_DIR}" "build"
The status should be failure
The output should include "::error::"
The output should not include "Build attempt"
The stderr should be present
End
End
End
