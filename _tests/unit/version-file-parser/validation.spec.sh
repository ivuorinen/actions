#!/usr/bin/env shellspec
# Unit tests for version-file-parser action validation and logic
# Framework is automatically loaded via spec_helper.sh

Describe "version-file-parser action"
  ACTION_DIR="version-file-parser"
  ACTION_FILE="$ACTION_DIR/action.yml"

  Context "when validating language input"
    It "accepts valid language input"
      When call test_input_validation "$ACTION_DIR" "language" "node" "success"
      The status should be success
    End
    It "accepts php language"
      When call test_input_validation "$ACTION_DIR" "language" "php" "success"
      The status should be success
    End
    It "accepts python language"
      When call test_input_validation "$ACTION_DIR" "language" "python" "success"
      The status should be success
    End
    It "accepts go language"
      When call test_input_validation "$ACTION_DIR" "language" "go" "success"
      The status should be success
    End
    It "rejects invalid language with special characters"
      When call test_input_validation "$ACTION_DIR" "language" "node; rm -rf /" "failure"
      The status should be success
    End
    It "rejects empty required inputs"
      When call test_input_validation "$ACTION_DIR" "language" "" "failure"
      The status should be success
    End
  End

  Context "when validating dockerfile-image input"
    It "accepts valid dockerfile image"
      When call test_input_validation "$ACTION_DIR" "dockerfile-image" "node" "success"
      The status should be success
    End
    It "accepts php dockerfile image"
      When call test_input_validation "$ACTION_DIR" "dockerfile-image" "php" "success"
      The status should be success
    End
    It "accepts python dockerfile image"
      When call test_input_validation "$ACTION_DIR" "dockerfile-image" "python" "success"
      The status should be success
    End
    It "rejects injection in dockerfile image"
      When call test_input_validation "$ACTION_DIR" "dockerfile-image" "node;malicious" "failure"
      The status should be success
    End
  End

  Context "when validating optional inputs"
    It "accepts valid validation regex"
      When call test_input_validation "$ACTION_DIR" "validation-regex" "^[0-9]+\.[0-9]+(\.[0-9]+)?$" "success"
      The status should be success
    End
    It "accepts valid default version"
      When call test_input_validation "$ACTION_DIR" "default-version" "18.0.0" "success"
      The status should be success
    End
    It "accepts tool versions key"
      When call test_input_validation "$ACTION_DIR" "tool-versions-key" "nodejs" "success"
      The status should be success
    End
  End

  Context "when checking action.yml structure"
    It "has valid YAML syntax"
      When call validate_action_yml_quiet "$ACTION_FILE"
      The status should be success
    End

    It "contains required metadata"
      When call get_action_name "$ACTION_FILE"
      The output should equal "Version File Parser"
    End

    It "defines expected inputs"
      When call get_action_inputs "$ACTION_FILE"
      The output should include "language"
      The output should include "tool-versions-key"
      The output should include "dockerfile-image"
    End

    It "defines expected outputs"
      When call get_action_outputs "$ACTION_FILE"
      The output should include "detected-version"
      The output should include "package-manager"
    End
  End

  Context "when validating security"
    It "rejects injection in language parameter"
      When call test_input_validation "$ACTION_DIR" "language" "node&&malicious" "failure"
      The status should be success
    End

    It "rejects pipe injection in tool versions key"
      When call test_input_validation "$ACTION_DIR" "tool-versions-key" "nodejs|dangerous" "failure"
      The status should be success
    End

    It "validates regex patterns safely"
      When call test_input_validation "$ACTION_DIR" "validation-regex" "^[0-9]+\.[0-9]+$" "success"
      The status should be success
    End

    It "rejects malicious regex patterns"
      When call test_input_validation "$ACTION_DIR" "validation-regex" ".*; rm -rf /" "failure"
      The status should be success
    End
  End

  Context "when testing outputs"
    It "produces all expected outputs consistently"
      When call test_action_outputs "$ACTION_DIR" "language" "node" "dockerfile-image" "node"
      The status should be success
      The stderr should include "Testing action outputs for: version-file-parser"
      The stderr should include "Output test passed for: version-file-parser"
    End
  End
End
