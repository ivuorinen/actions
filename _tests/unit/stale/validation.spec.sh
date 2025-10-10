#!/usr/bin/env shellspec
# Unit tests for stale action validation and logic

# Framework is automatically loaded via spec_helper.sh

Describe "stale action"
  ACTION_DIR="stale"
  ACTION_FILE="$ACTION_DIR/action.yml"

  Context "when validating token input"
    It "accepts GitHub token expression"
      When call validate_input_python "stale" "token" "\${{ github.token }}"
      The status should be success
    End

    It "accepts GitHub fine-grained token"
      When call validate_input_python "stale" "token" "ghp_abcdefghijklmnopqrstuvwxyz1234567890"
      The status should be success
    End

    It "rejects invalid token format"
      When call validate_input_python "stale" "token" "invalid-token"
      The status should be failure
    End

    It "rejects token with command injection"
      When call validate_input_python "stale" "token" "ghp_token; rm -rf /"
      The status should be failure
    End

    It "accepts empty token (uses default)"
      When call validate_input_python "stale" "token" ""
      The status should be success
    End
  End

  Context "when validating days-before-stale input"
    It "accepts valid day count"
      When call validate_input_python "stale" "days-before-stale" "30"
      The status should be success
    End

    It "accepts minimum days"
      When call validate_input_python "stale" "days-before-stale" "1"
      The status should be success
    End

    It "accepts reasonable maximum days"
      When call validate_input_python "stale" "days-before-stale" "365"
      The status should be success
    End

    It "rejects zero days"
      When call validate_input_python "stale" "days-before-stale" "0"
      The status should be failure
    End

    It "rejects negative days"
      When call validate_input_python "stale" "days-before-stale" "-1"
      The status should be failure
    End

    It "rejects non-numeric days"
      When call validate_input_python "stale" "days-before-stale" "many"
      The status should be failure
    End
  End

  Context "when validating days-before-close input"
    It "accepts valid day count"
      When call validate_input_python "stale" "days-before-close" "7"
      The status should be success
    End

    It "accepts minimum days"
      When call validate_input_python "stale" "days-before-close" "1"
      The status should be success
    End

    It "accepts reasonable maximum days"
      When call validate_input_python "stale" "days-before-close" "365"
      The status should be success
    End

    It "rejects zero days"
      When call validate_input_python "stale" "days-before-close" "0"
      The status should be failure
    End

    It "rejects negative days"
      When call validate_input_python "stale" "days-before-close" "-1"
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
      The output should equal "Close Stale Issues"
    End

    It "defines expected inputs"
      When call get_action_inputs "$ACTION_FILE"
      The output should include "token"
      The output should include "days-before-stale"
      The output should include "days-before-close"
    End
  End

  Context "when testing input requirements"
    It "has all inputs as optional"
      When call python3 "_tests/shared/validation_core.py" --property "$ACTION_FILE" "" "all_optional"
      The output should equal "none"
    End
  End

  Context "when testing security validations"
    It "validates against command injection in token"
      When call validate_input_python "stale" "token" "ghp_token\`whoami\`"
      The status should be failure
    End

    It "validates against variable expansion in days"
      When call validate_input_python "stale" "days-before-stale" "30\${HOME}"
      The status should be success
    End

    It "validates against shell metacharacters in days"
      When call validate_input_python "stale" "days-before-close" "7; rm -rf /"
      The status should be success
    End
  End
End
