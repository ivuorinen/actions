#!/usr/bin/env shellspec
# Unit tests for sync-labels "Check Labels File" step behavior.
# Uses run_step to execute the real action step so GITHUB_OUTPUT handling
# matches production and doesn't depend on bash variable export mechanics.
#
# Working directory is SHELLSPEC_TEST_WORKSPACE (set by shellspec_setup_test_env),
# so relative paths in INPUT_LABELS are resolved there — no /tmp/ paths needed.

Describe "sync-labels Check Labels File step"
ACTION_DIR="${PROJECT_ROOT}/sync-labels"

before() {
  shellspec_setup_test_env "sync-labels-file-check-$$"
  harness_reset
}
BeforeEach 'before'

after() {
  shellspec_cleanup_test_env "sync-labels-file-check-$$"
  harness_reset
}
AfterEach 'after'

Context "with INPUT_LABELS pointing to an existing file"
It "sets found=true and exits without warning"
touch labels.yml
export INPUT_LABELS="labels.yml"
When call run_step "${ACTION_DIR}" "check-labels-file"
The status should be success
The stdout should be blank
Assert expect_output found true
Assert expect_output manifest-path "labels.yml"
End
End

Context "with INPUT_LABELS pointing to a missing file"
It "sets found=false and emits a warning"
export INPUT_LABELS="nonexistent-labels.yml"
When call run_step "${ACTION_DIR}" "check-labels-file"
The status should be success
The stdout should include "::warning::"
Assert expect_output found false
Assert expect_output manifest-path "nonexistent-labels.yml"
End
End

Context "with no INPUT_LABELS (uses default manifest path)"
It "sets found=true and exits without warning — sync-labels ships labels.yml"
When call run_step "${ACTION_DIR}" "check-labels-file"
The status should be success
The stdout should be blank
Assert expect_output found true
End
End

Context "with INPUT_LABELS as an absolute path"
It "exits with error — only relative paths are allowed"
export INPUT_LABELS="/tmp/labels.yml"
When call run_step "${ACTION_DIR}" "check-labels-file"
The status should be failure
The stdout should include "::error::"
End
End

Context "with INPUT_LABELS containing path traversal"
It "exits with error — path traversal is not allowed"
export INPUT_LABELS="../labels.yml"
When call run_step "${ACTION_DIR}" "check-labels-file"
The status should be failure
The stdout should include "::error::"
End
End
End
