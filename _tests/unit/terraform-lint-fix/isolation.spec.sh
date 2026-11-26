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
  ! printf '%s\n' "$SHELLSPEC_SUBJECT" | grep -E '^::' | grep -Ev '^::warning::.* is not formatted, or is not valid Terraform$'
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

It "still reports the file by name"
printf 'a = 1\n' >bad.tf
mock_command terraform "fmt -check=true *" "" 1
When call run_step "${ACTION_DIR}" "syntax"
The status should be success
The stdout should include "::warning::./bad.tf is not formatted, or is not valid Terraform"
End
End

Describe "Fix Formatting"
# fmt -check exits 3 for a file it would rewrite. The mocks match in the order they are added.
It "formats and counts each file fmt would rewrite, keeping a name with a newline whole"
nl_name="$(printf 'a\nb.tf')"
printf 'a = 1\n' >"$nl_name"
printf 'b = 2\n' >main.tf
mock_command terraform "fmt -check *" "" 3
mock_command terraform "fmt *" "" 0
When call run_step "${ACTION_DIR}" "fix"
The status should be success
Assert expect_output fixed_count 2
Assert expect_argv terraform fmt "./${nl_name}"
End

# terraform fmt follows a symlink and rewrites its target, which can lie outside the workspace.
It "leaves a symlink named like a Terraform file alone"
printf 'a = 1\n' >"${SHELLSPEC_TMPBASE}/outside.tf"
ln -s "${SHELLSPEC_TMPBASE}/outside.tf" link.tf
printf 'b = 2\n' >main.tf
mock_command terraform "fmt -check *" "" 3
mock_command terraform "fmt *" "" 0
When call run_step "${ACTION_DIR}" "fix"
The status should be success
Assert expect_output fixed_count 1
The contents of file "${HARNESS_SESSION}/calls.jsonl" should not include "link.tf"
End

It "fails without a count when terraform fmt fails"
printf 'a = \n' >broken.tf
mock_command terraform "fmt -check *" "" 2
mock_command terraform "fmt *" "Error: Invalid expression" 1
When call run_step "${ACTION_DIR}" "fix"
The status should be failure
The stdout should include "Error: Invalid expression"
The contents of file "$GITHUB_OUTPUT" should not include "fixed_count"
End
End

Describe "Isolate TFLint Plugins"
github_env_is_empty() {
  [ ! -s "$GITHUB_ENV" ]
}

# published_dir: the dir output the step wrote, or nothing.
published_dir() {
  sed -n 's/^dir=//p' "$GITHUB_OUTPUT"
}

# A new directory under RUNNER_TEMP, made empty by mktemp, as a step output.
plugin_dir_is_new() {
  dir=$(published_dir)
  case "$dir" in
  "${RUNNER_TEMP}/terraform-lint-fix-plugins."??????) ;;
  *) return 1 ;;
  esac
  [ -d "$dir" ] && [ -z "$(ls -A "$dir")" ]
}

It "publishes a new, empty plugin directory under RUNNER_TEMP as a step output"
When call run_step "${ACTION_DIR}" "plugin-dir"
The status should be success
Assert plugin_dir_is_new
End

# A fixed path could be made, and filled with plugin executables, by another job on
# the machine before TFLint loads them.
It "uses another directory on each run"
run_step "${ACTION_DIR}" "plugin-dir"
first=$(published_dir)
: >"$GITHUB_OUTPUT"
When call run_step "${ACTION_DIR}" "plugin-dir"
The status should be success
Assert test "$(published_dir)" != "$first"
End

# GITHUB_ENV would reach the caller's steps after this action, and override a
# TFLINT_PLUGIN_DIR they set with a directory Cleanup deletes.
It "leaves the caller's later steps alone"
When call run_step "${ACTION_DIR}" "plugin-dir"
The status should be success
Assert github_env_is_empty
End

It "hands the directory to Initialize TFLint and Run TFLint only"
When call yq -r '.runs.steps[] | select(.env.TFLINT_PLUGIN_DIR != null) | .id + " " + .env.TFLINT_PLUGIN_DIR' "${ACTION_DIR}/action.yml"
The line 1 of output should equal 'init ${{ steps.plugin-dir.outputs.dir }}'
The line 2 of output should equal 'lint ${{ steps.plugin-dir.outputs.dir }}'
The lines of output should equal 2
End
End

Describe "Cleanup"
It "removes only the plugin directory of the action"
mkdir -p "${HOME}/.tflint.d/plugins" "${RUNNER_TEMP}/terraform-lint-fix-plugins.abc123"
export HARNESS_STEP_OUTPUTS="{\"plugin-dir\":{\"outputs\":{\"dir\":\"${RUNNER_TEMP}/terraform-lint-fix-plugins.abc123\"}}}"
When call run_step "${ACTION_DIR}" "cleanup"
The status should be success
The path "${RUNNER_TEMP}/terraform-lint-fix-plugins.abc123" should not be exist
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
