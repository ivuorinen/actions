#!/usr/bin/env shellspec
# Lockfile detection for eslint-lint: Bun writes bun.lock (text, Bun 1.2+) or
# bun.lockb (binary, older); both must select bun, not fall through to npm ci.

Describe "eslint-lint (lockfile detection)"
ACTION_DIR="${PROJECT_ROOT}/eslint-lint"

before() {
  shellspec_setup_test_env "eslint-lint-lockfile-$$"
  harness_reset
}
BeforeEach 'before'

after() {
  shellspec_cleanup_test_env "eslint-lint-lockfile-$$"
  harness_reset
}
AfterEach 'after'

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

It "hashes bun.lock into the dependency cache key"
When call grep -c "hashFiles(.*'bun.lock'" "${ACTION_DIR}/action.yml"
The output should equal 1
End
End
