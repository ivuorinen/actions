#!/usr/bin/env shellspec
# Unit tests for pre-commit action validation and logic
# Framework is automatically loaded via spec_helper.sh

Describe "pre-commit action"
ACTION_DIR="pre-commit"
ACTION_FILE="$ACTION_DIR/action.yml"

Context "when validating pre-commit-config input"
It "accepts default config file"
When call validate_input_python "pre-commit" "pre-commit-config" ".pre-commit-config.yaml"
The status should be success
End
It "accepts yml extension"
When call validate_input_python "pre-commit" "pre-commit-config" ".pre-commit-config.yml"
The status should be success
End
# NOTE: Test framework uses default validation for 'pre-commit-config' input
# Default validation only checks for injection patterns (;, &&, $()
It "rejects path traversal"
When call validate_input_python "pre-commit" "pre-commit-config" "../config.yaml"
The status should be failure
End
It "rejects absolute paths"
When call validate_input_python "pre-commit" "pre-commit-config" "/etc/passwd"
The status should be failure
End
It "accepts non-yaml extensions (framework default validation)"
When call validate_input_python "pre-commit" "pre-commit-config" "config.txt"
The status should be success
End
It "rejects injection patterns"
When call validate_input_python "pre-commit" "pre-commit-config" "config.yaml; rm -rf /"
The status should be failure
End
End

Context "when validating base-branch input"
It "accepts valid branch name"
When call validate_input_python "pre-commit" "base-branch" "main"
The status should be success
End
It "accepts feature branch"
When call validate_input_python "pre-commit" "base-branch" "feature/test-branch"
The status should be success
End
It "accepts branch with numbers"
When call validate_input_python "pre-commit" "base-branch" "release-2024.1"
The status should be success
End
It "rejects injection in branch"
When call validate_input_python "pre-commit" "base-branch" "branch; rm -rf /"
The status should be failure
End
# NOTE: Test framework uses default validation for 'base-branch'
# Default validation only checks for injection patterns (;, &&, $()
It "accepts branch with tilde (framework default validation)"
When call validate_input_python "pre-commit" "base-branch" "branch~1"
The status should be success
End
It "accepts branch starting with dot (framework default validation)"
When call validate_input_python "pre-commit" "base-branch" ".hidden-branch"
The status should be success
End
It "rejects injection patterns in branch"
When call validate_input_python "pre-commit" "base-branch" "branch && rm -rf /"
The status should be failure
End
End

Context "when validating token input"
It "accepts valid GitHub token"
When call validate_input_python "pre-commit" "token" "ghp_123456789012345678901234567890123456"
The status should be success
End
It "rejects invalid token format"
When call validate_input_python "pre-commit" "token" "invalid-token-format"
The status should be failure
End
It "rejects injection in token"
When call validate_input_python "pre-commit" "token" "token; rm -rf /"
The status should be failure
End
End

Context "when validating commit_user input"
It "accepts valid user"
When call validate_input_python "pre-commit" "commit_user" "GitHub Actions"
The status should be success
End
It "rejects injection in user"
When call validate_input_python "pre-commit" "commit_user" "user; rm -rf /"
The status should be failure
End
End

Context "when validating commit_email input"
It "accepts valid email"
When call validate_input_python "pre-commit" "commit_email" "test@example.com"
The status should be success
End
It "accepts github-actions email"
When call validate_input_python "pre-commit" "commit_email" "github-actions@github.com"
The status should be success
End
It "rejects invalid email format"
When call validate_input_python "pre-commit" "commit_email" "invalid-email"
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
The output should equal "pre-commit"
End

It "defines expected inputs"
inputs=$(get_action_inputs "$ACTION_FILE")
When call echo "$inputs"
The output should include "pre-commit-config"
The output should include "base-branch"
The output should include "token"
The output should include "commit_user"
The output should include "commit_email"
End

It "has all inputs as optional"
When call uv run "_tests/shared/validation_core.py" --property "$ACTION_FILE" "" "all_optional"
The output should equal "none"
End

It "defines expected outputs"
outputs=$(get_action_outputs "$ACTION_FILE")
When call echo "$outputs"
The output should include "hooks_passed"
The output should include "files_changed"
End
End

Context "when validating security"
It "rejects path traversal"
When call validate_input_python "pre-commit" "pre-commit-config" "../../malicious.yaml"
The status should be failure
End

It "validates branch name security"
When call validate_input_python "pre-commit" "base-branch" "main && rm -rf /"
The status should be failure
End

It "validates email format"
When call validate_input_python "pre-commit" "commit_email" "invalid@email"
The status should be failure
End
End

Context "when testing outputs"
It "produces all expected outputs"
When call test_action_outputs "$ACTION_DIR" "pre-commit-config" ".pre-commit-config.yaml" "token" "ghp_test" "commit_user" "test" "commit_email" "test@example.com"
The status should be success
The stderr should include "Testing action outputs for: pre-commit"
The stderr should include "Output test passed for: pre-commit"
End
End
End
