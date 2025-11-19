#!/usr/bin/env shellspec
# Unit tests for language-version-detect action validation and logic
# Framework is automatically loaded via spec_helper.sh

Describe "language-version-detect action"
ACTION_DIR="language-version-detect"
ACTION_FILE="$ACTION_DIR/action.yml"

Context "when validating language input"
It "accepts php language"
When call validate_input_python "language-version-detect" "language" "php"
The status should be success
End

It "accepts python language"
When call validate_input_python "language-version-detect" "language" "python"
The status should be success
End

It "accepts go language"
When call validate_input_python "language-version-detect" "language" "go"
The status should be success
End

It "accepts dotnet language"
When call validate_input_python "language-version-detect" "language" "dotnet"
The status should be success
End

It "rejects invalid language"
When call validate_input_python "language-version-detect" "language" "javascript"
The status should be failure
End

It "rejects empty language (required)"
When call validate_input_python "language-version-detect" "language" ""
The status should be failure
End

It "rejects language with command injection"
When call validate_input_python "language-version-detect" "language" "php; rm -rf /"
The status should be failure
End

It "rejects language with shell metacharacters"
When call validate_input_python "language-version-detect" "language" "php|echo"
The status should be failure
End
End

Context "when validating default-version input for PHP"
It "accepts valid PHP version 8.4"
When call validate_input_python "language-version-detect" "default-version" "8.4"
The status should be success
End

It "accepts valid PHP version 8.3"
When call validate_input_python "language-version-detect" "default-version" "8.3"
The status should be success
End

It "accepts valid PHP version 7.4"
When call validate_input_python "language-version-detect" "default-version" "7.4"
The status should be success
End

It "accepts valid PHP version with patch 8.3.1"
When call validate_input_python "language-version-detect" "default-version" "8.3.1"
The status should be success
End

It "accepts empty default-version (uses language default)"
When call validate_input_python "language-version-detect" "default-version" ""
The status should be success
End

It "rejects invalid PHP version format"
When call validate_input_python "language-version-detect" "default-version" "invalid"
The status should be failure
End
End

Context "when validating default-version input for Python"
It "accepts valid Python version 3.12"
When call validate_input_python "language-version-detect" "default-version" "3.12"
The status should be success
End

It "accepts valid Python version 3.11"
When call validate_input_python "language-version-detect" "default-version" "3.11"
The status should be success
End

It "accepts valid Python version 3.10"
When call validate_input_python "language-version-detect" "default-version" "3.10"
The status should be success
End

It "accepts valid Python version with patch 3.12.1"
When call validate_input_python "language-version-detect" "default-version" "3.12.1"
The status should be success
End

It "accepts valid Python version 3.9"
When call validate_input_python "language-version-detect" "default-version" "3.9"
The status should be success
End

It "accepts valid Python version 3.8"
When call validate_input_python "language-version-detect" "default-version" "3.8"
The status should be success
End
End

Context "when validating default-version input for Go"
It "accepts valid Go version 1.21"
When call validate_input_python "language-version-detect" "default-version" "1.21"
The status should be success
End

It "accepts valid Go version 1.20"
When call validate_input_python "language-version-detect" "default-version" "1.20"
The status should be success
End

It "accepts valid Go version with patch 1.21.5"
When call validate_input_python "language-version-detect" "default-version" "1.21.5"
The status should be success
End

It "accepts valid Go version 1.22"
When call validate_input_python "language-version-detect" "default-version" "1.22"
The status should be success
End
End

Context "when validating default-version input for .NET"
It "accepts valid .NET version 7.0"
When call validate_input_python "language-version-detect" "default-version" "7.0"
The status should be success
End

It "accepts valid .NET version 8.0"
When call validate_input_python "language-version-detect" "default-version" "8.0"
The status should be success
End

It "accepts valid .NET version 6.0"
When call validate_input_python "language-version-detect" "default-version" "6.0"
The status should be success
End

It "accepts valid .NET version with patch 7.0.1"
When call validate_input_python "language-version-detect" "default-version" "7.0.1"
The status should be success
End

It "accepts valid .NET major version 7"
When call validate_input_python "language-version-detect" "default-version" "7"
The status should be success
End
End

Context "when validating default-version input edge cases"
It "rejects version with v prefix"
When call validate_input_python "language-version-detect" "default-version" "v3.12"
The status should be failure
End

It "rejects version with command injection"
When call validate_input_python "language-version-detect" "default-version" "3.12; rm -rf /"
The status should be failure
End

It "rejects version with shell metacharacters"
When call validate_input_python "language-version-detect" "default-version" "3.12|echo"
The status should be failure
End

It "rejects version with command substitution"
When call validate_input_python "language-version-detect" "default-version" "\$(whoami)"
The status should be failure
End

It "rejects alphabetic version"
When call validate_input_python "language-version-detect" "default-version" "latest"
The status should be failure
End
End

Context "when validating token input"
It "accepts valid GitHub token (classic)"
When call validate_input_python "language-version-detect" "token" "ghp_123456789012345678901234567890123456"
The status should be success
End

It "accepts valid GitHub fine-grained token"
When call validate_input_python "language-version-detect" "token" "github_pat_1234567890123456789012345678901234567890123456789012345678901234567890a"
The status should be success
End

It "accepts empty token (optional)"
When call validate_input_python "language-version-detect" "token" ""
The status should be success
End

It "rejects invalid token format"
When call validate_input_python "language-version-detect" "token" "invalid-token"
The status should be failure
End

It "rejects token with command injection"
When call validate_input_python "language-version-detect" "token" "ghp_123456789012345678901234567890123456; rm -rf /"
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
The output should equal "Language Version Detect"
End

It "defines expected inputs"
When call get_action_inputs "$ACTION_FILE"
The output should include "language"
The output should include "default-version"
The output should include "token"
End

It "defines expected outputs"
When call get_action_outputs "$ACTION_FILE"
The output should include "detected-version"
The output should include "package-manager"
End
End

Context "when testing input requirements"
It "requires language input"
When call is_input_required "$ACTION_FILE" "language"
The status should be success
End

It "has default-version as optional input"
When call is_input_required "$ACTION_FILE" "default-version"
The status should be failure
End

It "has token as optional input"
When call is_input_required "$ACTION_FILE" "token"
The status should be failure
End
End

Context "when testing security validations"
It "validates against path traversal in language"
When call validate_input_python "language-version-detect" "language" "../../../etc"
The status should be failure
End

It "validates against shell metacharacters in language"
When call validate_input_python "language-version-detect" "language" "php&whoami"
The status should be failure
End

It "validates against command substitution in language"
When call validate_input_python "language-version-detect" "language" "php\`whoami\`"
The status should be failure
End

It "validates against path traversal in default-version"
When call validate_input_python "language-version-detect" "default-version" "../../../etc"
The status should be failure
End

It "validates against shell metacharacters in default-version"
When call validate_input_python "language-version-detect" "default-version" "3.12&echo"
The status should be failure
End

It "validates against command substitution in default-version"
When call validate_input_python "language-version-detect" "default-version" "3.12\$(whoami)"
The status should be failure
End

It "validates against path traversal in token"
When call validate_input_python "language-version-detect" "token" "../../../etc/passwd"
The status should be failure
End
End
End
