#!/usr/bin/env shellspec
# Unit tests for version-file-parser action validation and logic
# Framework is automatically loaded via spec_helper.sh

Describe "version-file-parser action"
  ACTION_DIR="version-file-parser"
  ACTION_FILE="$ACTION_DIR/action.yml"

  Context "when validating language input"
    It "accepts valid language input"
      When call validate_input_python "version-file-parser" "language" "node"
      The status should be success
    End
    It "accepts php language"
      When call validate_input_python "version-file-parser" "language" "php"
      The status should be success
    End
    It "accepts python language"
      When call validate_input_python "version-file-parser" "language" "python"
      The status should be success
    End
    It "accepts go language"
      When call validate_input_python "version-file-parser" "language" "go"
      The status should be success
    End
    It "rejects invalid language with special characters"
      When call validate_input_python "version-file-parser" "language" "node; rm -rf /"
      The status should be failure
    End
    It "rejects empty required inputs"
      When call validate_input_python "version-file-parser" "language" ""
      The status should be failure
    End
  End

  Context "when validating dockerfile-image input"
    It "accepts valid dockerfile image"
      When call validate_input_python "version-file-parser" "dockerfile-image" "node"
      The status should be success
    End
    It "accepts php dockerfile image"
      When call validate_input_python "version-file-parser" "dockerfile-image" "php"
      The status should be success
    End
    It "accepts python dockerfile image"
      When call validate_input_python "version-file-parser" "dockerfile-image" "python"
      The status should be success
    End
    It "rejects injection in dockerfile image"
      When call validate_input_python "version-file-parser" "dockerfile-image" "node;malicious"
      The status should be failure
    End
  End

  Context "when validating optional inputs"
    It "accepts valid validation regex"
      When call validate_input_python "version-file-parser" "validation-regex" "^[0-9]+\.[0-9]+(\.[0-9]+)?$"
      The status should be success
    End
    It "accepts valid default version"
      When call validate_input_python "version-file-parser" "default-version" "18.0.0"
      The status should be success
    End
    It "accepts tool versions key"
      When call validate_input_python "version-file-parser" "tool-versions-key" "nodejs"
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
      When call validate_input_python "version-file-parser" "language" "node&&malicious"
      The status should be failure
    End

    It "rejects pipe injection in tool versions key"
      When call validate_input_python "version-file-parser" "tool-versions-key" "nodejs|dangerous"
      The status should be failure
    End

    It "validates regex patterns safely"
      When call validate_input_python "version-file-parser" "validation-regex" "^[0-9]+\.[0-9]+$"
      The status should be success
    End

    It "rejects malicious regex patterns"
      When call validate_input_python "version-file-parser" "validation-regex" ".*; rm -rf /"
      The status should be failure
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
