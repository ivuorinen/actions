#!/usr/bin/env shellspec
# Behavior tests for go-lint's config handling.
#
# `[ ! -f path ]` is true for a dangling symlink, so writing the default config to
# the configured path follows the link to wherever the repository points it. The
# default config therefore lives in $RUNNER_TEMP, and the workspace is only read.
# Without .golangci.yml, the other names golangci-lint documents count as the
# repository's config; a config-file other than the default must exist.
#
# The mocks match golangci-lint's exact argv, so an unexpected config path or an
# unsupported flag matches no glob, the dispatcher exits 127, and the step fails.

Describe "go-lint config handling (behavior)"
ACTION_DIR="${PROJECT_ROOT}/go-lint"

before() {
  shellspec_setup_test_env "go-lint-behavior-$$"
  harness_reset
  export RUNNER_TEMP="${SHELLSPEC_TEST_TEMP_DIR}/runner-temp"
  mkdir -p "$RUNNER_TEMP"
  # The default config, in a new directory under RUNNER_TEMP: a glob, as for REPORT.
  DEFAULT_CONFIG="${RUNNER_TEMP}/go-lint-config.*/golangci-lint-default.yml"
  # golangci-lint writes the report itself, into a fresh directory under RUNNER_TEMP.
  REPORT="${RUNNER_TEMP}/go-lint.*/golangci-lint.sarif"
  OUTSIDE_TARGET="${SHELLSPEC_TEST_TEMP_DIR}/outside-workspace.yml"
  export INPUT_WORKING_DIRECTORY="."
  export INPUT_CONFIG_FILE=".golangci.yml"
  export INPUT_TIMEOUT="5m"
  export INPUT_CACHE="true"
  export INPUT_ONLY_NEW_ISSUES="true"
  export INPUT_DISABLE_ALL="false"
  export INPUT_REPORT_FORMAT="sarif"
  export INPUT_FAIL_ON_ERROR="true"
}
BeforeEach 'before'

after() {
  shellspec_cleanup_test_env "go-lint-behavior-$$"
  harness_reset
}
AfterEach 'after'

# run_step resolves no step outputs, so run the two steps through the harness's
# sequential runner: the lint step's config path comes from the config step.
run_config_then_lint() {
  local steps_dir="${SHELLSPEC_TEST_TEMP_DIR}/config-then-lint"
  mkdir -p "$steps_dir"
  yq '.runs.steps |= map(select(.id == "config" or .id == "lint"))' \
    "${ACTION_DIR}/action.yml" >"${steps_dir}/action.yml"
  run_all_owned_steps "$steps_dir"
}

# default_configs: each default config the config step wrote.
default_configs() {
  compgen -G "$DEFAULT_CONFIG" || true
}

no_default_config() {
  [ -z "$(default_configs)" ]
}

# default_config_written [TEXT]: one default config was written, holding TEXT, and the
# step published it as config_file and its directory as config_dir.
default_config_written() {
  local path
  path=$(default_configs)
  [ -n "$path" ] && [ "$(printf '%s\n' "$path" | wc -l)" -eq 1 ] || return 1
  grep -qxF "config_file=$path" "$GITHUB_OUTPUT" || return 1
  grep -qxF "config_dir=${path%/*}" "$GITHUB_OUTPUT" || return 1
  [ -z "${1:-}" ] || grep -qF -- "$1" "$path"
}

Describe "Prepare Configuration"
It "does not write through a dangling config symlink"
ln -s "$OUTSIDE_TARGET" .golangci.yml
When call run_step "${ACTION_DIR}" "config"
The status should be success
The stdout should include "Creating default golangci-lint configuration"
The path "$OUTSIDE_TARGET" should not be exist
The path .golangci.yml should be symlink
Assert default_config_written
End

It "writes nothing to the workspace when no config exists"
When call run_step "${ACTION_DIR}" "config"
The status should be success
The stdout should include "Creating default golangci-lint configuration"
The path .golangci.yml should not be exist
Assert default_config_written "linters:"
End

# A fixed path could be made, or filled, by another job on the machine first.
It "writes the default config into another new directory on each run"
run_step "${ACTION_DIR}" "config" >/dev/null
first=$(default_configs)
: >"$GITHUB_OUTPUT"
When call run_step "${ACTION_DIR}" "config"
The status should be success
The stdout should include "Creating default golangci-lint configuration"
Assert test "$(default_configs | grep -cvxF "$first")" -eq 1
End

It "keeps the repository's own config"
printf 'run:\n  tests: false\n' >.golangci.yml
When call run_step "${ACTION_DIR}" "config"
The status should be success
The contents of file .golangci.yml should equal "run:
  tests: false"
Assert no_default_config
Assert expect_output config_file ".golangci.yml"
End

It "keeps a symlink that resolves to a config in the repository"
mkdir configs
printf 'run:\n  tests: false\n' >configs/golangci.yml
ln -s configs/golangci.yml .golangci.yml
When call run_step "${ACTION_DIR}" "config"
The status should be success
The contents of file configs/golangci.yml should equal "run:
  tests: false"
Assert no_default_config
Assert expect_output config_file ".golangci.yml"
End

