#!/usr/bin/env shellspec
# Unit tests for docker-publish action validation and logic

# Framework is automatically loaded via spec_helper.sh

Describe "docker-publish action"
ACTION_DIR="docker-publish"
ACTION_FILE="$ACTION_DIR/action.yml"

Context "when validating inputs"
It "accepts valid registry"
When call validate_input_python "docker-publish" "registry" "dockerhub"
The status should be success
End
It "accepts github registry"
When call validate_input_python "docker-publish" "registry" "github"
The status should be success
End
It "accepts both registry"
When call validate_input_python "docker-publish" "registry" "both"
The status should be success
End
It "rejects empty registry input"
When call validate_input_python "docker-publish" "registry" ""
The status should be failure
End
It "accepts boolean values for nightly"
When call validate_input_python "docker-publish" "nightly" "true"
The status should be success
End
It "accepts valid platforms format"
When call validate_input_python "docker-publish" "platforms" "linux/amd64,linux/arm64"
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
