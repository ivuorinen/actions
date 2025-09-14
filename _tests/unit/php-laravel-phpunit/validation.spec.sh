#!/usr/bin/env shellspec
# Unit tests for php-laravel-phpunit action validation and logic

# Framework is automatically loaded via spec_helper.sh

Describe "php-laravel-phpunit action"
  ACTION_DIR="php-laravel-phpunit"
  ACTION_FILE="$ACTION_DIR/action.yml"

  Context "when validating php-version input"
    It "accepts latest"
      When call test_input_validation "$ACTION_DIR" "php-version" "latest" "success"
      The status should be success
    End

    It "accepts valid PHP version"
      When call test_input_validation "$ACTION_DIR" "php-version" "8.4" "success"
      The status should be success
    End

    It "accepts PHP version with patch"
      When call test_input_validation "$ACTION_DIR" "php-version" "8.4.1" "success"
      The status should be success
    End

    It "accepts PHP 7.4"
      When call test_input_validation "$ACTION_DIR" "php-version" "7.4" "success"
      The status should be success
    End

    It "accepts PHP 8.0"
      When call test_input_validation "$ACTION_DIR" "php-version" "8.0" "success"
      The status should be success
    End

    It "rejects invalid version format"
      When call test_input_validation "$ACTION_DIR" "php-version" "php8.4" "failure"
      The status should be success
    End

    It "rejects version with command injection"
      When call test_input_validation "$ACTION_DIR" "php-version" "8.4; rm -rf /" "failure"
      The status should be success
    End

    It "accepts empty version (uses default)"
      When call test_input_validation "$ACTION_DIR" "php-version" "" "success"
      The status should be success
    End
  End

  Context "when validating php-version-file input"
    It "accepts valid PHP version file"
      When call test_input_validation "$ACTION_DIR" "php-version-file" ".php-version" "success"
      The status should be success
    End

    It "accepts custom version file"
      When call test_input_validation "$ACTION_DIR" "php-version-file" "custom-php-version" "success"
      The status should be success
    End

    It "accepts version file with path"
      When call test_input_validation "$ACTION_DIR" "php-version-file" "config/.php-version" "success"
      The status should be success
    End

    It "rejects path traversal in version file"
      When call test_input_validation "$ACTION_DIR" "php-version-file" "../../../etc/passwd" "failure"
      The status should be success
    End

    It "rejects absolute path in version file"
      When call test_input_validation "$ACTION_DIR" "php-version-file" "/etc/passwd" "failure"
      The status should be success
    End

    It "rejects version file with command injection"
      When call test_input_validation "$ACTION_DIR" "php-version-file" ".php-version; rm -rf /" "failure"
      The status should be success
    End

    It "accepts empty version file"
      When call test_input_validation "$ACTION_DIR" "php-version-file" "" "success"
      The status should be success
    End
  End

  Context "when validating extensions input"
    It "accepts valid PHP extensions"
      When call test_input_validation "$ACTION_DIR" "extensions" "mbstring, intl, json" "success"
      The status should be success
    End

    It "accepts single extension"
      When call test_input_validation "$ACTION_DIR" "extensions" "mbstring" "success"
      The status should be success
    End

    It "accepts extensions without spaces"
      When call test_input_validation "$ACTION_DIR" "extensions" "mbstring,intl,json" "success"
      The status should be success
    End

    It "accepts extensions with underscores"
      When call test_input_validation "$ACTION_DIR" "extensions" "pdo_sqlite, pdo_mysql" "success"
      The status should be success
    End

    It "accepts extensions with numbers"
      When call test_input_validation "$ACTION_DIR" "extensions" "sqlite3, gd2" "success"
      The status should be success
    End

    It "rejects extensions with special characters"
      When call test_input_validation "$ACTION_DIR" "extensions" "mbstring@intl" "failure"
      The status should be success
    End

    It "rejects extensions with command injection"
      When call test_input_validation "$ACTION_DIR" "extensions" "mbstring; rm -rf /" "failure"
      The status should be success
    End

    It "accepts empty extensions"
      When call test_input_validation "$ACTION_DIR" "extensions" "" "success"
      The status should be success
    End
  End

  Context "when validating coverage input"
    It "accepts none coverage"
      When call test_input_validation "$ACTION_DIR" "coverage" "none" "success"
      The status should be success
    End

    It "accepts xdebug coverage"
      When call test_input_validation "$ACTION_DIR" "coverage" "xdebug" "success"
      The status should be success
    End

    It "accepts pcov coverage"
      When call test_input_validation "$ACTION_DIR" "coverage" "pcov" "success"
      The status should be success
    End

    It "accepts xdebug3 coverage"
      When call test_input_validation "$ACTION_DIR" "coverage" "xdebug3" "success"
      The status should be success
    End

    It "rejects invalid coverage driver"
      When call test_input_validation "$ACTION_DIR" "coverage" "invalid" "failure"
      The status should be success
    End

    It "rejects coverage with command injection"
      When call test_input_validation "$ACTION_DIR" "coverage" "none; rm -rf /" "failure"
      The status should be success
    End

    It "accepts empty coverage"
      When call test_input_validation "$ACTION_DIR" "coverage" "" "success"
      The status should be success
    End
  End

  Context "when validating token input"
    It "accepts GitHub token expression"
      When call test_input_validation "$ACTION_DIR" "token" "\${{ github.token }}" "success"
      The status should be success
    End

    It "accepts GitHub fine-grained token"
      When call test_input_validation "$ACTION_DIR" "token" "ghp_abcdefghijklmnopqrstuvwxyz1234567890" "success"
      The status should be success
    End

    It "accepts GitHub app token"
      When call test_input_validation "$ACTION_DIR" "token" "ghs_abcdefghijklmnopqrstuvwxyz1234567890" "success"
      The status should be success
    End

    It "rejects invalid token format"
      When call test_input_validation "$ACTION_DIR" "token" "invalid-token" "failure"
      The status should be success
    End

    It "accepts empty token"
      When call test_input_validation "$ACTION_DIR" "token" "" "success"
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
      The output should equal "Laravel Setup and Composer test"
    End

    It "defines expected inputs"
      When call get_action_inputs "$ACTION_FILE"
      The output should include "php-version"
      The output should include "php-version-file"
      The output should include "extensions"
      The output should include "coverage"
      The output should include "token"
    End

    It "defines expected outputs"
      When call get_action_outputs "$ACTION_FILE"
      The output should include "php-version"
      The output should include "php-version-file"
      The output should include "extensions"
      The output should include "coverage"
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

    It "has correct default php-version"
      When call python3 -c "
      import yaml
      with open('$ACTION_FILE') as f:
      data = yaml.safe_load(f)
      php_version = data.get('inputs', {}).get('php-version', {}).get('default', '')
      print(php_version)
      "
      The output should equal "latest"
    End

    It "has correct default php-version-file"
      When call python3 -c "
      import yaml
      with open('$ACTION_FILE') as f:
      data = yaml.safe_load(f)
      php_version_file = data.get('inputs', {}).get('php-version-file', {}).get('default', '')
      print(php_version_file)
      "
      The output should equal ".php-version"
    End
  End

  Context "when testing security validations"
    It "validates against path traversal in php-version-file"
      When call test_input_validation "$ACTION_DIR" "php-version-file" "../../etc/passwd" "failure"
      The status should be success
    End

    It "validates against shell metacharacters in extensions"
      When call test_input_validation "$ACTION_DIR" "extensions" "mbstring && rm -rf /" "failure"
      The status should be success
    End

    It "validates against backtick injection in coverage"
      When call test_input_validation "$ACTION_DIR" "coverage" "none\`whoami\`" "failure"
      The status should be success
    End

    It "validates against variable expansion in php-version"
      When call test_input_validation "$ACTION_DIR" "php-version" "8.4\${HOME}" "failure"
      The status should be success
    End
  End

  Context "when testing Laravel-specific validations"
    It "validates coverage driver enum values"
      When call test_input_validation "$ACTION_DIR" "coverage" "invalid-driver" "failure"
      The status should be success
    End

    It "validates php-version-file path safety"
      When call test_input_validation "$ACTION_DIR" "php-version-file" "/etc/shadow" "failure"
      The status should be success
    End

    It "validates extensions format for Laravel requirements"
      When call test_input_validation "$ACTION_DIR" "extensions" "mbstring, intl, json, pdo_sqlite, sqlite3" "success"
      The status should be success
    End
  End
End
