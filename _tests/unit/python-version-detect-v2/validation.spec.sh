#!/usr/bin/env shellspec
# Unit tests for python-version-detect-v2 action validation and logic

# Framework is automatically loaded via spec_helper.sh

Describe "python-version-detect-v2 action"
ACTION_DIR="python-version-detect-v2"
ACTION_FILE="$ACTION_DIR/action.yml"

Context "when validating default-version input"
It "accepts valid Python version"
When call validate_input_python "python-version-detect-v2" "default-version" "3.11"
The status should be success
End

It "accepts Python version with patch"
When call validate_input_python "python-version-detect-v2" "default-version" "3.11.5"
The status should be success
End

It "accepts Python 3.8"
When call validate_input_python "python-version-detect-v2" "default-version" "3.8"
The status should be success
End

It "accepts Python 3.12"
When call validate_input_python "python-version-detect-v2" "default-version" "3.12"
The status should be success
End

It "rejects Python version too old"
When call validate_input_python "python-version-detect-v2" "default-version" "2.7"
The status should be failure
End

It "rejects invalid version format"
When call validate_input_python "python-version-detect-v2" "default-version" "python3.11"
The status should be failure
End

It "rejects version with command injection"
When call validate_input_python "python-version-detect-v2" "default-version" "3.11; rm -rf /"
The status should be failure
End

It "rejects empty version"
When call validate_input_python "python-version-detect-v2" "default-version" ""
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
The output should equal "Python Version Detect v2"
End

It "defines expected inputs"
When call get_action_inputs "$ACTION_FILE"
The output should include "default-version"
End

It "defines expected outputs"
When call get_action_outputs "$ACTION_FILE"
The output should include "python-version"
End
End

Context "when testing input requirements"
It "has default-version as optional input"
When call uv run "_tests/shared/validation_core.py" --property "$ACTION_FILE" "default-version" "optional"
The output should equal "optional"
End
End

Context "when testing security validations"
It "validates against path traversal in version"
When call validate_input_python "python-version-detect-v2" "default-version" "../3.11"
The status should be failure
End

It "validates against shell metacharacters in version"
When call validate_input_python "python-version-detect-v2" "default-version" "3.11|echo"
The status should be failure
End

It "validates against backtick injection"
When call validate_input_python "python-version-detect-v2" "default-version" "3.11\`whoami\`"
The status should be failure
End
End
End
