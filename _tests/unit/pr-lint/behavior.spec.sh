#!/usr/bin/env shellspec
# Behavior tests for pr-lint: it lints code from the checked-out tree, so the
# steps that handle that tree must not run it with more privileges than the
# trigger gives the code's author.

Describe "pr-lint (behavior)"
ACTION_DIR="${PROJECT_ROOT}/pr-lint"

before() {
  shellspec_setup_test_env "pr-lint-behavior-$$"
  harness_reset
}
BeforeEach 'before'

after() {
  shellspec_cleanup_test_env "pr-lint-behavior-$$"
  harness_reset
}
AfterEach 'after'

Describe "trigger guard"
Describe "privileged triggers"
Parameters
"pull_request_target"
"workflow_run"
End

It "refuses $1"
export GITHUB_EVENT_NAME="$1"

When call run_step "${ACTION_DIR}" "guard-trigger"
The status should be failure
The stdout should include "::error::"
The stdout should include "$1"
The stdout should include "Run it on pull_request"
The stdout should include "read-only token and no secrets for untrusted pull requests"
End
End

Describe "other triggers"
# pull_request, push and merge_group are what .github/workflows/pr-lint.yml uses.
Parameters
"pull_request"
"push"
"merge_group"
"workflow_dispatch"
"schedule"
End

It "allows $1"
export GITHUB_EVENT_NAME="$1"

When call run_step "${ACTION_DIR}" "guard-trigger"
The status should be success
The stdout should not include "::error::"
End
End

It "runs after input validation and before the checkout"
validate_line=$(grep -n '^    - name: Validate Inputs' "${ACTION_DIR}/action.yml" | cut -d: -f1)
guard_line=$(grep -n '^      id: guard-trigger' "${ACTION_DIR}/action.yml" | cut -d: -f1)
checkout_line=$(grep -n '^    - name: Checkout Code' "${ACTION_DIR}/action.yml" | cut -d: -f1)
in_order() { [ "$validate_line" -lt "$guard_line" ] && [ "$guard_line" -lt "$checkout_line" ]; }

When call in_order
The status should be success
End
End

Describe "Node dependency install"
# run_step resolves ${{ steps.* }} to empty, so the step's PACKAGE_MANAGER is
# fixed in a temporary copy of the action, with the install script beside it, to
# reach each branch, in a repository with a package.json. A mock only answers its
# exact argv: any other flags fail with an unregistered-call error.
run_install_node() {
  mkdir -p .action
  sed -E "s/^( +PACKAGE_MANAGER:).*/\1 $1/" "${ACTION_DIR}/action.yml" >.action/action.yml
  cp "${ACTION_DIR}/install_node_dependencies.sh" .action/
  [ -f package.json ] || printf '%s\n' '{"name": "app"}' >package.json
  run_step "${PWD}/.action" "install-node"
}

# npm ci fails without one, and nothing is mocked here.
It "installs nothing with npm for a repository with no package.json"
mkdir -p .action
sed -E "s/^( +PACKAGE_MANAGER:).*/\1 npm/" "${ACTION_DIR}/action.yml" >.action/action.yml
cp "${ACTION_DIR}/install_node_dependencies.sh" .action/
When call run_step "${PWD}/.action" "install-node"
The status should be success
The stdout should include "No package.json: no dependencies to install"
End

# pnpm installs a workspace without a root manifest, so it runs without one.
It "installs with pnpm for a workspace with no root package.json"
mkdir -p .action
sed -E "s/^( +PACKAGE_MANAGER:).*/\1 pnpm/" "${ACTION_DIR}/action.yml" >.action/action.yml
cp "${ACTION_DIR}/install_node_dependencies.sh" .action/
mock_command pnpm "install --frozen-lockfile --ignore-scripts --ignore-pnpmfile" ""
When call run_step "${PWD}/.action" "install-node"
The status should be success
The stdout should include "Dependencies installed successfully"
End

