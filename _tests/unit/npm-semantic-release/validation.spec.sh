#!/usr/bin/env shellspec
# Unit tests for npm-semantic-release action validation and logic
# Framework is automatically loaded via spec_helper.sh

Describe "npm-semantic-release action"
ACTION_DIR="npm-semantic-release"
ACTION_FILE="$ACTION_DIR/action.yml"

Context "when validating npm_token input"
It "accepts valid GitHub package token format"
When call validate_input_python "npm-semantic-release" "npm_token" "ghp_123456789012345678901234567890123456"
The status should be success
End

It "accepts an npm_ token"
When call validate_input_python "npm-semantic-release" "npm_token" "npm_1234567890123456789012345678901234567890"
The status should be success
End

It "accepts a token format it does not recognise"
# The registry owns its token format, so the check only refuses what breaks a sink.
When call validate_input_python "npm-semantic-release" "npm_token" "some-registry-token-format"
The status should be success
End

It "rejects empty token"
When call validate_input_python "npm-semantic-release" "npm_token" ""
The status should be failure
End

It "rejects token with command injection"
When call validate_input_python "npm-semantic-release" "npm_token" "ghp_123456789012345678901234567890123456; rm -rf /"
The status should be failure
End

It "rejects a token containing a line break"
When call validate_input_python "npm-semantic-release" "npm_token" "$(printf 'npm_abc\nsecond-line')"
The status should be failure
End
End

Context "when validating registry-url input"
It "accepts valid https registry URL"
When call validate_input_python "npm-semantic-release" "registry-url" "https://registry.npmjs.org/"
The status should be success
End

It "accepts http registry URL on localhost"
When call validate_input_python "npm-semantic-release" "registry-url" "http://localhost:4873"
The status should be success
End

It "accepts http registry URL on 127.0.0.1"
When call validate_input_python "npm-semantic-release" "registry-url" "http://127.0.0.1:4873/"
The status should be success
End

It "rejects http registry URL on a remote host"
When call validate_input_python "npm-semantic-release" "registry-url" "http://registry.example.com/"
The status should be failure
End

It "rejects http registry URL on a host that starts with localhost"
When call validate_input_python "npm-semantic-release" "registry-url" "http://localhost.evil.example"
The status should be failure
End

It "rejects http registry URL on a host that starts with 127.0.0.1"
When call validate_input_python "npm-semantic-release" "registry-url" "http://127.0.0.1.evil.example"
The status should be failure
End

It "rejects registry URL with credentials"
When call validate_input_python "npm-semantic-release" "registry-url" "https://user:pass@registry.example.com/"
The status should be failure
End

It "rejects registry URL with localhost as userinfo"
When call validate_input_python "npm-semantic-release" "registry-url" "http://localhost@evil.example"
The status should be failure
End

It "rejects non-http(s) URL"
When call validate_input_python "npm-semantic-release" "registry-url" "ftp://registry.example.com"
The status should be failure
End

It "rejects invalid URL format"
When call validate_input_python "npm-semantic-release" "registry-url" "not-a-url"
The status should be failure
End

It "rejects URL with command injection"
When call validate_input_python "npm-semantic-release" "registry-url" "https://registry.npmjs.org|echo"
The status should be failure
End
End

Context "when validating scope input"
It "accepts valid npm scope"
When call validate_input_python "npm-semantic-release" "scope" "@ivuorinen"
The status should be success
End

It "accepts scope with hyphens"
When call validate_input_python "npm-semantic-release" "scope" "@my-organization"
The status should be success
End

It "rejects scope without @ prefix"
When call validate_input_python "npm-semantic-release" "scope" "myorg"
The status should be failure
End

It "rejects scope with invalid characters"
When call validate_input_python "npm-semantic-release" "scope" "@my_org!"
The status should be failure
End

It "rejects scope with command injection"
When call validate_input_python "npm-semantic-release" "scope" "@myorg; rm -rf /"
The status should be failure
End
End

