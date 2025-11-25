#!/usr/bin/env shellspec
# Unit tests for security-scan action validation and logic
# Framework is automatically loaded via spec_helper.sh

Describe "security-scan action"
ACTION_DIR="security-scan"
ACTION_FILE="$ACTION_DIR/action.yml"

Context "when validating token input"
  It "accepts valid GitHub token"
    When call validate_input_python "security-scan" "token" "ghp_123456789012345678901234567890123456"
    The status should be success
  End

  It "rejects injection in token"
    When call validate_input_python "security-scan" "token" "token; rm -rf /"
    The status should be failure
  End

  It "accepts empty token (optional)"
    When call validate_input_python "security-scan" "token" ""
    The status should be success
  End
End

Context "when validating actionlint-enabled input"
  It "accepts true value"
    When call validate_input_python "security-scan" "actionlint-enabled" "true"
    The status should be success
  End

  It "accepts false value"
    When call validate_input_python "security-scan" "actionlint-enabled" "false"
    The status should be success
  End

  It "rejects non-boolean value"
    When call validate_input_python "security-scan" "actionlint-enabled" "maybe"
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
    The output should equal "Security Scan"
  End

  It "defines all expected inputs"
    inputs=$(get_action_inputs "$ACTION_FILE")
    When call echo "$inputs"
    The output should include "gitleaks-license"
    The output should include "gitleaks-config"
    The output should include "trivy-severity"
    The output should include "trivy-scanners"
    The output should include "trivy-timeout"
    The output should include "actionlint-enabled"
    The output should include "token"
  End

  It "defines all expected outputs"
    outputs=$(get_action_outputs "$ACTION_FILE")
    When call echo "$outputs"
    The output should include "has_trivy_results"
    The output should include "has_gitleaks_results"
    The output should include "total_issues"
    The output should include "critical_issues"
  End

  It "uses composite run type"
    run_type=$(get_action_runs_using "$ACTION_FILE")
    When call echo "$run_type"
    The output should equal "composite"
  End
End

Context "when validating inputs per conventions"
  It "validates token against github_token convention"
    When call validate_input_python "security-scan" "token" "ghp_123456789012345678901234567890123456"
    The status should be success
  End

  It "validates actionlint-enabled as boolean"
    When call validate_input_python "security-scan" "actionlint-enabled" "true"
    The status should be success
  End

  It "rejects invalid boolean for actionlint-enabled"
    When call validate_input_python "security-scan" "actionlint-enabled" "1"
    The status should be failure
  End
End

Context "when testing optional inputs"
  It "accepts empty gitleaks-license"
    When call validate_input_python "security-scan" "gitleaks-license" ""
    The status should be success
  End

  It "accepts empty token"
    When call validate_input_python "security-scan" "token" ""
    The status should be success
  End

  It "accepts valid gitleaks-license value"
    When call validate_input_python "security-scan" "gitleaks-license" "license-key-123"
    The status should be success
  End
End
End
