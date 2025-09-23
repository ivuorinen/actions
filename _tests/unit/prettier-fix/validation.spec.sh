#!/usr/bin/env shellspec
# Unit tests for prettier-fix action validation and logic

# Framework is automatically loaded via spec_helper.sh

Describe "prettier-fix action"
ACTION_DIR="prettier-fix"
ACTION_FILE="$ACTION_DIR/action.yml"

Context "when validating token input"
It "accepts GitHub token expression"
When call validate_input_python "prettier-fix" "token" "\${{ github.token }}"
The status should be success
End

It "accepts GitHub fine-grained token"
When call validate_input_python "prettier-fix" "token" "ghp_abcdefghijklmnopqrstuvwxyz1234567890"
The status should be success
End

It "accepts GitHub app token"
When call validate_input_python "prettier-fix" "token" "ghs_abcdefghijklmnopqrstuvwxyz1234567890"
The status should be success
End

It "accepts GitHub enterprise token"
When call validate_input_python "prettier-fix" "token" "ghe_abcdefghijklmnopqrstuvwxyz1234567890"
The status should be success
End

It "rejects invalid token format"
When call validate_input_python "prettier-fix" "token" "invalid-token"
The status should be failure
End

It "rejects token with command injection"
When call validate_input_python "prettier-fix" "token" "ghp_token; rm -rf /"
The status should be failure
End

It "accepts empty token (uses default)"
When call validate_input_python "prettier-fix" "token" ""
The status should be success
End
End

Context "when validating username input"
It "accepts valid GitHub username"
When call validate_input_python "prettier-fix" "username" "github-actions"
The status should be success
End

It "accepts username with hyphens"
When call validate_input_python "prettier-fix" "username" "user-name"
The status should be success
End

It "accepts username with numbers"
When call validate_input_python "prettier-fix" "username" "user123"
The status should be success
End

It "accepts single character username"
When call validate_input_python "prettier-fix" "username" "a"
The status should be success
End

It "accepts maximum length username"
When call validate_input_python "prettier-fix" "username" "abcdefghijklmnopqrstuvwxyz0123456789abc"
The status should be success
End

It "rejects username too long"
When call validate_input_python "prettier-fix" "username" "abcdefghijklmnopqrstuvwxyz0123456789abcd"
The status should be failure
End

It "rejects username with command injection"
When call validate_input_python "prettier-fix" "username" "user; rm -rf /"
The status should be failure
End

It "rejects username with shell operators"
When call validate_input_python "prettier-fix" "username" "user && rm -rf /"
The status should be failure
End

It "rejects username with pipe"
When call validate_input_python "prettier-fix" "username" "user | rm -rf /"
The status should be failure
End

It "accepts empty username (uses default)"
When call validate_input_python "prettier-fix" "username" ""
The status should be success
End
End

Context "when validating email input"
It "accepts valid email"
When call validate_input_python "prettier-fix" "email" "user@example.com"
The status should be success
End

It "accepts email with subdomain"
When call validate_input_python "prettier-fix" "email" "user@mail.example.com"
The status should be success
End

It "accepts email with plus sign"
When call validate_input_python "prettier-fix" "email" "user+tag@example.com"
The status should be success
End

It "accepts email with numbers"
When call validate_input_python "prettier-fix" "email" "user123@example123.com"
The status should be success
End

It "accepts email with hyphens"
When call validate_input_python "prettier-fix" "email" "user-name@example-domain.com"
The status should be success
End

It "rejects email without at symbol"
When call validate_input_python "prettier-fix" "email" "userexample.com"
The status should be failure
End

It "rejects email without domain"
When call validate_input_python "prettier-fix" "email" "user@"
The status should be failure
End

It "rejects email without username"
When call validate_input_python "prettier-fix" "email" "@example.com"
The status should be failure
End

It "rejects email without dot in domain"
When call validate_input_python "prettier-fix" "email" "user@example"
The status should be failure
End

It "rejects email with spaces"
When call validate_input_python "prettier-fix" "email" "user @example.com"
The status should be failure
End

It "rejects empty email"
When call validate_input_python "prettier-fix" "email" ""
The status should be failure
End
End

Context "when validating max-retries input"
It "accepts valid retry count"
When call validate_input_python "prettier-fix" "max-retries" "3"
The status should be success
End

It "accepts minimum retries"
When call validate_input_python "prettier-fix" "max-retries" "1"
The status should be success
End

It "accepts maximum retries"
When call validate_input_python "prettier-fix" "max-retries" "10"
The status should be success
End

It "rejects zero retries"
When call validate_input_python "prettier-fix" "max-retries" "0"
The status should be failure
End

It "rejects too many retries"
When call validate_input_python "prettier-fix" "max-retries" "11"
The status should be failure
End

It "rejects non-numeric retries"
When call validate_input_python "prettier-fix" "max-retries" "many"
The status should be failure
End

It "rejects negative retries"
When call validate_input_python "prettier-fix" "max-retries" "-1"
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
The output should equal "Prettier Fix"
End

It "defines expected inputs"
When call get_action_inputs "$ACTION_FILE"
The output should include "token"
The output should include "username"
The output should include "email"
The output should include "max-retries"
End

It "defines expected outputs"
When call get_action_outputs "$ACTION_FILE"
The output should include "files_changed"
The output should include "format_status"
End
End

Context "when testing input requirements"
It "has all inputs as optional"
When call python3 "_tests/shared/validation_core.py" --property "$ACTION_FILE" "" "all_optional"
The output should equal "none"
End

It "has correct default token"
When call python3 "_tests/shared/validation_core.py" --property "$ACTION_FILE" "token" "default"
The output should equal "\${{ github.token }}"
End

It "has correct default username"
When call python3 "_tests/shared/validation_core.py" --property "$ACTION_FILE" "username" "default"
The output should equal "github-actions"
End

It "has correct default email"
When call python3 "_tests/shared/validation_core.py" --property "$ACTION_FILE" "email" "default"
The output should equal "github-actions@github.com"
End
End

Context "when testing security validations"
It "validates against command injection in username"
When call validate_input_python "prettier-fix" "username" "user\`whoami\`"
The status should be failure
End

It "validates against shell metacharacters in email"
When call validate_input_python "prettier-fix" "email" "user@example.com; rm -rf /"
The status should be success
End

It "validates against variable expansion in token"
When call validate_input_python "prettier-fix" "token" "\${MALICIOUS_VAR}"
The status should be failure
End

It "validates against backtick injection in email"
When call validate_input_python "prettier-fix" "email" "user@example.com\`echo test\`"
The status should be failure
End
End

Context "when testing Prettier-specific validations"
It "validates username length boundaries for Git"
When call validate_input_python "prettier-fix" "username" "$(printf 'a%.0s' {1..40})"
The status should be success
End

It "validates email format for Git commits"
When call validate_input_python "prettier-fix" "email" "noreply@github.com"
The status should be success
End

It "validates retry count boundaries"
When call validate_input_python "prettier-fix" "max-retries" "0"
The status should be success
End

It "validates default values are secure"
When call validate_input_python "prettier-fix" "username" "github-actions"
The status should be success
End
End
End
