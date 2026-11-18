#!/usr/bin/env shellspec
# biome-lint installs the action's package-lock.json with npm ci and runs that Biome by its path.
# Mocks match exact arguments, so anything else exits 127 and fails the example.

Describe "biome-lint tool pins"
ACTION_DIR="${PROJECT_ROOT}/biome-lint"

before() {
  shellspec_setup_test_env "biome-lint-pins-$$"
  harness_reset
  export INPUT_MAX_RETRIES="1"
}
BeforeEach 'before'

after() {
  shellspec_cleanup_test_env "biome-lint-pins-$$"
  harness_reset
}
AfterEach 'after'

Describe "Install Biome"
# mktemp names the prefix at random; the mock names it, so the layout below is where npm
# installed. npm itself is mocked, so the biome binary it would leave is laid out by hand.
before_install() {
  mkdir -p "${RUNNER_TEMP}/biome-lint-tools/node_modules/.bin"
  mock_command mktemp "-d ${RUNNER_TEMP}/biome-lint-tools.XXXXXX" "${RUNNER_TEMP}/biome-lint-tools"
}
BeforeEach 'before_install'

installed_biome() {
  _bin="${RUNNER_TEMP}/biome-lint-tools/node_modules/.bin/biome"
  printf '%s\n' '#!/bin/sh' 'echo "Version: 2.6.6"' >"$_bin"
  chmod +x "$_bin"
  printf '%s' "$_bin"
}

locked_install_args() {
  printf 'ci --prefix %s --ignore-scripts --no-audit --no-fund' "${RUNNER_TEMP}/biome-lint-tools"
}

It "installs the action's lockfile with npm ci and runs that Biome by path"
bin=$(installed_biome)
mock_command npm "$(locked_install_args)" ""
When call run_step "${ACTION_DIR}" "install-biome"
The status should be success
The stdout should include "Running Biome Version: 2.6.6 from $bin"
Assert expect_output bin "$bin"
End

It "installs the lockfile the action ships"
installed_biome >/dev/null
mock_command npm "$(locked_install_args)" ""
run_install() {
  run_step "${ACTION_DIR}" "install-biome" >/dev/null &&
    cmp "${ACTION_DIR}/package-lock.json" "${RUNNER_TEMP}/biome-lint-tools/package-lock.json" &&
    cmp "${ACTION_DIR}/package.json" "${RUNNER_TEMP}/biome-lint-tools/package.json"
}
When call run_install
The status should be success
End

# An older Biome on PATH plays no part: the steps after run the locked one by its path, and
# nothing goes on PATH for the rest of the job.
It "leaves PATH alone when another Biome is on it"
mock_command biome "--version" "Version: 1.9.4"
bin=$(installed_biome)
mock_command npm "$(locked_install_args)" ""
When call run_step "${ACTION_DIR}" "install-biome"
The status should be success
The stdout should include "from $bin"
The contents of file "$GITHUB_PATH" should equal ""
End

It "fails when npm ci leaves no biome binary"
mock_command npm "$(locked_install_args)" ""
When call run_step "${ACTION_DIR}" "install-biome"
The status should be failure
The stdout should include "::error::biome is not at ${RUNNER_TEMP}/biome-lint-tools/node_modules/.bin/biome after its install"
End

It "fails with an error when npm cannot install it"
mock_command npm "ci *" "" 1
When call run_step "${ACTION_DIR}" "install-biome"
The status should be failure
The stdout should include "::error::Failed to install Biome"
End
End

Describe "running the installed Biome"
# A copy the action installed runs by its path, kept whole however many spaces it holds.
It "checks with the Biome the install step named"
dir="${SHELLSPEC_TEST_TEMP_DIR}/runner temp/biome-lint-tools/node_modules/.bin"
mkdir -p "$dir"
printf '%s\n' '#!/bin/sh' 'printf "%s\n" "$*" >"$(dirname "$0")/argv"' 'printf "%s\n" "{\"runs\":[]}"' >"$dir/biome"
chmod +x "$dir/biome"
export HARNESS_STEP_OUTPUTS="{\"install-biome\":{\"outputs\":{\"bin\":\"$dir/biome\"}}}"
export INPUT_FAIL_ON_ERROR="true"
run_check() { run_step "${ACTION_DIR}" "check" >/dev/null && cat "$dir/argv"; }
When call run_check
The status should be success
The output should equal "check . --reporter=sarif"
End

It "fixes with the Biome the install step named"
dir="${SHELLSPEC_TEST_TEMP_DIR}/runner temp/biome-lint-tools/node_modules/.bin"
mkdir -p "$dir"
printf '%s\n' '#!/bin/sh' 'printf "%s\n" "$*" >"$(dirname "$0")/argv"' >"$dir/biome"
chmod +x "$dir/biome"
export HARNESS_STEP_OUTPUTS="{\"install-biome\":{\"outputs\":{\"bin\":\"$dir/biome\"}}}"
mock_command git "diff --name-only" ""
run_fix() { run_step "${ACTION_DIR}" "fix" >/dev/null && cat "$dir/argv"; }
When call run_fix
The status should be success
The output should equal "check --write ."
End

Parameters
"check"
"fix"
End

It "fails $1 mode when the install step named no Biome"
export HARNESS_STEP_OUTPUTS='{"install-biome":{"outputs":{"bin":""}}}'
export INPUT_FAIL_ON_ERROR="true"
mock_command git "diff --name-only" ""
When call run_step "${ACTION_DIR}" "$1"
The status should be failure
The stdout should include "::error::the install step named no Biome to run"
Assert expect_output status failure
End
End

It "ships a complete npm lock for its Biome"
When call package_lock_problems "${ACTION_DIR}"
The status should be success
The stdout should equal ""
End

# pnpm and Yarn are not involved: npm installs the action's own lockfile, whatever the
# repository uses.
It "does not set up a package manager just to install its own tool"
The contents of file "${ACTION_DIR}/action.yml" should not include "corepack"
The contents of file "${ACTION_DIR}/action.yml" should not include "setup-bun"
The contents of file "${ACTION_DIR}/action.yml" should not include "detect-pm"
End
End
