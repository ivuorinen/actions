#!/usr/bin/env shellspec
# Unit tests for prettier-lint action validation and logic
# Framework is automatically loaded via spec_helper.sh

Describe "prettier-lint action"
ACTION_DIR="prettier-lint"
ACTION_FILE="$ACTION_DIR/action.yml"

Context "when validating mode input"
It "accepts check mode"
When call validate_input_python "prettier-lint" "mode" "check"
The status should be success
End

It "accepts fix mode"
When call validate_input_python "prettier-lint" "mode" "fix"
The status should be success
End

It "accepts empty mode (uses default)"
When call validate_input_python "prettier-lint" "mode" ""
The status should be success
End

It "rejects invalid mode"
When call validate_input_python "prettier-lint" "mode" "invalid"
The status should be failure
End

It "rejects mode with command injection"
When call validate_input_python "prettier-lint" "mode" "check; rm -rf /"
The status should be failure
End
End

Context "when validating working-directory input"
It "accepts default directory"
When call validate_input_python "prettier-lint" "working-directory" "."
The status should be success
End

It "accepts valid subdirectory"
When call validate_input_python "prettier-lint" "working-directory" "src"
The status should be success
End

It "accepts empty working-directory (uses default)"
When call validate_input_python "prettier-lint" "working-directory" ""
The status should be success
End

It "rejects path traversal"
When call validate_input_python "prettier-lint" "working-directory" "../../../etc"
The status should be failure
End

It "rejects directory with command injection"
When call validate_input_python "prettier-lint" "working-directory" "src; rm -rf /"
The status should be failure
End
End

Context "when validating prettier-version input"
It "accepts latest version"
When call validate_input_python "prettier-lint" "prettier-version" "latest"
The status should be success
End

It "accepts semantic version"
When call validate_input_python "prettier-lint" "prettier-version" "3.2.5"
The status should be success
End

It "accepts major.minor version"
When call validate_input_python "prettier-lint" "prettier-version" "3.2"
The status should be success
End

It "accepts major version"
When call validate_input_python "prettier-lint" "prettier-version" "3"
The status should be success
End

It "accepts version with pre-release"
When call validate_input_python "prettier-lint" "prettier-version" "3.0.0-alpha.1"
The status should be success
End

It "accepts empty version (uses default)"
When call validate_input_python "prettier-lint" "prettier-version" ""
The status should be success
End

It "rejects invalid version format"
When call validate_input_python "prettier-lint" "prettier-version" "invalid"
The status should be failure
End

It "rejects version with command injection"
When call validate_input_python "prettier-lint" "prettier-version" "3.2.5; echo"
The status should be failure
End
End

Context "when validating config-file input"
It "accepts default config file"
When call validate_input_python "prettier-lint" "config-file" ".prettierrc"
The status should be success
End

It "accepts custom config file"
When call validate_input_python "prettier-lint" "config-file" ".prettierrc.js"
The status should be success
End

It "accepts config file in subdirectory"
When call validate_input_python "prettier-lint" "config-file" "config/prettier.config.js"
The status should be success
End

It "accepts empty config-file (uses default)"
When call validate_input_python "prettier-lint" "config-file" ""
The status should be success
End

It "rejects config file with path traversal"
When call validate_input_python "prettier-lint" "config-file" "../../../.prettierrc"
The status should be failure
End

It "rejects config file with command injection"
When call validate_input_python "prettier-lint" "config-file" ".prettierrc; rm -rf /"
The status should be failure
End
End

Context "when validating ignore-file input"
It "accepts default ignore file"
When call validate_input_python "prettier-lint" "ignore-file" ".prettierignore"
The status should be success
End

It "accepts custom ignore file"
When call validate_input_python "prettier-lint" "ignore-file" ".prettierignore.custom"
The status should be success
End

It "accepts empty ignore-file (uses default)"
When call validate_input_python "prettier-lint" "ignore-file" ""
The status should be success
End

It "rejects ignore file with path traversal"
When call validate_input_python "prettier-lint" "ignore-file" "../../../.prettierignore"
The status should be failure
End

It "rejects ignore file with command injection"
When call validate_input_python "prettier-lint" "ignore-file" ".prettierignore; echo"
The status should be failure
End
End

