#!/usr/bin/env shellspec
# Unit tests for terraform-lint-fix action validation and logic

# Framework is automatically loaded via spec_helper.sh

Describe "terraform-lint-fix action"
ACTION_DIR="terraform-lint-fix"
ACTION_FILE="$ACTION_DIR/action.yml"

Context "when validating token input"
It "accepts GitHub token expression"
When call validate_input_python "terraform-lint-fix" "token" "\${{ github.token }}"
The status should be success
End

It "accepts GitHub fine-grained token"
When call validate_input_python "terraform-lint-fix" "token" "ghp_abcdefghijklmnopqrstuvwxyz1234567890"
The status should be success
End

It "rejects invalid token format"
When call validate_input_python "terraform-lint-fix" "token" "invalid-token"
The status should be failure
End

It "rejects token with command injection"
When call validate_input_python "terraform-lint-fix" "token" "ghp_token; rm -rf /"
The status should be failure
End

It "accepts empty token (uses default)"
When call validate_input_python "terraform-lint-fix" "token" ""
The status should be success
End
End

Context "when validating terraform-version input"
It "accepts valid terraform version"
When call validate_input_python "terraform-lint-fix" "terraform-version" "1.5.0"
The status should be success
End

It "accepts latest terraform version"
When call validate_input_python "terraform-lint-fix" "terraform-version" "latest"
The status should be success
End

It "accepts terraform version with patch"
When call validate_input_python "terraform-lint-fix" "terraform-version" "1.5.7"
The status should be success
End

It "accepts terraform version with v prefix"
When call validate_input_python "terraform-lint-fix" "terraform-version" "v1.5.0"
The status should be success
End

It "rejects terraform version with command injection"
When call validate_input_python "terraform-lint-fix" "terraform-version" "1.5.0; rm -rf /"
The status should be failure
End

It "accepts empty terraform version (uses default)"
When call validate_input_python "terraform-lint-fix" "terraform-version" ""
The status should be success
End
End

Context "when validating working-directory input"
It "accepts current directory"
When call validate_input_python "terraform-lint-fix" "working-directory" "."
The status should be success
End

It "accepts relative directory"
When call validate_input_python "terraform-lint-fix" "working-directory" "terraform"
The status should be success
End

It "accepts nested directory"
When call validate_input_python "terraform-lint-fix" "working-directory" "infrastructure/terraform"
The status should be success
End

It "rejects path traversal"
When call validate_input_python "terraform-lint-fix" "working-directory" "../malicious"
The status should be failure
End

It "rejects absolute paths"
When call validate_input_python "terraform-lint-fix" "working-directory" "/etc/passwd"
The status should be failure
End

It "rejects directory with command injection"
When call validate_input_python "terraform-lint-fix" "working-directory" "terraform; rm -rf /"
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
The output should equal "Terraform Lint and Fix"
End

It "defines expected inputs"
When call get_action_inputs "$ACTION_FILE"
The output should include "token"
The output should include "terraform-version"
The output should include "working-directory"
End
End

Context "when testing input requirements"
It "has all inputs as optional"
When call "${PROJECT_ROOT}/.venv/bin/python3" "_tests/shared/validation_core.py" --property "$ACTION_FILE" "" "all_optional"
The output should equal "none"
End
End

Context "when testing security validations"
It "validates against path traversal in working directory"
When call validate_input_python "terraform-lint-fix" "working-directory" "../../malicious"
The status should be failure
End

It "validates against command injection in terraform version"
When call validate_input_python "terraform-lint-fix" "terraform-version" "1.5.0\`whoami\`"
The status should be failure
End

It "validates against shell metacharacters in token"
When call validate_input_python "terraform-lint-fix" "token" "ghp_token && rm -rf /"
The status should be failure
End
End

Context "when testing Terraform-specific validations"
It "validates terraform version format"
When call validate_input_python "terraform-lint-fix" "terraform-version" "1.x.x"
The status should be failure
End

It "validates working directory path safety"
When call validate_input_python "terraform-lint-fix" "working-directory" "/root/.ssh"
The status should be failure
End
End
End
