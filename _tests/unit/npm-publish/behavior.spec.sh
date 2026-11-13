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
# ~/.npmrc holds the credential. sh is dash on Ubuntu runners, and dash's echo
# expands backslash escapes, so writing with echo would turn a backslash sequence
# in an accepted value into a real line break and an extra config line.
setup_auth_inputs() {
  export HOME="$SHELLSPEC_TEST_TEMP_DIR"
  export INPUT_REGISTRY_URL="$1"
  export INPUT_NPM_TOKEN="$2"
}

It "writes the token for the registry host"
setup_auth_inputs "https://registry.npmjs.org/" "npm_aaaa"

When call run_step "${ACTION_DIR}" "authenticate"
The status should be success
The line 1 of contents of file "$HOME/.npmrc" should equal "//registry.npmjs.org/:_authToken=npm_aaaa"
The line 2 of contents of file "$HOME/.npmrc" should equal "always-auth=true"
The lines of contents of file "$HOME/.npmrc" should equal 2
End

It "keeps a backslash sequence in the token on one line"
setup_auth_inputs "https://registry.npmjs.org/" 'npm_aaaa\nsecond-line'

When call run_step "${ACTION_DIR}" "authenticate"
The status should be success
The line 1 of contents of file "$HOME/.npmrc" should equal '//registry.npmjs.org/:_authToken=npm_aaaa\nsecond-line'
The lines of contents of file "$HOME/.npmrc" should equal 2
End

It "keeps a backslash sequence in the registry URL on one line"
setup_auth_inputs 'https://registry.example.com/path\nsecond-line/' "npm_aaaa"

When call run_step "${ACTION_DIR}" "authenticate"
The status should be success
The line 1 of contents of file "$HOME/.npmrc" should equal '//registry.example.com/path\nsecond-line/:_authToken=npm_aaaa'
The lines of contents of file "$HOME/.npmrc" should equal 2
End

# Each key is what npm's own nerf-dart (@npmcli/config) derives from the URL, the key
# npm looks the token up under.
Describe "the registry key"
Parameters
"https://registry.npmjs.org" "//registry.npmjs.org/"
"https://npm.pkg.github.com/OWNER" "//npm.pkg.github.com/"
"https://registry.example.com/npm/?token=x#frag" "//registry.example.com/npm/"
"https://Registry.Example.COM:443/Scope/" "//registry.example.com/Scope/"
"https://user:secret@registry.example.com/a/b" "//registry.example.com/a/"
"http://localhost:4873/" "//localhost:4873/"
End

It "is $2 for $1"
setup_auth_inputs "$1" "npm_aaaa"

When call run_step "${ACTION_DIR}" "authenticate"
The status should be success
The line 1 of contents of file "$HOME/.npmrc" should equal "$2:_authToken=npm_aaaa"
End
End
End
End
