#!/usr/bin/env shellspec
# Unit tests for common-cache action validation and logic

# Framework is automatically loaded via spec_helper.sh

Describe "common-cache action"
  ACTION_DIR="common-cache"
  ACTION_FILE="$ACTION_DIR/action.yml"

  Context "when validating cache type input"
    It "accepts npm cache type"
      When call test_input_validation "$ACTION_DIR" "type" "npm" "success"
      The status should be success
    End
    It "accepts composer cache type"
      When call test_input_validation "$ACTION_DIR" "type" "composer" "success"
      The status should be success
    End
    It "accepts go cache type"
      When call test_input_validation "$ACTION_DIR" "type" "go" "success"
      The status should be success
    End
    It "accepts pip cache type"
      When call test_input_validation "$ACTION_DIR" "type" "pip" "success"
      The status should be success
    End
    It "accepts maven cache type"
      When call test_input_validation "$ACTION_DIR" "type" "maven" "success"
      The status should be success
    End
    It "accepts gradle cache type"
      When call test_input_validation "$ACTION_DIR" "type" "gradle" "success"
      The status should be success
    End
    It "rejects empty cache type"
      When call test_input_validation "$ACTION_DIR" "type" "" "failure"
      The status should be success
    End
    It "accepts invalid cache type (no validation in action)"
      When call test_input_validation "$ACTION_DIR" "type" "invalid-type" "success"
      The status should be success
    End
  End

  Context "when validating paths input"
    It "accepts single path"
      When call test_input_validation "$ACTION_DIR" "paths" "node_modules" "success"
      The status should be success
    End
    It "accepts multiple paths"
      When call test_input_validation "$ACTION_DIR" "paths" "node_modules,dist,build" "success"
      The status should be success
    End
    It "rejects empty paths"
      When call test_input_validation "$ACTION_DIR" "paths" "" "failure"
      The status should be success
    End
    It "rejects path traversal"
      When call test_input_validation "$ACTION_DIR" "paths" "../../../etc/passwd" "failure"
      The status should be success
    End
    It "rejects command injection in paths"
      When call test_input_validation "$ACTION_DIR" "paths" "node_modules;rm -rf /" "failure"
      The status should be success
    End
  End

  Context "when validating key-prefix input"
    It "accepts valid key prefix"
      When call test_input_validation "$ACTION_DIR" "key-prefix" "v2-build" "success"
      The status should be success
    End
    It "rejects command injection in key-prefix"
      When call test_input_validation "$ACTION_DIR" "key-prefix" "v2&&malicious" "failure"
      The status should be success
    End
  End

  Context "when validating key-files input"
    It "accepts single key file"
      When call test_input_validation "$ACTION_DIR" "key-files" "package.json" "success"
      The status should be success
    End
    It "accepts multiple key files"
      When call test_input_validation "$ACTION_DIR" "key-files" "package.json,package-lock.json,yarn.lock" "success"
      The status should be success
    End
    It "rejects path traversal in key-files"
      When call test_input_validation "$ACTION_DIR" "key-files" "../../../sensitive.json" "failure"
      The status should be success
    End
  End

  Context "when validating restore-keys input"
    It "accepts valid restore keys format"
      When call test_input_validation "$ACTION_DIR" "restore-keys" "Linux-npm-,Linux-" "success"
      The status should be success
    End
    It "rejects malicious restore keys"
      When call test_input_validation "$ACTION_DIR" "restore-keys" "Linux-npm-;rm -rf /" "failure"
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
      The output should equal "Common Cache"
    End

    It "defines required inputs"
      inputs=$(get_action_inputs "$ACTION_FILE")
      When call echo "$inputs"
      The output should include "type"
      The output should include "paths"
    End

    It "defines optional inputs"
      inputs=$(get_action_inputs "$ACTION_FILE")
      When call echo "$inputs"
      The output should include "key-prefix"
      The output should include "key-files"
      The output should include "restore-keys"
      The output should include "env-vars"
    End

    It "defines expected outputs"
      outputs=$(get_action_outputs "$ACTION_FILE")
      When call echo "$outputs"
      The output should include "cache-hit"
      The output should include "cache-key"
      The output should include "cache-paths"
    End
  End

  Context "when validating security"
    It "rejects injection in all input types"
      When call test_input_validation "$ACTION_DIR" "type" "npm;malicious" "failure"
      The status should be success
    End

    It "validates environment variable names safely"
      When call test_input_validation "$ACTION_DIR" "env-vars" "NODE_ENV,CI" "success"
      The status should be success
    End

    It "rejects injection in environment variables"
      When call test_input_validation "$ACTION_DIR" "env-vars" "NODE_ENV;rm -rf /" "failure"
      The status should be success
    End
  End

  Context "when testing outputs"
    It "produces all expected outputs consistently"
      When call test_action_outputs "$ACTION_DIR" "type" "npm" "paths" "node_modules"
      The status should be success
      The stderr should include "Testing action outputs for: common-cache"
      The stderr should include "Output test passed for: common-cache"
    End
  End
End
