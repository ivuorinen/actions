#!/usr/bin/env shellspec
# Unit tests for python-lint-fix action validation and logic

# Framework is automatically loaded via spec_helper.sh

Describe "python-lint-fix action"
ACTION_DIR="python-lint-fix"
ACTION_FILE="$ACTION_DIR/action.yml"

Context "when validating token input"
It "accepts GitHub token expression"
When call validate_input_python "python-lint-fix" "token" "\${{ github.token }}"
The status should be success
End

It "accepts GitHub fine-grained token"
When call validate_input_python "python-lint-fix" "token" "ghp_abcdefghijklmnopqrstuvwxyz1234567890"
The status should be success
End

It "accepts GitHub app token"
When call validate_input_python "python-lint-fix" "token" "ghs_abcdefghijklmnopqrstuvwxyz1234567890"
The status should be success
End

It "rejects invalid token format"
When call validate_input_python "python-lint-fix" "token" "invalid-token"
The status should be failure
End

It "rejects token with command injection"
When call validate_input_python "python-lint-fix" "token" "ghp_token; rm -rf /"
The status should be failure
End

It "accepts empty token (uses default)"
When call validate_input_python "python-lint-fix" "token" ""
The status should be success
End
End

Context "when validating username input"
It "accepts valid GitHub username"
When call validate_input_python "python-lint-fix" "username" "github-actions"
The status should be success
End

It "accepts username with hyphens"
When call validate_input_python "python-lint-fix" "username" "user-name"
The status should be success
End

It "accepts username with numbers"
When call validate_input_python "python-lint-fix" "username" "user123"
The status should be success
End

It "rejects username too long"
When call validate_input_python "python-lint-fix" "username" "$(awk 'BEGIN{for(i=1;i<=40;i++)printf "a"}')"
The status should be failure
End

It "rejects username with command injection"
When call validate_input_python "python-lint-fix" "username" "user; rm -rf /"
The status should be failure
End

It "accepts empty username (uses default)"
When call validate_input_python "python-lint-fix" "username" ""
The status should be success
End
End

Context "when validating email input"
It "accepts valid email"
When call validate_input_python "python-lint-fix" "email" "user@example.com"
The status should be success
End

It "accepts email with subdomain"
When call validate_input_python "python-lint-fix" "email" "user@mail.example.com"
The status should be success
End

It "rejects email without at symbol"
When call validate_input_python "python-lint-fix" "email" "userexample.com"
The status should be failure
End

It "rejects email without domain"
When call validate_input_python "python-lint-fix" "email" "user@"
The status should be failure
End

It "rejects email with spaces"
When call validate_input_python "python-lint-fix" "email" "user @example.com"
The status should be failure
End

It "accepts empty email (uses default)"
When call python3 "_tests/shared/validation_core.py" --validate "python-lint-fix" "email" ""
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
The output should equal "Python Lint and Fix"
End

It "defines expected inputs"
When call get_action_inputs "$ACTION_FILE"
The output should include "token"
The output should include "username"
The output should include "email"
End
End

Context "when testing input requirements"
It "has all inputs as optional"
When call python3 "_tests/shared/validation_core.py" --property "$ACTION_FILE" "" "all_optional"
The output should equal "none"
End
End

Context "when testing security validations"
It "validates against command injection in username"
When call validate_input_python "python-lint-fix" "username" "user\`whoami\`"
The status should be failure
End

It "validates against shell metacharacters in email"
When call validate_input_python "python-lint-fix" "email" "user@example.com; rm -rf /"
The status should be failure
End

It "validates against variable expansion in token"
When call validate_input_python "python-lint-fix" "token" "\${MALICIOUS_VAR}"
The status should be failure
End
End
End
