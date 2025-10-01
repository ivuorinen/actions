#!/usr/bin/env shellspec
# Unit tests for eslint-check action validation and logic
# Framework is automatically loaded via spec_helper.sh

Describe "eslint-check action"
  ACTION_DIR="eslint-check"
  ACTION_FILE="$ACTION_DIR/action.yml"

  Context "when validating working-directory input"
    It "accepts current directory"
      When call validate_input_python "eslint-check" "working-directory" "."
      The status should be success
    End
    It "accepts relative path"
      When call validate_input_python "eslint-check" "working-directory" "src/frontend"
      The status should be success
    End
    It "accepts nested directory"
      When call validate_input_python "eslint-check" "working-directory" "packages/ui"
      The status should be success
    End
    It "rejects path traversal"
      When call validate_input_python "eslint-check" "working-directory" "../../../etc/passwd"
      The status should be failure
    End
    It "rejects absolute paths"
      When call validate_input_python "eslint-check" "working-directory" "/etc/passwd"
      The status should be failure
    End
    It "rejects injection attempts"
      When call validate_input_python "eslint-check" "working-directory" "src; rm -rf /"
      The status should be failure
    End
  End

  Context "when validating eslint-version input"
    It "accepts latest version"
      When call validate_input_python "eslint-check" "eslint-version" "latest"
      The status should be success
    End
    It "accepts semantic version"
      When call validate_input_python "eslint-check" "eslint-version" "8.57.0"
      The status should be success
    End
    It "accepts version with prerelease"
      When call validate_input_python "eslint-check" "eslint-version" "9.0.0-alpha.0"
      The status should be success
    End
    It "accepts older stable version"
      When call validate_input_python "eslint-check" "eslint-version" "7.32.0"
      The status should be success
    End
    It "rejects invalid version format"
      When call validate_input_python "eslint-check" "eslint-version" "8.57"
      The status should be failure
    End
    It "rejects version with letters"
      When call validate_input_python "eslint-check" "eslint-version" "8.57.0a"
      The status should be failure
    End
    It "rejects empty version"
      When call validate_input_python "eslint-check" "eslint-version" ""
      The status should be failure
    End
  End

  Context "when validating config-file input"
    It "accepts default eslintrc"
      When call validate_input_python "eslint-check" "config-file" ".eslintrc"
      The status should be success
    End
    It "accepts eslintrc.json"
      When call validate_input_python "eslint-check" "config-file" ".eslintrc.json"
      The status should be success
    End
    It "accepts eslint.config.js"
      When call validate_input_python "eslint-check" "config-file" "eslint.config.js"
      The status should be success
    End
    It "accepts relative path config"
      When call validate_input_python "eslint-check" "config-file" "config/eslint.json"
      The status should be success
    End
    It "rejects path traversal"
      When call validate_input_python "eslint-check" "config-file" "../../../malicious.js"
      The status should be failure
    End
    It "rejects injection in config path"
      When call validate_input_python "eslint-check" "config-file" "config.js;rm -rf /"
      The status should be failure
    End
  End

  Context "when validating ignore-file input"
    It "accepts default eslintignore"
      When call validate_input_python "eslint-check" "ignore-file" ".eslintignore"
      The status should be success
    End
    It "accepts custom ignore file"
      When call validate_input_python "eslint-check" "ignore-file" "eslint-ignore.txt"
      The status should be success
    End
    It "accepts relative path ignore file"
      When call validate_input_python "eslint-check" "ignore-file" "config/.eslintignore"
      The status should be success
    End
    It "rejects path traversal"
      When call validate_input_python "eslint-check" "ignore-file" "../../sensitive.txt"
      The status should be failure
    End
  End

  Context "when validating file-extensions input"
    It "accepts default extensions"
      When call validate_input_python "eslint-check" "file-extensions" ".js,.jsx,.ts,.tsx"
      The status should be success
    End
    It "accepts single extension"
      When call validate_input_python "eslint-check" "file-extensions" ".js"
      The status should be success
    End
    It "accepts TypeScript extensions only"
      When call validate_input_python "eslint-check" "file-extensions" ".ts,.tsx"
      The status should be success
    End
    It "accepts Vue and JavaScript extensions"
      When call validate_input_python "eslint-check" "file-extensions" ".js,.vue,.ts"
      The status should be success
    End
    It "rejects extensions without dots"
      When call validate_input_python "eslint-check" "file-extensions" "js,ts"
      The status should be failure
    End
    It "rejects invalid extension format"
      When call validate_input_python "eslint-check" "file-extensions" ".js;.ts"
      The status should be failure
    End
    It "rejects extensions with special characters"
      When call validate_input_python "eslint-check" "file-extensions" ".js,.t$"
      The status should be failure
    End
  End

  Context "when validating boolean inputs"
    It "accepts cache as true"
      When call validate_input_python "eslint-check" "cache" "true"
      The status should be success
    End
    It "accepts cache as false"
      When call validate_input_python "eslint-check" "cache" "false"
      The status should be success
    End
    It "accepts fail-on-error as true"
      When call validate_input_python "eslint-check" "fail-on-error" "true"
      The status should be success
    End
    It "accepts fail-on-error as false"
      When call validate_input_python "eslint-check" "fail-on-error" "false"
      The status should be success
    End
    It "rejects invalid boolean value"
      When call validate_input_python "eslint-check" "cache" "maybe"
      The status should be failure
    End
    It "rejects numeric boolean"
      When call validate_input_python "eslint-check" "fail-on-error" "1"
      The status should be failure
    End
  End

  Context "when validating numeric inputs"
    It "accepts zero max-warnings"
      When call validate_input_python "eslint-check" "max-warnings" "0"
      The status should be success
    End
    It "accepts reasonable max-warnings"
      When call validate_input_python "eslint-check" "max-warnings" "10"
      The status should be success
    End
    It "accepts large max-warnings"
      When call validate_input_python "eslint-check" "max-warnings" "1000"
      The status should be success
    End
    It "accepts valid max-retries"
      When call validate_input_python "eslint-check" "max-retries" "3"
      The status should be success
    End
    It "accepts minimum retries"
      When call validate_input_python "eslint-check" "max-retries" "1"
      The status should be success
    End
    It "accepts maximum retries"
      When call validate_input_python "eslint-check" "max-retries" "10"
      The status should be success
    End
    It "rejects negative max-warnings"
      When call validate_input_python "eslint-check" "max-warnings" "-1"
      The status should be failure
    End
    It "rejects non-numeric max-warnings"
      When call validate_input_python "eslint-check" "max-warnings" "many"
      The status should be failure
    End
    It "rejects zero retries"
      When call validate_input_python "eslint-check" "max-retries" "0"
      The status should be failure
    End
    It "rejects retries above limit"
      When call validate_input_python "eslint-check" "max-retries" "15"
      The status should be failure
    End
  End

  Context "when validating report-format input"
    It "accepts stylish format"
      When call validate_input_python "eslint-check" "report-format" "stylish"
      The status should be success
    End
    It "accepts json format"
      When call validate_input_python "eslint-check" "report-format" "json"
      The status should be success
    End
    It "accepts sarif format"
      When call validate_input_python "eslint-check" "report-format" "sarif"
      The status should be success
    End
    It "accepts checkstyle format"
      When call validate_input_python "eslint-check" "report-format" "checkstyle"
      The status should be success
    End
    It "accepts compact format"
      When call validate_input_python "eslint-check" "report-format" "compact"
      The status should be success
    End
    It "accepts html format"
      When call validate_input_python "eslint-check" "report-format" "html"
      The status should be success
    End
    It "accepts junit format"
      When call validate_input_python "eslint-check" "report-format" "junit"
      The status should be success
    End
    It "accepts tap format"
      When call validate_input_python "eslint-check" "report-format" "tap"
      The status should be success
    End
    It "accepts unix format"
      When call validate_input_python "eslint-check" "report-format" "unix"
      The status should be success
    End
    It "rejects invalid format"
      When call validate_input_python "eslint-check" "report-format" "invalid"
      The status should be failure
    End
    It "rejects empty format"
      When call validate_input_python "eslint-check" "report-format" ""
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
      The output should equal "ESLint Check"
    End

    It "defines required inputs"
      inputs=$(get_action_inputs "$ACTION_FILE")
      When call echo "$inputs"
      The output should include "working-directory"
      The output should include "eslint-version"
      The output should include "max-retries"
    End

    It "defines optional inputs with defaults"
      inputs=$(get_action_inputs "$ACTION_FILE")
      When call echo "$inputs"
      The output should include "config-file"
      The output should include "ignore-file"
      The output should include "file-extensions"
      The output should include "cache"
      The output should include "max-warnings"
      The output should include "fail-on-error"
      The output should include "report-format"
    End

    It "defines expected outputs"
      outputs=$(get_action_outputs "$ACTION_FILE")
      When call echo "$outputs"
      The output should include "error-count"
      The output should include "warning-count"
      The output should include "sarif-file"
      The output should include "files-checked"
    End

    It "has composite run type"
      When call grep -q "using: composite" "$ACTION_FILE"
      The status should be success
    End

    It "includes input validation step"
      When call grep -q "Validate Inputs" "$ACTION_FILE"
      The status should be success
    End

    It "uses node-setup action"
      When call grep -q "./node-setup" "$ACTION_FILE"
      The status should be success
    End

    It "uses common-cache action"
      When call grep -q "./common-cache" "$ACTION_FILE"
      The status should be success
    End
  End

  Context "when validating security"
    It "validates input paths to prevent injection"
      When call validate_input_python "eslint-check" "working-directory" "../../../etc"
      The status should be failure
    End

    It "validates config file paths"
      When call validate_input_python "eslint-check" "config-file" "../../malicious.js"
      The status should be failure
    End

    It "sanitizes file extensions input"
      When call validate_input_python "eslint-check" "file-extensions" ".js;rm -rf /"
      The status should be failure
    End
  End

  Context "when testing outputs"
    It "produces all expected outputs"
      When call test_action_outputs "$ACTION_DIR" "working-directory" "." "eslint-version" "latest" "max-retries" "3"
      The status should be success
      The stderr should include "Testing action outputs for: eslint-check"
      The stderr should include "Output test passed for: eslint-check"
    End

    It "outputs consistent error and warning counts"
      When call test_action_outputs "$ACTION_DIR" "max-warnings" "0" "report-format" "sarif"
      The status should be success
      The stderr should include "Testing action outputs for: eslint-check"
      The stderr should include "Output test passed for: eslint-check"
    End
  End
End
