#!/usr/bin/env shellspec
# eslint-lint runs the repository's own ESLint when it has one, and otherwise installs the
# action's package-lock.json with npm ci instead of letting npx or bunx fetch whatever is newest.
# Mocks match exact arguments, so anything else exits 127 and fails the example.

Describe "eslint-lint tool pins"
ACTION_DIR="${PROJECT_ROOT}/eslint-lint"

before() {
  shellspec_setup_test_env "eslint-lint-pins-$$"
  harness_reset
}
BeforeEach 'before'

after() {
  shellspec_cleanup_test_env "eslint-lint-pins-$$"
  harness_reset
}
AfterEach 'after'

Describe "Install Package Manager"
It "prepares the pinned pnpm"
use_package_manager pnpm
mock_command corepack "prepare pnpm@$(pinned_version eslint-lint PNPM_VERSION) --activate" ""
When call run_step "${ACTION_DIR}" "install-pm"
The status should be success
End

It "prepares the pinned Yarn"
use_package_manager yarn
mock_command corepack "prepare yarn@$(pinned_version eslint-lint YARN_VERSION) --activate" ""
When call run_step "${ACTION_DIR}" "install-pm"
The status should be success
End
End

It "sets up the pinned Bun"
The contents of file "${ACTION_DIR}/action.yml" should include 'bun-version: ${{ env.BUN_VERSION }}'
End

Describe "Ensure ESLint"
FORMATTER="@microsoft/eslint-formatter-sarif"

before_ensure() {
  export RUNNER_TEMP="${SHELLSPEC_TEST_TEMP_DIR}/runner-temp"
  mkdir -p "$RUNNER_TEMP"
  export INPUT_REPORT_FORMAT="sarif"
  export GITHUB_WORKSPACE="$PWD"
}
BeforeEach 'before_ensure'

# Lay out what npm would leave in a prefix, since npm itself is mocked: an eslint binary that
# prints its version, and the SARIF formatter.
installed_eslint() {
  mkdir -p "$1/node_modules/.bin"
  printf '%s\n' '#!/bin/sh' 'echo v10.14.0' >"$1/node_modules/.bin/eslint"
  chmod +x "$1/node_modules/.bin/eslint"
  printf '%s' "$1/node_modules/.bin/eslint"
}

installed_formatter() {
  _dir="$1/node_modules/${FORMATTER}"
  mkdir -p "$_dir"
  printf '%s\n' '{"name": "@microsoft/eslint-formatter-sarif", "main": "sarif.js"}' >"$_dir/package.json"
  : >"$_dir/sarif.js"
  printf '%s' "$_dir/sarif.js"
}

locked_install_args() {
  printf 'ci --prefix %s --ignore-scripts --no-audit --no-fund' "${RUNNER_TEMP}/eslint-lint-tools"
}

# mktemp names each prefix at random; the mock names it, so the layout above is where npm
# installed.
mock_prefix() {
  mkdir -p "${RUNNER_TEMP}/$1"
  mock_command mktemp "-d ${RUNNER_TEMP}/$1.XXXXXX" "${RUNNER_TEMP}/$1"
}

Describe "when the repository has its own copy and formatter"
Parameters
# package manager, command, its arguments
"npm" "npx" "--no-install eslint"
"pnpm" "pnpm" "exec eslint"
"yarn" "yarn" "run --binaries-only eslint"
"bun" "bunx" "--no-install eslint"
End

# npm is not mocked, so any install fails the step.
It "runs it with $1 and installs nothing"
use_package_manager "$1"
mock_command yarn "--version" "4.18.1"
mkdir -p node_modules/eslint "node_modules/${FORMATTER}"
When call run_step "${ACTION_DIR}" "ensure-eslint"
The status should be success
Assert expect_output command "$2 $3"
Assert expect_output bin ""
Assert expect_output formatter "$FORMATTER"
End
End

# Yarn Plug'n'Play leaves no node_modules; package.json names what the repository has.
# --binaries-only keeps a package.json script named eslint from running in its place.
It "reads a Plug'n'Play repository's copy from package.json"
use_package_manager yarn
mock_command yarn "--version" "4.18.1"
printf '%s\n' '{"devDependencies": {"eslint": "^9.0.0", "@microsoft/eslint-formatter-sarif": "^3.0.0"}}' >package.json
When call run_step "${ACTION_DIR}" "ensure-eslint"
The status should be success
Assert expect_output command "yarn run --binaries-only eslint"
Assert expect_output formatter "$FORMATTER"
End

