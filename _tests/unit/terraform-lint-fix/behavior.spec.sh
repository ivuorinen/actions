#!/usr/bin/env shellspec
# Behavior tests for terraform-lint-fix's config handling.
#
# The action reads the configured TFLint config when it resolves to a regular file.
# Without the default file it lets TFLint fall back to its own lookup; any other
# configured path must exist. It generates no config, so a dangling symlink committed
# at the configured path is never a write target.
#
# The mocks match tflint's exact argv, so an unexpected --config or a flag or
# argument TFLint does not accept matches no glob, the dispatcher exits 127, and
# the step fails.

Describe "terraform-lint-fix config handling (behavior)"
ACTION_DIR="${PROJECT_ROOT}/terraform-lint-fix"

before() {
  shellspec_setup_test_env "terraform-lint-fix-behavior-$$"
  harness_reset
  OUTSIDE_TARGET="${SHELLSPEC_TEST_TEMP_DIR}/outside-workspace.hcl"
  export INPUT_WORKING_DIRECTORY="."
  export INPUT_CONFIG_FILE=".tflint.hcl"
  export INPUT_FORMAT="sarif"
  export INPUT_FAIL_ON_ERROR="true"
}
BeforeEach 'before'

after() {
  shellspec_cleanup_test_env "terraform-lint-fix-behavior-$$"
  harness_reset
}
AfterEach 'after'

Describe "Initialize TFLint"
It "does not pass or write through a dangling config symlink"
ln -s "$OUTSIDE_TARGET" .tflint.hcl
mock_command tflint "--init" ""
When call run_step "${ACTION_DIR}" "init"
The status should be success
The path "$OUTSIDE_TARGET" should not be exist
The path .tflint.hcl should be symlink
End

It "installs the plugins of the repository's own config"
printf 'config {\n}\n' >.tflint.hcl
mock_command tflint "--init --config .tflint.hcl" ""
When call run_step "${ACTION_DIR}" "init"
The status should be success
End

It "resolves the config relative to working-directory"
mkdir infra
printf 'config {\n}\n' >infra/.tflint.hcl
export INPUT_WORKING_DIRECTORY="infra"
mock_command tflint "--init --config .tflint.hcl" ""
When call run_step "${ACTION_DIR}" "init"
The status should be success
End

It "installs the plugins of a config-file other than the default"
printf 'config {\n}\n' >custom.hcl
export INPUT_CONFIG_FILE="custom.hcl"
mock_command tflint "--init --config custom.hcl" ""
When call run_step "${ACTION_DIR}" "init"
The status should be success
End

# The validator takes an empty value as unset, so it means the default here too.
It "takes an empty config-file as the default"
export INPUT_CONFIG_FILE=""
mock_command tflint "--init" ""
When call run_step "${ACTION_DIR}" "init"
The status should be success
End

# A mistyped path would otherwise lint with TFLint's own lookup and built-in rules.
It "fails on a config-file other than the default that does not exist"
export INPUT_CONFIG_FILE="custom.hcl"
mock_command tflint "--init" ""
When call run_step "${ACTION_DIR}" "init"
The status should be failure
The stdout should include "::error::config-file custom.hcl does not exist"
End
End

Describe "Run TFLint"
# The step writes the report into a fresh directory under RUNNER_TEMP and reports both paths.
sarif_file_is_in_reports_dir() {
  reports_dir=$(sed -En 's/^reports_dir=//p' "$GITHUB_OUTPUT")
  case "$reports_dir" in "$RUNNER_TEMP"/terraform-lint-fix.*) ;; *) return 1 ;; esac
  grep -Fxq "sarif_file=$reports_dir/tflint.sarif" "$GITHUB_OUTPUT"
}

It "does not pass or write through a dangling config symlink"
ln -s "$OUTSIDE_TARGET" .tflint.hcl
mock_command tflint "--format sarif --no-color" ""
When call run_step "${ACTION_DIR}" "lint"
The status should be success
The path "$OUTSIDE_TARGET" should not be exist
The path .tflint.hcl should be symlink
Assert sarif_file_is_in_reports_dir
End

