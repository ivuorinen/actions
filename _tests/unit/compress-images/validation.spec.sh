#!/usr/bin/env shellspec
# Unit tests for compress-images action validation and logic

# Framework is automatically loaded via spec_helper.sh

Describe "compress-images action"
  ACTION_DIR="compress-images"
  ACTION_FILE="$ACTION_DIR/action.yml"

  Context "when validating inputs"
    It "accepts valid quality setting"
      When call test_input_validation "$ACTION_DIR" "quality" "80" "success"
      The status should be success
    End
    It "rejects invalid quality"
      When call test_input_validation "$ACTION_DIR" "quality" "150" "failure"
      The status should be success
    End
    It "accepts valid path pattern"
      When call test_input_validation "$ACTION_DIR" "path" "assets/**/*.{jpg,png}" "success"
      The status should be success
    End
    It "rejects injection in path"
      When call test_input_validation "$ACTION_DIR" "path" "images;rm -rf /" "failure"
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
      The output should match pattern "*Compress*"
    End
  End
End
