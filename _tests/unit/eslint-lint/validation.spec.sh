#!/usr/bin/env shellspec
# Unit tests for eslint-lint action validation and logic
# Framework is automatically loaded via spec_helper.sh

Describe "eslint-lint action"
ACTION_DIR="eslint-lint"
ACTION_FILE="$ACTION_DIR/action.yml"

Context "when validating mode input"
It "accepts check mode"
When call validate_input_python "eslint-lint" "mode" "check"
The status should be success
End

It "accepts fix mode"
When call validate_input_python "eslint-lint" "mode" "fix"
The status should be success
End

It "accepts empty mode (uses default)"
When call validate_input_python "eslint-lint" "mode" ""
The status should be success
End

It "rejects invalid mode"
When call validate_input_python "eslint-lint" "mode" "invalid"
The status should be failure
End

It "rejects mode with command injection"
When call validate_input_python "eslint-lint" "mode" "check; rm -rf /"
The status should be failure
End
End

Context "when validating working-directory input"
It "accepts default directory"
When call validate_input_python "eslint-lint" "working-directory" "."
The status should be success
End

It "accepts valid subdirectory"
When call validate_input_python "eslint-lint" "working-directory" "src"
The status should be success
End

It "accepts empty working-directory (uses default)"
When call validate_input_python "eslint-lint" "working-directory" ""
The status should be success
End

It "rejects path traversal"
When call validate_input_python "eslint-lint" "working-directory" "../../../etc"
The status should be failure
End

It "rejects directory with command injection"
When call validate_input_python "eslint-lint" "working-directory" "src; rm -rf /"
The status should be failure
End
End

Context "when validating eslint-version input"
It "accepts latest version"
When call validate_input_python "eslint-lint" "eslint-version" "latest"
The status should be success
End

It "accepts semantic version"
When call validate_input_python "eslint-lint" "eslint-version" "8.57.0"
The status should be success
End

It "accepts major.minor version"
When call validate_input_python "eslint-lint" "eslint-version" "8.57"
The status should be success
End

It "accepts major version"
When call validate_input_python "eslint-lint" "eslint-version" "8"
The status should be success
End

It "accepts version with pre-release"
When call validate_input_python "eslint-lint" "eslint-version" "9.0.0-beta.1"
The status should be success
End

It "accepts empty version (uses default)"
When call validate_input_python "eslint-lint" "eslint-version" ""
The status should be success
End

It "rejects invalid version format"
When call validate_input_python "eslint-lint" "eslint-version" "invalid"
The status should be failure
End

It "rejects version with command injection"
When call validate_input_python "eslint-lint" "eslint-version" "8.57.0; echo"
The status should be failure
End
End

Context "when validating config-file input"
It "accepts default config file"
When call validate_input_python "eslint-lint" "config-file" ".eslintrc"
The status should be success
End

It "accepts custom config file"
When call validate_input_python "eslint-lint" "config-file" ".eslintrc.js"
The status should be success
End

It "accepts config file in subdirectory"
When call validate_input_python "eslint-lint" "config-file" "config/eslint.config.js"
The status should be success
End

It "accepts empty config-file (uses default)"
When call validate_input_python "eslint-lint" "config-file" ""
The status should be success
End

It "rejects config file with path traversal"
When call validate_input_python "eslint-lint" "config-file" "../../../.eslintrc"
The status should be failure
End

It "rejects config file with command injection"
When call validate_input_python "eslint-lint" "config-file" ".eslintrc; rm -rf /"
The status should be failure
End
End

Context "when validating ignore-file input"
It "accepts default ignore file"
When call validate_input_python "eslint-lint" "ignore-file" ".eslintignore"
The status should be success
End

It "accepts custom ignore file"
When call validate_input_python "eslint-lint" "ignore-file" ".eslintignore.custom"
The status should be success
End

It "accepts empty ignore-file (uses default)"
When call validate_input_python "eslint-lint" "ignore-file" ""
The status should be success
End

It "rejects ignore file with path traversal"
When call validate_input_python "eslint-lint" "ignore-file" "../../../.eslintignore"
The status should be failure
End

It "rejects ignore file with command injection"
When call validate_input_python "eslint-lint" "ignore-file" ".eslintignore; echo"
The status should be failure
End
End

