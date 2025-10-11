#!/usr/bin/env shellspec
# Unit tests for docker-publish-gh action validation and logic

# Framework is automatically loaded via spec_helper.sh

Describe "docker-publish-gh action"
ACTION_DIR="docker-publish-gh"
ACTION_FILE="$ACTION_DIR/action.yml"

Context "when validating inputs"
It "accepts valid image name"
When call validate_input_python "docker-publish-gh" "image-name" "myapp"
The status should be success
End
It "accepts valid GitHub token"
When call validate_input_python "docker-publish-gh" "token" "ghp_123456789012345678901234567890123456"
The status should be success
End
It "accepts valid tags"
When call validate_input_python "docker-publish-gh" "tags" "v1.0.0,latest"
The status should be success
End
It "rejects injection in token"
When call validate_input_python "docker-publish-gh" "token" "ghp_123;malicious"
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
