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

# The check itself: a key that hashes the npm lock alone misses both Bun lockfiles.
It "reports each lockfile the cache key does not hash"
printf '%s\n' "key: \${{ hashFiles('package-lock.json') }}" >action.yml
When call cache_key_misses action.yml package-lock.json bun.lock bun.lockb
The status should be success
The line 1 of output should equal "bun.lock"
The line 2 of output should equal "bun.lockb"
The lines of output should equal 2
End

It "reports a lockfile that a ! pattern in the key excludes"
printf '%s\n' "key: \${{ hashFiles('bun.lock*', '!bun.lockb') }}" >action.yml
When call cache_key_misses action.yml bun.lock bun.lockb
The status should be success
The output should equal "bun.lockb"
End

It "counts a **/ pattern in the key as matching at the root"
printf '%s\n' "- key: \${{ hashFiles('**/package-lock.json') }}" >action.yml
When call cache_key_misses action.yml package-lock.json
The status should be success
The output should equal ""
End

It "ships a complete npm lock for its own ESLint"
When call package_lock_problems "${ACTION_DIR}"
The status should be success
The stdout should equal ""
End

# The check itself: a package.json the lock was not made from is reported.
It "reports a lock that does not match package.json"
mkdir -p stale
sed -E 's/"eslint": "[0-9.]+"/"eslint": "1.0.0"/' "${ACTION_DIR}/package.json" >stale/package.json
cp "${ACTION_DIR}/package-lock.json" stale/package-lock.json
When call package_lock_problems stale
The stdout should include "the lock's root dependencies differ from package.json"
The stdout should include "the lock does not install eslint@1.0.0"
End

# The SARIF formatter needs ESLint ^8.9.0; without its nested copy, Node would hand it the
# root ESLint 10, which npm ls reports as outside that range.
It "reports a locked version outside the range the package that needs it declares"
mkdir -p nested
cp "${ACTION_DIR}/package.json" nested/package.json
python3 - "${ACTION_DIR}/package-lock.json" nested/package-lock.json <<'PY'
import json
import sys

lock = json.load(open(sys.argv[1], encoding="utf-8"))
nested = "node_modules/@microsoft/eslint-formatter-sarif/node_modules/eslint"
for path in [p for p in lock["packages"] if p == nested or p.startswith(nested + "/")]:
    del lock["packages"][path]
json.dump(lock, open(sys.argv[2], "w", encoding="utf-8"), indent=2)
PY
When call package_lock_problems nested
The stdout should include 'invalid: "^8.9.0" from node_modules/@microsoft/eslint-formatter-sarif'
End

Describe "Install Dependencies"
before_install() {
  export HARNESS_STEP_OUTPUTS='{"detect-pm":{"outputs":{"package-manager":"npm"}}}'
}
BeforeEach 'before_install'

# npm ci fails without a lockfile, and a repository with no package.json has nothing to
# install: ESLint then comes from the action's own lockfile. npm is not mocked, so a call fails.
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
