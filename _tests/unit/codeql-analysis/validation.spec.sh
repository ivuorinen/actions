#!/usr/bin/env bash

Describe "codeql-analysis validation"
Include "_tests/unit/spec_helper.sh"

Describe "language validation"
It "validates javascript language"
When call validate_input_python "codeql-analysis" "language" "javascript"
The status should be success
End

It "validates typescript language"
When call validate_input_python "codeql-analysis" "language" "typescript"
The status should be success
End

It "validates python language"
When call validate_input_python "codeql-analysis" "language" "python"
The status should be success
End

It "validates java language"
When call validate_input_python "codeql-analysis" "language" "java"
The status should be success
End

It "validates csharp language"
When call validate_input_python "codeql-analysis" "language" "csharp"
The status should be success
End

It "validates cpp language"
When call validate_input_python "codeql-analysis" "language" "cpp"
The status should be success
End

It "validates c language"
When call validate_input_python "codeql-analysis" "language" "c"
The status should be success
End

It "validates go language"
When call validate_input_python "codeql-analysis" "language" "go"
The status should be success
End

It "validates ruby language"
When call validate_input_python "codeql-analysis" "language" "ruby"
The status should be success
End

It "validates swift language"
When call validate_input_python "codeql-analysis" "language" "swift"
The status should be success
End

It "validates kotlin language"
When call validate_input_python "codeql-analysis" "language" "kotlin"
The status should be success
End

It "validates actions language"
When call validate_input_python "codeql-analysis" "language" "actions"
The status should be success
End

It "validates case insensitive languages"
When call validate_input_python "codeql-analysis" "language" "JavaScript"
The status should be success
End

It "rejects invalid language"
When call validate_input_python "codeql-analysis" "language" "invalid-lang"
The status should be failure
End

It "rejects empty language"
When call validate_input_python "codeql-analysis" "language" ""
The status should be failure
End

It "rejects unsupported language"
When call validate_input_python "codeql-analysis" "language" "rust"
The status should be failure
End
End

Describe "queries validation"
It "validates security-extended queries"
When call validate_input_python "codeql-analysis" "queries" "security-extended"
The status should be success
End

It "validates security-and-quality queries"
When call validate_input_python "codeql-analysis" "queries" "security-and-quality"
The status should be success
End

It "validates code-scanning queries"
When call validate_input_python "codeql-analysis" "queries" "code-scanning"
The status should be success
End

It "validates default queries"
When call validate_input_python "codeql-analysis" "queries" "default"
The status should be success
End

It "validates case insensitive queries"
When call validate_input_python "codeql-analysis" "queries" "Security-Extended"
The status should be success
End

It "validates custom query file with .ql extension"
When call validate_input_python "codeql-analysis" "queries" "custom-queries.ql"
The status should be success
End

It "validates custom query suite with .qls extension"
When call validate_input_python "codeql-analysis" "queries" "my-suite.qls"
The status should be success
End

It "validates custom query file with path"
When call validate_input_python "codeql-analysis" "queries" ".github/codeql/custom.ql"
The status should be success
End

It "rejects invalid query suite"
When call validate_input_python "codeql-analysis" "queries" "invalid-suite"
The status should be failure
End

It "rejects empty queries"
When call validate_input_python "codeql-analysis" "queries" ""
The status should be failure
End
End

Describe "category validation"
It "validates proper category format"
When call validate_input_python "codeql-analysis" "category" "/language:javascript"
The status should be success
End

It "validates custom category"
When call validate_input_python "codeql-analysis" "category" "/custom/analysis"
The status should be success
End

It "validates category with underscores"
When call validate_input_python "codeql-analysis" "category" "/my_custom_category"
The status should be success
End

It "validates category with hyphens"
When call validate_input_python "codeql-analysis" "category" "/my-custom-category"
The status should be success
End

It "validates category with colons"
When call validate_input_python "codeql-analysis" "category" "/language:python:custom"
The status should be success
End

It "validates empty category (optional)"
When call validate_input_python "codeql-analysis" "category" ""
The status should be success
End

It "rejects category without leading slash"
When call validate_input_python "codeql-analysis" "category" "language:javascript"
The status should be failure
End

It "rejects category with invalid characters"
When call validate_input_python "codeql-analysis" "category" "/language@javascript"
The status should be failure
End

It "rejects category with spaces"
When call validate_input_python "codeql-analysis" "category" "/language javascript"
The status should be failure
End
End

Describe "config-file validation"
It "validates valid config file path"
When call validate_input_python "codeql-analysis" "config-file" ".github/codeql/config.yml"
The status should be success
End

It "validates relative config file path"
When call validate_input_python "codeql-analysis" "config-file" "codeql-config.yml"
The status should be success
End

It "validates empty config file (optional)"
When call validate_input_python "codeql-analysis" "config-file" ""
The status should be success
End

