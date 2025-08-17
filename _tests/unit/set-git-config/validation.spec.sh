#!/usr/bin/env shellspec
# Unit tests for set-git-config action validation and logic
# Framework is automatically loaded via spec_helper.sh

Describe "set-git-config action"
  ACTION_DIR="set-git-config"
  ACTION_FILE="$ACTION_DIR/action.yml"

  Context "when validating inputs (no validation logic in action)"
    # NOTE: This action has no validation logic - all inputs are accepted
    # The action simply passes through values and conditionally sets outputs
    It "accepts valid token value"
      When call test_input_validation "$ACTION_DIR" "token" "ghp_123456789012345678901234567890123456" "success"
      The status should be success
    End
    It "accepts any username value"
      When call test_input_validation "$ACTION_DIR" "username" "any-username" "success"
      The status should be success
    End
    It "accepts valid email value"
      When call test_input_validation "$ACTION_DIR" "email" "test@example.com" "success"
      The status should be success
    End
    It "accepts any is_fiximus value"
      When call test_input_validation "$ACTION_DIR" "is_fiximus" "any-value" "success"
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
      The output should equal "Set Git Config"
    End

    It "defines required inputs"
      inputs=$(get_action_inputs "$ACTION_FILE")
      When call echo "$inputs"
      The output should include "token"
      The output should include "username"
      The output should include "email"
      The output should include "is_fiximus"
    End

    It "defines expected outputs"
      outputs=$(get_action_outputs "$ACTION_FILE")
      When call echo "$outputs"
      The output should include "token"
      The output should include "username"
      The output should include "email"
      The output should include "is_fiximus"
    End
  End

  Context "when testing outputs"
    It "produces all expected outputs"
      When call test_action_outputs "$ACTION_DIR" "token" "ghp_test" "username" "test" "email" "test@example.com" "is_fiximus" "false"
      The status should be success
      The stderr should include "Testing action outputs for: set-git-config"
      The stderr should include "Output test passed for: set-git-config"
    End
  End
End
