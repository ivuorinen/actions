#!/usr/bin/env shellspec
# Behavior-level tests for release-monthly using the composite-step harness.
#
# The clock is mocked, never read. The create-release step calls `date` exactly
# twice (`-u +%Y` and `-u +%m`), so both are registered as mocks and the harness
# shadows the real binary on the child PATH. Reading the real clock here made the
# suite's result depend on the calendar month and hid a production defect that only
# fires in August and September (see docs/audit/findings, tests-c1051f2d).

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

# Registers the two `date` calls the create-release step makes.
mock_clock() {
  mock_command date "-u +%Y" "$1"
  mock_command date "-u +%m" "$2"
}

It "increments patch when a release already exists for the current month and prefix=v"
# With prefix=v and an existing release for the current month, the
# action should bump the patch rather than reset to 0 or fail.
export INPUT_TOKEN="ghp_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
export INPUT_PREFIX="v"
export INPUT_DRY_RUN="true"
mock_clock "2026" "04"
# gh --json tagName --jq '.[0].tagName' returns just the tag string.
mock_command gh "release list --limit 1*" "v2026.4.0"
mock_command gh "release create*" ""

When call run_step "${ACTION_DIR}" "create-release"
The status should be success
The stdout should include "v2026.4.1"
Assert expect_output release_tag "v2026.4.1"
End

It "resets patch to 0 when the latest release is from an earlier month"
export INPUT_TOKEN="ghp_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
export INPUT_PREFIX=""
export INPUT_DRY_RUN="true"
mock_clock "2026" "04"
mock_command gh "release list --limit 1*" "2026.3.7"
mock_command gh "release create*" ""

When call run_step "${ACTION_DIR}" "create-release"
The status should be success
The stdout should include "2026.4.0"
Assert expect_output release_tag "2026.4.0"
Assert expect_output previous_tag "2026.3.7"
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
mock_clock "2026" "04"
mock_command gh "release list --limit 1 --json*" "2026.4.0"
mock_command gh "release list --limit 1" \
  "$(printf 'April 2026 Release\tLatest\t2026.4.0\t2026-04-15')"
mock_command gh "release create*" ""

When call run_step "${ACTION_DIR}" "create-release"
The status should be success
The stdout should include "2026.4.1"
Assert expect_output release_tag "2026.4.1"
End

Describe "month normalization"
# The step must strip the leading zero from `date -u +%m` without POSIX printf,
# which parses a leading-zero argument as octal. 08 and 09 are the discriminating
# cases (invalid octal digits → printf exits 1 → set -e kills the step); 01, 07
# and 10 are controls that catch a normalization that over-strips or stops
# stripping. Every month is pinned, so this is calendar-independent.
Parameters
"01" "2026.1.0" "2026.1.1"
"07" "2026.7.0" "2026.7.1"
"08" "2026.8.0" "2026.8.1"
"09" "2026.9.0" "2026.9.1"
"10" "2026.10.0" "2026.10.1"
"12" "2026.12.0" "2026.12.1"
End

It "normalizes month $1 without treating it as octal"
export INPUT_TOKEN="ghp_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
export INPUT_PREFIX=""
export INPUT_DRY_RUN="true"
mock_clock "2026" "$1"
mock_command gh "release list --limit 1*" "$2"
mock_command gh "release create*" ""

When call run_step "${ACTION_DIR}" "create-release"
The status should be success
The stdout should include "$3"
The stderr should not include "not completely converted"
Assert expect_output release_tag "$3"
End
End
End