Describe "without a version probe"
Parameters
"npm" "ci --ignore-scripts"
"pnpm" "install --frozen-lockfile --ignore-scripts --ignore-pnpmfile"
"bun" "install --frozen-lockfile --ignore-scripts"
End

It "installs without running repository code using $1"
mock_command "$1" "$2" ""

When call run_install_node "$1"
The status should be success
The stdout should include "Dependencies installed successfully"
End
End

Describe "pnpm and a lockfile that does not match the settings"
# Any mismatch fails the frozen install, overrides included: an unfrozen retry would lint
# against dependencies resolved again, not the ones the lockfile names.
It "fails on the frozen install's error instead of installing without the frozen check"
mock_command pnpm "install --frozen-lockfile --ignore-scripts --ignore-pnpmfile" "ERR_PNPM_LOCKFILE_CONFIG_MISMATCH  Cannot proceed" 1

When call run_install_node "pnpm"
The status should be failure
# A retry would reach an unregistered pnpm call, and the mock reports that on stderr.
The stderr should equal ""
The stdout should include "ERR_PNPM_LOCKFILE_CONFIG_MISMATCH"
The stdout should not include "Dependencies installed successfully"
End
End

# Each package manager builds a Git dependency from its repository with its scripts, whatever
# flags the install has, so a lockfile that names one stops the install before it starts.
Describe "a lockfile naming a Git dependency"
Parameters
"npm" "package-lock.json" '"resolved": "git+ssh://git@github.com/acme/lib.git#0123abc"'
"pnpm" "pnpm-lock.yaml" "    resolution: {commit: 0123abc, repo: https://github.com/acme/lib.git, type: git}"
"yarn" "yarn.lock" '  resolution: "lib@https://github.com/acme/lib.git#commit=0123abc"'
"yarn" "yarn.lock" '  resolved "git+https://github.com/acme/lib.git#0123abc"'
"yarn" "yarn.lock" '  resolved "https://example.org/lib.git#0123abc"'
"yarn" "yarn.lock" '"lib@https://github.com/acme/lib":'
"npm" "package-lock.json" '"resolved": "ssh://git@example.org/acme/lib.git#0123abc"'
"bun" "bun.lock" '    "lib": ["lib@github:acme/lib#0123abc", {}],'
End

It "stops the $1 install for $2"
printf '%s\n' "$3" >"$2"
mock_command "$1" "*" "installed anyway"

When call run_install_node "$1"
The status should be failure
The stdout should include "::error::$2 names a Git dependency"
The stdout should not include "installed anyway"
End
End

# Bun's binary lockfile holds the URL as a plain string among NUL bytes.
It "stops the bun install for a binary bun.lockb"
printf 'bun-lockfile\0\0\001lib@github:acme/lib#0123abc\0\0' >bun.lockb
mock_command bun "*" "installed anyway"

When call run_install_node "bun"
The status should be failure
The stdout should include "::error::bun.lockb names a Git dependency"
The stdout should not include "installed anyway"
End

# Archives install without a build: a registry tarball, one whose package name holds .git, and a
# release archive deeper in a Git host than an owner and a repository.
Describe "a lockfile of archives"
Parameters
"package-lock.json" '"resolved": "https://registry.npmjs.org/lib/-/lib-1.0.0.tgz"'
"package-lock.json" '"resolved": "https://registry.npmjs.org/x.github/-/x.github-1.0.0.tgz"'
"package-lock.json" '"resolved": "https://github.com/acme/lib/archive/v1.0.0.tar.gz"'
"yarn.lock" '  resolved "https://registry.yarnpkg.com/lib/-/lib-1.0.0.tgz#0123abc"'
End

It "installs $2 from $1"
printf '%s\n' "$2" >"$1"
mock_command npm "ci --ignore-scripts" ""

When call run_install_node "npm"
The status should be success
The stdout should include "Dependencies installed successfully"
End
End

