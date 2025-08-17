#!/usr/bin/env shellspec
# Unit tests for docker-build action validation and logic
# Framework is automatically loaded via spec_helper.sh

Describe "docker-build action"
  ACTION_DIR="docker-build"
  ACTION_FILE="$ACTION_DIR/action.yml"

  Context "when validating image-name input"
    It "accepts valid image name"
      When call test_input_validation "$ACTION_DIR" "image-name" "myapp" "success"
      The status should be success
    End
    It "rejects image name with registry prefix (slashes not allowed)"
      When call test_input_validation "$ACTION_DIR" "image-name" "registry.example.com/myapp" "failure"
      The status should be success
    End
    It "rejects command injection in image name"
      When call test_input_validation "$ACTION_DIR" "image-name" "app; rm -rf /" "failure"
      The status should be success
    End
  End

  Context "when validating tag input"
    It "accepts valid tag format"
      When call test_input_validation "$ACTION_DIR" "tag" "v1.0.0" "success"
      The status should be success
    End
    It "accepts semantic version tag"
      When call test_input_validation "$ACTION_DIR" "tag" "1.2.3" "success"
      The status should be success
    End
    It "accepts latest tag"
      When call test_input_validation "$ACTION_DIR" "tag" "latest" "success"
      The status should be success
    End
    It "rejects invalid tag format"
      When call test_input_validation "$ACTION_DIR" "tag" "invalid_tag!" "failure"
      The status should be success
    End
  End

  Context "when validating architectures input"
    It "accepts valid architectures list"
      When call test_input_validation "$ACTION_DIR" "architectures" "linux/amd64,linux/arm64" "success"
      The status should be success
    End
    It "accepts single architecture"
      When call test_input_validation "$ACTION_DIR" "architectures" "linux/amd64" "success"
      The status should be success
    End
    It "accepts ARM variants"
      When call test_input_validation "$ACTION_DIR" "architectures" "linux/arm/v7,linux/arm/v6" "success"
      The status should be success
    End
  End

  Context "when validating dockerfile input"
    It "accepts valid dockerfile path"
      When call test_input_validation "$ACTION_DIR" "dockerfile" "Dockerfile" "success"
      The status should be success
    End
    It "accepts custom dockerfile path"
      When call test_input_validation "$ACTION_DIR" "dockerfile" "docker/Dockerfile.prod" "success"
      The status should be success
    End
    It "rejects malicious dockerfile path"
      When call test_input_validation "$ACTION_DIR" "dockerfile" "../../../etc/passwd" "failure"
      The status should be success
    End
  End

  Context "when validating context input"
    It "accepts valid build context"
      When call test_input_validation "$ACTION_DIR" "context" "." "success"
      The status should be success
    End
    It "accepts relative context path"
      When call test_input_validation "$ACTION_DIR" "context" "src/app" "success"
      The status should be success
    End
    It "accepts path traversal in context (no validation in action)"
      When call test_input_validation "$ACTION_DIR" "context" "../../../etc" "success"
      The status should be success
    End
  End

  Context "when validating build-args input"
    It "accepts valid build args format"
      When call test_input_validation "$ACTION_DIR" "build-args" "NODE_ENV=production,VERSION=1.0.0" "success"
      The status should be success
    End
    It "accepts empty build args"
      When call test_input_validation "$ACTION_DIR" "build-args" "" "success"
      The status should be success
    End
    It "rejects malicious build args"
      When call test_input_validation "$ACTION_DIR" "build-args" "ARG=\$(rm -rf /)" "failure"
      The status should be success
    End
  End

  Context "when validating cache inputs"
    It "accepts valid cache mode"
      When call test_input_validation "$ACTION_DIR" "cache-mode" "max" "success"
      The status should be success
    End
    It "accepts min cache mode"
      When call test_input_validation "$ACTION_DIR" "cache-mode" "min" "success"
      The status should be success
    End
    It "accepts inline cache mode"
      When call test_input_validation "$ACTION_DIR" "cache-mode" "inline" "success"
      The status should be success
    End
    It "rejects invalid cache mode"
      When call test_input_validation "$ACTION_DIR" "cache-mode" "invalid" "failure"
      The status should be success
    End
    It "accepts valid cache-from format"
      When call test_input_validation "$ACTION_DIR" "cache-from" "type=registry,ref=myapp:cache" "success"
      The status should be success
    End
  End

  Context "when validating security features"
    It "accepts scan-image boolean"
      When call test_input_validation "$ACTION_DIR" "scan-image" "true" "success"
      The status should be success
    End
    It "accepts sign-image boolean"
      When call test_input_validation "$ACTION_DIR" "sign-image" "false" "success"
      The status should be success
    End
    It "accepts valid SBOM format"
      When call test_input_validation "$ACTION_DIR" "sbom-format" "spdx-json" "success"
      The status should be success
    End
    It "accepts cyclonedx SBOM format"
      When call test_input_validation "$ACTION_DIR" "sbom-format" "cyclonedx-json" "success"
      The status should be success
    End
    It "rejects invalid SBOM format"
      When call test_input_validation "$ACTION_DIR" "sbom-format" "invalid-format" "failure"
      The status should be success
    End
  End

  Context "when validating performance options"
    It "accepts valid parallel builds number"
      When call test_input_validation "$ACTION_DIR" "parallel-builds" "4" "success"
      The status should be success
    End
    It "accepts auto parallel builds"
      When call test_input_validation "$ACTION_DIR" "parallel-builds" "0" "success"
      The status should be success
    End
    It "rejects negative parallel builds"
      When call test_input_validation "$ACTION_DIR" "parallel-builds" "-1" "failure"
      The status should be success
    End
    It "rejects non-numeric parallel builds"
      When call test_input_validation "$ACTION_DIR" "parallel-builds" "not-a-number" "failure"
      The status should be success
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
      When call test_input_validation "$ACTION_DIR" "tag" "v1.0.0;rm -rf /" "failure"
      The status should be success
    End

    It "validates buildx version safely"
      When call test_input_validation "$ACTION_DIR" "buildx-version" "0.12.0" "success"
      The status should be success
    End

    It "rejects malicious buildx version"
      When call test_input_validation "$ACTION_DIR" "buildx-version" "0.12;malicious" "failure"
      The status should be success
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
