#!/usr/bin/env shellspec
# Behavior-level tests for npm-publish's Publish Package step.
#
# The dist-tag branch decides which tag every consumer's `npm install <pkg>`
# resolves to. It had no test at all: the action's only spec was
# validation.spec.sh, which exercises kit.CHECKS and never runs a `run:` block,
# so inverting the branch left the suite green (see docs/audit/findings,
# tests-94a13648).
#
# `npm` is in the harness's BLOCKED_COMMANDS and the child PATH is restricted to
# the mock bin dir plus the system dirs, so neither `npm` nor `node` resolves
# unless mocked. The npm mocks below match on the exact `--tag <value>`: a wrong
# dist-tag matches no glob, the dispatcher exits 127, and the step fails. That is
# what makes these tests discriminating rather than merely green.

Describe "npm-publish publish (behavior)"
ACTION_DIR="${PROJECT_ROOT}/npm-publish"

before() {
  shellspec_setup_test_env "npm-publish-behavior-$$"
  harness_reset
}
BeforeEach 'before'

after() {
  shellspec_cleanup_test_env "npm-publish-behavior-$$"
  harness_reset
}
AfterEach 'after'

# The step reads the manifest version via `node -p require('./package.json').version`.
mock_manifest_version() {
  mock_command node "-p *" "$1"
}

# Both `npm publish` calls the step makes, pinned to the expected dist-tag.
expect_publish_tag() {
  mock_command npm "publish * --dry-run --tag $1 *" ""
  mock_command npm "publish * --verbose --tag $1 *" ""
}

setup_inputs() {
  export INPUT_PACKAGE_VERSION="$1"
  export INPUT_SCOPE="@myorg"
  export INPUT_REGISTRY_URL="https://registry.npmjs.org"
  export INPUT_NPM_TOKEN="npm_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
}

# Mirrored in npm-semantic-release/behavior.spec.sh: both release actions must
# hold to this, and the fixtures differ because only this one publishes.
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

# The Authenticate NPM step writes ~/.npmrc.
export HOME="$SHELLSPEC_TEST_TEMP_DIR"
setup_inputs "1.0.0"
mock_manifest_version "1.0.0"
expect_publish_tag "latest"
mock_command corepack "*" ""
mock_command "$2" "$3" "ran: $2 $3"

When call run_all_owned_steps "${ACTION_DIR}"
The status should be success
The stdout should include "ran: $2 $3"
End
End
End

Describe "dist-tag selection"
Parameters
# input version        manifest version      expected dist-tag
"1.0.0" "1.0.0" "latest"
"2.3.4" "2.3.4" "latest"
"v1.0.0" "1.0.0" "latest"
"1.0.0-beta.1" "1.0.0-beta.1" "beta"
"1.0.0-rc.2" "1.0.0-rc.2" "rc"
"2.0.0-alpha" "2.0.0-alpha" "alpha"
"v3.1.0-next.7" "3.1.0-next.7" "next"
" V1.0.0  " "1.0.0" "latest"
"1.0.0+build" "1.0.0+build" "latest"
"2025.4.5+sha.abc1234" "2025.4.5+sha.abc1234" "latest"
"1.0.0-rc.1+build" "1.0.0-rc.1+build" "rc"
End

It "publishes $1 under dist-tag $3"
setup_inputs "$1"
mock_manifest_version "$2"
expect_publish_tag "$3"

When call run_step "${ACTION_DIR}" "publish"
The status should be success
End
End

It "masks the npm token before any input check runs"
# A workflow step cannot read its own job log, so masking is asserted where it is
# issued: the generated validator, the action's first step. The mask comes first
# even when a check then fails, here on the package version.
setup_inputs "not-a-version"

When run python3 "${ACTION_DIR}/validate.py"
The status should be failure
The line 1 of stdout should equal "::add-mask::${INPUT_NPM_TOKEN}"
The stdout should include "::error::npm-publish: package-version:"
End

It "refuses to publish when the manifest version disagrees with the input version"
# Guards against shipping a build whose manifest version is not the one the
# caller asked for. No npm mock is registered, so if the guard is removed the
# step reaches `npm publish` and the stub exits 127 — the status stays a
# failure either way, which is why the stdout assertion is what proves the
# guard is what fired.
setup_inputs "1.0.0"
mock_manifest_version "1.0.1"

When call run_step "${ACTION_DIR}" "publish"
The status should be failure
The stdout should include "::error::Version mismatch"
End

It "strips a leading v before comparing against the manifest version"
setup_inputs "v1.0.0"
mock_manifest_version "1.0.0"
expect_publish_tag "latest"

When call run_step "${ACTION_DIR}" "publish"
The status should be success
The stdout should not include "Version mismatch"
End

