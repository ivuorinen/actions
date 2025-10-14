#!/usr/bin/env shellspec
# Unit tests for go-lint action validation and logic

# Framework is automatically loaded via spec_helper.sh

Describe "go-lint action"
ACTION_DIR="go-lint"
ACTION_FILE="$ACTION_DIR/action.yml"

Context "when validating working-directory input"
It "accepts current directory"
When call validate_input_python "go-lint" "working-directory" "."
The status should be success
End

It "accepts relative directory path"
When call validate_input_python "go-lint" "working-directory" "src/main"
The status should be success
End

It "rejects path traversal"
When call validate_input_python "go-lint" "working-directory" "../src"
The status should be failure
End

It "rejects absolute path"
When call validate_input_python "go-lint" "working-directory" "/usr/src"
The status should be failure
End
End

Context "when validating golangci-lint-version input"
It "accepts latest version"
When call validate_input_python "go-lint" "golangci-lint-version" "latest"
The status should be success
End

It "accepts semantic version"
When call validate_input_python "go-lint" "golangci-lint-version" "1.55.2"
The status should be success
End

It "accepts semantic version with v prefix"
When call validate_input_python "go-lint" "golangci-lint-version" "v1.55.2"
The status should be success
End

It "rejects invalid version format"
When call validate_input_python "go-lint" "golangci-lint-version" "invalid-version"
The status should be failure
End
End

Context "when validating go-version input"
It "accepts stable version"
When call validate_input_python "go-lint" "go-version" "stable"
The status should be success
End

It "accepts major.minor version"
When call validate_input_python "go-lint" "go-version" "1.21"
The status should be success
End

It "accepts full semantic version"
When call validate_input_python "go-lint" "go-version" "1.21.5"
The status should be success
End

It "rejects invalid Go version"
When call validate_input_python "go-lint" "go-version" "go1.21"
The status should be failure
End
End

Context "when validating config-file input"
It "accepts default config file"
When call validate_input_python "go-lint" "config-file" ".golangci.yml"
The status should be success
End

It "accepts custom config file path"
When call validate_input_python "go-lint" "config-file" "configs/golangci.yaml"
The status should be success
End

It "rejects path traversal in config file"
When call validate_input_python "go-lint" "config-file" "../configs/golangci.yml"
The status should be failure
End
End

Context "when validating timeout input"
It "accepts timeout in minutes"
When call validate_input_python "go-lint" "timeout" "5m"
The status should be success
End

It "accepts timeout in seconds"
When call validate_input_python "go-lint" "timeout" "300s"
The status should be success
End

It "accepts timeout in hours"
When call validate_input_python "go-lint" "timeout" "1h"
The status should be success
End

It "rejects timeout without unit"
When call validate_input_python "go-lint" "timeout" "300"
The status should be failure
End

It "rejects invalid timeout format"
When call validate_input_python "go-lint" "timeout" "5 minutes"
The status should be failure
End
End

Context "when validating boolean inputs"
It "accepts true for cache"
When call validate_input_python "go-lint" "cache" "true"
The status should be success
End

It "accepts false for cache"
When call validate_input_python "go-lint" "cache" "false"
The status should be success
End

It "rejects invalid boolean for fail-on-error"
When call validate_input_python "go-lint" "fail-on-error" "maybe"
The status should be failure
End

It "accepts true for only-new-issues"
When call validate_input_python "go-lint" "only-new-issues" "true"
The status should be success
End

It "accepts false for disable-all"
When call validate_input_python "go-lint" "disable-all" "false"
The status should be success
End
End

Context "when validating report-format input"
It "accepts sarif format"
When call validate_input_python "go-lint" "report-format" "sarif"
The status should be success
End

It "accepts json format"
When call validate_input_python "go-lint" "report-format" "json"
The status should be success
End

It "accepts github-actions format"
When call validate_input_python "go-lint" "report-format" "github-actions"
The status should be success
End

It "rejects invalid report format"
When call validate_input_python "go-lint" "report-format" "invalid-format"
The status should be failure
End
End

Context "when validating max-retries input"
It "accepts valid retry count"
When call validate_input_python "go-lint" "max-retries" "3"
The status should be success
End

It "accepts minimum retry count"
When call validate_input_python "go-lint" "max-retries" "1"
The status should be success
End

It "accepts maximum retry count"
When call validate_input_python "go-lint" "max-retries" "10"
The status should be success
End

It "rejects retry count below minimum"
When call validate_input_python "go-lint" "max-retries" "0"
The status should be failure
End

It "rejects retry count above maximum"
When call validate_input_python "go-lint" "max-retries" "15"
The status should be failure
End
End

Context "when validating linter lists"
It "accepts valid enable-linters list"
When call validate_input_python "go-lint" "enable-linters" "gosec,govet,staticcheck"
The status should be success
End

It "accepts single linter in enable-linters"
When call validate_input_python "go-lint" "enable-linters" "gosec"
The status should be success
End

It "accepts valid disable-linters list"
When call validate_input_python "go-lint" "disable-linters" "exhaustivestruct,interfacer"
The status should be success
End

It "rejects invalid linter list format"
When call validate_input_python "go-lint" "enable-linters" "gosec, govet"
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
The output should equal "Go Lint Check"
End

It "defines expected outputs"
When call get_action_outputs "$ACTION_FILE"
The output should include "error-count"
The output should include "sarif-file"
The output should include "cache-hit"
The output should include "analyzed-files"
End
End

Context "when testing security validations"
It "validates against command injection in working-directory"
When call validate_input_python "go-lint" "working-directory" "src; rm -rf /"
The status should be failure
End

It "validates against command injection in config-file"
When call validate_input_python "go-lint" "config-file" "config.yml\$(whoami)"
The status should be failure
End

It "validates against shell expansion in enable-linters"
When call validate_input_python "go-lint" "enable-linters" "gosec,\$(echo malicious)"
The status should be failure
End
End
End
