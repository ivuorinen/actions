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
It "accepts empty registry input (optional)"
# registry is optional and not required; the kit's enum check skips empty values.
When call validate_input_python "docker-publish" "registry" ""
The status should be success
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

Context "when validating context input"
It "accepts the default context"
When call validate_input_python "docker-publish" "context" "."
The status should be success
End
It "accepts a relative context"
When call validate_input_python "docker-publish" "context" "./app"
The status should be success
End
It "rejects an absolute context"
When call validate_input_python "docker-publish" "context" "/etc"
The status should be failure
End
It "rejects a remote URL context"
When call validate_input_python "docker-publish" "context" "https://example.com/repo.git"
The status should be failure
End
It "rejects an scp-style Git context"
When call validate_input_python "docker-publish" "context" "git@example.com:org/repo.git"
The status should be failure
End
It "rejects a bare github.com Git context"
When call validate_input_python "docker-publish" "context" "github.com/org/repo"
The status should be failure
End
End

Context "when validating dockerfile input"
It "accepts a relative dockerfile"
When call validate_input_python "docker-publish" "dockerfile" "docker/Dockerfile.prod"
The status should be success
End
It "rejects path traversal"
When call validate_input_python "docker-publish" "dockerfile" "../Dockerfile"
The status should be failure
End
It "rejects a remote dockerfile"
When call validate_input_python "docker-publish" "dockerfile" "https://example.com/Dockerfile"
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
