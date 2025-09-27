#!/usr/bin/env shellspec
# Unit tests for php-laravel-phpunit action validation and logic

# Framework is automatically loaded via spec_helper.sh

Describe "php-laravel-phpunit action"
ACTION_DIR="php-laravel-phpunit"
ACTION_FILE="$ACTION_DIR/action.yml"

Context "when validating php-version input"
It "accepts latest"
When call validate_input_python "php-laravel-phpunit" "php-version" "latest"
The status should be success
End

It "accepts valid PHP version"
When call validate_input_python "php-laravel-phpunit" "php-version" "8.4"
The status should be success
End

It "accepts PHP version with patch"
When call validate_input_python "php-laravel-phpunit" "php-version" "8.4.1"
The status should be success
End

It "accepts PHP 7.4"
When call validate_input_python "php-laravel-phpunit" "php-version" "7.4"
The status should be success
End

It "accepts PHP 8.0"
When call validate_input_python "php-laravel-phpunit" "php-version" "8.0"
The status should be success
End

It "rejects invalid version format"
When call validate_input_python "php-laravel-phpunit" "php-version" "php8.4"
The status should be failure
End

It "rejects version with command injection"
When call validate_input_python "php-laravel-phpunit" "php-version" "8.4; rm -rf /"
The status should be failure
End

It "accepts empty version (uses default)"
When call validate_input_python "php-laravel-phpunit" "php-version" ""
The status should be success
End
End

Context "when validating php-version-file input"
It "accepts valid PHP version file"
When call validate_input_python "php-laravel-phpunit" "php-version-file" ".php-version"
The status should be success
End

It "accepts custom version file"
When call validate_input_python "php-laravel-phpunit" "php-version-file" "custom-php-version"
The status should be success
End

It "accepts version file with path"
When call validate_input_python "php-laravel-phpunit" "php-version-file" "config/.php-version"
The status should be success
End

It "rejects path traversal in version file"
When call validate_input_python "php-laravel-phpunit" "php-version-file" "../../../etc/passwd"
The status should be failure
End

It "rejects absolute path in version file"
When call validate_input_python "php-laravel-phpunit" "php-version-file" "/etc/passwd"
The status should be failure
End

It "rejects version file with command injection"
When call validate_input_python "php-laravel-phpunit" "php-version-file" ".php-version; rm -rf /"
The status should be failure
End

It "accepts empty version file"
When call validate_input_python "php-laravel-phpunit" "php-version-file" ""
The status should be success
End
End

Context "when validating extensions input"
It "accepts valid PHP extensions"
When call validate_input_python "php-laravel-phpunit" "extensions" "mbstring, intl, json"
The status should be success
End

It "accepts single extension"
When call validate_input_python "php-laravel-phpunit" "extensions" "mbstring"
The status should be success
End

It "accepts extensions without spaces"
When call validate_input_python "php-laravel-phpunit" "extensions" "mbstring,intl,json"
The status should be success
End

It "accepts extensions with underscores"
When call validate_input_python "php-laravel-phpunit" "extensions" "pdo_sqlite, pdo_mysql"
The status should be success
End

It "accepts extensions with numbers"
When call validate_input_python "php-laravel-phpunit" "extensions" "sqlite3, gd2"
The status should be success
End

It "rejects extensions with special characters"
When call python3 "_tests/shared/validation_core.py" --validate "php-laravel-phpunit" "extensions" "mbstring@intl"
The status should be failure
End

It "rejects extensions with command injection"
When call validate_input_python "php-laravel-phpunit" "extensions" "mbstring; rm -rf /"
The status should be failure
End

It "accepts empty extensions"
When call validate_input_python "php-laravel-phpunit" "extensions" ""
The status should be success
End
End

Context "when validating coverage input"
It "accepts none coverage"
When call validate_input_python "php-laravel-phpunit" "coverage" "none"
The status should be success
End

It "accepts xdebug coverage"
When call validate_input_python "php-laravel-phpunit" "coverage" "xdebug"
The status should be success
End

It "accepts pcov coverage"
When call validate_input_python "php-laravel-phpunit" "coverage" "pcov"
The status should be success
End

It "accepts xdebug3 coverage"
When call validate_input_python "php-laravel-phpunit" "coverage" "xdebug3"
The status should be success
End

It "rejects invalid coverage driver"
When call python3 "_tests/shared/validation_core.py" --validate "php-laravel-phpunit" "coverage" "invalid"
The status should be failure
End

It "rejects coverage with command injection"
When call validate_input_python "php-laravel-phpunit" "coverage" "none; rm -rf /"
The status should be failure
End

It "accepts empty coverage"
When call validate_input_python "php-laravel-phpunit" "coverage" ""
The status should be success
End
End

Context "when validating token input"
It "accepts GitHub token expression"
When call validate_input_python "php-laravel-phpunit" "token" "\${{ github.token }}"
The status should be success
End

It "accepts GitHub fine-grained token"
When call validate_input_python "php-laravel-phpunit" "token" "ghp_abcdefghijklmnopqrstuvwxyz1234567890"
The status should be success
End

It "accepts GitHub app token"
When call validate_input_python "php-laravel-phpunit" "token" "ghs_abcdefghijklmnopqrstuvwxyz1234567890"
The status should be success
End

It "rejects invalid token format"
When call validate_input_python "php-laravel-phpunit" "token" "invalid-token"
The status should be failure
End

It "accepts empty token"
When call validate_input_python "php-laravel-phpunit" "token" ""
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
When call check_all_optional
The output should equal "none"
End

It "has correct default php-version"
When call python3 "_tests/shared/validation_core.py" --property "$ACTION_FILE" "php-version" "default"
The output should equal "latest"
End

It "has correct default php-version-file"
When call python3 "_tests/shared/validation_core.py" --property "$ACTION_FILE" "php-version-file" "default"
The output should equal ".php-version"
End
End

Context "when testing security validations"
It "validates against path traversal in php-version-file"
When call validate_input_python "php-laravel-phpunit" "php-version-file" "../../etc/passwd"
The status should be failure
End

It "validates against shell metacharacters in extensions"
When call validate_input_python "php-laravel-phpunit" "extensions" "mbstring && rm -rf /"
The status should be failure
End

It "validates against backtick injection in coverage"
When call validate_input_python "php-laravel-phpunit" "coverage" "none\`whoami\`"
The status should be failure
End

It "validates against variable expansion in php-version"
When call validate_input_python "php-laravel-phpunit" "php-version" "8.4\${HOME}"
The status should be failure
End
End

Context "when testing Laravel-specific validations"
It "validates coverage driver enum values"
When call python3 "_tests/shared/validation_core.py" --validate "php-laravel-phpunit" "coverage" "invalid-driver"
The status should be failure
End

It "validates php-version-file path safety"
When call validate_input_python "php-laravel-phpunit" "php-version-file" "/etc/shadow"
The status should be failure
End

It "validates extensions format for Laravel requirements"
When call validate_input_python "php-laravel-phpunit" "extensions" "mbstring, intl, json, pdo_sqlite, sqlite3"
The status should be success
End
End
End
