#!/usr/bin/env shellspec
# Behavior tests for terraform-lint-fix: log output built from repository filenames
# must not form workflow commands, and the action must keep TFLint plugins in a
# directory of its own instead of the runner's shared ~/.tflint.d.

Describe "terraform-lint-fix isolation"
ACTION_DIR="${PROJECT_ROOT}/terraform-lint-fix"

before() {
  shellspec_setup_test_env "terraform-lint-fix-isolation-$$"
  harness_reset
  export RUNNER_TEMP="${SHELLSPEC_TEST_TEMP_DIR}/runner-temp"
  export HOME="${SHELLSPEC_TEST_TEMP_DIR}/home"
  mkdir -p "$RUNNER_TEMP" "$HOME"
}
BeforeEach 'before'

after() {
  shellspec_cleanup_test_env "terraform-lint-fix-isolation-$$"
  harness_reset
}
AfterEach 'after'

# True when no output line starts a workflow command other than the action's own warning.
no_injected_command() {
  ! printf '%s\n' "$SHELLSPEC_SUBJECT" | grep -E '^::' | grep -Ev '^::warning::Invalid Terraform syntax in '
}

Describe "Validate Terraform Syntax"
It "keeps a filename with a newline from starting a workflow command"
injected="$(printf 'x\n::error::injected')"
printf 'a = 1\n' >"${injected}.tf"
mock_command terraform "fmt -check=true *" "" 1
When call run_step "${ACTION_DIR}" "syntax"
The status should be success
The stdout should satisfy no_injected_command
End

It "still reports the invalid file by name"
printf 'a = 1\n' >bad.tf
mock_command terraform "fmt -check=true *" "" 1
When call run_step "${ACTION_DIR}" "syntax"
The status should be success
The stdout should include "::warning::Invalid Terraform syntax in ./bad.tf"
End
End

Describe "Isolate TFLint Plugins"
It "points TFLINT_PLUGIN_DIR under RUNNER_TEMP for the later steps"
When call run_step "${ACTION_DIR}" "plugin-dir"
The status should be success
The contents of file "$GITHUB_ENV" should include "TFLINT_PLUGIN_DIR=${RUNNER_TEMP}/"
End
End

Describe "Cleanup"
It "removes only the plugin directory of the action"
mkdir -p "${HOME}/.tflint.d/plugins" "${RUNNER_TEMP}/tflint-plugins"
export TFLINT_PLUGIN_DIR="${RUNNER_TEMP}/tflint-plugins"
When call run_step "${ACTION_DIR}" "cleanup"
The status should be success
The path "${RUNNER_TEMP}/tflint-plugins" should not be exist
The path "${HOME}/.tflint.d/plugins" should be directory
End

It "succeeds when the plugin step never ran"
unset TFLINT_PLUGIN_DIR
When call run_step "${ACTION_DIR}" "cleanup"
The status should be success
End

It "keeps a plugin directory the caller set"
mkdir -p "${HOME}/caller-plugins"
export TFLINT_PLUGIN_DIR="${HOME}/caller-plugins"
When call run_step "${ACTION_DIR}" "cleanup"
The status should be success
The path "${HOME}/caller-plugins" should be directory
End
End

Describe "action.yml"
It "no longer deletes the runner's shared ~/.tflint.d"
The contents of file "${ACTION_DIR}/action.yml" should not include '~/.tflint.d'
End
End
End
