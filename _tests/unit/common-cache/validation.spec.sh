#!/usr/bin/env shellspec
# Unit tests for common-cache action validation and logic

# Framework is automatically loaded via spec_helper.sh

Describe "common-cache action"
ACTION_DIR="common-cache"
ACTION_FILE="$ACTION_DIR/action.yml"

Context "when validating cache type input"
It "accepts npm cache type"
When call validate_input_python "common-cache" "type" "npm"
The status should be success
End
It "accepts composer cache type"
When call validate_input_python "common-cache" "type" "composer"
The status should be success
End
It "accepts go cache type"
When call validate_input_python "common-cache" "type" "go"
The status should be success
End
It "accepts pip cache type"
When call validate_input_python "common-cache" "type" "pip"
The status should be success
End
It "accepts maven cache type"
When call validate_input_python "common-cache" "type" "maven"
The status should be success
End
It "accepts gradle cache type"
When call validate_input_python "common-cache" "type" "gradle"
The status should be success
End
It "rejects empty cache type"
When call validate_input_python "common-cache" "type" ""
The status should be failure
End
It "rejects invalid cache type"
Pending "TODO: Implement enum validation for cache type"
When call validate_input_python "common-cache" "type" "invalid-type"
The status should be failure
End
End

Context "when validating paths input"
It "accepts single path"
When call validate_input_python "common-cache" "paths" "node_modules"
The status should be success
End
It "accepts multiple paths"
When call validate_input_python "common-cache" "paths" "node_modules,dist,build"
The status should be success
End
It "rejects empty paths"
When call validate_input_python "common-cache" "paths" ""
The status should be failure
End
It "rejects path traversal"
When call validate_input_python "common-cache" "paths" "../../../etc/passwd"
The status should be failure
End
It "rejects command injection in paths"
When call validate_input_python "common-cache" "paths" "node_modules;rm -rf /"
The status should be failure
End
End

Context "when validating key-prefix input"
It "accepts valid key prefix"
When call validate_input_python "common-cache" "key-prefix" "v2-build"
The status should be success
End
It "rejects command injection in key-prefix"
When call validate_input_python "common-cache" "key-prefix" "v2&&malicious"
The status should be failure
End
End

Context "when validating key-files input"
It "accepts single key file"
When call validate_input_python "common-cache" "key-files" "package.json"
The status should be success
End
It "accepts multiple key files"
When call validate_input_python "common-cache" "key-files" "package.json,package-lock.json,yarn.lock"
The status should be success
End
It "rejects path traversal in key-files"
When call validate_input_python "common-cache" "key-files" "../../../sensitive.json"
The status should be failure
End
End

Context "when validating restore-keys input"
It "accepts valid restore keys format"
When call validate_input_python "common-cache" "restore-keys" "Linux-npm-,Linux-"
The status should be success
End
It "rejects malicious restore keys"
When call validate_input_python "common-cache" "restore-keys" "Linux-npm-;rm -rf /"
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
The output should equal "Common Cache"
End

It "defines required inputs"
inputs=$(get_action_inputs "$ACTION_FILE")
When call echo "$inputs"
The output should include "type"
The output should include "paths"
End

It "defines optional inputs"
inputs=$(get_action_inputs "$ACTION_FILE")
When call echo "$inputs"
The output should include "key-prefix"
The output should include "key-files"
The output should include "restore-keys"
The output should include "env-vars"
End

It "defines expected outputs"
outputs=$(get_action_outputs "$ACTION_FILE")
When call echo "$outputs"
The output should include "cache-hit"
The output should include "cache-key"
The output should include "cache-paths"
End
End

Context "when validating security"
It "rejects injection in all input types"
When call validate_input_python "common-cache" "type" "npm;malicious"
The status should be failure
End

It "validates environment variable names safely"
When call validate_input_python "common-cache" "env-vars" "NODE_ENV,CI"
The status should be success
End

It "rejects injection in environment variables"
When call validate_input_python "common-cache" "env-vars" "NODE_ENV;rm -rf /"
The status should be failure
End
End

Context "when testing outputs"
It "produces all expected outputs consistently"
When call test_action_outputs "$ACTION_DIR" "type" "npm" "paths" "node_modules"
The status should be success
The stderr should include "Testing action outputs for: common-cache"
The stderr should include "Output test passed for: common-cache"
End
End
End
