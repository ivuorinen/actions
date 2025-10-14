#!/usr/bin/env shellspec
# Unit tests for pr-lint action validation and logic
# Framework is automatically loaded via spec_helper.sh

Describe "pr-lint action"
ACTION_DIR="pr-lint"
ACTION_FILE="$ACTION_DIR/action.yml"

Context "when validating token input"
It "accepts valid GitHub token"
When call validate_input_python "pr-lint" "token" "ghp_123456789012345678901234567890123456"
The status should be success
End
It "rejects injection in token"
When call validate_input_python "pr-lint" "token" "token; rm -rf /"
The status should be failure
End
End

Context "when validating username input"
It "accepts valid username"
When call validate_input_python "pr-lint" "username" "github-actions"
The status should be success
End
It "rejects injection in username"
When call validate_input_python "pr-lint" "username" "user; rm -rf /"
The status should be failure
End
End

Context "when validating email input"
It "accepts valid email"
When call validate_input_python "pr-lint" "email" "test@example.com"
The status should be success
End
It "rejects invalid email format"
When call validate_input_python "pr-lint" "email" "invalid-email"
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
The output should equal "PR Lint"
End

It "defines required inputs"
inputs=$(get_action_inputs "$ACTION_FILE")
When call echo "$inputs"
The output should include "token"
The output should include "username"
The output should include "email"
End

It "defines expected outputs"
outputs=$(get_action_outputs "$ACTION_FILE")
When call echo "$outputs"
The output should include "validation_status"
The output should include "errors_found"
End
End

Context "when validating security"
It "validates token format"
When call validate_input_python "pr-lint" "token" "invalid-token;rm -rf /"
The status should be failure
End

It "validates email format"
When call validate_input_python "pr-lint" "email" "invalid@email"
The status should be failure
End
End

Context "when testing outputs"
It "produces all expected outputs"
When call test_action_outputs "$ACTION_DIR" "token" "ghp_test" "username" "test" "email" "test@example.com"
The status should be success
The stderr should include "Testing action outputs for: pr-lint"
The stderr should include "Output test passed for: pr-lint"
End
End
End