Describe "npm authentication"
# The token reaches npm only through NODE_AUTH_TOKEN. The file holds a placeholder and
# exists only while the step runs. mktemp is mocked so a test knows the file's path, and
# keep_npmrc mocks rm, the only way to read a file the step always removes.
setup_auth_inputs() {
  setup_inputs "1.0.0"
  export INPUT_REGISTRY_URL="$1"
  mock_manifest_version "1.0.0"
  NPMRC_PATH="$SHELLSPEC_TEST_TEMP_DIR/npmrc"
  mock_command mktemp "*" "$NPMRC_PATH"
}

keep_npmrc() {
  mock_command rm "-f *" ""
}

github_env_is_empty() {
  [ ! -s "$GITHUB_ENV" ]
}

# Every step that receives the token, as "<step name>: <env var>".
token_env_by_step() {
  _harness_python - "${ACTION_DIR}/action.yml" <<'PY'
import sys

import yaml

with open(sys.argv[1], encoding="utf-8") as f:
    action = yaml.safe_load(f)
for step in action["runs"]["steps"]:
    for key, value in (step.get("env") or {}).items():
        if "inputs.npm_token" in str(value):
            print(f"{step['name']}: {key}")
PY
}

# Each key is what npm's own nerf-dart (@npmcli/config) derives from the URL, the key
# npm looks the token up under.
Describe "config file"
Parameters
"https://registry.npmjs.org/" "//registry.npmjs.org/"
"https://registry.npmjs.org" "//registry.npmjs.org/"
"https://npm.example.com/repo/" "//npm.example.com/repo/"
"https://npm.example.com:8443/" "//npm.example.com:8443/"
"https://npm.pkg.github.com/OWNER" "//npm.pkg.github.com/"
"https://registry.example.com/npm/?token=x#frag" "//registry.example.com/npm/"
"https://Registry.Example.COM:443/Scope/" "//registry.example.com/Scope/"
"https://user:secret@registry.example.com/a/b" "//registry.example.com/a/"
"http://localhost:4873/" "//localhost:4873/"
End

It "reads the token from the environment under the key $2 for $1"
setup_auth_inputs "$1"
expect_publish_tag "latest"
keep_npmrc

When call run_step "${ACTION_DIR}" "publish"
The status should be success
The contents of file "$NPMRC_PATH" should equal "$2:_authToken=\${NODE_AUTH_TOKEN}"
End
End

# sh is dash on Ubuntu runners, and dash's echo expands backslash escapes, which would
# turn a backslash sequence in an accepted URL into a real line break and a config line.
It "keeps a backslash sequence in the registry URL on one line"
setup_auth_inputs 'https://registry.example.com/path\nsecond-line/'
expect_publish_tag "latest"
keep_npmrc

When call run_step "${ACTION_DIR}" "publish"
The status should be success
The line 1 of contents of file "$NPMRC_PATH" should equal '//registry.example.com/path\nsecond-line/:_authToken=${NODE_AUTH_TOKEN}'
The lines of contents of file "$NPMRC_PATH" should equal 1
End

It "removes the config file after publishing"
setup_auth_inputs "https://registry.npmjs.org/"
expect_publish_tag "latest"

When call run_step "${ACTION_DIR}" "publish"
The status should be success
The path "$NPMRC_PATH" should not be exist
End

Describe "failed publish"
Parameters
"--dry-run"
"--verbose"
End

It "removes the config file when the $1 run fails"
setup_auth_inputs "https://registry.npmjs.org/"
mock_command npm "publish * $1 *" "" 1
mock_command npm "publish *" ""

When call run_step "${ACTION_DIR}" "publish"
The status should be failure
The path "$NPMRC_PATH" should not be exist
End
End

It "leaves nothing in the environment of later steps"
setup_auth_inputs "https://registry.npmjs.org/"
expect_publish_tag "latest"

When call run_step "${ACTION_DIR}" "publish"
The status should be success
Assert github_env_is_empty
End

It "gives the token to the publish step and nothing else that runs a command"
When call token_env_by_step
The status should be success
The line 1 of stdout should equal "Validate Inputs: INPUT_NPM_TOKEN"
The line 2 of stdout should equal "Publish Package: NODE_AUTH_TOKEN"
The lines of stdout should equal 2
End

It "points npm at the temporary config"
When call grep -F 'export NPM_CONFIG_USERCONFIG="$npmrc"' "${ACTION_DIR}/action.yml"
The status should be success
The stdout should include "NPM_CONFIG_USERCONFIG"
End

It "does not write to the home directory or set always-auth"
When call grep -E '~/|\$HOME|always-auth' "${ACTION_DIR}/action.yml"
The status should be failure
End
End
End
