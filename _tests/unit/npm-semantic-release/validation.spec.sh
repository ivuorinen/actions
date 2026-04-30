#!/usr/bin/env shellspec
# Unit tests for npm-semantic-release action validation and logic
# Framework is automatically loaded via spec_helper.sh

Describe "npm-semantic-release action"
ACTION_DIR="npm-semantic-release"
ACTION_FILE="$ACTION_DIR/action.yml"

Context "when validating npm_token input"
It "accepts valid GitHub package token format"
When call validate_input_python "npm-semantic-release" "npm_token" "ghp_123456789012345678901234567890123456"
The status should be success
End

It "accepts valid NPM classic token format"
When call validate_input_python "npm-semantic-release" "npm_token" "npm_1234567890123456789012345678901234567890"
The status should be success
End

It "rejects empty token"
When call validate_input_python "npm-semantic-release" "npm_token" ""
The status should be failure
End

It "rejects token with command injection"
When call validate_input_python "npm-semantic-release" "npm_token" "ghp_123456789012345678901234567890123456; rm -rf /"
The status should be failure
End
End

Context "when validating registry-url input"
It "accepts valid https registry URL"
When call validate_input_python "npm-semantic-release" "registry-url" "https://registry.npmjs.org/"
The status should be success
End

It "accepts http registry URL"
When call validate_input_python "npm-semantic-release" "registry-url" "http://localhost:4873"
The status should be success
End

It "rejects non-http(s) URL"
When call validate_input_python "npm-semantic-release" "registry-url" "ftp://registry.example.com"
The status should be failure
End

It "rejects invalid URL format"
When call validate_input_python "npm-semantic-release" "registry-url" "not-a-url"
The status should be failure
End

It "rejects URL with command injection"
When call validate_input_python "npm-semantic-release" "registry-url" "https://registry.npmjs.org|echo"
The status should be failure
End
End

Context "when validating scope input"
It "accepts valid npm scope"
When call validate_input_python "npm-semantic-release" "scope" "@ivuorinen"
The status should be success
End

It "accepts scope with hyphens"
When call validate_input_python "npm-semantic-release" "scope" "@my-organization"
The status should be success
End

It "rejects scope without @ prefix"
When call validate_input_python "npm-semantic-release" "scope" "myorg"
The status should be failure
End

It "rejects scope with invalid characters"
When call validate_input_python "npm-semantic-release" "scope" "@my_org!"
The status should be failure
End

It "rejects scope with command injection"
When call validate_input_python "npm-semantic-release" "scope" "@myorg; rm -rf /"
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
The output should equal "NPM Semantic Release"
End

It "defines expected inputs"
When call get_action_inputs "$ACTION_FILE"
The output should include "npm_token"
The output should include "registry-url"
The output should include "scope"
End

It "defines expected outputs"
When call get_action_outputs "$ACTION_FILE"
The output should include "new-release-published"
The output should include "new-release-version"
End
End

Context "when testing input requirements"
It "requires npm_token input"
inputs=$(get_action_inputs "$ACTION_FILE")
When call echo "$inputs"
The output should include "npm_token"
End

It "has registry-url as optional with default"
When call uv run "_tests/shared/validation_core.py" --property "$ACTION_FILE" "registry-url" "default"
The output should include "registry.npmjs.org"
End

It "has scope with default @ivuorinen"
When call uv run "_tests/shared/validation_core.py" --property "$ACTION_FILE" "scope" "default"
The output should include "@ivuorinen"
End
End

Context "when testing security validations"
It "validates against path traversal in scope"
When call validate_input_python "npm-semantic-release" "scope" "@../../../etc"
The status should be failure
End

It "validates against command substitution in scope"
When call validate_input_python "npm-semantic-release" "scope" "@\$(whoami)"
The status should be failure
End

It "validates against path traversal in registry-url"
When call validate_input_python "npm-semantic-release" "registry-url" "https://registry.npmjs.org/../../../etc"
The status should be failure
End
End
End
