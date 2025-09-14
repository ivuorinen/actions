#!/usr/bin/env shellspec
# Unit tests for npm-publish action validation and logic

# Framework is automatically loaded via spec_helper.sh

Describe "npm-publish action"
  ACTION_DIR="npm-publish"
  ACTION_FILE="$ACTION_DIR/action.yml"

  Context "when validating registry-url input"
    It "accepts valid https registry URL"
      When call test_input_validation "$ACTION_DIR" "registry-url" "https://registry.npmjs.org/" "success"
      The status should be success
    End

    It "accepts https registry URL without trailing slash"
      When call test_input_validation "$ACTION_DIR" "registry-url" "https://registry.npmjs.org" "success"
      The status should be success
    End

    It "accepts http registry URL"
      When call test_input_validation "$ACTION_DIR" "registry-url" "http://localhost:4873" "success"
      The status should be success
    End

    It "accepts registry URL with path"
      When call test_input_validation "$ACTION_DIR" "registry-url" "https://npm.example.com/registry/" "success"
      The status should be success
    End

    It "rejects non-http(s) URL"
      When call test_input_validation "$ACTION_DIR" "registry-url" "ftp://registry.example.com" "failure"
      The status should be success
    End

    It "rejects invalid URL format"
      When call test_input_validation "$ACTION_DIR" "registry-url" "not-a-url" "failure"
      The status should be success
    End

    It "rejects URL with command injection"
      When call test_input_validation "$ACTION_DIR" "registry-url" "https://registry.npmjs.org; rm -rf /" "failure"
      The status should be success
    End

    It "rejects empty registry URL"
      When call test_input_validation "$ACTION_DIR" "registry-url" "" "failure"
      The status should be success
    End
  End

  Context "when validating scope input"
    It "accepts valid NPM scope"
      When call test_input_validation "$ACTION_DIR" "scope" "@ivuorinen" "success"
      The status should be success
    End

    It "accepts scope with hyphens"
      When call test_input_validation "$ACTION_DIR" "scope" "@my-org" "success"
      The status should be success
    End

    It "accepts scope with underscores"
      When call test_input_validation "$ACTION_DIR" "scope" "@my_org" "success"
      The status should be success
    End

    It "accepts scope with dots"
      When call test_input_validation "$ACTION_DIR" "scope" "@my.org" "success"
      The status should be success
    End

    It "accepts scope with tilde"
      When call test_input_validation "$ACTION_DIR" "scope" "@my~org" "success"
      The status should be success
    End

    It "rejects scope without @ prefix"
      When call test_input_validation "$ACTION_DIR" "scope" "myorg" "failure"
      The status should be success
    End

    It "rejects scope starting with number after @"
      When call test_input_validation "$ACTION_DIR" "scope" "@1invalid" "failure"
      The status should be success
    End

    It "rejects scope with spaces"
      When call test_input_validation "$ACTION_DIR" "scope" "@my org" "failure"
      The status should be success
    End

    It "rejects scope with command injection"
      When call test_input_validation "$ACTION_DIR" "scope" "@org; rm -rf /" "failure"
      The status should be success
    End

    It "accepts empty scope"
      When call test_input_validation "$ACTION_DIR" "scope" "" "success"
      The status should be success
    End
  End

  Context "when validating package-version input"
    It "accepts semantic version"
      When call test_input_validation "$ACTION_DIR" "package-version" "1.2.3" "success"
      The status should be success
    End

    It "accepts semantic version with v prefix"
      When call test_input_validation "$ACTION_DIR" "package-version" "v1.2.3" "success"
      The status should be success
    End

    It "accepts prerelease version"
      When call test_input_validation "$ACTION_DIR" "package-version" "1.2.3-alpha" "success"
      The status should be success
    End

    It "accepts prerelease with number"
      When call test_input_validation "$ACTION_DIR" "package-version" "1.2.3-alpha.1" "success"
      The status should be success
    End

    It "accepts build metadata"
      When call test_input_validation "$ACTION_DIR" "package-version" "1.2.3+build.1" "success"
      The status should be success
    End

    It "accepts prerelease with build metadata"
      When call test_input_validation "$ACTION_DIR" "package-version" "1.2.3-alpha.1+build.1" "success"
      The status should be success
    End

    It "rejects invalid version format"
      When call test_input_validation "$ACTION_DIR" "package-version" "1.2" "failure"
      The status should be success
    End

    It "rejects version with command injection"
      When call test_input_validation "$ACTION_DIR" "package-version" "1.2.3; rm -rf /" "failure"
      The status should be success
    End

    It "rejects version with shell expansion"
      When call test_input_validation "$ACTION_DIR" "package-version" "1.2.3\$(whoami)" "failure"
      The status should be success
    End

    It "rejects empty version"
      When call test_input_validation "$ACTION_DIR" "package-version" "" "failure"
      The status should be success
    End
  End

  Context "when validating npm_token input"
    It "accepts GitHub token expression"
      When call test_input_validation "$ACTION_DIR" "npm_token" "\${{ github.token }}" "success"
      The status should be success
    End

    It "accepts NPM classic token format"
      When call test_input_validation "$ACTION_DIR" "npm_token" "npm_aBcDeFgHiJkLmNoPqRsTuVwXyZ1234567890abcdef" "success"
      The status should be success
    End

    It "accepts GitHub fine-grained token"
      When call test_input_validation "$ACTION_DIR" "npm_token" "ghp_abcdefghijklmnopqrstuvwxyz1234567890" "success"
      The status should be success
    End

    It "accepts GitHub app token"
      When call test_input_validation "$ACTION_DIR" "npm_token" "ghs_abcdefghijklmnopqrstuvwxyz1234567890" "success"
      The status should be success
    End

    It "rejects empty token"
      When call test_input_validation "$ACTION_DIR" "npm_token" "" "failure"
      The status should be success
    End

    It "rejects invalid token format"
      When call test_input_validation "$ACTION_DIR" "npm_token" "invalid-token" "failure"
      The status should be success
    End

    It "rejects token with command injection"
      When call test_input_validation "$ACTION_DIR" "npm_token" "token; rm -rf /" "failure"
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
      The output should equal "Publish to NPM"
    End

    It "defines expected inputs"
      When call get_action_inputs "$ACTION_FILE"
      The output should include "registry-url"
      The output should include "scope"
      The output should include "package-version"
      The output should include "npm_token"
    End

    It "defines expected outputs"
      When call get_action_outputs "$ACTION_FILE"
      The output should include "registry-url"
      The output should include "scope"
      The output should include "package-version"
      The output should include "npm_token"
    End
  End

  Context "when testing input requirements"
    It "requires npm_token input"
      inputs=$(get_action_inputs "$ACTION_FILE")
      When call echo "$inputs"
      The output should include "npm_token"
    End

    It "has registry-url as optional input"
      When call python3 -c "
      import yaml
      with open('$ACTION_FILE') as f:
      data = yaml.safe_load(f)
      registry_url = data.get('inputs', {}).get('registry-url', {})
      print('optional' if 'default' in registry_url else 'required')
      "
      The output should equal "optional"
    End

    It "has scope as optional input"
      When call python3 -c "
      import yaml
      with open('$ACTION_FILE') as f:
      data = yaml.safe_load(f)
      scope = data.get('inputs', {}).get('scope', {})
      print('optional' if 'default' in scope else 'required')
      "
      The output should equal "optional"
    End

    It "has package-version as optional input"
      When call python3 -c "
      import yaml
      with open('$ACTION_FILE') as f:
      data = yaml.safe_load(f)
      package_version = data.get('inputs', {}).get('package-version', {})
      print('optional' if 'default' in package_version else 'required')
      "
      The output should equal "optional"
    End
  End

  Context "when testing security validations"
    It "validates against path traversal in scope"
      When call test_input_validation "$ACTION_DIR" "scope" "@../malicious" "failure"
      The status should be success
    End

    It "validates against shell metacharacters in registry URL"
      When call test_input_validation "$ACTION_DIR" "registry-url" "https://registry.npmjs.org|echo" "failure"
      The status should be success
    End

    It "validates against backtick injection in version"
      When call test_input_validation "$ACTION_DIR" "package-version" "1.2.3\`whoami\`" "failure"
      The status should be success
    End

    It "validates against variable expansion in token"
      When call test_input_validation "$ACTION_DIR" "npm_token" "\${MALICIOUS_VAR}" "failure"
      The status should be success
    End
  End

  Context "when testing NPM-specific validations"
    It "validates scope format restrictions"
      When call test_input_validation "$ACTION_DIR" "scope" "@INVALID-CAPS" "failure"
      The status should be success
    End

    It "validates registry URL must be HTTP/HTTPS"
      When call test_input_validation "$ACTION_DIR" "registry-url" "file:///etc/passwd" "failure"
      The status should be success
    End

    It "validates package version semantic versioning compliance"
      When call test_input_validation "$ACTION_DIR" "package-version" "1.2.3.4" "failure"
      The status should be success
    End
  End
End
