#!/usr/bin/env shellspec
# Behavior-level tests for release-monthly using the composite-step harness.

Describe "release-monthly create-release (behavior)"
ACTION_DIR="${PROJECT_ROOT}/release-monthly"

before() {
  shellspec_setup_test_env "release-monthly-behavior-$$"
  harness_reset
}
BeforeEach 'before'

after() {
  shellspec_cleanup_test_env "release-monthly-behavior-$$"
  harness_reset
}
AfterEach 'after'

It "increments patch when a release already exists for the current month and prefix=v"
# With prefix=v and an existing release for the current month, the
# action should bump the patch rather than reset to 0 or fail.
export INPUT_TOKEN="ghp_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
export INPUT_PREFIX="v"
export INPUT_DRY_RUN="true"
export VALIDATED_TOKEN="$INPUT_TOKEN"
export VALIDATED_PREFIX="$INPUT_PREFIX"
export VALIDATED_DRY_RUN="$INPUT_DRY_RUN"
current_ym="$(date -u +'%Y.%-m')"
# gh --json tagName --jq '.[0].tagName' returns just the tag string.
mock_command gh "release list --limit 1*" "v${current_ym}.0"
mock_command gh "release create*" ""

When call run_step "${ACTION_DIR}" "create-release"
The status should be success
The stdout should include "v${current_ym}.1"
Assert expect_output release_tag "v${current_ym}.1"
End

It "uses gh's structured JSON output (not awk on a TITLE column)"
# Discriminating regression for the old awk '{print $1}' bug.
# TWO gh mocks: the specific `--json*` glob matches the NEW call and
# returns a clean tag; the broader glob matches the OLD awk-style
# invocation and returns a TSV row whose TITLE column contains
# whitespace. First match wins, so:
# - after the fix: specific glob matches, action gets "2026.4.0" → passes
# - if the fix is reverted: old invocation has no --json → matches
#   the broader glob → gets tab-separated stdout → awk returns
#   "April" → validate_version rejects → step exits 1 → test fails.
export INPUT_TOKEN="ghp_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
export INPUT_PREFIX=""
export INPUT_DRY_RUN="true"
export VALIDATED_TOKEN="$INPUT_TOKEN"
export VALIDATED_PREFIX="$INPUT_PREFIX"
export VALIDATED_DRY_RUN="$INPUT_DRY_RUN"
current_ym="$(date -u +'%Y.%-m')"
mock_command gh "release list --limit 1 --json*" "${current_ym}.0"
mock_command gh "release list --limit 1" \
  "$(printf 'April 2026 Release\tLatest\t%s.0\t2026-04-15' "${current_ym}")"
mock_command gh "release create*" ""

When call run_step "${ACTION_DIR}" "create-release"
The status should be success
The stdout should include "${current_ym}.1"
Assert expect_output release_tag "${current_ym}.1"
End
End
