#!/usr/bin/env shellspec
# Unit tests for php-composer action validation and logic

# Framework is automatically loaded via spec_helper.sh

Describe "php-composer action"
ACTION_DIR="php-composer"
ACTION_FILE="$ACTION_DIR/action.yml"

Context "when validating php input"
It "accepts valid PHP version"
When call validate_input_python "php-composer" "php" "8.4"
The status should be success
End

It "accepts PHP version with patch"
When call validate_input_python "php-composer" "php" "8.4.1"
The status should be success
End

It "accepts PHP 7.4"
When call validate_input_python "php-composer" "php" "7.4"
The status should be success
End

It "accepts PHP 8.0"
When call validate_input_python "php-composer" "php" "8.0"
The status should be success
End

It "accepts PHP 8.1"
When call validate_input_python "php-composer" "php" "8.1"
The status should be success
End

It "rejects PHP version too old"
When call validate_input_python "php-composer" "php" "5.5"
The status should be failure
End

It "rejects invalid version format"
When call validate_input_python "php-composer" "php" "php8.4"
The status should be failure
End

It "rejects version with command injection"
When call validate_input_python "php-composer" "php" "8.4; rm -rf /"
The status should be failure
End

It "rejects empty version"
When call validate_input_python "php-composer" "php" ""
The status should be failure
End
End

Context "when validating extensions input"
It "accepts valid PHP extensions"
When call validate_input_python "php-composer" "extensions" "mbstring, xml, zip"
The status should be success
End

It "accepts single extension"
When call validate_input_python "php-composer" "extensions" "mbstring"
The status should be success
End

It "accepts extensions without spaces"
When call validate_input_python "php-composer" "extensions" "mbstring,xml,zip"
The status should be success
End

It "accepts extensions with underscores"
When call validate_input_python "php-composer" "extensions" "pdo_mysql, gd_jpeg"
The status should be success
End

It "rejects extensions with special characters"
When call validate_input_python "php-composer" "extensions" "mbstring@xml"
The status should be failure
End

It "rejects extensions with command injection"
When call validate_input_python "php-composer" "extensions" "mbstring; rm -rf /"
The status should be failure
End

It "accepts empty extensions"
When call validate_input_python "php-composer" "extensions" ""
The status should be failure
End
End

Context "when validating tools input"
It "accepts valid Composer tools"
When call validate_input_python "php-composer" "tools" "composer:v2"
The status should be success
End

It "accepts multiple tools"
When call validate_input_python "php-composer" "tools" "composer:v2, phpunit:^9.0"
The status should be success
End

It "accepts tools with version constraints"
When call validate_input_python "php-composer" "tools" "phpcs, phpstan:1.10"
The status should be success
End

It "rejects tools with special characters"
When call validate_input_python "php-composer" "tools" "composer@malicious"
The status should be failure
End

It "rejects tools with command injection"
When call validate_input_python "php-composer" "tools" "composer; rm -rf /"
The status should be failure
End

It "accepts empty tools"
When call validate_input_python "php-composer" "tools" ""
The status should be failure
End
End

Context "when validating composer-version input"
It "accepts composer version 1"
When call validate_input_python "php-composer" "composer-version" "1"
The status should be success
End

It "accepts composer version 2"
When call validate_input_python "php-composer" "composer-version" "2"
The status should be success
End

It "rejects invalid composer version"
When call validate_input_python "php-composer" "composer-version" "3"
The status should be failure
End

It "rejects non-numeric composer version"
When call validate_input_python "php-composer" "composer-version" "latest"
The status should be failure
End

It "rejects empty composer version"
When call validate_input_python "php-composer" "composer-version" ""
The status should be failure
End
End

Context "when validating stability input"
It "accepts stable"
When call validate_input_python "php-composer" "stability" "stable"
The status should be success
End

It "accepts RC"
When call validate_input_python "php-composer" "stability" "RC"
The status should be success
End

It "accepts beta"
When call validate_input_python "php-composer" "stability" "beta"
The status should be success
End

It "accepts alpha"
When call validate_input_python "php-composer" "stability" "alpha"
The status should be success
End

It "accepts dev"
When call validate_input_python "php-composer" "stability" "dev"
The status should be success
End

It "rejects invalid stability"
When call validate_input_python "php-composer" "stability" "unstable"
The status should be failure
End

It "rejects stability with injection"
When call validate_input_python "php-composer" "stability" "stable; rm -rf /"
The status should be failure
End
End

