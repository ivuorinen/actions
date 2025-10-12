#!/usr/bin/env shellspec
# Unit tests for github-release action validation and logic

# Framework is automatically loaded via spec_helper.sh
# Using the centralized validate_input_python function from spec_helper.sh

Describe "github-release action"
ACTION_DIR="github-release"
ACTION_FILE="$ACTION_DIR/action.yml"

Context "when validating version input"
It "accepts valid semantic version"
When call validate_input_python "github-release" "version" "1.2.3"
The status should be success
End

It "accepts semantic version with v prefix"
When call validate_input_python "github-release" "version" "v1.2.3"
The status should be success
End

It "accepts prerelease version"
When call validate_input_python "github-release" "version" "1.2.3-alpha"
The status should be success
End

It "accepts build metadata version"
When call validate_input_python "github-release" "version" "1.2.3+build.1"
The status should be success
End

It "accepts prerelease with build metadata"
When call validate_input_python "github-release" "version" "1.2.3-alpha.1+build.1"
The status should be success
End

It "accepts CalVer format"
When call validate_input_python "github-release" "version" "2024.3.1"
The status should be success
End

It "rejects invalid version format"
When call validate_input_python "github-release" "version" "invalid-version"
The status should be failure
End

It "rejects version with command injection"
When call validate_input_python "github-release" "version" "1.2.3; rm -rf /"
The status should be failure
End

It "rejects empty version"
When call validate_input_python "github-release" "version" ""
The status should be failure
End
End

Context "when validating changelog input"
It "accepts empty changelog"
When call validate_input_python "github-release" "changelog" ""
The status should be success
End

It "accepts normal changelog content"
When call validate_input_python "github-release" "changelog" "## What's Changed\n- Fixed bug #123\n- Added feature X"
The status should be success
End

It "accepts changelog with special characters"
When call validate_input_python "github-release" "changelog" "Version 1.2.3\n\n- Bug fixes & improvements\n- Added @mention support"
The status should be success
End

It "rejects changelog with command injection"
When call validate_input_python "github-release" "changelog" "Release notes; rm -rf /"
The status should be failure
End

It "rejects changelog with shell expansion"
When call validate_input_python "github-release" "changelog" "Release \$(whoami) notes"
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
The output should equal "GitHub Release"
End

It "defines expected inputs"
When call get_action_inputs "$ACTION_FILE"
The output should include "version"
The output should include "changelog"
End

It "defines expected outputs"
When call get_action_outputs "$ACTION_FILE"
The output should include "release_url"
The output should include "release_id"
The output should include "upload_url"
End
End

Context "when testing input requirements"
It "requires version input"
inputs=$(get_action_inputs "$ACTION_FILE")
When call echo "$inputs"
The output should include "version"
End

It "has changelog as optional input"
# Test that changelog has a default value in action.yml
When call "${PROJECT_ROOT}/.venv/bin/python3" "_tests/shared/validation_core.py" --property "$ACTION_FILE" "changelog" "optional"
The output should equal "optional"
End
End

Context "when testing security validations"
It "validates against path traversal in version"
When call validate_input_python "github-release" "version" "../1.2.3"
The status should be failure
End

It "validates against shell metacharacters in version"
When call validate_input_python "github-release" "version" "1.2.3|echo"
The status should be failure
End

It "validates against shell metacharacters in changelog"
When call validate_input_python "github-release" "changelog" "Release notes|echo test"
The status should be failure
End
End
End
