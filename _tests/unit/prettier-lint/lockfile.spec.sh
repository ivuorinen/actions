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

It "ships a complete npm lock for its own Prettier"
When call package_lock_problems "${ACTION_DIR}"
The status should be success
The stdout should equal ""
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

# The running Yarn picks the flag; only the expected install call is mocked, so another fails.
It "installs with --frozen-lockfile under Yarn 1"
export HARNESS_STEP_OUTPUTS='{"detect-pm":{"outputs":{"package-manager":"yarn"}}}'
mock_command yarn "--version" "1.22.22"
mock_command yarn "install --frozen-lockfile" ""
When call run_step "${ACTION_DIR}" "install-deps"
The status should be success
The stdout should include "Dependencies installed successfully"
End

# No .yarnrc.yml: a Yarn 4 project can pin Yarn through packageManager alone.
It "installs with --immutable under Yarn 2+, without a .yarnrc.yml"
export HARNESS_STEP_OUTPUTS='{"detect-pm":{"outputs":{"package-manager":"yarn"}}}'
mock_command yarn "--version" "4.18.1"
mock_command yarn "install --immutable" ""
When call run_step "${ACTION_DIR}" "install-deps"
The status should be success
The stdout should include "Dependencies installed successfully"
End
End
End
