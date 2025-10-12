#!/usr/bin/env shellspec
# Unit tests for docker-build action validation and logic
# Framework is automatically loaded via spec_helper.sh

Describe "docker-build action"
ACTION_DIR="docker-build"
ACTION_FILE="$ACTION_DIR/action.yml"

Context "when validating image-name input"
It "accepts valid image name"
When call validate_input_python "docker-build" "image-name" "myapp"
The status should be success
End
It "accepts image name with registry prefix"
When call validate_input_python "docker-build" "image-name" "registry.example.com/myapp"
The status should be success
End
It "rejects command injection in image name"
When call validate_input_python "docker-build" "image-name" "app; rm -rf /"
The status should be failure
End
End

Context "when validating tag input"
It "accepts valid tag format"
When call validate_input_python "docker-build" "tag" "v1.0.0"
The status should be success
End
It "accepts semantic version tag"
When call validate_input_python "docker-build" "tag" "1.2.3"
The status should be success
End
It "accepts latest tag"
When call validate_input_python "docker-build" "tag" "latest"
The status should be success
End
It "rejects invalid tag format"
When call validate_input_python "docker-build" "tag" "invalid_tag!"
The status should be failure
End
End

Context "when validating architectures input"
It "accepts valid architectures list"
When call validate_input_python "docker-build" "architectures" "linux/amd64,linux/arm64"
The status should be success
End
It "accepts single architecture"
When call validate_input_python "docker-build" "architectures" "linux/amd64"
The status should be success
End
It "accepts ARM variants"
When call validate_input_python "docker-build" "architectures" "linux/arm/v7,linux/arm/v6"
The status should be success
End
End

Context "when validating dockerfile input"
It "accepts valid dockerfile path"
When call validate_input_python "docker-build" "dockerfile" "Dockerfile"
The status should be success
End
It "accepts custom dockerfile path"
When call validate_input_python "docker-build" "dockerfile" "docker/Dockerfile.prod"
The status should be success
End
It "rejects malicious dockerfile path"
When call validate_input_python "docker-build" "dockerfile" "../../../etc/passwd"
The status should be failure
End
End

Context "when validating context input"
It "accepts valid build context"
When call validate_input_python "docker-build" "context" "."
The status should be success
End
It "accepts relative context path"
When call validate_input_python "docker-build" "context" "src/app"
The status should be success
End
It "accepts path traversal in context (no validation in action)"
When call validate_input_python "docker-build" "context" "../../../etc"
The status should be success
End
End

Context "when validating build-args input"
It "accepts valid build args format"
When call validate_input_python "docker-build" "build-args" "NODE_ENV=production,VERSION=1.0.0"
The status should be success
End
It "accepts empty build args"
When call validate_input_python "docker-build" "build-args" ""
The status should be success
End
It "rejects malicious build args"
When call validate_input_python "docker-build" "build-args" "ARG=\$(rm -rf /)"
The status should be failure
End
End

Context "when validating cache inputs"
It "accepts valid cache mode"
When call validate_input_python "docker-build" "cache-mode" "max"
The status should be success
End
It "accepts min cache mode"
When call validate_input_python "docker-build" "cache-mode" "min"
The status should be success
End
It "accepts inline cache mode"
When call validate_input_python "docker-build" "cache-mode" "inline"
The status should be success
End
It "rejects invalid cache mode"
When call validate_input_python "docker-build" "cache-mode" "invalid"
The status should be failure
End
It "accepts valid cache-from format"
When call validate_input_python "docker-build" "cache-from" "type=registry,ref=myapp:cache"
The status should be success
End
End

Context "when validating security features"
It "accepts scan-image boolean"
When call validate_input_python "docker-build" "scan-image" "true"
The status should be success
End
It "accepts sign-image boolean"
When call validate_input_python "docker-build" "sign-image" "false"
The status should be success
End
It "accepts valid SBOM format"
When call validate_input_python "docker-build" "sbom-format" "spdx-json"
The status should be success
End
It "accepts cyclonedx SBOM format"
When call validate_input_python "docker-build" "sbom-format" "cyclonedx-json"
The status should be success
End
It "rejects invalid SBOM format"
When call validate_input_python "docker-build" "sbom-format" "invalid-format"
The status should be failure
End
End

Context "when validating performance options"
It "accepts valid parallel builds number"
When call validate_input_python "docker-build" "parallel-builds" "4"
The status should be success
End
It "accepts auto parallel builds"
When call validate_input_python "docker-build" "parallel-builds" "0"
The status should be success
End
It "rejects negative parallel builds"
When call validate_input_python "docker-build" "parallel-builds" "-1"
The status should be failure
End
It "rejects non-numeric parallel builds"
When call validate_input_python "docker-build" "parallel-builds" "not-a-number"
The status should be failure
End
End

Context "when checking action.yml structure"
It "has valid YAML syntax"
When call validate_action_yml_quiet "$ACTION_FILE"
The status should be success
End

It "has correct action name"
When call get_action_name "$ACTION_FILE"
The output should match pattern "*Docker*"
End

It "defines all required inputs"
When call get_action_inputs "$ACTION_FILE"
The output should include "tag"
End

It "defines all expected outputs"
When call get_action_outputs "$ACTION_FILE"
The output should include "image-digest"
The output should include "metadata"
The output should include "platforms"
The output should include "build-time"
End
End

Context "when validating security"
It "rejects injection in all Docker inputs"
When call validate_input_python "docker-build" "tag" "v1.0.0;rm -rf /"
The status should be failure
End

It "validates buildx version safely"
When call validate_input_python "docker-build" "buildx-version" "0.12.0"
The status should be success
End

It "rejects malicious buildx version"
When call validate_input_python "docker-build" "buildx-version" "0.12;malicious"
The status should be failure
End
End

Context "when testing outputs"
It "produces all expected outputs consistently"
When call test_action_outputs "$ACTION_DIR" "tag" "v1.0.0" "dockerfile" "Dockerfile"
The status should be success
The stderr should include "Testing action outputs for: docker-build"
The stderr should include "Output test passed for: docker-build"
End
End
End
