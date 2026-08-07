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
End
