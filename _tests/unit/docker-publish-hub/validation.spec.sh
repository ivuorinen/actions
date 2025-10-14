#!/usr/bin/env shellspec
# Unit tests for docker-publish-hub action validation and logic

# Framework is automatically loaded via spec_helper.sh

Describe "docker-publish-hub action"
ACTION_DIR="docker-publish-hub"
ACTION_FILE="$ACTION_DIR/action.yml"

Context "when validating inputs"
It "accepts valid image name"
When call validate_input_python "docker-publish-hub" "image-name" "myapp"
The status should be success
End
It "accepts valid username"
When call validate_input_python "docker-publish-hub" "username" "dockeruser"
The status should be success
End
It "accepts valid password"
When call validate_input_python "docker-publish-hub" "password" "secretpassword123"
The status should be success
End
It "accepts valid tags"
When call validate_input_python "docker-publish-hub" "tags" "v1.0.0,latest"
The status should be success
End
It "rejects injection in username"
When call validate_input_python "docker-publish-hub" "username" "user;malicious"
The status should be failure
End
It "rejects injection in password"
When call validate_input_python "docker-publish-hub" "password" "pass;rm -rf /"
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
The output should match pattern "*Docker*"
End
End
End
