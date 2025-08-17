#!/usr/bin/env shellspec
# Unit tests for common-file-check action validation and logic

# Framework is automatically loaded via spec_helper.sh

Describe "common-file-check action"
  ACTION_DIR="common-file-check"
  ACTION_FILE="$ACTION_DIR/action.yml"

  Context "when validating file-pattern input"
    It "accepts simple file pattern"
      When call test_input_validation "$ACTION_DIR" "file-pattern" "package.json" "success"
      The status should be success
    End
    It "accepts glob pattern with wildcard"
      When call test_input_validation "$ACTION_DIR" "file-pattern" "*.json" "success"
      The status should be success
    End
    It "accepts glob pattern with question mark"
      When call test_input_validation "$ACTION_DIR" "file-pattern" "test?.js" "success"
      The status should be success
    End
    It "accepts nested path pattern"
      When call test_input_validation "$ACTION_DIR" "file-pattern" "src/**/*.ts" "success"
      The status should be success
    End
    It "accepts pattern with braces"
      When call test_input_validation "$ACTION_DIR" "file-pattern" "*.{js,ts}" "success"
      The status should be success
    End
    It "accepts pattern with brackets"
      When call test_input_validation "$ACTION_DIR" "file-pattern" "[A-Z]*.txt" "success"
      The status should be success
    End
    It "rejects empty file pattern"
      When call test_input_validation "$ACTION_DIR" "file-pattern" "" "failure"
      The status should be success
    End
    It "rejects path traversal"
      When call test_input_validation "$ACTION_DIR" "file-pattern" "../../../etc/passwd" "failure"
      The status should be success
    End
    It "rejects command injection"
      When call test_input_validation "$ACTION_DIR" "file-pattern" "*.json;rm -rf /" "failure"
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
      The output should equal "Common File Check"
    End

    It "defines expected inputs"
      inputs=$(get_action_inputs "$ACTION_FILE")
      When call echo "$inputs"
      The output should include "file-pattern"
    End

    It "defines expected outputs"
      outputs=$(get_action_outputs "$ACTION_FILE")
      When call echo "$outputs"
      The output should include "found"
    End
  End

  Context "when validating security"
    It "validates glob patterns safely"
      When call test_input_validation "$ACTION_DIR" "file-pattern" "**/*.{js,ts,json}" "success"
      The status should be success
    End

    It "rejects injection in glob patterns"
      When call test_input_validation "$ACTION_DIR" "file-pattern" "*.js&&malicious" "failure"
      The status should be success
    End

    It "rejects pipe injection in patterns"
      When call test_input_validation "$ACTION_DIR" "file-pattern" "*.js|dangerous" "failure"
      The status should be success
    End
  End

  Context "when testing outputs"
    It "produces all expected outputs consistently"
      When call test_action_outputs "$ACTION_DIR" "file-pattern" "*.json"
      The status should be success
      The stderr should include "Testing action outputs for: common-file-check"
      The stderr should include "Output test passed for: common-file-check"
    End
  End
End
