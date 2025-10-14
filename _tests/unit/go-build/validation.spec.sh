#!/usr/bin/env shellspec
# Unit tests for go-build action validation and logic

# Framework is automatically loaded via spec_helper.sh

Describe "go-build action"
ACTION_DIR="go-build"
ACTION_FILE="$ACTION_DIR/action.yml"

Context "when validating go-version input"
It "accepts valid Go version"
When call validate_input_python "go-build" "go-version" "1.21.0"
The status should be success
End

It "accepts Go version with v prefix"
When call validate_input_python "go-build" "go-version" "v1.21.0"
The status should be success
End

It "accepts newer Go version"
When call validate_input_python "go-build" "go-version" "1.22.1"
The status should be success
End

It "accepts prerelease Go version"
When call validate_input_python "go-build" "go-version" "1.21.0-rc1"
The status should be success
End

It "rejects invalid Go version format"
When call validate_input_python "go-build" "go-version" "invalid-version"
The status should be failure
End

It "rejects Go version with command injection"
When call validate_input_python "go-build" "go-version" "1.21; rm -rf /"
The status should be failure
End
End

Context "when validating destination input"
It "accepts valid relative path"
When call validate_input_python "go-build" "destination" "./bin"
The status should be success
End

It "accepts nested directory path"
When call validate_input_python "go-build" "destination" "build/output"
The status should be success
End

It "accepts simple directory name"
When call validate_input_python "go-build" "destination" "dist"
The status should be success
End

It "rejects path traversal in destination"
When call validate_input_python "go-build" "destination" "../bin"
The status should be failure
End

It "rejects absolute path"
When call validate_input_python "go-build" "destination" "/usr/bin"
The status should be failure
End

It "rejects destination with command injection"
When call validate_input_python "go-build" "destination" "./bin; rm -rf /"
The status should be failure
End
End

Context "when validating max-retries input"
It "accepts valid retry count"
When call validate_input_python "go-build" "max-retries" "3"
The status should be success
End

It "accepts minimum retry count"
When call validate_input_python "go-build" "max-retries" "1"
The status should be success
End

It "accepts maximum retry count"
When call validate_input_python "go-build" "max-retries" "10"
The status should be success
End

It "rejects retry count below minimum"
When call validate_input_python "go-build" "max-retries" "0"
The status should be failure
End

It "rejects retry count above maximum"
When call validate_input_python "go-build" "max-retries" "15"
The status should be failure
End

It "rejects non-numeric retry count"
When call validate_input_python "go-build" "max-retries" "many"
The status should be failure
End

It "rejects decimal retry count"
When call validate_input_python "go-build" "max-retries" "3.5"
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
The output should equal "Go Build"
End

It "defines expected inputs"
When call get_action_inputs "$ACTION_FILE"
The output should include "go-version"
The output should include "destination"
The output should include "max-retries"
End

It "defines expected outputs"
When call get_action_outputs "$ACTION_FILE"
The output should include "build_status"
The output should include "test_status"
The output should include "go_version"
The output should include "binary_path"
The output should include "coverage_path"
End
End

Context "when testing input defaults"
It "has default destination"
When call uv run "_tests/shared/validation_core.py" --property "$ACTION_FILE" "destination" "default"
The output should equal "./bin"
End

It "has default max-retries"
When call uv run "_tests/shared/validation_core.py" --property "$ACTION_FILE" "max-retries" "default"
The output should equal "3"
End

It "has all inputs as optional"
When call uv run "_tests/shared/validation_core.py" --property "$ACTION_FILE" "" "all_optional"
The output should equal "none"
End
End

Context "when testing security validations"
It "validates against shell injection in go-version"
When call validate_input_python "go-build" "go-version" "1.21.0|echo test"
The status should be failure
End

It "validates against shell injection in destination"
When call validate_input_python "go-build" "destination" "bin\$(whoami)"
The status should be failure
End

It "validates against shell injection in max-retries"
When call validate_input_python "go-build" "max-retries" "3;echo test"
The status should be failure
End
End
End