# A registry package's funding links and deprecation message can name a repository on a Git
# host; they say nothing about where the package comes from.
Describe "a registry lockfile whose metadata links to a Git host"
# This repository's own locks hold GitHub funding links.
Parameters
"package-lock.json"
"eslint-lint/package-lock.json"
"prettier-lint/package-lock.json"
End

It "installs from this repository's $1"
cp "${PROJECT_ROOT}/$1" package-lock.json
mock_command npm "ci --ignore-scripts" ""

When call run_install_node "npm"
The status should be success
The stdout should include "Dependencies installed successfully"
End
End

It "installs despite deprecation messages naming a repository"
cat >package-lock.json <<'EOF'
{
  "packages": {
    "node_modules/lib": {
      "version": "1.0.0",
      "resolved": "https://registry.npmjs.org/lib/-/lib-1.0.0.tgz",
      "deprecated": "Moved to https://github.com/acme/lib",
      "funding": {
        "url": "https://github.com/sponsors/acme"
      }
    }
  }
}
EOF
cat >pnpm-lock.yaml <<'EOF'
packages:
  lib@1.0.0:
    resolution: {integrity: sha512-0123}
    deprecated: Moved to https://github.com/acme/lib
EOF
mock_command npm "ci --ignore-scripts" ""

When call run_install_node "npm"
The status should be success
The stdout should include "Dependencies installed successfully"
End

Describe "Corepack settings from the checkout"
Parameters
"Install Package Manager (Fallback)"
"Install Node Dependencies"
End

# A step's COREPACK_ENV_FILE, which a .corepack.env in the checkout must not override.
It "ignores them in $1"
When call step_value "$ACTION_DIR" "$1" env.COREPACK_ENV_FILE
The output should equal "0"
End
End

Describe "yarn"
Parameters
"1.22.22" "install --frozen-lockfile --ignore-scripts"
"2.4.3" "install --immutable --skip-builds"
"3.8.7" "install --immutable --mode=skip-build"
"4.9.2" "install --immutable --mode=skip-build"
"10.0.0" "install --immutable --mode=skip-build"
End

It "uses the flags yarn $1 understands"
mock_command yarn "--version" "$1"
mock_command yarn "$2" ""

When call run_install_node "yarn"
The status should be success
The stdout should include "Dependencies installed successfully"
End
End

# --skip-builds came in Yarn 2.4.0. Only --version is mocked: an install would reach an
# unregistered call, which the mock reports on stderr.
Describe "yarn before 2.4.0"
Parameters
"2.0.0"
"2.3.1"
End

It "refuses yarn $1, which cannot skip builds"
mock_command yarn "--version" "$1"

When call run_install_node "yarn"
The status should be failure
The stderr should equal ""
The stdout should include "::error::Yarn 2.0 to 2.3 cannot install without running builds"
The stdout should not include "Dependencies installed successfully"
End
End
End

Describe "PHP dependency install"
It "installs without composer scripts or plugins"
mock_command composer "install --no-progress --prefer-dist --no-interaction --no-scripts --no-plugins" ""

When call run_step "${ACTION_DIR}" "install-php"
The status should be success
End
End

Describe "Python dependencies"
# A host install cannot reach MegaLinter's container, so the action must not
# run one: building a package runs its code.
It "are not installed on the runner"
When call grep -E 'pip3? install|actions/setup-python|requirements\.txt' "${ACTION_DIR}/action.yml"
The status should be failure
End
End

Describe "packageManager detection"
It "does not echo the value from package.json"
printf '{"packageManager":"pnpm@9.0.0\\n::warning::from-package-json"}\n' >package.json

When call run_step "${ACTION_DIR}" "detect-node"
The status should be success
The stdout should include "Found packageManager field in package.json"
The stdout should not include "::warning::"
Assert expect_output has-package-manager true
End
End

Describe "documented permissions"
header_permissions() { sed -n '/^# permissions:/,/^---$/p' "${ACTION_DIR}/action.yml"; }

It "asks only for what the steps use"
When call header_permissions
The stdout should include "contents: read"
The stdout should include "pull-requests: write"
The stdout should not include "contents: write"
End
End
End
