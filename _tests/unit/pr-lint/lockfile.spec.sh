#!/usr/bin/env shellspec
# Lockfile detection for pr-lint: Bun writes bun.lock (text, Bun 1.2+) or
# bun.lockb (binary, older); both must select bun, not fall through to npm ci.

Describe "pr-lint (lockfile detection)"
ACTION_DIR="${PROJECT_ROOT}/pr-lint"

before() {
  shellspec_setup_test_env "pr-lint-lockfile-$$"
  harness_reset
}
BeforeEach 'before'

after() {
  shellspec_cleanup_test_env "pr-lint-lockfile-$$"
  harness_reset
}
AfterEach 'after'

# Parameters apply to every example after them in a block, so the matrix has its own.
Describe "detect-pm"
Parameters
"bun.lockb" "bun"
"bun.lock" "bun"
"bun.lock pnpm-lock.yaml" "bun"
"pnpm-lock.yaml" "pnpm"
"yarn.lock" "yarn"
"" "npm"
End

It "resolves $1 to $2"
for _f in $1; do : >"$_f"; done

When call run_step "${ACTION_DIR}" "detect-pm"
The status should be success
The stdout should include "Detected package manager: $2"
Assert expect_output package-manager "$2"
End
End

It "hashes each package manager's lockfile into the dependency cache key"
When call cache_key_misses "${ACTION_DIR}/action.yml" package-lock.json yarn.lock pnpm-lock.yaml bun.lock bun.lockb
The status should be success
The output should equal ""
End
End
