#!/usr/bin/env shellspec
# Unit tests for codeql-analysis action validation
# Framework is automatically loaded via spec_helper.sh

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

It "accepts a non-suite token as a custom query reference"
# The kit treats any [A-Za-z0-9._/@-]+ token as a custom query/pack reference,
# so a bare word like "invalid-suite" is a valid custom reference, not a suite error.
When call validate_input_python "codeql-analysis" "queries" "invalid-suite"
The status should be success
End

It "accepts empty queries (optional)"
When call validate_input_python "codeql-analysis" "queries" ""
The status should be success
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

It "accepts category without leading slash"
# The kit's category_format check allows any letters/digits/_./:- string;
# a leading slash is optional, so "language:javascript" is valid.
When call validate_input_python "codeql-analysis" "category" "language:javascript"
The status should be success
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

It "accepts empty token (optional)"
When call validate_input_python "codeql-analysis" "token" ""
The status should be success
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

It "accepts uppercase TRUE (case-insensitive)"
# The kit's boolean check is case-insensitive: "true"/"false" in any case pass.
When call validate_input_python "codeql-analysis" "upload-results" "TRUE"
The status should be success
End

It "accepts uppercase FALSE (case-insensitive)"
When call validate_input_python "codeql-analysis" "upload-results" "FALSE"
The status should be success
End

It "rejects invalid boolean"
When call validate_input_python "codeql-analysis" "upload-results" "yes"
The status should be failure
End

It "accepts empty value (optional)"
When call validate_input_python "codeql-analysis" "upload-results" ""
The status should be success
End
End

Describe "complete action validation"
It "validates the required language input with minimal config"
When call validate_input_python "codeql-analysis" "language" "javascript"
The status should be success
End

It "validates inputs from a full config (language)"
When call validate_input_python "codeql-analysis" "language" "python"
The status should be success
End

It "validates inputs from a full config (config-file)"
When call validate_input_python "codeql-analysis" "config-file" ".github/codeql/config.yml"
The status should be success
End

It "validates inputs from a full config (token)"
When call validate_input_python "codeql-analysis" "token" "ghp_1234567890abcdef1234567890abcdef1234"
The status should be success
End

It "fails validation with missing required language"
When call validate_input_python "codeql-analysis" "language" ""
The status should be failure
End

It "fails validation with invalid language"
When call validate_input_python "codeql-analysis" "language" "invalid-lang"
The status should be failure
End
End
End
