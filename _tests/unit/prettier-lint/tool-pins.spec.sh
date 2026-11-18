#!/usr/bin/env shellspec
# prettier-lint runs the repository's own Prettier when it has one, and otherwise installs the
# action's package-lock.json with npm ci instead of letting npx fetch whatever is newest. Mocks
# match exact arguments, so anything else exits 127 and fails the example.

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

# Lay out the prettier binary npm would leave in a prefix, since npm itself is mocked.
installed_prettier() {
  mkdir -p "$1/node_modules/.bin"
  printf '%s\n' '#!/bin/sh' 'echo 3.9.10' >"$1/node_modules/.bin/prettier"
  chmod +x "$1/node_modules/.bin/prettier"
  printf '%s' "$1/node_modules/.bin/prettier"
}

locked_install_args() {
  printf 'ci --prefix %s --ignore-scripts --no-audit --no-fund' "${RUNNER_TEMP}/prettier-lint-tools"
}

# mktemp names each prefix at random; the mock names it, so the layout above is where npm
# installed.
mock_prefix() {
  mkdir -p "${RUNNER_TEMP}/$1"
  mock_command mktemp "-d ${RUNNER_TEMP}/$1.XXXXXX" "${RUNNER_TEMP}/$1"
}

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

# Yarn 2 and later only see binaries of the nearest package's dependencies, so a child
# workspace that does not declare Prettier reaches the root's copy through --top-level.
It "runs the root workspace's Yarn copy from a child workspace that does not declare it"
use_package_manager yarn
mock_command yarn "--version" "4.18.1"
printf '%s\n' '{"workspaces": ["packages/*"], "devDependencies": {"prettier": "^3.0.0"}}' >package.json
mkdir -p packages/app
printf '%s\n' '{"name": "app"}' >packages/app/package.json
cd packages/app || return 1
When call run_step "${ACTION_DIR}" "ensure-prettier"
The status should be success
Assert expect_output command "yarn run --top-level --binaries-only prettier"
End

# A directory below the workspace that declares Prettier is still that workspace for Yarn.
It "runs a child workspace's own Yarn copy from a directory below it"
use_package_manager yarn
mock_command yarn "--version" "4.18.1"
printf '%s\n' '{"workspaces": ["packages/*"]}' >package.json
mkdir -p packages/app/src
printf '%s\n' '{"name": "app", "devDependencies": {"prettier": "^3.0.0"}}' >packages/app/package.json
cd packages/app/src || return 1
When call run_step "${ACTION_DIR}" "ensure-prettier"
The status should be success
Assert expect_output command "yarn run --binaries-only prettier"
End

# Yarn 1 has no --binaries-only, so a node_modules install runs through npx.
It "runs a Yarn 1 repository's copy through npx"
use_package_manager yarn
mock_command yarn "--version" "1.22.22"
mkdir -p node_modules/prettier
When call run_step "${ACTION_DIR}" "ensure-prettier"
The status should be success
Assert expect_output command "npx --no-install prettier"
End

# Yarn 1 Plug'n'Play has no node_modules for npx, so it runs through Yarn, as before this
# action pinned anything. Yarn 1 has no way to skip a script of the same name.
It "runs a Yarn 1 Plug'n'Play repository's copy through Yarn"
use_package_manager yarn
mock_command yarn "--version" "1.22.22"
printf '%s\n' '{"devDependencies": {"prettier": "^3.0.0"}}' >package.json
When call run_step "${ACTION_DIR}" "ensure-prettier"
The status should be success
Assert expect_output command "yarn prettier"
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
bin=$(installed_prettier "${RUNNER_TEMP}/prettier-lint-tools")
mock_prefix prettier-lint-tools
mock_command npm "$(locked_install_args)" ""
When call run_step "${ACTION_DIR}" "ensure-prettier"
The status should be success
The stdout should include "Running Prettier 3.9.10 from $bin"
Assert expect_output command ""
Assert expect_output bin "$bin"
End

Describe "when the repository has no copy"
before_missing() {
  use_package_manager npm
}
BeforeEach 'before_missing'

