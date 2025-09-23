#!/usr/bin/env shellspec
# Unit tests for prettier-check action validation and logic

# Framework is automatically loaded via spec_helper.sh

Describe "prettier-check action"
ACTION_DIR="prettier-check"
ACTION_FILE="$ACTION_DIR/action.yml"

Context "when validating working-directory input"
It "accepts current directory"
When call validate_input_python "prettier-check" "working-directory" "."
The status should be success
End

It "accepts relative directory"
When call validate_input_python "prettier-check" "working-directory" "src"
The status should be success
End

It "accepts nested directory"
When call validate_input_python "prettier-check" "working-directory" "src/components"
The status should be success
End

It "rejects path traversal"
When call validate_input_python "prettier-check" "working-directory" "../malicious"
The status should be failure
End

It "rejects absolute paths"
When call validate_input_python "prettier-check" "working-directory" "/etc/passwd"
The status should be failure
End

It "rejects directory with command injection"
When call validate_input_python "prettier-check" "working-directory" "src; rm -rf /"
The status should be failure
End
End

Context "when validating prettier-version input"
It "accepts latest version"
When call validate_input_python "prettier-check" "prettier-version" "latest"
The status should be success
End

It "accepts semantic version"
When call validate_input_python "prettier-check" "prettier-version" "3.0.0"
The status should be success
End

It "accepts prerelease version"
When call validate_input_python "prettier-check" "prettier-version" "3.0.0-alpha"
The status should be success
End

It "rejects invalid version format"
When call python3 "_tests/shared/validation_core.py" --validate "prettier-check" "prettier-version" "v3.0.0"
The status should be failure
End

It "rejects version with command injection"
When call validate_input_python "prettier-check" "prettier-version" "3.0.0; rm -rf /"
The status should be failure
End
End

Context "when validating config-file input"
It "accepts valid config file"
When call validate_input_python "prettier-check" "config-file" ".prettierrc"
The status should be success
End

It "accepts config file with extension"
When call validate_input_python "prettier-check" "config-file" ".prettierrc.json"
The status should be success
End

It "accepts config file in subdirectory"
When call validate_input_python "prettier-check" "config-file" "config/.prettierrc"
The status should be success
End

It "rejects path traversal in config file"
When call validate_input_python "prettier-check" "config-file" "../../../etc/passwd"
The status should be failure
End

It "rejects absolute path in config file"
When call validate_input_python "prettier-check" "config-file" "/etc/passwd"
The status should be failure
End
End

Context "when validating ignore-file input"
It "accepts valid ignore file"
When call validate_input_python "prettier-check" "ignore-file" ".prettierignore"
The status should be success
End

It "accepts ignore file in subdirectory"
When call validate_input_python "prettier-check" "ignore-file" "config/.prettierignore"
The status should be success
End

It "rejects path traversal in ignore file"
When call validate_input_python "prettier-check" "ignore-file" "../../../etc/passwd"
The status should be failure
End

It "rejects absolute path in ignore file"
When call validate_input_python "prettier-check" "ignore-file" "/etc/passwd"
The status should be failure
End
End

Context "when validating file-pattern input"
It "accepts valid glob pattern"
When call validate_input_python "prettier-check" "file-pattern" "**/*.{js,ts}"
The status should be success
End

It "accepts simple file pattern"
When call validate_input_python "prettier-check" "file-pattern" "*.js"
The status should be success
End

It "accepts multiple extensions"
When call validate_input_python "prettier-check" "file-pattern" "**/*.{js,jsx,ts,tsx,css}"
The status should be success
End

It "rejects pattern with path traversal"
When call python3 "_tests/shared/validation_core.py" --validate "prettier-check" "file-pattern" "../**/*.js"
The status should be failure
End

It "rejects pattern with absolute path"
When call python3 "_tests/shared/validation_core.py" --validate "prettier-check" "file-pattern" "/etc/**/*.conf"
The status should be failure
End
End

Context "when validating boolean inputs"
It "accepts true for cache"
When call validate_input_python "prettier-check" "cache" "true"
The status should be success
End

