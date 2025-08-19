#!/usr/bin/env shellspec
# Unit tests for eslint-check action validation and logic
# Framework is automatically loaded via spec_helper.sh

Describe "eslint-check action"
  ACTION_DIR="eslint-check"
  ACTION_FILE="$ACTION_DIR/action.yml"

  Context "when validating working-directory input"
    It "accepts current directory"
      When call test_input_validation "$ACTION_DIR" "working-directory" "." "success"
      The status should be success
    End
    It "accepts relative path"
      When call test_input_validation "$ACTION_DIR" "working-directory" "src/frontend" "success"
      The status should be success
    End
    It "accepts nested directory"
      When call test_input_validation "$ACTION_DIR" "working-directory" "packages/ui" "success"
      The status should be success
    End
    It "rejects path traversal"
      When call test_input_validation "$ACTION_DIR" "working-directory" "../../../etc/passwd" "failure"
      The status should be success
    End
    It "rejects absolute paths"
      When call test_input_validation "$ACTION_DIR" "working-directory" "/etc/passwd" "failure"
      The status should be success
    End
    It "rejects injection attempts"
      When call test_input_validation "$ACTION_DIR" "working-directory" "src; rm -rf /" "failure"
      The status should be success
    End
  End

  Context "when validating eslint-version input"
    It "accepts latest version"
      When call test_input_validation "$ACTION_DIR" "eslint-version" "latest" "success"
      The status should be success
    End
    It "accepts semantic version"
      When call test_input_validation "$ACTION_DIR" "eslint-version" "8.57.0" "success"
      The status should be success
    End
    It "accepts version with prerelease"
      When call test_input_validation "$ACTION_DIR" "eslint-version" "9.0.0-alpha.0" "success"
      The status should be success
    End
    It "accepts older stable version"
      When call test_input_validation "$ACTION_DIR" "eslint-version" "7.32.0" "success"
      The status should be success
    End
    It "rejects invalid version format"
      When call test_input_validation "$ACTION_DIR" "eslint-version" "8.57" "failure"
      The status should be success
    End
    It "rejects version with letters"
      When call test_input_validation "$ACTION_DIR" "eslint-version" "8.57.0a" "failure"
      The status should be success
    End
    It "rejects empty version"
      When call test_input_validation "$ACTION_DIR" "eslint-version" "" "failure"
      The status should be success
    End
  End

  Context "when validating config-file input"
    It "accepts default eslintrc"
      When call test_input_validation "$ACTION_DIR" "config-file" ".eslintrc" "success"
      The status should be success
    End
    It "accepts eslintrc.json"
      When call test_input_validation "$ACTION_DIR" "config-file" ".eslintrc.json" "success"
      The status should be success
    End
    It "accepts eslint.config.js"
      When call test_input_validation "$ACTION_DIR" "config-file" "eslint.config.js" "success"
      The status should be success
    End
    It "accepts relative path config"
      When call test_input_validation "$ACTION_DIR" "config-file" "config/eslint.json" "success"
      The status should be success
    End
    It "rejects path traversal"
      When call test_input_validation "$ACTION_DIR" "config-file" "../../../malicious.js" "failure"
      The status should be success
    End
    It "rejects injection in config path"
      When call test_input_validation "$ACTION_DIR" "config-file" "config.js;rm -rf /" "failure"
      The status should be success
    End
  End

  Context "when validating ignore-file input"
    It "accepts default eslintignore"
      When call test_input_validation "$ACTION_DIR" "ignore-file" ".eslintignore" "success"
      The status should be success
    End
    It "accepts custom ignore file"
      When call test_input_validation "$ACTION_DIR" "ignore-file" "eslint-ignore.txt" "success"
      The status should be success
    End
    It "accepts relative path ignore file"
      When call test_input_validation "$ACTION_DIR" "ignore-file" "config/.eslintignore" "success"
      The status should be success
    End
    It "rejects path traversal"
      When call test_input_validation "$ACTION_DIR" "ignore-file" "../../sensitive.txt" "failure"
      The status should be success
    End
  End

  Context "when validating file-extensions input"
    It "accepts default extensions"
      When call test_input_validation "$ACTION_DIR" "file-extensions" ".js,.jsx,.ts,.tsx" "success"
      The status should be success
    End
    It "accepts single extension"
      When call test_input_validation "$ACTION_DIR" "file-extensions" ".js" "success"
      The status should be success
    End
    It "accepts TypeScript extensions only"
      When call test_input_validation "$ACTION_DIR" "file-extensions" ".ts,.tsx" "success"
      The status should be success
    End
    It "accepts Vue and JavaScript extensions"
      When call test_input_validation "$ACTION_DIR" "file-extensions" ".js,.vue,.ts" "success"
      The status should be success
    End
    It "rejects extensions without dots"
      When call test_input_validation "$ACTION_DIR" "file-extensions" "js,ts" "failure"
      The status should be success
    End
    It "rejects invalid extension format"
      When call test_input_validation "$ACTION_DIR" "file-extensions" ".js;.ts" "failure"
      The status should be success
    End
    It "rejects extensions with special characters"
      When call test_input_validation "$ACTION_DIR" "file-extensions" ".js,.t$" "failure"
      The status should be success
    End
  End

  Context "when validating boolean inputs"
    It "accepts cache as true"
      When call test_input_validation "$ACTION_DIR" "cache" "true" "success"
      The status should be success
    End
    It "accepts cache as false"
      When call test_input_validation "$ACTION_DIR" "cache" "false" "success"
      The status should be success
    End
    It "accepts fail-on-error as true"
      When call test_input_validation "$ACTION_DIR" "fail-on-error" "true" "success"
      The status should be success
    End
    It "accepts fail-on-error as false"
      When call test_input_validation "$ACTION_DIR" "fail-on-error" "false" "success"
      The status should be success
    End
    It "rejects invalid boolean value"
      When call test_input_validation "$ACTION_DIR" "cache" "maybe" "failure"
      The status should be success
    End
    It "rejects numeric boolean"
      When call test_input_validation "$ACTION_DIR" "fail-on-error" "1" "failure"
      The status should be success
    End
  End

  Context "when validating numeric inputs"
    It "accepts zero max-warnings"
      When call test_input_validation "$ACTION_DIR" "max-warnings" "0" "success"
      The status should be success
    End
    It "accepts reasonable max-warnings"
      When call test_input_validation "$ACTION_DIR" "max-warnings" "10" "success"
      The status should be success
    End
    It "accepts large max-warnings"
      When call test_input_validation "$ACTION_DIR" "max-warnings" "1000" "success"
      The status should be success
    End
    It "accepts valid max-retries"
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
    It "rejects negative max-warnings"
      When call test_input_validation "$ACTION_DIR" "max-warnings" "-1" "failure"
      The status should be success
    End
    It "rejects non-numeric max-warnings"
      When call test_input_validation "$ACTION_DIR" "max-warnings" "many" "failure"
      The status should be success
    End
    It "rejects zero retries"
      When call test_input_validation "$ACTION_DIR" "max-retries" "0" "failure"
      The status should be success
    End
    It "rejects retries above limit"
      When call test_input_validation "$ACTION_DIR" "max-retries" "15" "failure"
      The status should be success
    End
  End

  Context "when validating report-format input"
    It "accepts stylish format"
      When call test_input_validation "$ACTION_DIR" "report-format" "stylish" "success"
      The status should be success
    End
    It "accepts json format"
      When call test_input_validation "$ACTION_DIR" "report-format" "json" "success"
      The status should be success
    End
    It "accepts sarif format"
      When call test_input_validation "$ACTION_DIR" "report-format" "sarif" "success"
      The status should be success
    End
    It "accepts checkstyle format"
      When call test_input_validation "$ACTION_DIR" "report-format" "checkstyle" "success"
      The status should be success
    End
    It "accepts compact format"
      When call test_input_validation "$ACTION_DIR" "report-format" "compact" "success"
      The status should be success
    End
    It "accepts html format"
      When call test_input_validation "$ACTION_DIR" "report-format" "html" "success"
      The status should be success
    End
    It "accepts junit format"
      When call test_input_validation "$ACTION_DIR" "report-format" "junit" "success"
      The status should be success
    End
    It "accepts tap format"
      When call test_input_validation "$ACTION_DIR" "report-format" "tap" "success"
      The status should be success
    End
    It "accepts unix format"
      When call test_input_validation "$ACTION_DIR" "report-format" "unix" "success"
      The status should be success
    End
    It "rejects invalid format"
      When call test_input_validation "$ACTION_DIR" "report-format" "invalid" "failure"
      The status should be success
    End
    It "rejects empty format"
      When call test_input_validation "$ACTION_DIR" "report-format" "" "failure"
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
      When call grep -q "../node-setup" "$ACTION_FILE"
      The status should be success
    End

    It "uses common-cache action"
      When call grep -q "../common-cache" "$ACTION_FILE"
      The status should be success
    End
  End

  Context "when validating security"
    It "validates input paths to prevent injection"
      When call test_input_validation "$ACTION_DIR" "working-directory" "../../../etc" "failure"
      The status should be success
    End

    It "validates config file paths"
      When call test_input_validation "$ACTION_DIR" "config-file" "../../malicious.js" "failure"
      The status should be success
    End

    It "sanitizes file extensions input"
      When call test_input_validation "$ACTION_DIR" "file-extensions" ".js;rm -rf /" "failure"
      The status should be success
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
