#!/usr/bin/env shellspec
# Unit tests for common-retry action validation and logic

# Framework is automatically loaded via spec_helper.sh

Describe "common-retry action"
  ACTION_DIR="common-retry"
  ACTION_FILE="$ACTION_DIR/action.yml"

  Context "when validating max-retries input"
    It "accepts minimum value (1)"
      When call test_input_validation "$ACTION_DIR" "max-retries" "1" "success"
      The status should be success
    End
    It "accepts maximum value (10)"
      When call test_input_validation "$ACTION_DIR" "max-retries" "10" "success"
      The status should be success
    End
    It "rejects below minimum"
      When call test_input_validation "$ACTION_DIR" "max-retries" "0" "failure"
      The status should be success
    End
    It "rejects above maximum"
      When call test_input_validation "$ACTION_DIR" "max-retries" "11" "failure"
      The status should be success
    End
    It "rejects non-numeric"
      When call test_input_validation "$ACTION_DIR" "max-retries" "invalid" "failure"
      The status should be success
    End
  End

  Context "when validating retry-delay input"
    It "accepts minimum value (1)"
      When call test_input_validation "$ACTION_DIR" "retry-delay" "1" "success"
      The status should be success
    End
    It "accepts maximum value (300)"
      When call test_input_validation "$ACTION_DIR" "retry-delay" "300" "success"
      The status should be success
    End
    It "rejects below minimum"
      When call test_input_validation "$ACTION_DIR" "retry-delay" "0" "failure"
      The status should be success
    End
    It "rejects above maximum"
      When call test_input_validation "$ACTION_DIR" "retry-delay" "301" "failure"
      The status should be success
    End
  End

  Context "when validating backoff-strategy input"
    It "accepts linear strategy"
      When call test_input_validation "$ACTION_DIR" "backoff-strategy" "linear" "success"
      The status should be success
    End
    It "accepts exponential strategy"
      When call test_input_validation "$ACTION_DIR" "backoff-strategy" "exponential" "success"
      The status should be success
    End
    It "accepts fixed strategy"
      When call test_input_validation "$ACTION_DIR" "backoff-strategy" "fixed" "success"
      The status should be success
    End
    It "rejects invalid strategy"
      When call test_input_validation "$ACTION_DIR" "backoff-strategy" "invalid" "failure"
      The status should be success
    End
  End

  Context "when validating timeout input"
    It "accepts minimum value (1)"
      When call test_input_validation "$ACTION_DIR" "timeout" "1" "success"
      The status should be success
    End
    It "accepts maximum value (3600)"
      When call test_input_validation "$ACTION_DIR" "timeout" "3600" "success"
      The status should be success
    End
    It "rejects below minimum"
      When call test_input_validation "$ACTION_DIR" "timeout" "0" "failure"
      The status should be success
    End
    It "rejects above maximum"
      When call test_input_validation "$ACTION_DIR" "timeout" "3601" "failure"
      The status should be success
    End
  End

  Context "when validating working-directory input"
    It "accepts current directory"
      When call test_input_validation "$ACTION_DIR" "working-directory" "." "success"
      The status should be success
    End
    It "accepts relative path"
      When call test_input_validation "$ACTION_DIR" "working-directory" "src/app" "success"
      The status should be success
    End
    It "rejects path traversal"
      When call test_input_validation "$ACTION_DIR" "working-directory" "../../../etc" "failure"
      The status should be success
    End
  End

  Context "when validating shell input"
    It "accepts bash shell"
      When call test_input_validation "$ACTION_DIR" "shell" "bash" "success"
      The status should be success
    End
    It "accepts sh shell"
      When call test_input_validation "$ACTION_DIR" "shell" "sh" "success"
      The status should be success
    End
    It "rejects zsh shell"
      When call test_input_validation "$ACTION_DIR" "shell" "zsh" "failure"
      The status should be success
    End
  End

  Context "when checking action.yml structure"
    It "has valid YAML syntax"
      When call validate_action_yml_quiet "$ACTION_FILE"
      The status should be success
    End

    It "has correct action name"
      name=$(get_action_name "$ACTION_FILE")
      When call echo "$name"
      The output should equal "Common Retry"
    End
  End

  Context "when validating security"
    It "rejects command injection with semicolon"
      When call test_input_validation "$ACTION_DIR" "command" "value; rm -rf /" "failure"
      The status should be success
    End

    It "rejects command injection with ampersand"
      When call test_input_validation "$ACTION_DIR" "command" "value && malicious" "failure"
      The status should be success
    End

    It "accepts valid success codes"
      When call test_input_validation "$ACTION_DIR" "success-codes" "0,1,2" "success"
      The status should be success
    End

    It "rejects success codes with injection"
      When call test_input_validation "$ACTION_DIR" "success-codes" "0;rm -rf /" "failure"
      The status should be success
    End

    It "accepts valid retry codes"
      When call test_input_validation "$ACTION_DIR" "retry-codes" "1,126,127" "success"
      The status should be success
    End

    It "rejects retry codes with injection"
      When call test_input_validation "$ACTION_DIR" "retry-codes" "1;rm -rf /" "failure"
      The status should be success
    End
  End

End
