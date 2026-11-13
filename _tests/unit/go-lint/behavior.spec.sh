#!/usr/bin/env shellspec
# Behavior tests for go-lint's config handling.
#
# `[ ! -f path ]` is true for a dangling symlink, so writing the default config to
# the configured path follows the link to wherever the repository points it. The
# default config therefore lives in $RUNNER_TEMP, and the workspace is only read.
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
  DEFAULT_CONFIG="${RUNNER_TEMP}/golangci-lint-default.yml"
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

Describe "Prepare Configuration"
It "does not write through a dangling config symlink"
ln -s "$OUTSIDE_TARGET" .golangci.yml
When call run_step "${ACTION_DIR}" "config"
The status should be success
The stdout should include "Creating default golangci-lint configuration"
The path "$OUTSIDE_TARGET" should not be exist
The path .golangci.yml should be symlink
The file "$DEFAULT_CONFIG" should be exist
Assert expect_output config_file "$DEFAULT_CONFIG"
End

It "writes nothing to the workspace when no config exists"
When call run_step "${ACTION_DIR}" "config"
The status should be success
The stdout should include "Creating default golangci-lint configuration"
The path .golangci.yml should not be exist
The contents of file "$DEFAULT_CONFIG" should include "linters:"
Assert expect_output config_file "$DEFAULT_CONFIG"
End

It "keeps the repository's own config"
printf 'run:\n  tests: false\n' >.golangci.yml
When call run_step "${ACTION_DIR}" "config"
The status should be success
The contents of file .golangci.yml should equal "run:
  tests: false"
The path "$DEFAULT_CONFIG" should not be exist
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
The path "$DEFAULT_CONFIG" should not be exist
Assert expect_output config_file ".golangci.yml"
End

It "resolves the config relative to working-directory"
mkdir svc
printf 'run:\n  tests: false\n' >svc/.golangci.yml
export INPUT_WORKING_DIRECTORY="svc"
When call run_step "${ACTION_DIR}" "config"
The status should be success
The path "$DEFAULT_CONFIG" should not be exist
Assert expect_output config_file ".golangci.yml"
End
End

Describe "Run golangci-lint"
It "lints with the default config when the repository has a dangling symlink"
ln -s "$OUTSIDE_TARGET" .golangci.yml
mock_command golangci-lint "run --config ${DEFAULT_CONFIG} --timeout 5m --new --out-format sarif ./..." ""
When call run_config_then_lint
The status should be success
The stdout should include "Running golangci-lint"
The path "$OUTSIDE_TARGET" should not be exist
End

It "lints with the repository's own config when it has one"
printf 'run:\n  tests: false\n' >.golangci.yml
mock_command golangci-lint "run --config .golangci.yml --timeout 5m --new --out-format sarif ./..." ""
When call run_config_then_lint
The status should be success
The stdout should include "Running golangci-lint"
The path "$DEFAULT_CONFIG" should not be exist
End

It "passes no cache flag when caching is disabled, as golangci-lint has none"
export INPUT_CACHE="false"
mock_command golangci-lint "run --config ${DEFAULT_CONFIG} --timeout 5m --new --out-format sarif ./..." ""
When call run_config_then_lint
The status should be success
The stdout should include "Running golangci-lint"
End
End
End
