#!/usr/bin/env shellspec
# Unit tests for php-composer action validation and logic

# Framework is automatically loaded via spec_helper.sh

Describe "php-composer action"
  ACTION_DIR="php-composer"
  ACTION_FILE="$ACTION_DIR/action.yml"

  Context "when validating php input"
    It "accepts valid PHP version"
      When call test_input_validation "$ACTION_DIR" "php" "8.4" "success"
      The status should be success
    End

    It "accepts PHP version with patch"
      When call test_input_validation "$ACTION_DIR" "php" "8.4.1" "success"
      The status should be success
    End

    It "accepts PHP 7.4"
      When call test_input_validation "$ACTION_DIR" "php" "7.4" "success"
      The status should be success
    End

    It "accepts PHP 8.0"
      When call test_input_validation "$ACTION_DIR" "php" "8.0" "success"
      The status should be success
    End

    It "accepts PHP 8.1"
      When call test_input_validation "$ACTION_DIR" "php" "8.1" "success"
      The status should be success
    End

    It "rejects PHP version too old"
      When call test_input_validation "$ACTION_DIR" "php" "5.5" "failure"
      The status should be success
    End

    It "rejects invalid version format"
      When call test_input_validation "$ACTION_DIR" "php" "php8.4" "failure"
      The status should be success
    End

    It "rejects version with command injection"
      When call test_input_validation "$ACTION_DIR" "php" "8.4; rm -rf /" "failure"
      The status should be success
    End

    It "rejects empty version"
      When call test_input_validation "$ACTION_DIR" "php" "" "failure"
      The status should be success
    End
  End

  Context "when validating extensions input"
    It "accepts valid PHP extensions"
      When call test_input_validation "$ACTION_DIR" "extensions" "mbstring, xml, zip" "success"
      The status should be success
    End

    It "accepts single extension"
      When call test_input_validation "$ACTION_DIR" "extensions" "mbstring" "success"
      The status should be success
    End

    It "accepts extensions without spaces"
      When call test_input_validation "$ACTION_DIR" "extensions" "mbstring,xml,zip" "success"
      The status should be success
    End

    It "accepts extensions with underscores"
      When call test_input_validation "$ACTION_DIR" "extensions" "pdo_mysql, gd_jpeg" "success"
      The status should be success
    End

    It "rejects extensions with special characters"
      When call test_input_validation "$ACTION_DIR" "extensions" "mbstring@xml" "failure"
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

  Context "when validating tools input"
    It "accepts valid Composer tools"
      When call test_input_validation "$ACTION_DIR" "tools" "composer:v2" "success"
      The status should be success
    End

    It "accepts multiple tools"
      When call test_input_validation "$ACTION_DIR" "tools" "composer:v2, phpunit:^9.0" "success"
      The status should be success
    End

    It "accepts tools with version constraints"
      When call test_input_validation "$ACTION_DIR" "tools" "phpcs, phpstan:1.10" "success"
      The status should be success
    End

    It "rejects tools with special characters"
      When call test_input_validation "$ACTION_DIR" "tools" "composer@malicious" "failure"
      The status should be success
    End

    It "rejects tools with command injection"
      When call test_input_validation "$ACTION_DIR" "tools" "composer; rm -rf /" "failure"
      The status should be success
    End

    It "accepts empty tools"
      When call test_input_validation "$ACTION_DIR" "tools" "" "success"
      The status should be success
    End
  End

  Context "when validating composer-version input"
    It "accepts composer version 1"
      When call test_input_validation "$ACTION_DIR" "composer-version" "1" "success"
      The status should be success
    End

    It "accepts composer version 2"
      When call test_input_validation "$ACTION_DIR" "composer-version" "2" "success"
      The status should be success
    End

    It "rejects invalid composer version"
      When call test_input_validation "$ACTION_DIR" "composer-version" "3" "failure"
      The status should be success
    End

    It "rejects non-numeric composer version"
      When call test_input_validation "$ACTION_DIR" "composer-version" "latest" "failure"
      The status should be success
    End

    It "rejects empty composer version"
      When call test_input_validation "$ACTION_DIR" "composer-version" "" "failure"
      The status should be success
    End
  End

  Context "when validating stability input"
    It "accepts stable"
      When call test_input_validation "$ACTION_DIR" "stability" "stable" "success"
      The status should be success
    End

    It "accepts RC"
      When call test_input_validation "$ACTION_DIR" "stability" "RC" "success"
      The status should be success
    End

    It "accepts beta"
      When call test_input_validation "$ACTION_DIR" "stability" "beta" "success"
      The status should be success
    End

    It "accepts alpha"
      When call test_input_validation "$ACTION_DIR" "stability" "alpha" "success"
      The status should be success
    End

    It "accepts dev"
      When call test_input_validation "$ACTION_DIR" "stability" "dev" "success"
      The status should be success
    End

    It "rejects invalid stability"
      When call test_input_validation "$ACTION_DIR" "stability" "unstable" "failure"
      The status should be success
    End

    It "rejects stability with injection"
      When call test_input_validation "$ACTION_DIR" "stability" "stable; rm -rf /" "failure"
      The status should be success
    End
  End

  Context "when validating cache-directories input"
    It "accepts valid cache directory"
      When call test_input_validation "$ACTION_DIR" "cache-directories" "vendor/cache" "success"
      The status should be success
    End

    It "accepts multiple cache directories"
      When call test_input_validation "$ACTION_DIR" "cache-directories" "vendor/cache, .cache" "success"
      The status should be success
    End

    It "accepts directories with underscores and hyphens"
      When call test_input_validation "$ACTION_DIR" "cache-directories" "cache_dir, cache-dir" "success"
      The status should be success
    End

    It "rejects path traversal"
      When call test_input_validation "$ACTION_DIR" "cache-directories" "../malicious" "failure"
      The status should be success
    End

    It "rejects absolute paths"
      When call test_input_validation "$ACTION_DIR" "cache-directories" "/etc/passwd" "failure"
      The status should be success
    End

    It "rejects directories with command injection"
      When call test_input_validation "$ACTION_DIR" "cache-directories" "cache; rm -rf /" "failure"
      The status should be success
    End

    It "accepts empty cache directories"
      When call test_input_validation "$ACTION_DIR" "cache-directories" "" "success"
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

    It "rejects negative retries"
      When call test_input_validation "$ACTION_DIR" "max-retries" "-1" "failure"
      The status should be success
    End
  End

  Context "when validating args input"
    It "accepts valid Composer arguments"
      When call test_input_validation "$ACTION_DIR" "args" "--no-progress --prefer-dist" "success"
      The status should be success
    End

    It "accepts empty args"
      When call test_input_validation "$ACTION_DIR" "args" "" "success"
      The status should be success
    End

    It "rejects args with command injection"
      When call test_input_validation "$ACTION_DIR" "args" "--no-progress; rm -rf /" "failure"
      The status should be success
    End

    It "rejects args with pipe"
      When call test_input_validation "$ACTION_DIR" "args" "--no-progress | cat /etc/passwd" "failure"
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
      The output should equal "Run Composer Install"
    End

    It "defines expected inputs"
      When call get_action_inputs "$ACTION_FILE"
      The output should include "php"
      The output should include "extensions"
      The output should include "tools"
      The output should include "args"
      The output should include "composer-version"
      The output should include "stability"
      The output should include "cache-directories"
      The output should include "token"
      The output should include "max-retries"
    End

    It "defines expected outputs"
      When call get_action_outputs "$ACTION_FILE"
      The output should include "lock"
      The output should include "php-version"
      The output should include "composer-version"
      The output should include "cache-hit"
    End
  End

  Context "when testing input requirements"
    It "requires php input"
      When call python3 -c "
      import yaml
      with open('$ACTION_FILE') as f:
      data = yaml.safe_load(f)
      php = data.get('inputs', {}).get('php', {})
      print('required' if php.get('required', False) else 'optional')
      "
      The output should equal "required"
    End

    It "has extensions as optional input"
      When call python3 -c "
      import yaml
      with open('$ACTION_FILE') as f:
      data = yaml.safe_load(f)
      extensions = data.get('inputs', {}).get('extensions', {})
      print('optional' if 'default' in extensions else 'required')
      "
      The output should equal "optional"
    End
  End

  Context "when testing security validations"
    It "validates against path traversal in cache directories"
      When call test_input_validation "$ACTION_DIR" "cache-directories" "../../etc/passwd" "failure"
      The status should be success
    End

    It "validates against shell metacharacters in tools"
      When call test_input_validation "$ACTION_DIR" "tools" "composer && rm -rf /" "failure"
      The status should be success
    End

    It "validates against backtick injection in args"
      When call test_input_validation "$ACTION_DIR" "args" "--no-progress \`whoami\`" "failure"
      The status should be success
    End

    It "validates against variable expansion in extensions"
      When call test_input_validation "$ACTION_DIR" "extensions" "mbstring,\${HOME}" "failure"
      The status should be success
    End
  End

  Context "when testing PHP-specific validations"
    It "validates PHP version boundaries"
      When call test_input_validation "$ACTION_DIR" "php" "10.0" "success"
      The status should be success
    End

    It "validates Composer version enum restriction"
      When call test_input_validation "$ACTION_DIR" "composer-version" "0" "failure"
      The status should be success
    End

    It "validates stability enum values"
      When call test_input_validation "$ACTION_DIR" "stability" "experimental" "failure"
      The status should be success
    End
  End
End