Context "when validating cache-directories input"
It "accepts valid cache directory"
When call validate_input_python "php-composer" "cache-directories" "vendor/cache"
The status should be success
End

It "accepts multiple cache directories"
When call validate_input_python "php-composer" "cache-directories" "vendor/cache, .cache"
The status should be success
End

It "accepts directories with underscores and hyphens"
When call validate_input_python "php-composer" "cache-directories" "cache_dir, cache-dir"
The status should be success
End

It "rejects path traversal"
When call validate_input_python "php-composer" "cache-directories" "../malicious"
The status should be failure
End

It "rejects absolute paths"
When call validate_input_python "php-composer" "cache-directories" "/etc/passwd"
The status should be failure
End

It "rejects directories with command injection"
When call validate_input_python "php-composer" "cache-directories" "cache; rm -rf /"
The status should be failure
End

It "accepts empty cache directories"
When call validate_input_python "php-composer" "cache-directories" ""
The status should be failure
End
End

Context "when validating token input"
It "accepts GitHub token expression"
When call validate_input_python "php-composer" "token" "\${{ github.token }}"
The status should be success
End

It "accepts GitHub fine-grained token"
When call validate_input_python "php-composer" "token" "ghp_abcdefghijklmnopqrstuvwxyz1234567890"
The status should be success
End

It "accepts GitHub app token"
When call validate_input_python "php-composer" "token" "ghs_abcdefghijklmnopqrstuvwxyz1234567890"
The status should be success
End

It "rejects invalid token format"
When call validate_input_python "php-composer" "token" "invalid-token"
The status should be failure
End

It "accepts empty token"
When call validate_input_python "php-composer" "token" ""
The status should be failure
End
End

Context "when validating max-retries input"
It "accepts valid retry count"
When call validate_input_python "php-composer" "max-retries" "3"
The status should be success
End

It "accepts minimum retries"
When call validate_input_python "php-composer" "max-retries" "1"
The status should be success
End

It "accepts maximum retries"
When call validate_input_python "php-composer" "max-retries" "10"
The status should be success
End

It "rejects zero retries"
When call validate_input_python "php-composer" "max-retries" "0"
The status should be failure
End

It "rejects too many retries"
When call validate_input_python "php-composer" "max-retries" "11"
The status should be failure
End

It "rejects non-numeric retries"
When call validate_input_python "php-composer" "max-retries" "many"
The status should be failure
End

It "rejects negative retries"
When call validate_input_python "php-composer" "max-retries" "-1"
The status should be failure
End
End

Context "when validating args input"
It "accepts valid Composer arguments"
When call validate_input_python "php-composer" "args" "--no-progress --prefer-dist"
The status should be success
End

It "accepts empty args"
When call validate_input_python "php-composer" "args" ""
The status should be failure
End

It "rejects args with command injection"
When call validate_input_python "php-composer" "args" "--no-progress; rm -rf /"
The status should be failure
End

It "rejects args with pipe"
When call validate_input_python "php-composer" "args" "--no-progress | cat /etc/passwd"
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
When call python3 "_tests/shared/validation_core.py" --property "$ACTION_FILE" "php" "required"
The output should equal "required"
End

It "has extensions as optional input"
When call python3 "_tests/shared/validation_core.py" --property "$ACTION_FILE" "extensions" "optional"
The output should equal "optional"
End
End

Context "when testing security validations"
It "validates against path traversal in cache directories"
When call validate_input_python "php-composer" "cache-directories" "../../etc/passwd"
The status should be failure
End

It "validates against shell metacharacters in tools"
When call validate_input_python "php-composer" "tools" "composer && rm -rf /"
The status should be failure
End

It "validates against backtick injection in args"
When call validate_input_python "php-composer" "args" "--no-progress \`whoami\`"
The status should be failure
End

It "validates against variable expansion in extensions"
When call validate_input_python "php-composer" "extensions" "mbstring,\${HOME}"
The status should be failure
End
End

Context "when testing PHP-specific validations"
It "validates PHP version boundaries"
When call validate_input_python "php-composer" "php" "10.0"
The status should be failure
End

It "validates Composer version enum restriction"
When call validate_input_python "php-composer" "composer-version" "0"
The status should be failure
End

It "validates stability enum values"
When call validate_input_python "php-composer" "stability" "experimental"
The status should be failure
End
End
End