It "installs the action's lockfile with npm ci and runs that copy by path"
bin=$(installed_prettier "${RUNNER_TEMP}/prettier-lint-tools")
mock_prefix prettier-lint-tools
mock_command npm "$(locked_install_args)" ""
When call run_step "${ACTION_DIR}" "ensure-prettier"
The status should be success
The stdout should include "Running Prettier 3.9.10 from $bin"
Assert expect_output command ""
Assert expect_output bin "$bin"
Assert expect_argv npm ci --prefix "${RUNNER_TEMP}/prettier-lint-tools" --ignore-scripts --no-audit --no-fund
End

It "fails when the installed Prettier does not run"
_dir="${RUNNER_TEMP}/prettier-lint-tools/node_modules/.bin"
mkdir -p "$_dir"
printf '%s\n' '#!/bin/sh' 'exit 1' >"$_dir/prettier"
chmod +x "$_dir/prettier"
mock_prefix prettier-lint-tools
mock_command npm "$(locked_install_args)" ""
When call run_step "${ACTION_DIR}" "ensure-prettier"
The status should be failure
The stdout should include "::error::prettier at $_dir/prettier does not run"
Assert expect_output status failure
The contents of file "$GITHUB_OUTPUT" should not include "bin="
End

It "installs the lockfile the action ships"
installed_prettier "${RUNNER_TEMP}/prettier-lint-tools" >/dev/null
mock_prefix prettier-lint-tools
mock_command npm "$(locked_install_args)" ""
run_ensure() {
  run_step "${ACTION_DIR}" "ensure-prettier" >/dev/null &&
    cmp "${ACTION_DIR}/package-lock.json" "${RUNNER_TEMP}/prettier-lint-tools/package-lock.json" &&
    cmp "${ACTION_DIR}/package.json" "${RUNNER_TEMP}/prettier-lint-tools/package.json"
}
When call run_ensure
The status should be success
End

# npx --no-install also finds a global copy, so a probe that runs it would pick this one.
It "installs the locked copy even when an older global copy runs"
mock_command npx "--no-install prettier --version" "2.0.0"
bin=$(installed_prettier "${RUNNER_TEMP}/prettier-lint-tools")
mock_prefix prettier-lint-tools
mock_command npm "$(locked_install_args)" ""
When call run_step "${ACTION_DIR}" "ensure-prettier"
The status should be success
The stdout should include "Running Prettier 3.9.10 from $bin"
Assert expect_output bin "$bin"
End

It "fails when npm ci leaves no prettier binary"
mock_prefix prettier-lint-tools
mock_command npm "$(locked_install_args)" ""
When call run_step "${ACTION_DIR}" "ensure-prettier"
The status should be failure
The stdout should include "::error::prettier is not at ${RUNNER_TEMP}/prettier-lint-tools/node_modules/.bin/prettier after its install"
End

It "fails the step when the locked install fails"
mock_prefix prettier-lint-tools
mock_command npm "ci *" "" 1
When call run_step "${ACTION_DIR}" "ensure-prettier"
The status should be failure
End

# The validator reads a version of only spaces as left out; npm would read it as any version.
It "reads a prettier-version of only spaces as left out"
export INPUT_PRETTIER_VERSION="   "
bin=$(installed_prettier "${RUNNER_TEMP}/prettier-lint-tools")
mock_prefix prettier-lint-tools
mock_command npm "$(locked_install_args)" ""
When call run_step "${ACTION_DIR}" "ensure-prettier"
The status should be success
The stdout should include "Running Prettier 3.9.10 from $bin"
Assert expect_output bin "$bin"
End

Parameters
"3.0.0"
"latest"
End

# The lockfile holds one version, so a version the caller names comes from the registry,
# without lifecycle scripts.
It "installs $1 without lifecycle scripts when the caller asks for it"
export INPUT_PRETTIER_VERSION="$1"
bin=$(installed_prettier "${RUNNER_TEMP}/prettier-lint-requested")
mock_prefix prettier-lint-requested
mock_command npm "install --prefix ${RUNNER_TEMP}/prettier-lint-requested --no-package-lock --no-audit --no-fund --ignore-scripts prettier@$1" ""
When call run_step "${ACTION_DIR}" "ensure-prettier"
The status should be success
The stdout should include "Running Prettier 3.9.10 from $bin"
Assert expect_output command ""
Assert expect_output bin "$bin"
End
End
End