Context "when validating file-pattern input"
It "accepts default pattern"
When call validate_input_python "prettier-lint" "file-pattern" "**/*.{js,jsx,ts,tsx,css,scss,json,md,yaml,yml}"
The status should be success
End

It "accepts simple pattern"
When call validate_input_python "prettier-lint" "file-pattern" "**/*.js"
The status should be success
End

It "accepts multiple patterns"
When call validate_input_python "prettier-lint" "file-pattern" "**/*.{js,ts}"
The status should be success
End

It "accepts specific directory pattern"
When call validate_input_python "prettier-lint" "file-pattern" "src/**/*.js"
The status should be success
End

It "accepts empty file-pattern (uses default)"
When call validate_input_python "prettier-lint" "file-pattern" ""
The status should be success
End

It "rejects pattern with command injection"
When call validate_input_python "prettier-lint" "file-pattern" "**/*.js; rm -rf /"
The status should be failure
End
End

Context "when validating cache input"
It "accepts true"
When call validate_input_python "prettier-lint" "cache" "true"
The status should be success
End

It "accepts false"
When call validate_input_python "prettier-lint" "cache" "false"
The status should be success
End

It "accepts empty cache (uses default)"
When call validate_input_python "prettier-lint" "cache" ""
The status should be success
End

It "rejects invalid boolean value"
When call validate_input_python "prettier-lint" "cache" "maybe"
The status should be failure
End
End

Context "when validating fail-on-error input"
It "accepts true"
When call validate_input_python "prettier-lint" "fail-on-error" "true"
The status should be success
End

It "accepts false"
When call validate_input_python "prettier-lint" "fail-on-error" "false"
The status should be success
End

It "accepts empty fail-on-error (uses default)"
When call validate_input_python "prettier-lint" "fail-on-error" ""
The status should be success
End

It "rejects invalid boolean value"
When call validate_input_python "prettier-lint" "fail-on-error" "yes"
The status should be failure
End
End

Context "when validating report-format input"
It "accepts json format"
When call validate_input_python "prettier-lint" "report-format" "json"
The status should be success
End

It "accepts sarif format"
When call validate_input_python "prettier-lint" "report-format" "sarif"
The status should be success
End

It "accepts empty report-format (uses default)"
When call validate_input_python "prettier-lint" "report-format" ""
The status should be success
End

It "rejects invalid format"
When call validate_input_python "prettier-lint" "report-format" "invalid"
The status should be failure
End

It "rejects format with command injection"
When call validate_input_python "prettier-lint" "report-format" "json; rm -rf /"
The status should be failure
End
End

Context "when validating max-retries input"
It "accepts default value 3"
When call validate_input_python "prettier-lint" "max-retries" "3"
The status should be success
End

It "accepts retry count of 1"
When call validate_input_python "prettier-lint" "max-retries" "1"
The status should be success
End

It "accepts retry count of 10"
When call validate_input_python "prettier-lint" "max-retries" "10"
The status should be success
End

It "accepts empty max-retries (uses default)"
When call validate_input_python "prettier-lint" "max-retries" ""
The status should be success
End

It "rejects zero retries"
When call validate_input_python "prettier-lint" "max-retries" "0"
The status should be failure
End

It "rejects negative retry count"
When call validate_input_python "prettier-lint" "max-retries" "-1"
The status should be failure
End

It "rejects retry count above 10"
When call validate_input_python "prettier-lint" "max-retries" "11"
The status should be failure
End

It "rejects non-numeric retry count"
When call validate_input_python "prettier-lint" "max-retries" "abc"
The status should be failure
End

It "rejects retry count with command injection"
When call validate_input_python "prettier-lint" "max-retries" "3; echo"
The status should be failure
End
End

Context "when validating plugins input"
It "accepts empty plugins (optional)"
When call validate_input_python "prettier-lint" "plugins" ""
The status should be success
End

It "accepts single plugin"
When call validate_input_python "prettier-lint" "plugins" "prettier-plugin-tailwindcss"
The status should be success
End

It "accepts multiple plugins"
When call validate_input_python "prettier-lint" "plugins" "prettier-plugin-tailwindcss,prettier-plugin-organize-imports"
The status should be success
End

