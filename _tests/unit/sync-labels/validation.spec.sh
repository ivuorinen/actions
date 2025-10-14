#!/usr/bin/env shellspec
# Unit tests for sync-labels action validation and logic

# Framework is automatically loaded via spec_helper.sh

Describe "sync-labels action"
ACTION_DIR="sync-labels"
ACTION_FILE="$ACTION_DIR/action.yml"

Context "when validating token input"
It "accepts GitHub token expression"
When call uv run "_tests/shared/validation_core.py" --validate "sync-labels" "token" "\${{ github.token }}"
The status should be success
End

It "accepts GitHub fine-grained token"
When call uv run "_tests/shared/validation_core.py" --validate "sync-labels" "token" "ghp_abcdefghijklmnopqrstuvwxyz1234567890"
The status should be success
End

It "rejects invalid token format"
When call validate_input_python "sync-labels" "token" "invalid-token"
The status should be failure
End

It "rejects token with command injection"
When call validate_input_python "sync-labels" "token" "ghp_token; rm -rf /"
The status should be failure
End
End

Context "when validating config-file input"
It "accepts valid config file"
When call uv run "_tests/shared/validation_core.py" --validate "sync-labels" "labels" ".github/labels.yml"
The status should be success
End

It "accepts config file with json extension"
When call uv run "_tests/shared/validation_core.py" --validate "sync-labels" "labels" ".github/labels.json"
The status should be success
End

It "rejects path traversal in config file"
When call validate_input_python "sync-labels" "labels" "../../../etc/passwd"
The status should be failure
End

It "rejects absolute path in config file"
When call validate_input_python "sync-labels" "labels" "/etc/passwd"
The status should be failure
End

It "rejects config file with command injection"
When call validate_input_python "sync-labels" "labels" "labels.yml; rm -rf /"
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
The output should equal "Sync labels"
End

It "defines expected inputs"
When call get_action_inputs "$ACTION_FILE"
The output should include "token"
The output should include "labels"
End
End

Context "when testing input requirements"
It "token input is optional"
When call uv run "_tests/shared/validation_core.py" --property "$ACTION_FILE" "token" "optional"
The output should equal "optional"
End
End

Context "when testing security validations"
It "validates against path traversal in config file"
When call validate_input_python "sync-labels" "labels" "../../malicious.yml"
The status should be failure
End

It "validates against command injection in token"
When call validate_input_python "sync-labels" "token" "ghp_token\`whoami\`"
The status should be failure
End

It "validates against shell metacharacters in config file"
When call validate_input_python "sync-labels" "labels" "labels.yml && rm -rf /"
The status should be failure
End
End
End