Describe "running the resolved command"
before_run() {
  export HARNESS_STEP_OUTPUTS='{"ensure-prettier":{"outputs":{"command":"yarn prettier","bin":""}}}'
  export INPUT_FILE_PATTERN="**/*.js"
  export INPUT_CONFIG_FILE=".prettierrc" INPUT_IGNORE_FILE=".prettierignore"
  export INPUT_CACHE="false" INPUT_FAIL_ON_ERROR="true"
}
BeforeEach 'before_run'

It "checks with it"
mock_command yarn "prettier --check -- **/*.js" ""
When call run_step "${ACTION_DIR}" "check"
The status should be success
The stdout should include "Prettier check completed"
Assert expect_output status success
End

# A copy the action installed runs by its path, kept whole however many spaces it holds.
It "runs the copy the action installed by its path"
dir="${SHELLSPEC_TEST_TEMP_DIR}/runner temp/prettier-lint-tools/node_modules/.bin"
mkdir -p "$dir"
printf '%s\n' '#!/bin/sh' 'printf "%s\n" "$@" >"$(dirname "$0")/argv"' >"$dir/prettier"
chmod +x "$dir/prettier"
export HARNESS_STEP_OUTPUTS="{\"ensure-prettier\":{\"outputs\":{\"command\":\"\",\"bin\":\"$dir/prettier\"}}}"
run_check() { run_step "${ACTION_DIR}" "check" >/dev/null && cat "$dir/argv"; }
When call run_check
The status should be success
# One argument per line, so an argument that swallowed the next would show.
The line 1 of output should equal "--check"
The line 2 of output should equal "--"
The line 3 of output should equal "**/*.js"
The lines of output should equal 3
End

# The summary line is matched whole: a file whose name starts like it is still a file.
It "counts a file named like Prettier's summary line"
export INPUT_FAIL_ON_ERROR="false"
mock_command yarn "prettier --check -- **/*.js" "[warn] Code style issues found in 2 files.js
[warn] Code style issues found in the above file. Run Prettier with --write to fix." 1
When call run_step "${ACTION_DIR}" "check"
The status should be success
The stdout should include "[warn] Code style issues found in 2 files.js"
Assert expect_output unformatted_files 1
End

It "skips Prettier 2's summary line too"
export INPUT_FAIL_ON_ERROR="false"
mock_command yarn "prettier --check -- **/*.js" "[warn] a.js
[warn] b.js
[warn] Code style issues found in 2 files. Forgot to run Prettier?" 1
When call run_step "${ACTION_DIR}" "check"
The status should be success
The stdout should include "Forgot to run Prettier?"
Assert expect_output unformatted_files 2
End

# GitHub Actions sets CI, which makes Prettier color its tags, and a caller can set
# FORCE_COLOR. The stand-in colors them as both Prettiers do, on stderr as they write them:
# Prettier 3 unless NO_COLOR is set, Prettier 2's Chalk whenever FORCE_COLOR is not 0. A step
# that left color on would count nothing.
Describe "under GitHub Actions"
before_color() {
  dir="${SHELLSPEC_TEST_TEMP_DIR}/colored/node_modules/.bin"
  mkdir -p "$dir"
  export HARNESS_STEP_OUTPUTS="{\"ensure-prettier\":{\"outputs\":{\"command\":\"\",\"bin\":\"$dir/prettier\"}}}"
  export CI="true" GITHUB_ACTIONS="true" INPUT_FAIL_ON_ERROR="false"
  unset NO_COLOR FORCE_COLOR
}
BeforeEach 'before_color'

colored_prettier() {
  printf '%s\n' '#!/bin/sh' \
    'o="[$(printf "\033[31m")" c="$(printf "\033[39m")]"' \
    'if [ -n "${NO_COLOR:-}" ]; then o="[" c="]"; fi' \
    'case "${FORCE_COLOR:-}" in "" | 0) ;; *) o="[$(printf "\033[31m")" c="$(printf "\033[39m")]" ;; esac' \
    "printf '%s%s%s %s\n' \"\$o\" \"$1\" \"\$c\" \"$2\" >&2" "exit 1" >"$dir/prettier"
  chmod +x "$dir/prettier"
}