It "accepts scoped plugin"
When call validate_input_python "prettier-lint" "plugins" "@trivago/prettier-plugin-sort-imports"
The status should be success
End

It "rejects plugins with command injection"
When call validate_input_python "prettier-lint" "plugins" "prettier-plugin-tailwindcss; rm -rf /"
The status should be failure
End
End

Context "when validating token input"
It "accepts valid GitHub token (classic)"
When call validate_input_python "prettier-lint" "token" "ghp_123456789012345678901234567890123456"
The status should be success
End

It "accepts valid GitHub fine-grained token"
When call validate_input_python "prettier-lint" "token" "github_pat_1234567890123456789012345678901234567890123456789012345678901234567890a"
The status should be success
End

It "accepts empty token (optional)"
When call validate_input_python "prettier-lint" "token" ""
The status should be success
End

It "rejects invalid token format"
When call validate_input_python "prettier-lint" "token" "invalid-token"
The status should be failure
End

It "rejects token with command injection"
When call validate_input_python "prettier-lint" "token" "ghp_123456789012345678901234567890123456; rm -rf /"
The status should be failure
End
End

Context "when validating username input"
It "accepts valid username"
When call validate_input_python "prettier-lint" "username" "github-actions"
The status should be success
End

It "accepts username with hyphens"
When call validate_input_python "prettier-lint" "username" "my-bot-user"
The status should be success
End

It "accepts alphanumeric username"
When call validate_input_python "prettier-lint" "username" "user123"
The status should be success
End

It "accepts empty username (uses default)"
When call validate_input_python "prettier-lint" "username" ""
The status should be success
End

It "rejects username with command injection"
When call validate_input_python "prettier-lint" "username" "user; rm -rf /"
The status should be failure
End

It "rejects username with special characters"
When call validate_input_python "prettier-lint" "username" "user@bot"
The status should be failure
End
End

Context "when validating email input"
It "accepts valid email"
When call validate_input_python "prettier-lint" "email" "github-actions@github.com"
The status should be success
End

It "accepts email with plus sign"
When call validate_input_python "prettier-lint" "email" "user+bot@example.com"
The status should be success
End

It "accepts email with subdomain"
When call validate_input_python "prettier-lint" "email" "bot@ci.example.com"
The status should be success
End

It "accepts empty email (uses default)"
When call validate_input_python "prettier-lint" "email" ""
The status should be success
End

It "rejects invalid email format"
When call validate_input_python "prettier-lint" "email" "not-an-email"
The status should be failure
End

It "rejects email with command injection"
When call validate_input_python "prettier-lint" "email" "user@example.com; rm -rf /"
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
The output should equal "Prettier Lint"
End

It "defines expected inputs"
When call get_action_inputs "$ACTION_FILE"
The output should include "mode"
The output should include "working-directory"
The output should include "prettier-version"
The output should include "config-file"
The output should include "ignore-file"
The output should include "file-pattern"
The output should include "cache"
The output should include "fail-on-error"
The output should include "report-format"
The output should include "max-retries"
The output should include "plugins"
The output should include "token"
The output should include "username"
The output should include "email"
End

It "defines expected outputs"
When call get_action_outputs "$ACTION_FILE"
The output should include "status"
The output should include "files-checked"
The output should include "unformatted-files"
The output should include "sarif-file"
The output should include "files-changed"
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
When call validate_input_python "prettier-lint" "working-directory" "../../../etc"
The status should be failure
End

It "validates against shell metacharacters in mode"
When call validate_input_python "prettier-lint" "mode" "check|echo"
The status should be failure
End

It "validates against command substitution in config-file"
When call validate_input_python "prettier-lint" "config-file" "\$(whoami)"
The status should be failure
End

It "validates against path traversal in token"
When call validate_input_python "prettier-lint" "token" "../../../etc/passwd"
The status should be failure
End

It "validates against shell metacharacters in username"
When call validate_input_python "prettier-lint" "username" "user&whoami"
The status should be failure
End

It "validates against command injection in email"
When call validate_input_python "prettier-lint" "email" "user@example.com\`whoami\`"
The status should be failure
End

It "validates against command injection in plugins"
When call validate_input_python "prettier-lint" "plugins" "plugin1,plugin2; rm -rf /"
The status should be failure
End
End
End