It "resolves the config relative to working-directory"
mkdir svc
printf 'run:\n  tests: false\n' >svc/.golangci.yml
export INPUT_WORKING_DIRECTORY="svc"
When call run_step "${ACTION_DIR}" "config"
The status should be success
Assert no_default_config
Assert expect_output config_file ".golangci.yml"
End

It "keeps a config-file other than the default"
printf 'run:\n  tests: false\n' >custom.yml
export INPUT_CONFIG_FILE="custom.yml"
When call run_step "${ACTION_DIR}" "config"
The status should be success
Assert no_default_config
Assert expect_output config_file "custom.yml"
End

# The validator takes an empty value as unset, so it means the default here too.
It "takes an empty config-file as the default"
printf 'run:\n  tests: false\n' >.golangci.yml
export INPUT_CONFIG_FILE=""
When call run_step "${ACTION_DIR}" "config"
The status should be success
Assert expect_output config_file ".golangci.yml"
End

# A mistyped path would otherwise lint with the built-in default.
It "fails on a config-file other than the default that does not exist"
export INPUT_CONFIG_FILE="custom.yml"
When call run_step "${ACTION_DIR}" "config"
The status should be failure
The stdout should include "::error::config-file custom.yml does not exist"
Assert no_default_config
End

# golangci-lint documents four names for its config; the default input names only one.
Describe "a config under another name golangci-lint documents"
Parameters
".golangci.yaml"
".golangci.toml"
".golangci.json"
End

It "uses the repository's $1 when .golangci.yml is absent"
: >"$1"
When call run_step "${ACTION_DIR}" "config"
The status should be success
Assert no_default_config
Assert expect_output config_file "$1"
End
End
End

Describe "Run golangci-lint"
It "lints with the default config when the repository has a dangling symlink"
ln -s "$OUTSIDE_TARGET" .golangci.yml
mock_command golangci-lint "run --config ${DEFAULT_CONFIG} --timeout 5m --issues-exit-code=1 --new --output.sarif.path=${REPORT} ./..." ""
When call run_config_then_lint
The status should be success
The stdout should include "Running golangci-lint"
The path "$OUTSIDE_TARGET" should not be exist
End

It "lints with the repository's own config when it has one"
printf 'run:\n  tests: false\n' >.golangci.yml
mock_command golangci-lint "run --config .golangci.yml --timeout 5m --issues-exit-code=1 --new --output.sarif.path=${REPORT} ./..." ""
When call run_config_then_lint
The status should be success
The stdout should include "Running golangci-lint"
Assert no_default_config
End

It "passes no cache flag when caching is disabled, as golangci-lint has none"
export INPUT_CACHE="false"
mock_command golangci-lint "run --config ${DEFAULT_CONFIG} --timeout 5m --issues-exit-code=1 --new --output.sarif.path=${REPORT} ./..." ""
When call run_config_then_lint
The status should be success
The stdout should include "Running golangci-lint"
End

Describe "exit status"
# A repository's run.issues-exit-code would otherwise decide which status means issues.
It "pins the exit status for found issues to 1"
When call step_value "${ACTION_DIR}" lint run
The output should include 'set -- --config "$CONFIG_FILE" --timeout "$TIMEOUT" --issues-exit-code=1'
End

It "passes on issues with fail-on-error off, and names the report"
export INPUT_FAIL_ON_ERROR="false"
mock_command golangci-lint "run *" "" 1
When call run_config_then_lint
The status should be success
The stdout should include "Running golangci-lint"
The contents of file "$GITHUB_OUTPUT" should include "sarif_file="
End

It "fails on issues with fail-on-error on, after naming the report"
mock_command golangci-lint "run *" "" 1
When call run_config_then_lint
The status should be failure
The stdout should include "::error::golangci-lint found 0 issues"
The contents of file "$GITHUB_OUTPUT" should include "sarif_file="
End

# 3 failure, 4 timeout, 5 no Go files, 7 an error was logged: golangci-lint did not finish.
Parameters
3
4
5
7
End

It "fails on exit status $1 even with fail-on-error off, and names no report"
export INPUT_FAIL_ON_ERROR="false"
mock_command golangci-lint "run *" "" "$1"
When call run_config_then_lint
The status should be failure
The stdout should include "::error::golangci-lint failed with exit status $1"
The contents of file "$GITHUB_OUTPUT" should not include "sarif_file="
The contents of file "$GITHUB_OUTPUT" should not include "analyzed_files="
End
End
End

Describe "Cleanup"
It "removes the directory of the default config"
mkdir -p "${RUNNER_TEMP}/go-lint-config.abc123"
: >"${RUNNER_TEMP}/go-lint-config.abc123/golangci-lint-default.yml"
export HARNESS_STEP_OUTPUTS="{\"config\":{\"outputs\":{\"config_dir\":\"${RUNNER_TEMP}/go-lint-config.abc123\"}}}"
When call run_step "${ACTION_DIR}" "cleanup"
The status should be success
The path "${RUNNER_TEMP}/go-lint-config.abc123" should not be exist
End

It "removes nothing when the repository has its own config"
printf 'run:\n  tests: false\n' >.golangci.yml
When call run_step "${ACTION_DIR}" "cleanup"
The status should be success
The path .golangci.yml should be file
End
End
End