Context "when validating file-extensions input"
It "accepts default extensions"
When call validate_input_python "eslint-lint" "file-extensions" ".js,.jsx,.ts,.tsx"
The status should be success
End

It "accepts single extension"
When call validate_input_python "eslint-lint" "file-extensions" ".js"
The status should be success
End

It "accepts multiple extensions"
When call validate_input_python "eslint-lint" "file-extensions" ".js,.ts,.mjs"
The status should be success
End

It "accepts empty file-extensions (uses default)"
When call validate_input_python "eslint-lint" "file-extensions" ""
The status should be success
End

It "rejects extensions without leading dot"
When call validate_input_python "eslint-lint" "file-extensions" "js,jsx"
The status should be failure
End

It "rejects extensions with command injection"
When call validate_input_python "eslint-lint" "file-extensions" ".js; rm -rf /"
The status should be failure
End
End

Context "when validating cache input"
It "accepts true"
When call validate_input_python "eslint-lint" "cache" "true"
The status should be success
End

It "accepts false"
When call validate_input_python "eslint-lint" "cache" "false"
The status should be success
End

It "accepts empty cache (uses default)"
When call validate_input_python "eslint-lint" "cache" ""
The status should be success
End

It "rejects invalid boolean value"
When call validate_input_python "eslint-lint" "cache" "maybe"
The status should be failure
End
End

Context "when validating max-warnings input"
It "accepts default value 0"
When call validate_input_python "eslint-lint" "max-warnings" "0"
The status should be success
End

It "accepts positive integer"
When call validate_input_python "eslint-lint" "max-warnings" "10"
The status should be success
End

It "accepts large number"
When call validate_input_python "eslint-lint" "max-warnings" "1000"
The status should be success
End

It "accepts empty max-warnings (uses default)"
When call validate_input_python "eslint-lint" "max-warnings" ""
The status should be success
End

It "rejects negative number"
When call validate_input_python "eslint-lint" "max-warnings" "-1"
The status should be failure
End

It "rejects non-numeric value"
When call validate_input_python "eslint-lint" "max-warnings" "abc"
The status should be failure
End

It "rejects max-warnings with command injection"
When call validate_input_python "eslint-lint" "max-warnings" "0; echo"
The status should be failure
End
End

Context "when validating fail-on-error input"
It "accepts true"
When call validate_input_python "eslint-lint" "fail-on-error" "true"
The status should be success
End

It "accepts false"
When call validate_input_python "eslint-lint" "fail-on-error" "false"
The status should be success
End

It "accepts empty fail-on-error (uses default)"
When call validate_input_python "eslint-lint" "fail-on-error" ""
The status should be success
End

It "rejects invalid boolean value"
When call validate_input_python "eslint-lint" "fail-on-error" "yes"
The status should be failure
End
End

Context "when validating report-format input"
It "accepts stylish format"
When call validate_input_python "eslint-lint" "report-format" "stylish"
The status should be success
End

It "accepts json format"
When call validate_input_python "eslint-lint" "report-format" "json"
The status should be success
End

It "accepts sarif format"
When call validate_input_python "eslint-lint" "report-format" "sarif"
The status should be success
End

It "accepts empty report-format (uses default)"
When call validate_input_python "eslint-lint" "report-format" ""
The status should be success
End

It "rejects invalid format"
When call validate_input_python "eslint-lint" "report-format" "invalid"
The status should be failure
End

It "rejects format with command injection"
When call validate_input_python "eslint-lint" "report-format" "json; rm -rf /"
The status should be failure
End
End

Context "when validating max-retries input"
It "accepts default value 3"
When call validate_input_python "eslint-lint" "max-retries" "3"
The status should be success
End

It "accepts retry count of 1"
When call validate_input_python "eslint-lint" "max-retries" "1"
The status should be success
End

It "accepts retry count of 10"
When call validate_input_python "eslint-lint" "max-retries" "10"
The status should be success
End

It "accepts empty max-retries (uses default)"
When call validate_input_python "eslint-lint" "max-retries" ""
The status should be success
End

It "rejects zero retries"
When call validate_input_python "eslint-lint" "max-retries" "0"
The status should be failure
End

It "rejects negative retry count"
When call validate_input_python "eslint-lint" "max-retries" "-1"
The status should be failure
End

It "rejects retry count above 10"
When call validate_input_python "eslint-lint" "max-retries" "11"
The status should be failure
End

