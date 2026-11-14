#!/usr/bin/env shellspec
# Unit tests for python-lint-fix action validation and logic

# Framework is automatically loaded via spec_helper.sh

Describe "python-lint-fix action"
ACTION_DIR="python-lint-fix"
ACTION_FILE="$ACTION_DIR/action.yml"

Context "when validating token input"
It "rejects an unexpanded expression as a token"
When call validate_input_python "python-lint-fix" "token" "\${{ github.token }}"
The status should be failure
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
When call uv run "_tests/shared/validation_core.py" --validate "python-lint-fix" "email" ""
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
When call uv run "_tests/shared/validation_core.py" --property "$ACTION_FILE" "" "all_optional"
The output should equal "none"
End
End

Context "when lint fails"
It "lets the lint step fail without skipping the fix and commit steps"
When call yq -r '.runs.steps[] | select(.id == "lint") | .["continue-on-error"]' "$ACTION_FILE"
The output should equal "true"
End

It "fails the action after the commit step when lint failed"
When call yq -r '.runs.steps[].name | select(. == "Commit Fixes" or . == "Fail on Lint Errors")' "$ACTION_FILE"
The line 1 of output should equal "Commit Fixes"
The line 2 of output should equal "Fail on Lint Errors"
End

It "gates the final failure step on the lint outcome"
When call yq -r '.runs.steps[] | select(.name == "Fail on Lint Errors") | .if' "$ACTION_FILE"
The output should equal "steps.lint.outcome == 'failure'"
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

It "rejects a token passed as an env-var reference"
# The runner does not expand $VAR in a with: value, so the action would use this text
# as the token. Pass the secret as an expression, which the runner does expand.
When call validate_input_python "python-lint-fix" "token" "\${SOME_TOKEN_VAR}"
The status should be failure
End
End

Context "when working-directory starts with a dash"
It "rejects a leading dash"
When call validate_input_python "python-lint-fix" "working-directory" "--help"
The status should be failure
End

It "ends cd options before the working directory"
When call grep -c 'cd -- "$WORKING_DIRECTORY"' python-lint-fix/action.yml
The status should be success
The output should equal 3
End
End
End