It "writes no config to the workspace when none exists"
mock_command tflint "--format sarif --no-color" ""
When call run_step "${ACTION_DIR}" "lint"
The status should be success
The path .tflint.hcl should not be exist
End

It "keeps the repository's own config"
printf 'config {\n}\n' >.tflint.hcl
mock_command tflint "--config .tflint.hcl --format sarif --no-color" ""
When call run_step "${ACTION_DIR}" "lint"
The status should be success
The contents of file .tflint.hcl should equal "config {
}"
End

It "keeps a symlink that resolves to a config in the repository"
mkdir configs
printf 'config {\n}\n' >configs/tflint.hcl
ln -s configs/tflint.hcl .tflint.hcl
mock_command tflint "--config .tflint.hcl --format sarif --no-color" ""
When call run_step "${ACTION_DIR}" "lint"
The status should be success
The contents of file configs/tflint.hcl should equal "config {
}"
End

It "resolves the config relative to working-directory"
mkdir infra
printf 'config {\n}\n' >infra/.tflint.hcl
export INPUT_WORKING_DIRECTORY="infra"
mock_command tflint "--config .tflint.hcl --format sarif --no-color" ""
When call run_step "${ACTION_DIR}" "lint"
The status should be success
End

It "reports zero errors and the report when TFLint finds nothing"
mock_command tflint "--format sarif --no-color" '{"runs": []}'
When call run_step "${ACTION_DIR}" "lint"
The status should be success
Assert expect_output error_count "0"
Assert sarif_file_is_in_reports_dir
End

# Issues leave the step to finish: the formatting fixes are committed and the report uploaded
# before Fail on Issues ends the job.
It "finishes on issues, names the report and marks them for Fail on Issues"
mock_command tflint "--format sarif --no-color" '{"level": "error"}' 2
When call run_step "${ACTION_DIR}" "lint"
The status should be success
Assert expect_output error_count "1"
Assert expect_output issues true
Assert sarif_file_is_in_reports_dir
End

It "fails the job on issues only when fail-on-error is true, after the fixes and the upload"
When call yq -r '.runs.steps[] | select(.name == "Run Terraform Format" or .name == "Commit Fixes" or .name == "Upload SARIF Report" or .name == "Fail on Issues") | .name' "${ACTION_DIR}/action.yml"
The line 4 of output should equal "Fail on Issues"
End

It "takes the issues the lint step marked, and fail-on-error, as the condition to fail"
When call step_value "${ACTION_DIR}" "Fail on Issues" if
The output should equal "steps.lint.outputs.issues == 'true' && inputs.fail-on-error == 'true'"
End

# With force set in the TFLint config, a run with findings exits 0: its report is still counted,
# and Fail on Issues stays out of it, as force asks.
It "counts the errors in the report of a run that exits 0 with findings"
mock_command tflint "--format sarif --no-color" '{"level": "error"}'
When call run_step "${ACTION_DIR}" "lint"
The status should be success
Assert expect_output error_count "1"
The contents of file "$GITHUB_OUTPUT" should not include "issues="
End

# Exit status 1 means TFLint could not lint; its report holds the error, not the findings.
It "fails when TFLint could not lint, even with fail-on-error off, and names no report"
export INPUT_FAIL_ON_ERROR="false"
mock_command tflint "--format sarif --no-color" "Failed to load configurations" 1
When call run_step "${ACTION_DIR}" "lint"
The status should be failure
The stdout should include "::error::TFLint failed with exit status 1"
The stderr should include "Failed to load configurations"
The contents of file "$GITHUB_OUTPUT" should not include "sarif_file="
End
End

Describe "action.yml"
It "contains no step that generates a TFLint config"
The contents of file "${ACTION_DIR}/action.yml" should not include 'cat > "$CONFIG_FILE"'
End

It "does not call the --validate flag, which TFLint does not have"
The contents of file "${ACTION_DIR}/action.yml" should not include '--validate'
End
End
End