# Yarn 2 and later only see binaries of the nearest package's dependencies, so a child
# workspace that does not declare ESLint reaches the root's copy through --top-level.
It "runs the root workspace's Yarn copy from a child workspace that does not declare it"
use_package_manager yarn
mock_command yarn "--version" "4.18.1"
printf '%s\n' '{"workspaces": ["packages/*"], "devDependencies": {"eslint": "^9.0.0", "@microsoft/eslint-formatter-sarif": "^3.0.0"}}' >package.json
mkdir -p packages/app
printf '%s\n' '{"name": "app"}' >packages/app/package.json
cd packages/app || return 1
When call run_step "${ACTION_DIR}" "ensure-eslint"
The status should be success
Assert expect_output command "yarn run --top-level --binaries-only eslint"
Assert expect_output formatter "$FORMATTER"
End

# A directory below the workspace that declares ESLint is still that workspace for Yarn.
It "runs a child workspace's own Yarn copy from a directory below it"
use_package_manager yarn
mock_command yarn "--version" "4.18.1"
printf '%s\n' '{"workspaces": ["packages/*"]}' >package.json
mkdir -p packages/app/src
printf '%s\n' '{"name": "app", "devDependencies": {"eslint": "^9.0.0", "@microsoft/eslint-formatter-sarif": "^3.0.0"}}' \
  >packages/app/package.json
cd packages/app/src || return 1
When call run_step "${ACTION_DIR}" "ensure-eslint"
The status should be success
Assert expect_output command "yarn run --binaries-only eslint"
Assert expect_output formatter "$FORMATTER"
End

# Yarn 1 has no --binaries-only, but it always installs node_modules for npx.
It "runs a Yarn 1 repository's copy through npx"
use_package_manager yarn
mock_command yarn "--version" "1.22.22"
mkdir -p node_modules/eslint "node_modules/${FORMATTER}"
When call run_step "${ACTION_DIR}" "ensure-eslint"
The status should be success
Assert expect_output command "npx --no-install eslint"
End

# Yarn 1 Plug'n'Play has no node_modules for npx, so it runs through Yarn, as before this
# action pinned anything. Yarn 1 has no way to skip a script of the same name.
It "runs a Yarn 1 Plug'n'Play repository's copy through Yarn"
use_package_manager yarn
mock_command yarn "--version" "1.22.22"
printf '%s\n' '{"devDependencies": {"eslint": "^8.0.0", "@microsoft/eslint-formatter-sarif": "^3.0.0"}}' >package.json
When call run_step "${ACTION_DIR}" "ensure-eslint"
The status should be success
Assert expect_output command "yarn eslint"
End

# Node resolves packages through parent directories, so linting a subdirectory still finds them.
It "finds a copy installed at the repository root when the working directory is below it"
use_package_manager npm
mkdir -p node_modules/eslint "node_modules/${FORMATTER}" src
cd src || return 1
When call run_step "${ACTION_DIR}" "ensure-eslint"
The status should be success
Assert expect_output command "npx --no-install eslint"
Assert expect_output formatter "$FORMATTER"
End

It "looks no higher than the checkout"
use_package_manager npm
mkdir -p node_modules/eslint "node_modules/${FORMATTER}" src
export GITHUB_WORKSPACE="$PWD/src" INPUT_REPORT_FORMAT="stylish"
cd src || return 1
bin=$(installed_eslint "${RUNNER_TEMP}/eslint-lint-tools")
mock_prefix eslint-lint-tools
mock_command npm "$(locked_install_args)" ""
When call run_step "${ACTION_DIR}" "ensure-eslint"
The status should be success
The stdout should include "Running ESLint v10.14.0"
Assert expect_output command ""
Assert expect_output bin "$bin"
End

It "takes the SARIF formatter from the action's lockfile when the repository's own ESLint has none"
use_package_manager npm
mkdir -p node_modules/eslint
path=$(installed_formatter "${RUNNER_TEMP}/eslint-lint-tools")
mock_prefix eslint-lint-tools
mock_command npm "$(locked_install_args)" ""
When call run_step "${ACTION_DIR}" "ensure-eslint"
The status should be success
Assert expect_output command "npx --no-install eslint"
Assert expect_output bin ""
Assert expect_output formatter "$path"
End

It "installs no formatter for another report format"
use_package_manager npm
mkdir -p node_modules/eslint
export INPUT_REPORT_FORMAT="stylish"
When call run_step "${ACTION_DIR}" "ensure-eslint"
The status should be success
Assert expect_output command "npx --no-install eslint"
End

Describe "when the repository has no copy"
before_missing() {
  use_package_manager npm
  export INPUT_REPORT_FORMAT="stylish"
}
BeforeEach 'before_missing'