It "rejects non-numeric retry count"
When call validate_input_python "eslint-lint" "max-retries" "abc"
The status should be failure
End

It "rejects retry count with command injection"
When call validate_input_python "eslint-lint" "max-retries" "3; echo"
The status should be failure
End
End

Context "when validating token input"
It "accepts valid GitHub token (classic)"
When call validate_input_python "eslint-lint" "token" "ghp_123456789012345678901234567890123456"
The status should be success
End

It "accepts valid GitHub fine-grained token"
When call validate_input_python "eslint-lint" "token" "github_pat_1234567890123456789012345678901234567890123456789012345678901234567890a"
The status should be success
End

It "accepts empty token (optional)"
When call validate_input_python "eslint-lint" "token" ""
The status should be success
End

It "rejects invalid token format"
When call validate_input_python "eslint-lint" "token" "invalid-token"
The status should be failure
End

It "rejects token with command injection"
When call validate_input_python "eslint-lint" "token" "ghp_123456789012345678901234567890123456; rm -rf /"
The status should be failure
End
End

Context "when validating username input"
It "accepts valid username"
When call validate_input_python "eslint-lint" "username" "github-actions"
The status should be success
End

It "accepts username with hyphens"
When call validate_input_python "eslint-lint" "username" "my-bot-user"
The status should be success
End

It "accepts alphanumeric username"
When call validate_input_python "eslint-lint" "username" "user123"
The status should be success
End

It "accepts empty username (uses default)"
When call validate_input_python "eslint-lint" "username" ""
The status should be success
End

It "rejects username with command injection"
When call validate_input_python "eslint-lint" "username" "user; rm -rf /"
The status should be failure
End

It "rejects username with special characters"
When call validate_input_python "eslint-lint" "username" "user@bot"
The status should be failure
End
End

Context "when validating email input"
It "accepts valid email"
When call validate_input_python "eslint-lint" "email" "github-actions@github.com"
The status should be success
End

It "accepts email with plus sign"
When call validate_input_python "eslint-lint" "email" "user+bot@example.com"
The status should be success
End

It "accepts email with subdomain"
When call validate_input_python "eslint-lint" "email" "bot@ci.example.com"
The status should be success
End

It "accepts empty email (uses default)"
When call validate_input_python "eslint-lint" "email" ""
The status should be success
End

It "rejects invalid email format"
When call validate_input_python "eslint-lint" "email" "not-an-email"
The status should be failure
End

It "rejects email with command injection"
When call validate_input_python "eslint-lint" "email" "user@example.com; rm -rf /"
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
The output should equal "ESLint Lint"
End

It "defines expected inputs"
When call get_action_inputs "$ACTION_FILE"
The output should include "mode"
The output should include "working-directory"
The output should include "eslint-version"
The output should include "config-file"
The output should include "ignore-file"
The output should include "file-extensions"
The output should include "cache"
The output should include "max-warnings"
The output should include "fail-on-error"
The output should include "report-format"
The output should include "max-retries"
The output should include "token"
The output should include "username"
The output should include "email"
End

It "defines expected outputs"
When call get_action_outputs "$ACTION_FILE"
The output should include "status"
The output should include "error-count"
The output should include "warning-count"
The output should include "sarif-file"
The output should include "files-checked"
The output should include "files-changed"
The output should include "errors-fixed"
End
End

Context "when testing input requirements"
It "has all inputs as optional (with defaults)"
When call is_input_required "$ACTION_FILE" "mode"
The status should be failure
End
End

Context "when testing security validations"
It "validates against path traversal in working-directory"
When call validate_input_python "eslint-lint" "working-directory" "../../../etc"
The status should be failure
End

It "validates against shell metacharacters in mode"
When call validate_input_python "eslint-lint" "mode" "check|echo"
The status should be failure
End

It "validates against command substitution in config-file"
When call validate_input_python "eslint-lint" "config-file" "\$(whoami)"
The status should be failure
End

It "validates against path traversal in token"
When call validate_input_python "eslint-lint" "token" "../../../etc/passwd"
The status should be failure
End

It "validates against shell metacharacters in username"
When call validate_input_python "eslint-lint" "username" "user&whoami"
The status should be failure
End

It "validates against command injection in email"
When call validate_input_python "eslint-lint" "email" "user@example.com\`whoami\`"
The status should be failure
End
End
End
