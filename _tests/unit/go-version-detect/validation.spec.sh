#!/usr/bin/env shellspec
# Unit tests for go-version-detect action validation and logic

# Framework is automatically loaded via spec_helper.sh

Describe "go-version-detect action"
ACTION_DIR="go-version-detect"
ACTION_FILE="$ACTION_DIR/action.yml"

# Test version constants (update these when Go releases new versions)
CURRENT_STABLE_GO_VERSION="1.25"
CURRENT_STABLE_GO_PATCH="1.25.0"
PREVIOUS_GO_VERSION="1.24.0"
MIN_SUPPORTED_GO_VERSION="1.18"
MAX_SUPPORTED_GO_VERSION="1.30"
TOO_OLD_GO_VERSION="1.17"
TOO_NEW_GO_VERSION="1.26"

Context "when validating default-version input"
It "accepts valid semantic version"
When call validate_input_python "go-version-detect" "default-version" "$CURRENT_STABLE_GO_VERSION"
The status should be success
End

It "accepts semantic version with patch"
When call validate_input_python "go-version-detect" "default-version" "$PREVIOUS_GO_VERSION"
The status should be success
End

It "accepts minimum supported Go version"
When call validate_input_python "go-version-detect" "default-version" "$MIN_SUPPORTED_GO_VERSION"
The status should be success
End

It "accepts current stable Go version"
When call validate_input_python "go-version-detect" "default-version" "$CURRENT_STABLE_GO_PATCH"
The status should be success
End

It "rejects version without minor"
When call validate_input_python "go-version-detect" "default-version" "1"
The status should be failure
End

It "rejects invalid version format"
When call validate_input_python "go-version-detect" "default-version" "invalid-version"
The status should be failure
End

It "rejects version with command injection"
When call validate_input_python "go-version-detect" "default-version" "${CURRENT_STABLE_GO_VERSION}; rm -rf /"
The status should be failure
End

It "rejects version with shell expansion"
When call validate_input_python "go-version-detect" "default-version" "${CURRENT_STABLE_GO_VERSION}\$(echo test)"
The status should be failure
End

It "rejects major version other than 1"
When call validate_input_python "go-version-detect" "default-version" "2.0"
The status should be failure
End

It "rejects too old minor version"
When call validate_input_python "go-version-detect" "default-version" "$TOO_OLD_GO_VERSION"
The status should be failure
End

It "rejects too new minor version"
When call validate_input_python "go-version-detect" "default-version" "$TOO_NEW_GO_VERSION"
The status should be failure
End

It "rejects empty version"
When call validate_input_python "go-version-detect" "default-version" ""
The status should be failure
End

It "rejects version with leading v"
When call validate_input_python "go-version-detect" "default-version" "v${CURRENT_STABLE_GO_VERSION}"
The status should be failure
End

It "rejects version with prerelease"
When call validate_input_python "go-version-detect" "default-version" "${CURRENT_STABLE_GO_VERSION}-beta"
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
The output should equal "Go Version Detect"
End

It "defines expected inputs"
When call get_action_inputs "$ACTION_FILE"
The output should include "default-version"
End

It "defines expected outputs"
When call get_action_outputs "$ACTION_FILE"
The output should include "go-version"
End
End

Context "when testing input requirements"
It "has default-version as optional input"
# Test that default-version has a default value in action.yml
When call python3 "_tests/shared/validation_core.py" --property "$ACTION_FILE" "default-version" "optional"
The output should equal "optional"
End

It "has correct default version"
When call python3 "_tests/shared/validation_core.py" --property "$ACTION_FILE" "default-version" "default"
The output should equal "$CURRENT_STABLE_GO_VERSION"
End
End

Context "when testing security validations"
It "validates against path traversal in version"
When call validate_input_python "go-version-detect" "default-version" "../${CURRENT_STABLE_GO_VERSION}"
The status should be failure
End

It "validates against shell metacharacters in version"
When call validate_input_python "go-version-detect" "default-version" "${CURRENT_STABLE_GO_VERSION}|echo"
The status should be failure
End

It "validates against backtick injection"
When call validate_input_python "go-version-detect" "default-version" "${CURRENT_STABLE_GO_VERSION}\`whoami\`"
The status should be failure
End

It "validates against variable expansion"
When call validate_input_python "go-version-detect" "default-version" "${CURRENT_STABLE_GO_VERSION}\${HOME}"
The status should be failure
End
End

Context "when testing version range validation"
It "validates reasonable Go version range boundaries"
# Test boundary conditions for Go version validation
When call validate_input_python "go-version-detect" "default-version" "$TOO_OLD_GO_VERSION"
The status should be failure
End

It "validates upper boundary"
When call validate_input_python "go-version-detect" "default-version" "$TOO_NEW_GO_VERSION"
The status should be failure
End

It "validates exact boundary valid values"
When call validate_input_python "go-version-detect" "default-version" "$MIN_SUPPORTED_GO_VERSION"
The status should be success
End

It "validates exact boundary valid values upper"
When call validate_input_python "go-version-detect" "default-version" "$MAX_SUPPORTED_GO_VERSION"
The status should be success
End
End
End
