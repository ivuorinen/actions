#!/usr/bin/env shellspec
# eslint-lint runs the repository's own ESLint when it has one, and otherwise installs a pinned
# copy instead of letting npx or bunx fetch whatever is newest. Mocks match exact arguments, so
# anything else exits 127 and fails the example.

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

# Lay out what `npm install --prefix` would leave, since npm itself is mocked.
installed_formatter() {
  _dir="${RUNNER_TEMP}/eslint-formatter-sarif/node_modules/${FORMATTER}"
  mkdir -p "$_dir"
  printf '%s\n' '{"name": "@microsoft/eslint-formatter-sarif", "main": "sarif.js"}' >"$_dir/package.json"
  : >"$_dir/sarif.js"
  printf '%s' "$_dir/sarif.js"
}

formatter_install_args() {
  printf 'install --prefix %s --no-package-lock --no-audit --no-fund --ignore-scripts %s@%s' \
    "${RUNNER_TEMP}/eslint-formatter-sarif" "$FORMATTER" "$(pinned_version eslint-lint ESLINT_FORMATTER_SARIF_VERSION)"
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
mock_command npm "install -g eslint@$(pinned_version eslint-lint DEFAULT_ESLINT_VERSION)" ""
When call run_step "${ACTION_DIR}" "ensure-eslint"
The status should be success
Assert expect_output command "eslint"
End

It "installs the SARIF formatter apart when the repository's own ESLint has none"
use_package_manager npm
mkdir -p node_modules/eslint
path=$(installed_formatter)
mock_command npm "$(formatter_install_args)" ""
When call run_step "${ACTION_DIR}" "ensure-eslint"
The status should be success
Assert expect_output command "npx --no-install eslint"
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

It "installs the pinned version and runs that"
mock_command npm "install -g eslint@$(pinned_version eslint-lint DEFAULT_ESLINT_VERSION)" ""
When call run_step "${ACTION_DIR}" "ensure-eslint"
The status should be success
Assert expect_output command "eslint"
End

# npx --no-install also finds a global copy, so a probe that runs it would pick this one.
It "installs the pinned version even when an older global copy runs"
mock_command npx "--no-install eslint --version" "v8.0.0"
mock_command npm "install -g eslint@$(pinned_version eslint-lint DEFAULT_ESLINT_VERSION)" ""
When call run_step "${ACTION_DIR}" "ensure-eslint"
The status should be success
Assert expect_output command "eslint"
End

It "installs the SARIF formatter apart for the pinned copy"
export INPUT_REPORT_FORMAT="sarif"
path=$(installed_formatter)
mock_command npm "install -g eslint@$(pinned_version eslint-lint DEFAULT_ESLINT_VERSION)" ""
mock_command npm "$(formatter_install_args)" ""
When call run_step "${ACTION_DIR}" "ensure-eslint"
The status should be success
Assert expect_output command "eslint"
Assert expect_output formatter "$path"
End

Parameters
"9.39.1"
"latest"
End

It "installs $1 when the caller asks for it"
export INPUT_ESLINT_VERSION="$1"
mock_command npm "install -g eslint@$1" ""
When call run_step "${ACTION_DIR}" "ensure-eslint"
The status should be success
Assert expect_output command "eslint"
End
End

It "fails the step when the pinned version cannot be installed"
use_package_manager npm
mock_command npm "install -g *" "" 1
When call run_step "${ACTION_DIR}" "ensure-eslint"
The status should be failure
End
End

Describe "running the resolved command"
before_run() {
  export HARNESS_STEP_OUTPUTS='{"ensure-eslint":{"outputs":{"command":"npx --no-install eslint","formatter":"/tmp/f/sarif.js"}}}'
  export INPUT_FILE_EXTENSIONS=".js"
}
BeforeEach 'before_run'

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
End
End
