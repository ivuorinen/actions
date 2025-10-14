#!/usr/bin/env shellspec
# Unit tests for npm-publish action validation and logic
# Framework is automatically loaded via spec_helper.sh

Describe "npm-publish action"
ACTION_DIR="npm-publish"
ACTION_FILE="$ACTION_DIR/action.yml"

Context "when validating registry-url input"
It "accepts valid https registry URL"
When call validate_input_python "npm-publish" "registry-url" "https://registry.npmjs.org/"
The status should be success
End

It "accepts https registry URL without trailing slash"
When call validate_input_python "npm-publish" "registry-url" "https://registry.npmjs.org"
The status should be success
End

It "accepts http registry URL"
When call validate_input_python "npm-publish" "registry-url" "http://localhost:4873"
The status should be success
End

It "accepts registry URL with path"
When call validate_input_python "npm-publish" "registry-url" "https://npm.example.com/registry/"
The status should be success
End

It "rejects non-http(s) URL"
When call validate_input_python "npm-publish" "registry-url" "ftp://registry.example.com"
The status should be failure
End

It "rejects invalid URL format"
When call validate_input_python "npm-publish" "registry-url" "not-a-url"
The status should be failure
End
End

Context "when validating npm_token input"
It "accepts valid GitHub token format (exact length)"
When call validate_input_python "npm-publish" "npm_token" "ghp_123456789012345678901234567890123456"
The status should be success
End

It "accepts valid NPM classic token format"
When call validate_input_python "npm-publish" "npm_token" "npm_1234567890123456789012345678901234567890"
The status should be success
End

It "accepts GitHub fine-grained token (exact length)"
When call validate_input_python "npm-publish" "npm_token" "github_pat_1234567890123456789012345678901234567890123456789012345678901234567890a"
The status should be success
End

It "rejects invalid token format"
When call validate_input_python "npm-publish" "npm_token" "invalid-token-format"
The status should be failure
End

It "rejects empty token"
When call validate_input_python "npm-publish" "npm_token" ""
The status should be failure
End

It "rejects token with command injection"
When call validate_input_python "npm-publish" "npm_token" "ghp_123456789012345678901234567890123456; rm -rf /"
The status should be failure
End
End

Context "when validating scope input"
It "accepts valid npm scope"
When call validate_input_python "npm-publish" "scope" "@myorg"
The status should be success
End

It "accepts scope with hyphens"
When call validate_input_python "npm-publish" "scope" "@my-organization"
The status should be success
End

It "accepts scope with numbers"
When call validate_input_python "npm-publish" "scope" "@myorg123"
The status should be success
End

It "rejects scope without @ prefix"
When call validate_input_python "npm-publish" "scope" "myorg"
The status should be failure
End

It "rejects scope with invalid characters"
When call validate_input_python "npm-publish" "scope" "@my_org!"
The status should be failure
End

It "rejects scope with command injection"
When call validate_input_python "npm-publish" "scope" "@myorg; rm -rf /"
The status should be failure
End
End

Context "when validating access input"
It "accepts public access"
When call validate_input_python "npm-publish" "access" "public"
The status should be success
End

It "accepts restricted access"
When call validate_input_python "npm-publish" "access" "restricted"
The status should be success
End

It "accepts private access (no specific validation)"
When call validate_input_python "npm-publish" "access" "private"
The status should be success
End

It "accepts empty access"
When call validate_input_python "npm-publish" "access" ""
The status should be success
End
End

Context "when validating provenance input"
It "accepts true for provenance"
When call validate_input_python "npm-publish" "provenance" "true"
The status should be success
End

It "accepts false for provenance"
When call validate_input_python "npm-publish" "provenance" "false"
The status should be success
End

It "accepts any value for provenance (no specific validation)"
When call validate_input_python "npm-publish" "provenance" "maybe"
The status should be success
End
End

Context "when validating dry-run input"
It "accepts true for dry-run"
When call validate_input_python "npm-publish" "dry-run" "true"
The status should be success
End

It "accepts false for dry-run"
When call validate_input_python "npm-publish" "dry-run" "false"
The status should be success
End

It "accepts any value for dry-run (no specific validation)"
When call validate_input_python "npm-publish" "dry-run" "yes"
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
The output should equal "Publish to NPM"
End

It "defines expected inputs"
When call get_action_inputs "$ACTION_FILE"
The output should include "npm_token"
The output should include "registry-url"
End

It "defines expected outputs"
When call get_action_outputs "$ACTION_FILE"
The output should include "registry-url"
The output should include "scope"
The output should include "package-version"
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
End

Context "when testing security validations"
It "validates against path traversal in all inputs"
When call validate_input_python "npm-publish" "scope" "@../../../etc"
The status should be failure
End

It "validates against shell metacharacters"
When call validate_input_python "npm-publish" "registry-url" "https://registry.npmjs.org|echo"
The status should be failure
End

It "validates against command substitution"
When call validate_input_python "npm-publish" "scope" "@\$(whoami)"
The status should be failure
End
End
End
