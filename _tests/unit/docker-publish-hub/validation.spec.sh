#!/usr/bin/env shellspec
# Unit tests for docker-publish-hub action validation and logic

# Framework is automatically loaded via spec_helper.sh

Describe "docker-publish-hub action"
  ACTION_DIR="docker-publish-hub"
  ACTION_FILE="$ACTION_DIR/action.yml"

  Context "when validating inputs"
    It "accepts valid image name"
      When call test_input_validation "$ACTION_DIR" "image-name" "myapp" "success"
      The status should be success
    End
    It "accepts valid username"
      When call test_input_validation "$ACTION_DIR" "username" "dockeruser" "success"
      The status should be success
    End
    It "accepts valid password"
      When call test_input_validation "$ACTION_DIR" "password" "secretpassword123" "success"
      The status should be success
    End
    It "accepts valid tag"
      When call test_input_validation "$ACTION_DIR" "tag" "v1.0.0" "success"
      The status should be success
    End
    It "rejects injection in username"
      When call test_input_validation "$ACTION_DIR" "username" "user;malicious" "failure"
      The status should be success
    End
    It "rejects injection in password"
      When call test_input_validation "$ACTION_DIR" "password" "pass;rm -rf /" "failure"
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
      The output should match pattern "*Docker*"
    End
  End
End
