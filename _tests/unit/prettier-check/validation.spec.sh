#!/usr/bin/env shellspec
# Unit tests for prettier-check action validation and logic

# Framework is automatically loaded via spec_helper.sh

Describe "prettier-check action"
  ACTION_DIR="prettier-check"
  ACTION_FILE="$ACTION_DIR/action.yml"

  Context "when validating working-directory input"
    It "accepts current directory"
      When call test_input_validation "$ACTION_DIR" "working-directory" "." "success"
      The status should be success
    End

    It "accepts relative directory"
      When call test_input_validation "$ACTION_DIR" "working-directory" "src" "success"
      The status should be success
    End

    It "accepts nested directory"
      When call test_input_validation "$ACTION_DIR" "working-directory" "src/components" "success"
      The status should be success
    End

    It "rejects path traversal"
      When call test_input_validation "$ACTION_DIR" "working-directory" "../malicious" "failure"
      The status should be success
    End

    It "rejects absolute paths"
      When call test_input_validation "$ACTION_DIR" "working-directory" "/etc/passwd" "failure"
      The status should be success
    End

    It "rejects directory with command injection"
      When call test_input_validation "$ACTION_DIR" "working-directory" "src; rm -rf /" "failure"
      The status should be success
    End
  End

  Context "when validating prettier-version input"
    It "accepts latest version"
      When call test_input_validation "$ACTION_DIR" "prettier-version" "latest" "success"
      The status should be success
    End

    It "accepts semantic version"
      When call test_input_validation "$ACTION_DIR" "prettier-version" "3.0.0" "success"
      The status should be success
    End

    It "accepts prerelease version"
      When call test_input_validation "$ACTION_DIR" "prettier-version" "3.0.0-alpha" "success"
      The status should be success
    End

    It "rejects invalid version format"
      When call test_input_validation "$ACTION_DIR" "prettier-version" "v3.0.0" "failure"
      The status should be success
    End

    It "rejects version with command injection"
      When call test_input_validation "$ACTION_DIR" "prettier-version" "3.0.0; rm -rf /" "failure"
      The status should be success
    End
  End

  Context "when validating config-file input"
    It "accepts valid config file"
      When call test_input_validation "$ACTION_DIR" "config-file" ".prettierrc" "success"
      The status should be success
    End

    It "accepts config file with extension"
      When call test_input_validation "$ACTION_DIR" "config-file" ".prettierrc.json" "success"
      The status should be success
    End

    It "accepts config file in subdirectory"
      When call test_input_validation "$ACTION_DIR" "config-file" "config/.prettierrc" "success"
      The status should be success
    End

    It "rejects path traversal in config file"
      When call test_input_validation "$ACTION_DIR" "config-file" "../../../etc/passwd" "failure"
      The status should be success
    End

    It "rejects absolute path in config file"
      When call test_input_validation "$ACTION_DIR" "config-file" "/etc/passwd" "failure"
      The status should be success
    End
  End

  Context "when validating ignore-file input"
    It "accepts valid ignore file"
      When call test_input_validation "$ACTION_DIR" "ignore-file" ".prettierignore" "success"
      The status should be success
    End

    It "accepts ignore file in subdirectory"
      When call test_input_validation "$ACTION_DIR" "ignore-file" "config/.prettierignore" "success"
      The status should be success
    End

    It "rejects path traversal in ignore file"
      When call test_input_validation "$ACTION_DIR" "ignore-file" "../../../etc/passwd" "failure"
      The status should be success
    End

    It "rejects absolute path in ignore file"
      When call test_input_validation "$ACTION_DIR" "ignore-file" "/etc/passwd" "failure"
      The status should be success
    End
  End

  Context "when validating file-pattern input"
    It "accepts valid glob pattern"
      When call test_input_validation "$ACTION_DIR" "file-pattern" "**/*.{js,ts}" "success"
      The status should be success
    End

    It "accepts simple file pattern"
      When call test_input_validation "$ACTION_DIR" "file-pattern" "*.js" "success"
      The status should be success
    End

    It "accepts multiple extensions"
      When call test_input_validation "$ACTION_DIR" "file-pattern" "**/*.{js,jsx,ts,tsx,css}" "success"
      The status should be success
    End

    It "rejects pattern with path traversal"
      When call test_input_validation "$ACTION_DIR" "file-pattern" "../**/*.js" "failure"
      The status should be success
    End

    It "rejects pattern with absolute path"
      When call test_input_validation "$ACTION_DIR" "file-pattern" "/etc/**/*.conf" "failure"
      The status should be success
    End
  End

  Context "when validating boolean inputs"
    It "accepts true for cache"
      When call test_input_validation "$ACTION_DIR" "cache" "true" "success"
      The status should be success
    End

    It "accepts false for cache"
      When call test_input_validation "$ACTION_DIR" "cache" "false" "success"
      The status should be success
    End

    It "rejects invalid cache value"
      When call test_input_validation "$ACTION_DIR" "cache" "yes" "failure"
      The status should be success
    End

    It "accepts true for fail-on-error"
      When call test_input_validation "$ACTION_DIR" "fail-on-error" "true" "success"
      The status should be success
    End

    It "accepts false for fail-on-error"
      When call test_input_validation "$ACTION_DIR" "fail-on-error" "false" "success"
      The status should be success
    End

    It "accepts true for check-only"
      When call test_input_validation "$ACTION_DIR" "check-only" "true" "success"
      The status should be success
    End

    It "accepts false for check-only"
      When call test_input_validation "$ACTION_DIR" "check-only" "false" "success"
      The status should be success
    End
  End

  Context "when validating report-format input"
    It "accepts json format"
      When call test_input_validation "$ACTION_DIR" "report-format" "json" "success"
      The status should be success
    End

    It "accepts sarif format"
      When call test_input_validation "$ACTION_DIR" "report-format" "sarif" "success"
      The status should be success
    End

    It "rejects invalid format"
      When call test_input_validation "$ACTION_DIR" "report-format" "xml" "failure"
      The status should be success
    End

    It "rejects empty format"
      When call test_input_validation "$ACTION_DIR" "report-format" "" "failure"
      The status should be success
    End
  End

  Context "when validating max-retries input"
    It "accepts valid retry count"
      When call test_input_validation "$ACTION_DIR" "max-retries" "3" "success"
      The status should be success
    End

    It "accepts minimum retries"
      When call test_input_validation "$ACTION_DIR" "max-retries" "1" "success"
      The status should be success
    End

    It "accepts maximum retries"
      When call test_input_validation "$ACTION_DIR" "max-retries" "10" "success"
      The status should be success
    End

    It "rejects zero retries"
      When call test_input_validation "$ACTION_DIR" "max-retries" "0" "failure"
      The status should be success
    End

    It "rejects too many retries"
      When call test_input_validation "$ACTION_DIR" "max-retries" "11" "failure"
      The status should be success
    End

    It "rejects non-numeric retries"
      When call test_input_validation "$ACTION_DIR" "max-retries" "many" "failure"
      The status should be success
    End
  End

  Context "when validating plugins input"
    It "accepts empty plugins"
      When call test_input_validation "$ACTION_DIR" "plugins" "" "success"
      The status should be success
    End

    It "accepts valid plugin name"
      When call test_input_validation "$ACTION_DIR" "plugins" "prettier-plugin-java" "success"
      The status should be success
    End

    It "accepts scoped plugin"
      When call test_input_validation "$ACTION_DIR" "plugins" "@prettier/plugin-xml" "success"
      The status should be success
    End

    It "accepts multiple plugins"
      When call test_input_validation "$ACTION_DIR" "plugins" "plugin1,@scope/plugin2" "success"
      The status should be success
    End

    It "rejects plugins with command injection"
      When call test_input_validation "$ACTION_DIR" "plugins" "plugin1; rm -rf /" "failure"
      The status should be success
    End

    It "rejects plugins with shell operators"
      When call test_input_validation "$ACTION_DIR" "plugins" "plugin1 && malicious" "failure"
      The status should be success
    End

    It "rejects plugins with pipe"
      When call test_input_validation "$ACTION_DIR" "plugins" "plugin1 | cat /etc/passwd" "failure"
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
      When call python3 -c "
      import yaml
      with open('$ACTION_FILE') as f:
      data = yaml.safe_load(f)
      inputs = data.get('inputs', {})
      required_inputs = [k for k, v in inputs.items() if v.get('required', False)]
      print('none' if not required_inputs else ','.join(required_inputs))
      "
      The output should equal "none"
    End
  End

  Context "when testing security validations"
    It "validates against path traversal in multiple inputs"
      When call test_input_validation "$ACTION_DIR" "working-directory" "../../malicious" "failure"
      The status should be success
    End

    It "validates against command injection in plugins"
      When call test_input_validation "$ACTION_DIR" "plugins" "plugin\`whoami\`" "failure"
      The status should be success
    End

    It "validates against shell expansion in file patterns"
      When call test_input_validation "$ACTION_DIR" "file-pattern" "**/*.js\${HOME}" "failure"
      The status should be success
    End
  End
End