Context "when validating extra_plugins input with accepted specs"
Parameters
"conventional-changelog-conventionalcommits@^9.3.1" "the default value"
"@semantic-release/git@10.0.1" "a scoped package with a version"
"@semantic-release/git" "a scoped package with no version"
"semver@1.0.0-rc.1" "a pre-release version"
"semver@1.0.0+build" "build metadata"
"@semantic-release/changelog@6.0.0 @semantic-release/git" "two space-separated plugins"
End

It "accepts $2"
When call validate_input_python "npm-semantic-release" "extra_plugins" "$1"
The status should be success
End
End

Context "when validating extra_plugins input"
It "accepts a multi-line YAML block value, including its trailing newline"
block_value="@semantic-release/changelog@6.0.0
@semantic-release/git
"
When call validate_input_python "npm-semantic-release" "extra_plugins" "$block_value"
The status should be success
End

It "rejects pipe-separated plugins"
When call validate_input_python "npm-semantic-release" "extra_plugins" "semver@7|ms@2"
The status should be failure
End

It "rejects comma-separated plugins"
When call validate_input_python "npm-semantic-release" "extra_plugins" "semver@7,ms@2"
The status should be failure
End

It "rejects an npm option"
When call validate_input_python "npm-semantic-release" "extra_plugins" "semver --force"
The status should be failure
End

It "rejects a comparator range, which is a redirect to a shell"
When call validate_input_python "npm-semantic-release" "extra_plugins" "semver@>=7.0.0"
The status should be failure
End

It "rejects shell syntax"
When call validate_input_python "npm-semantic-release" "extra_plugins" "semver;ms"
The status should be failure
End

It "rejects a value that is not a package from the registry"
When call validate_input_python "npm-semantic-release" "extra_plugins" "github:user/repo"
The status should be failure
End
End

Context "when validating node-version input"
Parameters:value "24" "24.1.0" "latest" "lts/*" "lts/-1" "lts/iron" "lts/Hydrogen"

It "accepts $1"
When call validate_input_python "npm-semantic-release" "node-version" "$1"
The status should be success
End
End

Context "when validating node-version input for values setup-node rejects"
Parameters:value "lts" "lts/" "LTS/iron" "lts/-0" "lts/1" "lts/iron;x" "lts/../iron" "lts/iron-rc.1" "lts/iron+build"

It "rejects $1"
When call validate_input_python "npm-semantic-release" "node-version" "$1"
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
The output should equal "NPM Semantic Release"
End

It "defines expected inputs"
When call get_action_inputs "$ACTION_FILE"
The output should include "npm_token"
The output should include "registry-url"
The output should include "scope"
End

It "defines expected outputs"
When call get_action_outputs "$ACTION_FILE"
The output should include "new-release-published"
The output should include "new-release-version"
End
End

Context "when testing input requirements"
It "requires npm_token input"
inputs=$(get_action_inputs "$ACTION_FILE")
When call echo "$inputs"
The output should include "npm_token"
End

It "has registry-url as optional with default"
When call _harness_python "_tests/shared/validation_core.py" --property "$ACTION_FILE" "registry-url" "default"
The output should include "registry.npmjs.org"
End

It "has scope with default @ivuorinen"
When call _harness_python "_tests/shared/validation_core.py" --property "$ACTION_FILE" "scope" "default"
The output should include "@ivuorinen"
End
End

Context "when testing security validations"
It "validates against path traversal in scope"
When call validate_input_python "npm-semantic-release" "scope" "@../../../etc"
The status should be failure
End

It "validates against command substitution in scope"
When call validate_input_python "npm-semantic-release" "scope" "@\$(whoami)"
The status should be failure
End

It "validates against path traversal in registry-url"
When call validate_input_python "npm-semantic-release" "registry-url" "https://registry.npmjs.org/../../../etc"
The status should be failure
End
End
End
