#!/usr/bin/env shellspec
# terraform-lint-fix sets up pinned Terraform and TFLint, and the default TFLint config pins its
# plugin. tflint mocks match exact arguments, so a flag TFLint no longer accepts exits 127 and
# fails the example.

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

Describe "Configure TFLint"
before_configure() {
  export INPUT_CONFIG_FILE=".tflint.hcl"
}
BeforeEach 'before_configure'

It "writes a default config with the plugin pinned"
When call run_step "${ACTION_DIR}" "configure"
The status should be success
The contents of file ".tflint.hcl" should include "version = \"$(pinned_version terraform-lint-fix TFLINT_RULESET_AWS_VERSION)\""
The contents of file ".tflint.hcl" should not include "latest"
End

# TFLint removed the `module` attribute in v0.54.0 and refuses a config that has it.
It "writes a default config current TFLint accepts"
When call run_step "${ACTION_DIR}" "configure"
The status should be success
The contents of file ".tflint.hcl" should include 'call_module_type = "local"'
The contents of file ".tflint.hcl" should not include "module = true"
End

It "leaves a repository's config alone"
printf 'config {}\n' >.tflint.hcl
When call run_step "${ACTION_DIR}" "configure"
The status should be success
The contents of file ".tflint.hcl" should equal "config {}"
End
End

Describe "Initialize TFLint"
It "installs the plugins of the config in use"
export INPUT_CONFIG_FILE="custom.hcl"
mock_command tflint "--init --config custom.hcl" ""
When call run_step "${ACTION_DIR}" "init"
The status should be success
End

# A plugin can only be installed once the config naming it exists.
step_line() {
  grep -n "id: $1\$" "${ACTION_DIR}/action.yml" | cut -d: -f1
}

It "runs after the default config is written"
configure_line=$(step_line configure)
init_line=$(step_line init)
When call test "$configure_line" -lt "$init_line"
The status should be success
End
End

Describe "Run TFLint"
before_lint() {
  export INPUT_WORKING_DIRECTORY="." INPUT_CONFIG_FILE=".tflint.hcl" INPUT_FORMAT="sarif" INPUT_FAIL_ON_ERROR="true"
}
BeforeEach 'before_lint'

# TFLint dropped positional paths in v0.47; the step changes directory instead.
It "passes no positional path"
mock_command tflint "--config .tflint.hcl --format sarif --no-color" ""
When call run_step "${ACTION_DIR}" "lint"
The status should be success
Assert expect_output sarif_file "reports/tflint.sarif"
End

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
mock_command tflint "--config .tflint.hcl --format sarif --no-color" "$2" 2
When call run_step "${ACTION_DIR}" "lint"
The status should be success
Assert expect_output error_count "$3"
Assert only_key_value_lines
End
End
End
End
