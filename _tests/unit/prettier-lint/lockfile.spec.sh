#!/usr/bin/env shellspec
# Lockfile detection for prettier-lint: Bun writes bun.lock (text, Bun 1.2+) or
# bun.lockb (binary, older); both must select bun, not fall through to npm ci.

Describe "prettier-lint (lockfile detection)"
ACTION_DIR="${PROJECT_ROOT}/prettier-lint"

before() {
  shellspec_setup_test_env "prettier-lint-lockfile-$$"
  harness_reset
}
BeforeEach 'before'

after() {
  shellspec_cleanup_test_env "prettier-lint-lockfile-$$"
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

Describe "Install Dependencies"
before_install() {
  export HARNESS_STEP_OUTPUTS='{"detect-pm":{"outputs":{"package-manager":"npm"}}}'
}
BeforeEach 'before_install'

# npm ci fails without a lockfile, and a repository with no package.json has nothing to
# install: Prettier then comes from the action's own lockfile. npm is not mocked, so a call fails.
It "installs nothing for a repository with no package.json"
When call run_step "${ACTION_DIR}" "install-deps"
The status should be success
The stdout should include "No package.json: no dependencies to install"
End

It "installs a repository's npm dependencies with npm ci"
printf '%s\n' '{"name": "app"}' >package.json
mock_command npm "ci" ""
When call run_step "${ACTION_DIR}" "install-deps"
The status should be success
The stdout should include "Dependencies installed successfully"
End
End
End
