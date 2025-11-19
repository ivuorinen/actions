#!/usr/bin/env shellspec
# Unit tests for action-versioning action validation and logic
# Framework is automatically loaded via spec_helper.sh

Describe "action-versioning action"
ACTION_DIR="action-versioning"
ACTION_FILE="$ACTION_DIR/action.yml"

Context "when validating major-version input"
It "accepts valid year-based version (vYYYY)"
When call validate_input_python "action-versioning" "major-version" "v2025"
The status should be success
End

It "accepts valid semantic version (v1)"
When call validate_input_python "action-versioning" "major-version" "v1"
The status should be success
End

It "accepts valid semantic version (v2)"
When call validate_input_python "action-versioning" "major-version" "v2"
The status should be success
End

It "accepts year-based version from 2020"
When call validate_input_python "action-versioning" "major-version" "v2020"
The status should be success
End

It "accepts year-based version for 2030"
When call validate_input_python "action-versioning" "major-version" "v2030"
The status should be success
End

It "rejects version without v prefix"
When call validate_input_python "action-versioning" "major-version" "2025"
The status should be failure
End

It "rejects invalid version format"
When call validate_input_python "action-versioning" "major-version" "invalid"
The status should be failure
End

It "rejects empty version"
When call validate_input_python "action-versioning" "major-version" ""
The status should be failure
End

It "rejects version with command injection"
When call validate_input_python "action-versioning" "major-version" "v2025; rm -rf /"
The status should be failure
End
End

Context "when validating token input"
It "accepts valid GitHub token (classic)"
When call validate_input_python "action-versioning" "token" "ghp_123456789012345678901234567890123456"
The status should be success
End

It "accepts valid GitHub fine-grained token"
When call validate_input_python "action-versioning" "token" "github_pat_1234567890123456789012345678901234567890123456789012345678901234567890a"
The status should be success
End

It "accepts empty token (optional input)"
When call validate_input_python "action-versioning" "token" ""
The status should be success
End

It "rejects invalid token format"
When call validate_input_python "action-versioning" "token" "invalid-token"
The status should be failure
End

It "rejects token with command injection"
When call validate_input_python "action-versioning" "token" "ghp_123456789012345678901234567890123456; rm -rf /"
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
The output should equal "Action Versioning"
End

It "defines expected inputs"
When call get_action_inputs "$ACTION_FILE"
The output should include "major-version"
The output should include "token"
End

It "defines expected outputs"
When call get_action_outputs "$ACTION_FILE"
The output should include "updated"
The output should include "commit-sha"
The output should include "needs-annual-bump"
End
End

Context "when testing input requirements"
It "requires major-version input"
When call is_input_required "$ACTION_FILE" "major-version"
The status should be success
End

It "has token as optional input"
When call is_input_required "$ACTION_FILE" "token"
The status should be failure
End
End

Context "when testing security validations"
It "validates against path traversal in major-version"
When call validate_input_python "action-versioning" "major-version" "v../../etc"
The status should be failure
End

It "validates against shell metacharacters in major-version"
When call validate_input_python "action-versioning" "major-version" "v2025|echo"
The status should be failure
End

It "validates against command substitution in major-version"
When call validate_input_python "action-versioning" "major-version" "v\$(whoami)"
The status should be failure
End

It "validates against path traversal in token"
When call validate_input_python "action-versioning" "token" "../../../etc/passwd"
The status should be failure
End
End
End
