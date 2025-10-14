#!/usr/bin/env shellspec
# Unit tests for common-retry action validation and logic

# Framework is automatically loaded via spec_helper.sh

Describe "common-retry action"
ACTION_DIR="common-retry"
ACTION_FILE="$ACTION_DIR/action.yml"

Context "when validating max-retries input"
It "accepts minimum value (1)"
When call validate_input_python "common-retry" "max-retries" "1"
The status should be success
End
It "accepts maximum value (10)"
When call validate_input_python "common-retry" "max-retries" "10"
The status should be success
End
It "rejects below minimum"
When call validate_input_python "common-retry" "max-retries" "0"
The status should be failure
End
It "rejects above maximum"
When call validate_input_python "common-retry" "max-retries" "11"
The status should be failure
End
It "rejects non-numeric"
When call validate_input_python "common-retry" "max-retries" "invalid"
The status should be failure
End
End

Context "when validating retry-delay input"
It "accepts minimum value (1)"
When call validate_input_python "common-retry" "retry-delay" "1"
The status should be success
End
It "accepts maximum value (300)"
When call validate_input_python "common-retry" "retry-delay" "300"
The status should be success
End
It "rejects below minimum"
When call validate_input_python "common-retry" "retry-delay" "0"
The status should be failure
End
It "rejects above maximum"
When call validate_input_python "common-retry" "retry-delay" "301"
The status should be failure
End
End

Context "when validating backoff-strategy input"
It "accepts linear strategy"
When call validate_input_python "common-retry" "backoff-strategy" "linear"
The status should be success
End
It "accepts exponential strategy"
When call validate_input_python "common-retry" "backoff-strategy" "exponential"
The status should be success
End
It "accepts fixed strategy"
When call validate_input_python "common-retry" "backoff-strategy" "fixed"
The status should be success
End
It "rejects invalid strategy"
When call validate_input_python "common-retry" "backoff-strategy" "invalid"
The status should be failure
End
End

Context "when validating timeout input"
It "accepts minimum value (1)"
When call validate_input_python "common-retry" "timeout" "1"
The status should be success
End
It "accepts maximum value (3600)"
When call validate_input_python "common-retry" "timeout" "3600"
The status should be success
End
It "rejects below minimum"
When call validate_input_python "common-retry" "timeout" "0"
The status should be failure
End
It "rejects above maximum"
When call validate_input_python "common-retry" "timeout" "3601"
The status should be failure
End
End

Context "when validating working-directory input"
It "accepts current directory"
When call validate_input_python "common-retry" "working-directory" "."
The status should be success
End
It "accepts relative path"
When call validate_input_python "common-retry" "working-directory" "src/app"
The status should be success
End
It "rejects path traversal"
When call validate_input_python "common-retry" "working-directory" "../../../etc"
The status should be failure
End
End

Context "when validating shell input"
It "accepts bash shell"
When call validate_input_python "common-retry" "shell" "bash"
The status should be success
End
It "accepts sh shell"
When call validate_input_python "common-retry" "shell" "sh"
The status should be success
End
It "rejects zsh shell"
When call validate_input_python "common-retry" "shell" "zsh"
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
The output should equal "Common Retry"
End
End

Context "when validating security"
It "rejects command injection with semicolon"
When call validate_input_python "common-retry" "command" "value; rm -rf /"
The status should be failure
End

It "rejects command injection with ampersand"
When call validate_input_python "common-retry" "command" "value && malicious"
The status should be failure
End

It "accepts valid success codes"
When call validate_input_python "common-retry" "success-codes" "0,1,2"
The status should be success
End

It "rejects success codes with injection"
When call validate_input_python "common-retry" "success-codes" "0;rm -rf /"
The status should be failure
End

It "accepts valid retry codes"
When call validate_input_python "common-retry" "retry-codes" "1,126,127"
The status should be success
End

It "rejects retry codes with injection"
When call validate_input_python "common-retry" "retry-codes" "1;rm -rf /"
The status should be failure
End
End

End
