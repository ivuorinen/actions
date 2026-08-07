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
End

It "publishes $1 under dist-tag $3"
setup_inputs "$1"
mock_manifest_version "$2"
expect_publish_tag "$3"

When call run_step "${ACTION_DIR}" "publish"
The status should be success
End
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
End
