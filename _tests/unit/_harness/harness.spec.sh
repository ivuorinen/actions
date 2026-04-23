#!/usr/bin/env shellspec
# End-to-end ShellSpec tests for the composite-step harness.

Describe "harness"
  FIXTURES="${PROJECT_ROOT}/_tests/fixtures/harness"

  before() {
    shellspec_setup_test_env "harness-$$"
    harness_reset
  }
  BeforeEach 'before'

  after() {
    shellspec_cleanup_test_env "harness-$$"
    harness_reset
  }
  AfterEach 'after'

  Describe "echo-inputs fixture"
    It "passes INPUT_FOO through to the step and writes the output"
      export INPUT_FOO="hello"
      When call run_step "${FIXTURES}/echo-inputs" "emit"
      The status should be success
      The file "$GITHUB_OUTPUT" should be exist
      Assert expect_output echoed hello
    End
  End

  Describe "uses-gh fixture"
    It "fails when gh is not mocked (gh absent from restricted PATH)"
      # The harness restricts PATH so unmocked external commands aren't found.
      # Exact error message varies by shell; we only assert "not found".
      When call run_step "${FIXTURES}/uses-gh" "fetch"
      The status should not be success
      The stderr should include "not found"
    End

    It "runs when gh is mocked"
      mock_command gh "release list *" "v2026.4.0"
      When call run_step "${FIXTURES}/uses-gh" "fetch"
      The status should be success
      Assert expect_output tag "v2026.4.0"
    End
  End

  Describe "if-conditional fixture"
    It "runs the gated step when prior step outputs match"
      When call run_all_owned_steps "${FIXTURES}/if-conditional"
      The status should be success
      Assert expect_output flag yes
      Assert expect_output ran true
    End
  End
End
