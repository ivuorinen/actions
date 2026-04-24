#!/usr/bin/env shellspec
# Unit tests for release-monthly action validation and logic
# Framework is automatically loaded via spec_helper.sh

Describe "release-monthly action"
ACTION_DIR="release-monthly"
ACTION_FILE="$ACTION_DIR/action.yml"

Context "when validating token input"
# NOTE: Test framework uses strict GitHub token format validation
It "accepts valid GitHub token with correct format"
When call validate_input_python "release-monthly" "token" "ghp_123456789012345678901234567890123456"
The status should be success
End
It "rejects empty token"
When call validate_input_python "release-monthly" "token" ""
The status should be failure
End
It "rejects injection in token"
When call validate_input_python "release-monthly" "token" "token; rm -rf /"
The status should be failure
End
End

Context "when validating dry-run input"
It "accepts true value"
When call validate_input_python "release-monthly" "dry-run" "true"
The status should be success
End
It "accepts false value"
When call validate_input_python "release-monthly" "dry-run" "false"
The status should be success
End
# NOTE: Convention-based validation applies boolean validation to 'dry-run'
# Boolean validator rejects non-boolean values
It "rejects invalid boolean value"
When call validate_input_python "release-monthly" "dry-run" "maybe"
The status should be failure
End
It "rejects injection in dry-run"
When call validate_input_python "release-monthly" "dry-run" "true; rm -rf /"
The status should be failure
End
End

Context "when validating prefix input"
# NOTE: prefix has default: '' so empty values are accepted
It "accepts empty prefix (has empty default)"
When call validate_input_python "release-monthly" "prefix" ""
The status should be success
End
It "accepts valid prefix"
When call validate_input_python "release-monthly" "prefix" "v"
The status should be success
End
It "accepts alphanumeric prefix"
When call validate_input_python "release-monthly" "prefix" "release-v1.0-"
The status should be success
End
# NOTE: validator now rejects inputs that the action's `case` pattern
# would reject at runtime. Tautological "accepts special chars" tests
# removed — behavior.spec.sh exercises the real action.
It "rejects injection in prefix"
When call validate_input_python "release-monthly" "prefix" "prefix; rm -rf /"
The status should be failure
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
The output should equal "Do Monthly Release"
End

It "defines required inputs"
inputs=$(get_action_inputs "$ACTION_FILE")
When call echo "$inputs"
The output should include "token"
The output should include "dry-run"
The output should include "prefix"
End

It "defines expected outputs"
outputs=$(get_action_outputs "$ACTION_FILE")
When call echo "$outputs"
The output should include "release-tag"
The output should include "release-url"
The output should include "previous-tag"
End
End

Context "when validating security"
It "validates token is required"
When call validate_input_python "release-monthly" "token" ""
The status should be failure
End

It "validates prefix format"
When call validate_input_python "release-monthly" "prefix" "invalid;prefix"
The status should be failure
End
End

# Note: output assertions moved to behavior.spec.sh — real action
# execution via the harness, not tautological mock data.
End
