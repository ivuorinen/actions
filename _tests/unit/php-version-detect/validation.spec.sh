#!/usr/bin/env shellspec
# Unit tests for php-version-detect action validation and logic

# Framework is automatically loaded via spec_helper.sh

Describe "php-version-detect action"
ACTION_DIR="php-version-detect"
ACTION_FILE="$ACTION_DIR/action.yml"

Context "when validating default-version input"
It "accepts valid PHP version"
When call validate_input_python "php-version-detect" "default-version" "8.2"
The status should be success
End

It "accepts PHP version with patch"
When call validate_input_python "php-version-detect" "default-version" "8.3.1"
The status should be success
End

It "accepts PHP 7.4"
When call validate_input_python "php-version-detect" "default-version" "7.4"
The status should be success
End

It "accepts PHP 8.0"
When call validate_input_python "php-version-detect" "default-version" "8.0"
The status should be success
End

It "accepts PHP 8.1"
When call validate_input_python "php-version-detect" "default-version" "8.1"
The status should be success
End

It "accepts PHP 8.4"
When call validate_input_python "php-version-detect" "default-version" "8.4"
The status should be success
End

It "rejects PHP version too old"
When call validate_input_python "php-version-detect" "default-version" "5.6"
The status should be failure
End

It "rejects PHP version too new"
When call validate_input_python "php-version-detect" "default-version" "10.0"
The status should be failure
End

It "rejects invalid version format"
When call validate_input_python "php-version-detect" "default-version" "php8.2"
The status should be failure
End

It "rejects version with command injection"
When call validate_input_python "php-version-detect" "default-version" "8.2; rm -rf /"
The status should be failure
End

It "rejects version without minor"
When call validate_input_python "php-version-detect" "default-version" "8"
The status should be failure
End

It "rejects empty version"
When call validate_input_python "php-version-detect" "default-version" ""
The status should be failure
End

It "rejects version with v prefix"
When call validate_input_python "php-version-detect" "default-version" "v8.2"
The status should be failure
End

It "rejects PHP 8 with invalid minor version"
When call validate_input_python "php-version-detect" "default-version" "8.5"
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
The output should equal "PHP Version Detect"
End

It "defines expected inputs"
When call get_action_inputs "$ACTION_FILE"
The output should include "default-version"
End

It "defines expected outputs"
When call get_action_outputs "$ACTION_FILE"
The output should include "php-version"
End
End

Context "when testing input requirements"
It "has default-version as optional input"
When call python3 "_tests/shared/validation_core.py" --property "$ACTION_FILE" "default-version" "optional"
The output should equal "optional"
End

It "has correct default version"
When call python3 "_tests/shared/validation_core.py" --property "$ACTION_FILE" "default-version" "default"
The output should equal "8.2"
End
End

Context "when testing security validations"
It "validates against path traversal in version"
When call validate_input_python "php-version-detect" "default-version" "../8.2"
The status should be failure
End

It "validates against shell metacharacters in version"
When call validate_input_python "php-version-detect" "default-version" "8.2|echo"
The status should be failure
End

It "validates against backtick injection"
When call validate_input_python "php-version-detect" "default-version" "8.2\`whoami\`"
The status should be failure
End

It "validates against variable expansion"
When call validate_input_python "php-version-detect" "default-version" "8.2\${HOME}"
The status should be failure
End
End

Context "when testing PHP version range validation"
It "validates PHP 7 minor version boundaries"
When call validate_input_python "php-version-detect" "default-version" "7.0"
The status should be success
End

It "validates PHP 7.4 specifically"
When call validate_input_python "php-version-detect" "default-version" "7.4"
The status should be success
End

It "validates PHP 8 minor version boundaries"
When call validate_input_python "php-version-detect" "default-version" "8.0"
The status should be success
End

It "validates PHP 8.4 boundary"
When call validate_input_python "php-version-detect" "default-version" "8.4"
The status should be success
End

It "validates PHP 9 future version"
When call validate_input_python "php-version-detect" "default-version" "9.0"
The status should be success
End
End
End
