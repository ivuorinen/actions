#!/usr/bin/env shellspec
# Unit tests for github-release action validation and logic

# Framework is automatically loaded via spec_helper.sh

Describe "github-release action"
  ACTION_DIR="github-release"
  ACTION_FILE="$ACTION_DIR/action.yml"

  Context "when validating version input"
    It "accepts valid semantic version"
      When call test_input_validation "$ACTION_DIR" "version" "1.2.3" "success"
      The status should be success
    End

    It "accepts semantic version with v prefix"
      When call test_input_validation "$ACTION_DIR" "version" "v1.2.3" "success"
      The status should be success
    End

    It "accepts prerelease version"
      When call test_input_validation "$ACTION_DIR" "version" "1.2.3-alpha" "success"
      The status should be success
    End

    It "accepts build metadata version"
      When call test_input_validation "$ACTION_DIR" "version" "1.2.3+build.1" "success"
      The status should be success
    End

    It "accepts prerelease with build metadata"
      When call test_input_validation "$ACTION_DIR" "version" "1.2.3-alpha.1+build.1" "success"
      The status should be success
    End

    It "accepts CalVer format"
      When call test_input_validation "$ACTION_DIR" "version" "2024.3.1" "success"
      The status should be success
    End

    It "rejects invalid version format"
      When call test_input_validation "$ACTION_DIR" "version" "invalid-version" "failure"
      The status should be success
    End

    It "rejects version with command injection"
      When call test_input_validation "$ACTION_DIR" "version" "1.2.3; rm -rf /" "failure"
      The status should be success
    End

    It "rejects empty version"
      When call test_input_validation "$ACTION_DIR" "version" "" "failure"
      The status should be success
    End
  End

  Context "when validating changelog input"
    It "accepts empty changelog"
      When call test_input_validation "$ACTION_DIR" "changelog" "" "success"
      The status should be success
    End

    It "accepts normal changelog content"
      When call test_input_validation "$ACTION_DIR" "changelog" "## What's Changed\n- Fixed bug #123\n- Added feature X" "success"
      The status should be success
    End

    It "accepts changelog with special characters"
      When call test_input_validation "$ACTION_DIR" "changelog" "Version 1.2.3\n\n- Bug fixes & improvements\n- Added @mention support" "success"
      The status should be success
    End

    It "rejects changelog with command injection"
      When call test_input_validation "$ACTION_DIR" "changelog" "Release notes; rm -rf /" "failure"
      The status should be success
    End

    It "rejects changelog with shell expansion"
      When call test_input_validation "$ACTION_DIR" "changelog" "Release \$(whoami) notes" "failure"
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
      The output should equal "GitHub Release"
    End

    It "defines expected inputs"
      When call get_action_inputs "$ACTION_FILE"
      The output should include "version"
      The output should include "changelog"
    End

    It "defines expected outputs"
      When call get_action_outputs "$ACTION_FILE"
      The output should include "release_url"
      The output should include "release_id"
      The output should include "upload_url"
    End
  End

  Context "when testing input requirements"
    It "requires version input"
      inputs=$(get_action_inputs "$ACTION_FILE")
      When call echo "$inputs"
      The output should include "version"
    End

    It "has changelog as optional input"
      # Test that changelog has a default value in action.yml
      When call python3 -c "
      import yaml
      with open('$ACTION_FILE') as f:
      data = yaml.safe_load(f)
      changelog = data.get('inputs', {}).get('changelog', {})
      print('optional' if not changelog.get('required', True) else 'required')
      "
      The output should equal "optional"
    End
  End

  Context "when testing security validations"
    It "validates against path traversal in version"
      When call test_input_validation "$ACTION_DIR" "version" "../1.2.3" "failure"
      The status should be success
    End

    It "validates against shell metacharacters in version"
      When call test_input_validation "$ACTION_DIR" "version" "1.2.3|echo" "failure"
      The status should be success
    End

    It "validates against shell metacharacters in changelog"
      When call test_input_validation "$ACTION_DIR" "changelog" "Release notes|echo test" "failure"
      The status should be success
    End
  End
End
