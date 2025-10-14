#!/usr/bin/env shellspec
# Unit tests for validate-inputs action validation and logic

# Framework is automatically loaded via spec_helper.sh

Describe "validate-inputs action"
ACTION_DIR="validate-inputs"
ACTION_FILE="$ACTION_DIR/action.yml"

Context "when validating action input"
It "accepts valid action name"
When call validate_input_python "validate-inputs" "action" "github-release"
The status should be success
End

It "accepts action name with hyphens"
When call validate_input_python "validate-inputs" "action" "docker-build"
The status should be success
End

It "accepts action name with underscores"
When call validate_input_python "validate-inputs" "action" "npm_publish"
The status should be success
End

It "rejects action with command injection"
When call validate_input_python "validate-inputs" "action" "github-release; rm -rf /"
The status should be failure
End

It "rejects action with shell operators"
When call validate_input_python "validate-inputs" "action" "github-release && malicious"
The status should be failure
End

It "rejects action with pipe"
When call validate_input_python "validate-inputs" "action" "github-release | cat /etc/passwd"
The status should be failure
End

It "rejects empty action"
When call validate_input_python "validate-inputs" "action" ""
The status should be failure
End
End

Context "when validating rules-file input"
It "accepts valid rules file"
When call validate_input_python "validate-inputs" "rules-file" "validate-inputs/rules/github-release.yml"
The status should be success
End

It "accepts rules file with relative path"
When call validate_input_python "validate-inputs" "rules-file" "rules/action.yml"
The status should be success
End

It "rejects path traversal in rules file"
When call validate_input_python "validate-inputs" "rules-file" "../../../etc/passwd"
The status should be failure
End

It "rejects absolute path in rules file"
When call validate_input_python "validate-inputs" "rules-file" "/etc/passwd"
The status should be failure
End

It "rejects rules file with command injection"
When call validate_input_python "validate-inputs" "rules-file" "rules.yml; rm -rf /"
The status should be failure
End

It "accepts empty rules file (uses default)"
When call validate_input_python "validate-inputs" "rules-file" ""
The status should be success
End
End

Context "when validating fail-on-error input"
It "accepts true for fail-on-error"
When call validate_input_python "validate-inputs" "fail-on-error" "true"
The status should be success
End

It "accepts false for fail-on-error"
When call validate_input_python "validate-inputs" "fail-on-error" "false"
The status should be success
End

It "rejects invalid fail-on-error value"
When call validate_input_python "validate-inputs" "fail-on-error" "yes"
The status should be failure
End

It "rejects empty fail-on-error"
When call validate_input_python "validate-inputs" "fail-on-error" ""
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
The output should equal "Validate Inputs"
End

It "defines expected inputs"
When call get_action_inputs "$ACTION_FILE"
The output should include "action"
The output should include "rules-file"
The output should include "fail-on-error"
End

It "defines expected outputs"
When call get_action_outputs "$ACTION_FILE"
The output should include "validation-result"
The output should include "errors-found"
The output should include "rules-applied"
End
End

Context "when testing input requirements"
It "requires action input"
When call uv run "_tests/shared/validation_core.py" --property "$ACTION_FILE" "action" "required"
The output should equal "required"
End

It "has rules-file as optional input"
When call uv run "_tests/shared/validation_core.py" --property "$ACTION_FILE" "rules-file" "optional"
The output should equal "optional"
End

It "has fail-on-error as optional input"
When call uv run "_tests/shared/validation_core.py" --property "$ACTION_FILE" "fail-on-error" "optional"
The output should equal "optional"
End
End

Context "when testing security validations"
It "validates against path traversal in rules file"
When call validate_input_python "validate-inputs" "rules-file" "../../malicious.yml"
The status should be failure
End

It "validates against command injection in action name"
When call validate_input_python "validate-inputs" "action" "test\`whoami\`"
The status should be failure
End

It "validates against shell metacharacters in rules file"
When call validate_input_python "validate-inputs" "rules-file" "rules.yml && rm -rf /"
The status should be failure
End
End

Context "when testing validation-specific functionality"
It "validates action name format restrictions"
When call validate_input_python "validate-inputs" "action" "invalid/action/name"
The status should be failure
End

It "validates rules file extension requirements"
When call validate_input_python "validate-inputs" "rules-file" "rules.txt"
The status should be success
End

It "validates boolean input parsing"
When call validate_input_python "validate-inputs" "fail-on-error" "TRUE"
The status should be success
End
End
End
