#!/usr/bin/env shellspec
# Behavior tests for terraform-lint-fix's config handling.
#
# The action reads the configured TFLint config when it resolves to a regular file
# and otherwise lets TFLint fall back to its own lookup. It generates no config, so
# a dangling symlink committed at the configured path is never a write target.
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
End

Describe "Run TFLint"
It "does not pass or write through a dangling config symlink"
ln -s "$OUTSIDE_TARGET" .tflint.hcl
mock_command tflint "--format sarif --no-color" ""
When call run_step "${ACTION_DIR}" "lint"
The status should be success
The path "$OUTSIDE_TARGET" should not be exist
The path .tflint.hcl should be symlink
Assert expect_output sarif_file "reports/tflint.sarif"
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
