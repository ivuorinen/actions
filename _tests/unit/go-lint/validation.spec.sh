#!/usr/bin/env shellspec
# Unit tests for go-lint action validation and logic

# Framework is automatically loaded via spec_helper.sh

Describe "go-lint action"
  ACTION_DIR="go-lint"
  ACTION_FILE="$ACTION_DIR/action.yml"

  Context "when validating working-directory input"
    It "accepts current directory"
      When call test_input_validation "$ACTION_DIR" "working-directory" "." "success"
      The status should be success
    End

    It "accepts relative directory path"
      When call test_input_validation "$ACTION_DIR" "working-directory" "src/main" "success"
      The status should be success
    End

    It "rejects path traversal"
      When call test_input_validation "$ACTION_DIR" "working-directory" "../src" "failure"
      The status should be success
    End

    It "rejects absolute path"
      When call test_input_validation "$ACTION_DIR" "working-directory" "/usr/src" "failure"
      The status should be success
    End
  End

  Context "when validating golangci-lint-version input"
    It "accepts latest version"
      When call test_input_validation "$ACTION_DIR" "golangci-lint-version" "latest" "success"
      The status should be success
    End

    It "accepts semantic version"
      When call test_input_validation "$ACTION_DIR" "golangci-lint-version" "1.55.2" "success"
      The status should be success
    End

    It "accepts semantic version with v prefix"
      When call test_input_validation "$ACTION_DIR" "golangci-lint-version" "v1.55.2" "success"
      The status should be success
    End

    It "rejects invalid version format"
      When call test_input_validation "$ACTION_DIR" "golangci-lint-version" "invalid-version" "failure"
      The status should be success
    End
  End

  Context "when validating go-version input"
    It "accepts stable version"
      When call test_input_validation "$ACTION_DIR" "go-version" "stable" "success"
      The status should be success
    End

    It "accepts major.minor version"
      When call test_input_validation "$ACTION_DIR" "go-version" "1.21" "success"
      The status should be success
    End

    It "accepts full semantic version"
      When call test_input_validation "$ACTION_DIR" "go-version" "1.21.5" "success"
      The status should be success
    End

    It "rejects invalid Go version"
      When call test_input_validation "$ACTION_DIR" "go-version" "go1.21" "failure"
      The status should be success
    End
  End

  Context "when validating config-file input"
    It "accepts default config file"
      When call test_input_validation "$ACTION_DIR" "config-file" ".golangci.yml" "success"
      The status should be success
    End

    It "accepts custom config file path"
      When call test_input_validation "$ACTION_DIR" "config-file" "configs/golangci.yaml" "success"
      The status should be success
    End

    It "rejects path traversal in config file"
      When call test_input_validation "$ACTION_DIR" "config-file" "../configs/golangci.yml" "failure"
      The status should be success
    End
  End

  Context "when validating timeout input"
    It "accepts timeout in minutes"
      When call test_input_validation "$ACTION_DIR" "timeout" "5m" "success"
      The status should be success
    End

    It "accepts timeout in seconds"
      When call test_input_validation "$ACTION_DIR" "timeout" "300s" "success"
      The status should be success
    End

    It "accepts timeout in hours"
      When call test_input_validation "$ACTION_DIR" "timeout" "1h" "success"
      The status should be success
    End

    It "rejects timeout without unit"
      When call test_input_validation "$ACTION_DIR" "timeout" "300" "failure"
      The status should be success
    End

    It "rejects invalid timeout format"
      When call test_input_validation "$ACTION_DIR" "timeout" "5 minutes" "failure"
      The status should be success
    End
  End

  Context "when validating boolean inputs"
    It "accepts true for cache"
      When call test_input_validation "$ACTION_DIR" "cache" "true" "success"
      The status should be success
    End

    It "accepts false for cache"
      When call test_input_validation "$ACTION_DIR" "cache" "false" "success"
      The status should be success
    End

    It "rejects invalid boolean for fail-on-error"
      When call test_input_validation "$ACTION_DIR" "fail-on-error" "maybe" "failure"
      The status should be success
    End

    It "accepts true for only-new-issues"
      When call test_input_validation "$ACTION_DIR" "only-new-issues" "true" "success"
      The status should be success
    End

    It "accepts false for disable-all"
      When call test_input_validation "$ACTION_DIR" "disable-all" "false" "success"
      The status should be success
    End
  End

  Context "when validating report-format input"
    It "accepts sarif format"
      When call test_input_validation "$ACTION_DIR" "report-format" "sarif" "success"
      The status should be success
    End

    It "accepts json format"
      When call test_input_validation "$ACTION_DIR" "report-format" "json" "success"
      The status should be success
    End

    It "accepts github-actions format"
      When call test_input_validation "$ACTION_DIR" "report-format" "github-actions" "success"
      The status should be success
    End

    It "rejects invalid report format"
      When call test_input_validation "$ACTION_DIR" "report-format" "invalid-format" "failure"
      The status should be success
    End
  End

  Context "when validating max-retries input"
    It "accepts valid retry count"
      When call test_input_validation "$ACTION_DIR" "max-retries" "3" "success"
      The status should be success
    End

    It "accepts minimum retry count"
      When call test_input_validation "$ACTION_DIR" "max-retries" "1" "success"
      The status should be success
    End

    It "accepts maximum retry count"
      When call test_input_validation "$ACTION_DIR" "max-retries" "10" "success"
      The status should be success
    End

    It "rejects retry count below minimum"
      When call test_input_validation "$ACTION_DIR" "max-retries" "0" "failure"
      The status should be success
    End

    It "rejects retry count above maximum"
      When call test_input_validation "$ACTION_DIR" "max-retries" "15" "failure"
      The status should be success
    End
  End

  Context "when validating linter lists"
    It "accepts valid enable-linters list"
      When call test_input_validation "$ACTION_DIR" "enable-linters" "gosec,govet,staticcheck" "success"
      The status should be success
    End

    It "accepts single linter in enable-linters"
      When call test_input_validation "$ACTION_DIR" "enable-linters" "gosec" "success"
      The status should be success
    End

    It "accepts valid disable-linters list"
      When call test_input_validation "$ACTION_DIR" "disable-linters" "exhaustivestruct,interfacer" "success"
      The status should be success
    End

    It "rejects invalid linter list format"
      When call test_input_validation "$ACTION_DIR" "enable-linters" "gosec, govet" "failure"
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
      When call test_input_validation "$ACTION_DIR" "working-directory" "src; rm -rf /" "failure"
      The status should be success
    End

    It "validates against command injection in config-file"
      When call test_input_validation "$ACTION_DIR" "config-file" "config.yml\$(whoami)" "failure"
      The status should be success
    End

    It "validates against shell expansion in enable-linters"
      When call test_input_validation "$ACTION_DIR" "enable-linters" "gosec,\$(echo malicious)" "failure"
      The status should be success
    End
  End
End
