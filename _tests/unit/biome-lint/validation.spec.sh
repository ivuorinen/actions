#!/usr/bin/env shellspec
# Unit tests for biome-lint action validation and logic
# Framework is automatically loaded via spec_helper.sh

Describe "biome-lint action"
ACTION_DIR="biome-lint"
ACTION_FILE="$ACTION_DIR/action.yml"

Context "when validating mode input"
It "accepts check mode"
When call validate_input_python "biome-lint" "mode" "check"
The status should be success
End

It "accepts fix mode"
When call validate_input_python "biome-lint" "mode" "fix"
The status should be success
End

It "accepts empty mode (uses default)"
When call validate_input_python "biome-lint" "mode" ""
The status should be success
End

It "rejects invalid mode"
When call validate_input_python "biome-lint" "mode" "invalid"
The status should be failure
End

It "rejects mode with command injection"
When call validate_input_python "biome-lint" "mode" "check; rm -rf /"
The status should be failure
End
End

Context "when validating token input"
It "accepts valid GitHub token (classic)"
When call validate_input_python "biome-lint" "token" "ghp_123456789012345678901234567890123456"
The status should be success
End

It "accepts valid GitHub fine-grained token"
When call validate_input_python "biome-lint" "token" "github_pat_1234567890123456789012345678901234567890123456789012345678901234567890a"
The status should be success
End

It "accepts empty token (optional)"
When call validate_input_python "biome-lint" "token" ""
The status should be success
End

It "rejects invalid token format"
When call validate_input_python "biome-lint" "token" "invalid-token"
The status should be failure
End

It "rejects token with command injection"
When call validate_input_python "biome-lint" "token" "ghp_123456789012345678901234567890123456; echo"
The status should be failure
End
End

Context "when validating username input"
It "accepts valid username"
When call validate_input_python "biome-lint" "username" "github-actions"
The status should be success
End

It "accepts username with hyphens"
When call validate_input_python "biome-lint" "username" "my-bot-user"
The status should be success
End

It "accepts empty username (uses default)"
When call validate_input_python "biome-lint" "username" ""
The status should be success
End

It "rejects username with command injection"
When call validate_input_python "biome-lint" "username" "user; rm -rf /"
The status should be failure
End
End

Context "when validating email input"
It "accepts valid email"
When call validate_input_python "biome-lint" "email" "github-actions@github.com"
The status should be success
End

It "accepts email with plus sign"
When call validate_input_python "biome-lint" "email" "user+bot@example.com"
The status should be success
End

It "accepts email with subdomain"
When call validate_input_python "biome-lint" "email" "bot@ci.example.com"
The status should be success
End

It "accepts empty email (uses default)"
When call validate_input_python "biome-lint" "email" ""
The status should be success
End

It "rejects invalid email format"
When call validate_input_python "biome-lint" "email" "not-an-email"
The status should be failure
End

It "rejects email with command injection"
When call validate_input_python "biome-lint" "email" "user@example.com; rm -rf /"
The status should be failure
End
End

Context "when validating max-retries input"
It "accepts valid retry count (default)"
When call validate_input_python "biome-lint" "max-retries" "3"
The status should be success
End

It "accepts retry count of 1"
When call validate_input_python "biome-lint" "max-retries" "1"
The status should be success
End

It "accepts retry count of 10"
When call validate_input_python "biome-lint" "max-retries" "10"
The status should be success
End

It "accepts empty max-retries (uses default)"
When call validate_input_python "biome-lint" "max-retries" ""
The status should be success
End

It "rejects negative retry count"
When call validate_input_python "biome-lint" "max-retries" "-1"
The status should be failure
End

It "rejects non-numeric retry count"
When call validate_input_python "biome-lint" "max-retries" "abc"
The status should be failure
End

It "rejects retry count with command injection"
When call validate_input_python "biome-lint" "max-retries" "3; echo"
The status should be failure
End
End

Context "when validating fail-on-error input"
It "accepts true"
When call validate_input_python "biome-lint" "fail-on-error" "true"
The status should be success
End

It "accepts false"
When call validate_input_python "biome-lint" "fail-on-error" "false"
The status should be success
End

It "accepts empty (uses default)"
When call validate_input_python "biome-lint" "fail-on-error" ""
The status should be success
End

It "rejects invalid boolean value"
When call validate_input_python "biome-lint" "fail-on-error" "maybe"
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
The output should equal "Biome Lint"
End

It "defines expected inputs"
When call get_action_inputs "$ACTION_FILE"
The output should include "mode"
The output should include "token"
The output should include "username"
The output should include "email"
The output should include "max-retries"
The output should include "fail-on-error"
End

It "defines expected outputs"
When call get_action_outputs "$ACTION_FILE"
The output should include "status"
The output should include "errors_count"
The output should include "warnings_count"
The output should include "files_changed"
End
End

Context "when testing input requirements"
It "has all inputs as optional (with defaults)"
When call is_input_required "$ACTION_FILE" "mode"
The status should be failure
End
End

Context "when testing security validations"
It "validates against path traversal"
When call validate_input_python "biome-lint" "username" "../../../etc"
The status should be failure
End

It "validates against shell metacharacters"
When call validate_input_python "biome-lint" "email" "user@example.com|echo"
The status should be failure
End

It "validates against command substitution"
When call validate_input_python "biome-lint" "username" "\$(whoami)"
The status should be failure
End
End
End