It "installs the action's lockfile with npm ci and runs that copy by path"
bin=$(installed_eslint "${RUNNER_TEMP}/eslint-lint-tools")
mock_prefix eslint-lint-tools
mock_command npm "$(locked_install_args)" ""
When call run_step "${ACTION_DIR}" "ensure-eslint"
The status should be success
The stdout should include "Running ESLint v10.14.0 from $bin"
Assert expect_output command ""
Assert expect_output bin "$bin"
The path "${RUNNER_TEMP}/eslint-lint-tools/package-lock.json" should be file
End

It "installs the lockfile the action ships"
installed_eslint "${RUNNER_TEMP}/eslint-lint-tools" >/dev/null
mock_prefix eslint-lint-tools
mock_command npm "$(locked_install_args)" ""
run_ensure() {
  run_step "${ACTION_DIR}" "ensure-eslint" >/dev/null &&
    cmp "${ACTION_DIR}/package-lock.json" "${RUNNER_TEMP}/eslint-lint-tools/package-lock.json" &&
    cmp "${ACTION_DIR}/package.json" "${RUNNER_TEMP}/eslint-lint-tools/package.json"
}
When call run_ensure
The status should be success
End

# npx --no-install also finds a global copy, so a probe that runs it would pick this one.
It "installs the locked copy even when an older global copy runs"
mock_command npx "--no-install eslint --version" "v8.0.0"
bin=$(installed_eslint "${RUNNER_TEMP}/eslint-lint-tools")
mock_prefix eslint-lint-tools
mock_command npm "$(locked_install_args)" ""
When call run_step "${ACTION_DIR}" "ensure-eslint"
The status should be success
The stdout should include "Running ESLint v10.14.0 from $bin"
Assert expect_output bin "$bin"
End

It "takes the SARIF formatter from the same locked install"
export INPUT_REPORT_FORMAT="sarif"
bin=$(installed_eslint "${RUNNER_TEMP}/eslint-lint-tools")
path=$(installed_formatter "${RUNNER_TEMP}/eslint-lint-tools")
mock_prefix eslint-lint-tools
mock_command npm "$(locked_install_args)" ""
When call run_step "${ACTION_DIR}" "ensure-eslint"
The status should be success
The stdout should include "Running ESLint v10.14.0 from $bin"
Assert expect_output bin "$bin"
Assert expect_output formatter "$path"
End

It "fails when npm ci leaves no eslint binary"
mock_prefix eslint-lint-tools
mock_command npm "$(locked_install_args)" ""
When call run_step "${ACTION_DIR}" "ensure-eslint"
The status should be failure
The stdout should include "::error::eslint is not at ${RUNNER_TEMP}/eslint-lint-tools/node_modules/.bin/eslint after its install"
End

It "fails the step when the locked install fails"
mock_prefix eslint-lint-tools
mock_command npm "ci *" "" 1
When call run_step "${ACTION_DIR}" "ensure-eslint"
The status should be failure
End

# The validator reads a version of only spaces as left out; npm would read it as any version.
It "reads an eslint-version of only spaces as left out"
export INPUT_ESLINT_VERSION="   "
bin=$(installed_eslint "${RUNNER_TEMP}/eslint-lint-tools")
mock_prefix eslint-lint-tools
mock_command npm "$(locked_install_args)" ""
When call run_step "${ACTION_DIR}" "ensure-eslint"
The status should be success
The stdout should include "Running ESLint v10.14.0 from $bin"
Assert expect_output bin "$bin"
End

Parameters
"9.39.1"
"latest"
End

# The lockfile holds one version, so a version the caller names comes from the registry,
# without lifecycle scripts.
It "installs $1 without lifecycle scripts when the caller asks for it"
export INPUT_ESLINT_VERSION="$1"
bin=$(installed_eslint "${RUNNER_TEMP}/eslint-lint-requested")
mock_prefix eslint-lint-requested
mock_command npm "install --prefix ${RUNNER_TEMP}/eslint-lint-requested --no-package-lock --no-audit --no-fund --ignore-scripts eslint@$1" ""
When call run_step "${ACTION_DIR}" "ensure-eslint"
The status should be success
The stdout should include "Running ESLint v10.14.0 from $bin"
Assert expect_output command ""
Assert expect_output bin "$bin"
End
End
End

Describe "running the resolved command"
before_run() {
  export HARNESS_STEP_OUTPUTS='{"ensure-eslint":{"outputs":{"command":"npx --no-install eslint","bin":"","formatter":"/tmp/f/sarif.js"}}}'
  export INPUT_FILE_EXTENSIONS=".js"
}
BeforeEach 'before_run'

