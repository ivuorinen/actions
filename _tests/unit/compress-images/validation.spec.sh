#!/usr/bin/env shellspec
# Unit tests for compress-images action validation and logic

# Framework is automatically loaded via spec_helper.sh

Describe "compress-images action"
  ACTION_DIR="compress-images"
  ACTION_FILE="$ACTION_DIR/action.yml"

  Context "when validating inputs"
    It "accepts valid quality setting"
      # pick one of the defined quality inputs
      inputs="$(get_action_inputs "$ACTION_FILE")"
      QUALITY_INPUT=$(echo "$inputs" | grep -E '^(image-quality|png-quality)$' | head -n1)
      When call validate_input_python "compress-images" "$QUALITY_INPUT" "80"
      The status should be success
    End
    It "rejects invalid quality"
      # pick one of the defined quality inputs
      inputs="$(get_action_inputs "$ACTION_FILE")"
      QUALITY_INPUT=$(echo "$inputs" | grep -E '^(image-quality|png-quality)$' | head -n1)
      When call validate_input_python "compress-images" "$QUALITY_INPUT" "150"
      The status should be failure
    End
    It "accepts valid path pattern"
      # use the defined path-filter input
      PATH_INPUT="ignore-paths"
      When call validate_input_python "compress-images" "$PATH_INPUT" "assets/**/*.{jpg,png}"
      The status should be success
    End
    It "rejects injection in path"
      # use the defined path-filter input
      PATH_INPUT="ignore-paths"
      When call validate_input_python "compress-images" "$PATH_INPUT" "images;rm -rf /tmp"
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
      The output should match pattern "*Compress*"
    End
  End
End