It "accepts false for cache"
When call validate_input_python "prettier-check" "cache" "false"
The status should be success
End

It "rejects invalid cache value"
When call validate_input_python "prettier-check" "cache" "yes"
The status should be failure
End

It "accepts true for fail-on-error"
When call validate_input_python "prettier-check" "fail-on-error" "true"
The status should be success
End

It "accepts false for fail-on-error"
When call validate_input_python "prettier-check" "fail-on-error" "false"
The status should be success
End

It "accepts true for check-only"
When call validate_input_python "prettier-check" "check-only" "true"
The status should be success
End

It "accepts false for check-only"
When call validate_input_python "prettier-check" "check-only" "false"
The status should be success
End
End

Context "when validating report-format input"
It "accepts json format"
When call validate_input_python "prettier-check" "report-format" "json"
The status should be success
End

It "accepts sarif format"
When call validate_input_python "prettier-check" "report-format" "sarif"
The status should be success
End

It "rejects invalid format"
When call validate_input_python "prettier-check" "report-format" "xml"
The status should be failure
End

It "rejects empty format"
When call validate_input_python "prettier-check" "report-format" ""
The status should be failure
End
End

Context "when validating max-retries input"
It "accepts valid retry count"
When call validate_input_python "prettier-check" "max-retries" "3"
The status should be success
End

It "accepts minimum retries"
When call validate_input_python "prettier-check" "max-retries" "1"
The status should be success
End

It "accepts maximum retries"
When call validate_input_python "prettier-check" "max-retries" "10"
The status should be success
End

It "rejects zero retries"
When call validate_input_python "prettier-check" "max-retries" "0"
The status should be failure
End

It "rejects too many retries"
When call validate_input_python "prettier-check" "max-retries" "11"
The status should be failure
End

It "rejects non-numeric retries"
When call validate_input_python "prettier-check" "max-retries" "many"
The status should be failure
End
End

Context "when validating plugins input"
It "accepts empty plugins"
When call validate_input_python "prettier-check" "plugins" ""
The status should be success
End

It "accepts valid plugin name"
When call validate_input_python "prettier-check" "plugins" "prettier-plugin-java"
The status should be success
End

It "accepts scoped plugin"
When call validate_input_python "prettier-check" "plugins" "@prettier/plugin-xml"
The status should be success
End

It "accepts multiple plugins"
When call validate_input_python "prettier-check" "plugins" "plugin1,@scope/plugin2"
The status should be success
End

It "rejects plugins with command injection"
When call validate_input_python "prettier-check" "plugins" "plugin1; rm -rf /"
The status should be failure
End

It "rejects plugins with shell operators"
When call validate_input_python "prettier-check" "plugins" "plugin1 && malicious"
The status should be failure
End

It "rejects plugins with pipe"
When call validate_input_python "prettier-check" "plugins" "plugin1 | cat /etc/passwd"
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
The output should equal "Prettier Check"
End

It "defines expected inputs"
When call get_action_inputs "$ACTION_FILE"
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
The output should include "check-only"
End

It "defines expected outputs"
When call get_action_outputs "$ACTION_FILE"
The output should include "files-checked"
The output should include "unformatted-files"
The output should include "sarif-file"
The output should include "cache-hit"
End
End

Context "when testing input requirements"
It "has all inputs as optional"
When call python3 "_tests/shared/validation_core.py" --property "$ACTION_FILE" "any" "all_optional"
The output should equal "none"
End
End

Context "when testing security validations"
It "validates against path traversal in multiple inputs"
When call validate_input_python "prettier-check" "working-directory" "../../malicious"
The status should be failure
End

It "validates against command injection in plugins"
When call validate_input_python "prettier-check" "plugins" "plugin\`whoami\`"
The status should be failure
End

It "validates against shell expansion in file patterns"
When call python3 "_tests/shared/validation_core.py" --validate "prettier-check" "file-pattern" "**/*.js\${HOME}"
The status should be failure
End
End
End
