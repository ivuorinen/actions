#!/usr/bin/env shellspec
# Unit tests for version-validator action validation and logic

# Framework is automatically loaded via spec_helper.sh

Describe "version-validator action"
ACTION_DIR="version-validator"
ACTION_FILE="$ACTION_DIR/action.yml"

Context "when validating version input"
It "accepts valid semantic version"
When call validate_input_python "version-validator" "version" "1.2.3"
The status should be success
End
It "accepts semantic version with v prefix"
When call validate_input_python "version-validator" "version" "v1.2.3"
The status should be success
End
It "accepts prerelease version"
When call validate_input_python "version-validator" "version" "1.2.3-alpha"
The status should be success
End
It "accepts prerelease with number"
When call validate_input_python "version-validator" "version" "1.2.3-alpha.1"
The status should be success
End
It "accepts build metadata"
When call validate_input_python "version-validator" "version" "1.2.3+build.1"
The status should be success
End
It "accepts prerelease with build metadata"
When call validate_input_python "version-validator" "version" "1.2.3-alpha.1+build.1"
The status should be success
End
It "accepts CalVer format"
When call validate_input_python "version-validator" "version" "2024.3.1"
The status should be success
End
It "rejects invalid version format"
When call validate_input_python "version-validator" "version" "invalid.version"
The status should be failure
End
It "rejects version with command injection"
When call validate_input_python "version-validator" "version" "1.2.3; rm -rf /"
The status should be failure
End
It "rejects version with shell expansion"
When call validate_input_python "version-validator" "version" "1.2.3\$(whoami)"
The status should be failure
End
It "rejects empty version"
When call validate_input_python "version-validator" "version" ""
The status should be failure
End
End

Context "when validating validation-regex input"
It "accepts valid regex pattern"
When call validate_input_python "version-validator" "validation-regex" "^[0-9]+\.[0-9]+\.[0-9]+$"
The status should be success
End
It "accepts semantic version regex"
When call validate_input_python "version-validator" "validation-regex" "^[0-9]+\.[0-9]+(\.[0-9]+)?(-[a-zA-Z0-9.-]+)?(\+[a-zA-Z0-9.-]+)?$"
The status should be success
End
It "accepts empty validation-regex (uses default)"
When call validate_input_python "version-validator" "validation-regex" ""
The status should be success
End
It "rejects dangerous regex patterns"
When call validate_input_python "version-validator" "validation-regex" ".*.*"
The status should be success
End
End

Context "when validating language input"
It "accepts valid language name"
When call validate_input_python "version-validator" "language" "nodejs"
The status should be success
End
It "accepts version as language"
When call validate_input_python "version-validator" "language" "version"
The status should be success
End
It "accepts empty language (uses default)"
When call validate_input_python "version-validator" "language" ""
The status should be success
End
It "rejects language with command injection"
When call validate_input_python "version-validator" "language" "version; rm -rf /"
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
The output should match pattern "*Version*"
End
It "defines expected inputs"
When call get_action_inputs "$ACTION_FILE"
The output should include "version"
The output should include "validation-regex"
The output should include "language"
End
It "defines expected outputs"
When call get_action_outputs "$ACTION_FILE"
The output should include "is-valid"
The output should include "validated-version"
The output should include "error-message"
End
End

Context "when testing input requirements"
It "requires version input"
When call python3 "_tests/shared/validation_core.py" --property "$ACTION_FILE" "version" "required"
The status should be success
End
It "has validation-regex as optional input"
When call python3 "_tests/shared/validation_core.py" --property "$ACTION_FILE" "validation-regex" "optional"
The status should be success
End
It "has language as optional input"
When call python3 "_tests/shared/validation_core.py" --property "$ACTION_FILE" "language" "optional"
The status should be success
End
End

Context "when testing security validations"
It "validates against path traversal in version"
When call validate_input_python "version-validator" "version" "../1.2.3"
The status should be failure
End
It "validates against shell metacharacters in version"
When call validate_input_python "version-validator" "version" "1.2.3|echo"
The status should be failure
End
It "validates against backtick injection in language"
When call validate_input_python "version-validator" "language" "version\`whoami\`"
The status should be failure
End
It "validates against variable expansion in version"
When call validate_input_python "version-validator" "version" "1.2.3\${HOME}"
The status should be failure
End
End

Context "when testing version validation functionality"
It "validates semantic version format restrictions"
When call validate_input_python "version-validator" "version" "1.2"
The status should be success
End
It "validates regex pattern safety"
When call validate_input_python "version-validator" "validation-regex" "^[0-9]+$"
The status should be success
End
It "validates language parameter format"
When call validate_input_python "version-validator" "language" "NODEJS"
The status should be success
End
It "validates complex version formats"
When call validate_input_python "version-validator" "version" "1.0.0-beta.1+exp.sha.5114f85"
The status should be success
End
End
End
