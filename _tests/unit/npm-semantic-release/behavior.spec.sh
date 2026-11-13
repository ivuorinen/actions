#!/usr/bin/env shellspec
# Behavior-level tests for npm-semantic-release's shell steps.
#
# The release itself runs through cycjimmy/semantic-release-action (a `uses:`
# step), which the harness cannot execute. What it *can* execute is the shell
# that decides how the release runs: which package manager is used and whether
# a .nvmrc pins the Node version. Both were previously untested — the action had
# validation specs only, which exercise kit.CHECKS and never enter a `run:`
# block (see docs/audit/findings, tests-94a13648).
#
# These steps read the filesystem rather than external commands, so the
# workspace is the fixture and no mocks are needed. $PWD is the test workspace.

Describe "npm-semantic-release (behavior)"
ACTION_DIR="${PROJECT_ROOT}/npm-semantic-release"

before() {
  shellspec_setup_test_env "npm-semantic-release-behavior-$$"
  harness_reset
}
BeforeEach 'before'

after() {
  shellspec_cleanup_test_env "npm-semantic-release-behavior-$$"
  harness_reset
}
AfterEach 'after'

Describe "package-manager detection"
# Lockfile -> package manager. The order in the action is bun, pnpm, yarn,
# else npm, so the parameters below also pin the precedence between them:
# a repo carrying two lockfiles must resolve to the earlier branch, not to
# whichever `[ -f ]` happens to run last.
Parameters
# lockfiles to create              expected manager   what it pins
"bun.lockb" "bun" "bun branch"
"pnpm-lock.yaml" "pnpm" "pnpm branch"
"yarn.lock" "yarn" "yarn branch"
"" "npm" "default when no lockfile"
"bun.lockb pnpm-lock.yaml" "bun" "bun outranks pnpm"
"pnpm-lock.yaml yarn.lock" "pnpm" "pnpm outranks yarn"
"bun.lockb yarn.lock" "bun" "bun outranks yarn"
End

It "resolves to $2 — $3"
for _f in $1; do : >"$_f"; done

When call run_step "${ACTION_DIR}" "detect-pm"
The status should be success
The stdout should include "Detected package manager: $2"
Assert expect_output package-manager "$2"
End
End

Describe ".nvmrc detection"
It "reports has-nvmrc=true when .nvmrc is present"
printf '20.11.0\n' >.nvmrc

When call run_step "${ACTION_DIR}" "detect-nvmrc"
The status should be success
Assert expect_output has-nvmrc true
End

It "reports has-nvmrc=false when .nvmrc is absent"
When call run_step "${ACTION_DIR}" "detect-nvmrc"
The status should be success
Assert expect_output has-nvmrc false
End
End

Describe "package.json guard"
It "fails with a structured error when package.json is missing"
When call run_step "${ACTION_DIR}" "verify-package-json"
The status should be failure
The stdout should include "::error::package.json not found"
End

It "succeeds when package.json is present"
printf '{"name":"pkg","version":"1.0.0"}\n' >package.json

When call run_step "${ACTION_DIR}" "verify-package-json"
The status should be success
End
End

# Mirrored in npm-publish/behavior.spec.sh: both release actions must hold to
# this, and the fixtures differ because only that one publishes.
Describe "dependency install"
ACTION_FILE="${ACTION_DIR}/action.yml"

It "neither restores dependencies from a cache nor skips the install"
When call grep -nE 'actions/cache|cache-hit|path:[[:space:]]*node_modules' "$ACTION_FILE"
The status should be failure
End

It "turns off the automatic package manager cache on every setup-node step"
When call grep -c 'package-manager-cache: false' "$ACTION_FILE"
The stdout should equal "$(grep -c 'uses: actions/setup-node@' "$ACTION_FILE")"
End

It "turns off the executable cache on the setup-bun step"
# Inert while bun-version is `latest`, active as soon as it names a version.
When call grep -c 'no-cache: true' "$ACTION_FILE"
The stdout should equal "$(grep -c 'uses: oven-sh/setup-bun@' "$ACTION_FILE")"
End

Describe "lockfile-strict install"
Parameters
# files to create         command   arguments that must reach it
"package-lock.json" "npm" "ci"
"pnpm-lock.yaml" "pnpm" "install --frozen-lockfile"
"yarn.lock .yarnrc.yml" "yarn" "install --immutable"
"yarn.lock" "yarn" "install --frozen-lockfile"
"bun.lockb" "bun" "install --frozen-lockfile"
End

It "runs $2 $3 for $1"
# The harness ignores working-directory, so validate.py is looked up in the
# workspace. validation.spec.sh covers the real validator.
: >validate.py
printf '{"name":"pkg","version":"1.0.0"}\n' >package.json
for _f in $1; do : >"$_f"; done

mock_command corepack "*" ""
mock_command "$2" "$3" "ran: $2 $3"

When call run_all_owned_steps "${ACTION_DIR}"
The status should be success
The stdout should include "ran: $2 $3"
End
End
End
End