It "still fails when Prettier cannot load a plugin"
colored_prettier error "Cannot find package 'prettier-plugin-missing'"
When call run_step "${ACTION_DIR}" "check"
The status should equal 1
The stdout should include "::error::Prettier could not check the files"
End

It "still counts an unformatted file"
colored_prettier warn "a.js"
When call run_step "${ACTION_DIR}" "check"
The status should be success
The stdout should include "[warn] a.js"
Assert expect_output unformatted_files 1
End

It "still counts an unformatted file when the caller sets FORCE_COLOR"
colored_prettier warn "a.js"
export FORCE_COLOR="1"
When call run_step "${ACTION_DIR}" "check"
The status should be success
The stdout should include "[warn] a.js"
Assert expect_output unformatted_files 1
End
End

# Prettier exits 1 for a plugin it cannot load, as for a formatting difference, but prints an
# [error] line; with fail-on-error off that still fails the step.
It "fails when Prettier cannot load a plugin, even with fail-on-error off"
export INPUT_FAIL_ON_ERROR="false"
mock_command yarn "prettier --check -- **/*.js" "[error] Cannot find package 'prettier-plugin-missing'" 1
When call run_step "${ACTION_DIR}" "check"
The status should equal 1
The stdout should include "::error::Prettier could not check the files (exit status 1; see its [error] lines above)"
Assert expect_output status failure
End

# Prettier names each unformatted file on a [warn] line and adds a summary [warn] line.
It "counts unformatted files without Prettier's summary line"
export INPUT_FAIL_ON_ERROR="false"
mock_command yarn "prettier --check -- **/*.js" "[warn] a.js
[warn] b.js
[warn] Code style issues found in 2 files. Run Prettier with --write to fix." 1
When call run_step "${ACTION_DIR}" "check"
The status should be success
The stdout should include "[warn] b.js"
Assert expect_output unformatted_files 2
Assert expect_output status failure
End

It "fails when Prettier cannot check, even with fail-on-error off"
export INPUT_FAIL_ON_ERROR="false"
mock_command yarn "prettier --check -- **/*.js" "[error] No parser could be inferred" 2
When call run_step "${ACTION_DIR}" "check"
The status should equal 2
The stdout should include "::error::Prettier could not check the files (exit status 2; see its [error] lines above)"
Assert expect_output status failure
End

# The ensure step runs before check and fix mode alike, so it checks each file once for both.
It "fails before either mode when a config file other than the default does not exist"
export INPUT_CONFIG_FILE="missing.prettierrc"
When call run_step "${ACTION_DIR}" "ensure-prettier"
The status should be failure
The stdout should include "::error::config-file missing.prettierrc does not exist"
Assert expect_output status failure
End

It "fails before either mode when an ignore file other than the default does not exist"
export INPUT_IGNORE_FILE="missing.prettierignore"
When call run_step "${ACTION_DIR}" "ensure-prettier"
The status should be failure
The stdout should include "::error::ignore-file missing.prettierignore does not exist"
Assert expect_output status failure
End

Parameters
"check" "--check"
"fix" "--write"
End

It "passes a config file and an ignore file other than the defaults on in $1 mode"
: >custom.prettierrc
: >custom.prettierignore
export INPUT_CONFIG_FILE="custom.prettierrc" INPUT_IGNORE_FILE="custom.prettierignore"
mock_command yarn "prettier $2 --config custom.prettierrc --ignore-path .gitignore --ignore-path custom.prettierignore -- **/*.js" ""
mock_command git "status --porcelain" ""
When call run_step "${ACTION_DIR}" "$1"
The status should be success
The stdout should include "Prettier $1 completed"
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

It "fails fix mode when Prettier cannot format a file"
mock_command yarn "prettier --write -- **/*.js" "[error] a.js: SyntaxError" 2
mock_command git "status --porcelain" ""
When call run_step "${ACTION_DIR}" "fix"
The status should equal 2
The stdout should include "::error::Prettier failed with exit status 2"
Assert expect_output status failure
End
End
End