# A copy the action installed runs by its path, kept whole however many spaces it holds.
It "runs the copy the action installed by its path"
dir="${SHELLSPEC_TEST_TEMP_DIR}/runner temp/eslint-lint-tools/node_modules/.bin"
mkdir -p "$dir"
printf '%s\n' '#!/bin/sh' 'printf "%s\n" "$*" >"$(dirname "$0")/argv"' >"$dir/eslint"
chmod +x "$dir/eslint"
export HARNESS_STEP_OUTPUTS="{\"ensure-eslint\":{\"outputs\":{\"command\":\"\",\"bin\":\"$dir/eslint\",\"formatter\":\"\"}}}"
export INPUT_CONFIG_FILE=".eslintrc" INPUT_CACHE="false" INPUT_MAX_WARNINGS="0"
export INPUT_REPORT_FORMAT="stylish" INPUT_FAIL_ON_ERROR="true"
run_check() { run_step "${ACTION_DIR}" "check" >/dev/null && cat "$dir/argv"; }
When call run_check
The status should be success
The output should equal ". --ext .js --max-warnings 0 --format stylish"
End

It "passes a config file other than the default on"
: >eslint.config.mjs
export INPUT_CONFIG_FILE="eslint.config.mjs" INPUT_CACHE="false" INPUT_MAX_WARNINGS="0"
export INPUT_REPORT_FORMAT="stylish" INPUT_FAIL_ON_ERROR="true"
mock_command npx "--no-install eslint . --ext .js --config eslint.config.mjs --max-warnings 0 --format stylish" ""
When call run_step "${ACTION_DIR}" "check"
The status should be success
The stdout should include "ESLint check completed"
End

Parameters
"check"
"fix"
End

It "fails $1 mode when a config file other than the default does not exist"
export INPUT_CONFIG_FILE="missing.config.mjs" INPUT_CACHE="false" INPUT_MAX_WARNINGS="0"
export INPUT_REPORT_FORMAT="stylish" INPUT_FAIL_ON_ERROR="true"
mock_command git "diff *" ""
When call run_step "${ACTION_DIR}" "$1"
The status should be failure
The stdout should include "::error::config-file missing.config.mjs does not exist"
Assert expect_output status failure
End

It "writes SARIF through the formatter the ensure step chose"
export INPUT_CONFIG_FILE=".eslintrc" INPUT_CACHE="false" INPUT_MAX_WARNINGS="0"
export INPUT_REPORT_FORMAT="sarif" INPUT_FAIL_ON_ERROR="true"
mock_command npx "--no-install eslint . --ext .js --max-warnings 0 --format /tmp/f/sarif.js --output-file eslint-results.sarif" ""
When call run_step "${ACTION_DIR}" "check"
The status should be success
The stdout should include "ESLint check completed"
End

It "checks with it"
export INPUT_CONFIG_FILE=".eslintrc" INPUT_CACHE="false" INPUT_MAX_WARNINGS="0"
export INPUT_REPORT_FORMAT="stylish" INPUT_FAIL_ON_ERROR="true"
mock_command npx "--no-install eslint . --ext .js --max-warnings 0 --format stylish" ""
When call run_step "${ACTION_DIR}" "check"
The status should be success
The stdout should include "ESLint check completed"
Assert expect_output status success
End

It "fixes with it"
mock_command npx "--no-install eslint . --ext .js --fix" ""
mock_command git "diff *" ""
When call run_step "${ACTION_DIR}" "fix"
The status should be success
The stdout should include "ESLint fix completed"
Assert expect_output status success
End

It "fixes with the config file check mode uses"
: >eslint.config.mjs
export INPUT_CONFIG_FILE="eslint.config.mjs"
mock_command npx "--no-install eslint . --ext .js --fix --config eslint.config.mjs" ""
mock_command git "diff *" ""
When call run_step "${ACTION_DIR}" "fix"
The status should be success
The stdout should include "ESLint fix completed"
Assert expect_output status success
End

# Exit status 1 is problems --fix could not fix; what it fixed is still committed.
It "keeps what it fixed when problems remain"
mock_command npx "--no-install eslint . --ext .js --fix" "" 1
mock_command git "diff *" ""
When call run_step "${ACTION_DIR}" "fix"
The status should be success
The stdout should include "ESLint fix completed"
Assert expect_output status success
End

It "fails when ESLint cannot run, as with a bad configuration"
mock_command npx "--no-install eslint . --ext .js --fix" "" 2
mock_command git "diff *" ""
When call run_step "${ACTION_DIR}" "fix"
The status should equal 2
The stdout should include "::error::ESLint failed with exit status 2"
Assert expect_output status failure
End
End
End
