#!/usr/bin/env shellspec
# prettier-lint runs the repository's own Prettier when it has one, and otherwise installs a
# pinned copy instead of letting npx fetch whatever is newest. Mocks match exact arguments, so
# anything else exits 127 and fails the example.

Describe "prettier-lint tool pins"
ACTION_DIR="${PROJECT_ROOT}/prettier-lint"

before() {
  shellspec_setup_test_env "prettier-lint-pins-$$"
  harness_reset
}
BeforeEach 'before'

after() {
  shellspec_cleanup_test_env "prettier-lint-pins-$$"
  harness_reset
}
AfterEach 'after'

Describe "Install Package Manager"
It "prepares the pinned pnpm"
use_package_manager pnpm
mock_command corepack "prepare pnpm@$(pinned_version prettier-lint PNPM_VERSION) --activate" ""
When call run_step "${ACTION_DIR}" "install-pm"
The status should be success
End

It "prepares the pinned Yarn"
use_package_manager yarn
mock_command corepack "prepare yarn@$(pinned_version prettier-lint YARN_VERSION) --activate" ""
When call run_step "${ACTION_DIR}" "install-pm"
The status should be success
End
End

It "sets up the pinned Bun"
The contents of file "${ACTION_DIR}/action.yml" should include 'bun-version: ${{ env.BUN_VERSION }}'
End

Describe "Ensure Prettier"
before_ensure() {
  export GITHUB_WORKSPACE="$PWD"
}
BeforeEach 'before_ensure'

Describe "when the repository has its own copy"
Parameters
# package manager, command, its arguments
"npm" "npx" "--no-install prettier"
"pnpm" "pnpm" "exec prettier"
"yarn" "yarn" "run --binaries-only prettier"
"bun" "bunx" "--no-install prettier"
End

# npm is not mocked, so any install fails the step.
It "runs it with $1 and installs nothing"
use_package_manager "$1"
mock_command yarn "--version" "4.18.1"
mkdir -p node_modules/prettier
When call run_step "${ACTION_DIR}" "ensure-prettier"
The status should be success
Assert expect_output command "$2 $3"
End
End

# Yarn Plug'n'Play leaves no node_modules, and npx cannot load a copy through its loader.
# --binaries-only keeps a package.json script named prettier from running in its place.
It "runs a Plug'n'Play repository's copy through Yarn"
use_package_manager yarn
mock_command yarn "--version" "4.18.1"
printf '%s\n' '{"devDependencies": {"prettier": "^3.0.0"}}' >package.json
When call run_step "${ACTION_DIR}" "ensure-prettier"
The status should be success
Assert expect_output command "yarn run --binaries-only prettier"
End

# Yarn 1 has no --binaries-only, but it has no Plug'n'Play and always installs node_modules.
It "runs a Yarn 1 repository's copy through npx"
use_package_manager yarn
mock_command yarn "--version" "1.22.22"
mkdir -p node_modules/prettier
When call run_step "${ACTION_DIR}" "ensure-prettier"
The status should be success
Assert expect_output command "npx --no-install prettier"
End

# Node resolves packages through parent directories, so a subdirectory still finds them.
It "finds a copy installed at the repository root when the working directory is below it"
use_package_manager npm
mkdir -p node_modules/prettier src
cd src || return 1
When call run_step "${ACTION_DIR}" "ensure-prettier"
The status should be success
Assert expect_output command "npx --no-install prettier"
End

It "looks no higher than the checkout"
use_package_manager npm
mkdir -p node_modules/prettier src
export GITHUB_WORKSPACE="$PWD/src"
cd src || return 1
mock_command npm "install -g prettier@$(pinned_version prettier-lint DEFAULT_PRETTIER_VERSION)" ""
When call run_step "${ACTION_DIR}" "ensure-prettier"
The status should be success
Assert expect_output command "prettier"
End

Describe "when the repository has no copy"
before_missing() {
  use_package_manager npm
}
BeforeEach 'before_missing'

It "installs the pinned version and runs that"
mock_command npm "install -g prettier@$(pinned_version prettier-lint DEFAULT_PRETTIER_VERSION)" ""
When call run_step "${ACTION_DIR}" "ensure-prettier"
The status should be success
Assert expect_output command "prettier"
End

# npx --no-install also finds a global copy, so a probe that runs it would pick this one.
It "installs the pinned version even when an older global copy runs"
mock_command npx "--no-install prettier --version" "2.0.0"
mock_command npm "install -g prettier@$(pinned_version prettier-lint DEFAULT_PRETTIER_VERSION)" ""
When call run_step "${ACTION_DIR}" "ensure-prettier"
The status should be success
Assert expect_output command "prettier"
End

Parameters
"3.0.0"
"latest"
End

It "installs $1 when the caller asks for it"
export INPUT_PRETTIER_VERSION="$1"
mock_command npm "install -g prettier@$1" ""
When call run_step "${ACTION_DIR}" "ensure-prettier"
The status should be success
End
End

It "fails the step when the pinned version cannot be installed"
use_package_manager npm
mock_command npm "install -g *" "" 1
When call run_step "${ACTION_DIR}" "ensure-prettier"
The status should be failure
End
End

Describe "running the resolved command"
before_run() {
  export HARNESS_STEP_OUTPUTS='{"ensure-prettier":{"outputs":{"command":"yarn prettier"}}}'
  export INPUT_FILE_PATTERN="**/*.js"
}
BeforeEach 'before_run'

It "checks with it"
export INPUT_CONFIG_FILE=".prettierrc" INPUT_CACHE="false" INPUT_FAIL_ON_ERROR="true"
mock_command yarn "prettier --check -- **/*.js" ""
When call run_step "${ACTION_DIR}" "check"
The status should be success
The stdout should include "Prettier check completed"
Assert expect_output status success
End

It "fixes with it"
mock_command yarn "prettier --write -- **/*.js" ""
mock_command git "status --porcelain" ""
When call run_step "${ACTION_DIR}" "fix"
The status should be success
The stdout should include "Prettier fix completed"
Assert expect_output status success
End
End
End
