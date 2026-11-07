#!/usr/bin/env shellspec
# terraform-lint-fix sets up pinned Terraform and TFLint. tflint mocks match exact arguments, so a
# flag TFLint no longer accepts exits 127 and fails the example.

Describe "terraform-lint-fix tool pins"
ACTION_DIR="${PROJECT_ROOT}/terraform-lint-fix"

before() {
  shellspec_setup_test_env "terraform-lint-fix-pins-$$"
  harness_reset
}
BeforeEach 'before'

after() {
  shellspec_cleanup_test_env "terraform-lint-fix-pins-$$"
  harness_reset
}
AfterEach 'after'

It "sets up the pinned Terraform unless the caller names one"
The contents of file "${ACTION_DIR}/action.yml" should include \
  'terraform_version: ${{ inputs.terraform-version || env.DEFAULT_TERRAFORM_VERSION }}'
End

It "sets up the pinned TFLint unless the caller names one"
The contents of file "${ACTION_DIR}/action.yml" should include \
  'tflint_version: ${{ inputs.tflint-version || env.DEFAULT_TFLINT_VERSION }}'
End

Describe "Run TFLint"
before_lint() {
  export INPUT_WORKING_DIRECTORY="." INPUT_CONFIG_FILE=".tflint.hcl" INPUT_FORMAT="sarif" INPUT_FAIL_ON_ERROR="true"
}
BeforeEach 'before_lint'

# GitHub rejects $GITHUB_OUTPUT as a whole when any line in it is not key=value.
only_key_value_lines() {
  ! grep -qv '=' "$GITHUB_OUTPUT"
}

Describe "when TFLint reports findings and fail-on-error is off"
before_findings() {
  export INPUT_FAIL_ON_ERROR="false"
}
BeforeEach 'before_findings'

Parameters
"none at error level" '{"level": "warning"}' "0"
"two at error level" '{"level": "error"},{"level":"error"},{"level": "warning"}' "2"
End

It "counts $1"
mock_command tflint "--format sarif --no-color" "$2" 2
When call run_step "${ACTION_DIR}" "lint"
The status should be success
Assert expect_output error_count "$3"
Assert only_key_value_lines
End
End
End
End