It "rejects absolute path"
When call validate_input_python "codeql-analysis" "config-file" "/etc/config.yml"
The status should be failure
End

It "rejects path traversal"
When call validate_input_python "codeql-analysis" "config-file" "../config.yml"
The status should be failure
End
End

Describe "checkout-ref validation"
It "validates main branch"
When call validate_input_python "codeql-analysis" "checkout-ref" "main"
The status should be success
End

It "validates feature branch"
When call validate_input_python "codeql-analysis" "checkout-ref" "feature/security-updates"
The status should be success
End

It "validates commit SHA"
When call validate_input_python "codeql-analysis" "checkout-ref" "abc123def456"
The status should be success
End

It "validates tag"
When call validate_input_python "codeql-analysis" "checkout-ref" "v1.2.3"
The status should be success
End

It "validates empty checkout-ref (optional)"
When call validate_input_python "codeql-analysis" "checkout-ref" ""
The status should be success
End
End

Describe "token validation"
It "validates classic GitHub token"
When call validate_input_python "codeql-analysis" "token" "ghp_1234567890abcdef1234567890abcdef1234"
The status should be success
End

It "validates fine-grained token"
When call validate_input_python "codeql-analysis" "token" "github_pat_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
The status should be success
End

It "validates installation token"
When call validate_input_python "codeql-analysis" "token" "ghs_1234567890abcdef1234567890abcdef1234"
The status should be success
End

It "rejects invalid token format"
When call validate_input_python "codeql-analysis" "token" "invalid-token"
The status should be failure
End

It "rejects empty token"
When call validate_input_python "codeql-analysis" "token" ""
The status should be failure
End
End

Describe "working-directory validation"
It "validates current directory"
When call validate_input_python "codeql-analysis" "working-directory" "."
The status should be success
End

It "validates relative directory"
When call validate_input_python "codeql-analysis" "working-directory" "src"
The status should be success
End

It "validates nested directory"
When call validate_input_python "codeql-analysis" "working-directory" "backend/src"
The status should be success
End

It "rejects absolute path"
When call validate_input_python "codeql-analysis" "working-directory" "/home/user/project"
The status should be failure
End

It "rejects path traversal"
When call validate_input_python "codeql-analysis" "working-directory" "../other-project"
The status should be failure
End
End

Describe "upload-results validation"
It "validates true value"
When call validate_input_python "codeql-analysis" "upload-results" "true"
The status should be success
End

It "validates false value"
When call validate_input_python "codeql-analysis" "upload-results" "false"
The status should be success
End

It "rejects uppercase TRUE"
When call validate_input_python "codeql-analysis" "upload-results" "TRUE"
The status should be failure
End

It "rejects uppercase FALSE"
When call validate_input_python "codeql-analysis" "upload-results" "FALSE"
The status should be failure
End

It "rejects invalid boolean"
When call validate_input_python "codeql-analysis" "upload-results" "yes"
The status should be failure
End

It "rejects empty value"
When call validate_input_python "codeql-analysis" "upload-results" ""
The status should be failure
End
End

Describe "complete action validation"
It "validates all required inputs with minimal config"
# Set up environment for the validation
export INPUT_ACTION_TYPE="codeql-analysis"
export INPUT_LANGUAGE="javascript"

When call "${PROJECT_ROOT}/.venv/bin/python3" validate-inputs/validator.py
The status should be success
The stderr should include "All input validation checks passed"
End

It "validates all inputs with full config"
# Set up environment for the validation
export INPUT_ACTION_TYPE="codeql-analysis"
export INPUT_LANGUAGE="python"
export INPUT_QUERIES="security-extended"
export INPUT_CONFIG_FILE=".github/codeql/config.yml"
export INPUT_CATEGORY="/custom/python-analysis"
export INPUT_CHECKOUT_REF="main"
export INPUT_TOKEN="ghp_1234567890abcdef1234567890abcdef1234"
export INPUT_WORKING_DIRECTORY="backend"
export INPUT_UPLOAD_RESULTS="true"

When call "${PROJECT_ROOT}/.venv/bin/python3" validate-inputs/validator.py
The status should be success
The stderr should include "All input validation checks passed"
End

It "fails validation with missing required language"
# Set up environment for the validation
export INPUT_ACTION_TYPE="codeql-analysis"
unset INPUT_LANGUAGE

When call "${PROJECT_ROOT}/.venv/bin/python3" validate-inputs/validator.py
The status should be failure
The stderr should include "Required input 'language' is missing"
End

It "fails validation with invalid language and queries"
# Set up environment for the validation
export INPUT_ACTION_TYPE="codeql-analysis"
export INPUT_LANGUAGE="invalid-lang"
export INPUT_QUERIES="invalid-suite"

When call "${PROJECT_ROOT}/.venv/bin/python3" validate-inputs/validator.py
The status should be failure
The stderr should include "Unsupported CodeQL language"
The stderr should include "Invalid CodeQL query suite"
End
End
End
