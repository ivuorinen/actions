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

# Installed for ESLint to read, so the repository's install scripts never run.
It "installs a repository's npm dependencies with npm ci, without install scripts"
printf '%s\n' '{"name": "app"}' >package.json
mock_command npm "ci --ignore-scripts" ""
When call run_step "${ACTION_DIR}" "install-deps"
The status should be success
The stdout should include "Dependencies installed successfully"
End

# The running Yarn picks the flags; only the expected install call is mocked, so another fails.
It "installs with --frozen-lockfile under Yarn 1, without install scripts"
printf '%s\n' '{"name": "app"}' >package.json
export HARNESS_STEP_OUTPUTS='{"detect-pm":{"outputs":{"package-manager":"yarn"}}}'
mock_command yarn "--version" "1.22.22"
mock_command yarn "install --frozen-lockfile --ignore-scripts" ""
When call run_step "${ACTION_DIR}" "install-deps"
The status should be success
The stdout should include "Dependencies installed successfully"
End

# No .yarnrc.yml: a Yarn 4 project can pin Yarn through packageManager alone.
It "installs with --immutable under Yarn 2+, without a .yarnrc.yml or builds"
printf '%s\n' '{"name": "app"}' >package.json
export HARNESS_STEP_OUTPUTS='{"detect-pm":{"outputs":{"package-manager":"yarn"}}}'
mock_command yarn "--version" "4.18.1"
mock_command yarn "install --immutable --mode=skip-build" ""
When call run_step "${ACTION_DIR}" "install-deps"
The status should be success
The stdout should include "Dependencies installed successfully"
End

It "installs with bun without install scripts"
printf '%s\n' '{"name": "app"}' >package.json
export HARNESS_STEP_OUTPUTS='{"detect-pm":{"outputs":{"package-manager":"bun"}}}'
mock_command bun "install --frozen-lockfile --ignore-scripts" ""
When call run_step "${ACTION_DIR}" "install-deps"
The status should be success
The stdout should include "Dependencies installed successfully"
End

# pr-lint's spec tests every branch of the shared script.
It "ships pr-lint's install_node_dependencies.sh unchanged"
When call cmp "${ACTION_DIR}/install_node_dependencies.sh" "${PROJECT_ROOT}/pr-lint/install_node_dependencies.sh"
The status should be success
End

End

# Corepack loads a .corepack.env from the checkout in every step that runs corepack or a
# pnpm or yarn shim, and it can name the registry and turn off the signature check.
Describe "Corepack settings from the checkout"
Parameters
"Enable Corepack"
"Install Package Manager"
"Install Dependencies"
"Ensure ESLint"
"Run ESLint Check"
"Run ESLint Fix"
End

It "are ignored in $1"
When call step_value "$ACTION_DIR" "$1" env.COREPACK_ENV_FILE
The output should equal "0"
End
End
End
