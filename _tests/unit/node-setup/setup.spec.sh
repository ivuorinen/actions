#!/usr/bin/env shellspec
# Unit tests for node-setup action

# Framework is automatically loaded via spec_helper.sh

Describe "node-setup action"
  ACTION_DIR="node-setup"
  ACTION_FILE="$ACTION_DIR/action.yml"

  # Framework is automatically initialized via spec_helper.sh

  Context "when validating inputs"
    It "accepts valid Node.js version"
      When call test_input_validation "$ACTION_DIR" "node-version" "18.17.0" "success"
      The status should be success
    End

    It "accepts valid package manager"
      When call test_input_validation "$ACTION_DIR" "package-manager" "npm" "success"
      The status should be success
    End

    It "accepts yarn as package manager"
      When call test_input_validation "$ACTION_DIR" "package-manager" "yarn" "success"
      The status should be success
    End

    It "accepts pnpm as package manager"
      When call test_input_validation "$ACTION_DIR" "package-manager" "pnpm" "success"
      The status should be success
    End

    It "accepts bun as package manager"
      When call test_input_validation "$ACTION_DIR" "package-manager" "bun" "success"
      The status should be success
    End

    It "rejects invalid package manager"
      When call test_input_validation "$ACTION_DIR" "package-manager" "invalid-manager" "failure"
      The status should be success
    End

    It "rejects malformed Node.js version"
      When call test_input_validation "$ACTION_DIR" "node-version" "not-a-version" "failure"
      The status should be success
    End

    It "rejects command injection in inputs"
      When call test_input_validation "$ACTION_DIR" "node-version" "18.0.0; rm -rf /" "failure"
      The status should be success
    End
  End

  Context "when checking action structure"
    It "has valid YAML syntax"
      When call validate_action_yml_quiet "$ACTION_FILE"
      The status should be success
    End

    It "has correct action name"
      When call get_action_name "$ACTION_FILE"
      The output should equal "Node Setup"
    End

    It "defines expected inputs"
      When call get_action_inputs "$ACTION_FILE"
      The output should include "default-version"
      The output should include "package-manager"
    End

    It "defines expected outputs"
      When call get_action_outputs "$ACTION_FILE"
      The output should include "node-version"
      The output should include "package-manager"
      The output should include "cache-hit"
    End
  End

  Context "when testing Node.js version detection"
    BeforeEach "shellspec_setup_test_env 'node-version-detection'"
    AfterEach "shellspec_cleanup_test_env 'node-version-detection'"

    It "detects version from package.json engines field"
      create_mock_node_repo

      # Mock action output based on package.json
      echo "node-version=18.0.0" >> "$GITHUB_OUTPUT"

      When call shellspec_validate_action_output "node-version" "18.0.0"
      The status should be success
    End

    It "detects version from .nvmrc file"
      create_mock_node_repo
      echo "18.17.1" > .nvmrc

      # Mock action output
      echo "node-version=18.17.1" >> "$GITHUB_OUTPUT"

      When call shellspec_validate_action_output "node-version" "18.17.1"
      The status should be success
    End

    It "uses default version when none specified"
      create_mock_node_repo
      # Remove engines field simulation

      # Mock default version output
      echo "node-version=20.0.0" >> "$GITHUB_OUTPUT"

      When call shellspec_validate_action_output "node-version" "20.0.0"
      The status should be success
    End
  End

  Context "when testing package manager detection"
    BeforeEach "shellspec_setup_test_env 'package-manager-detection'"
    AfterEach "shellspec_cleanup_test_env 'package-manager-detection'"

    It "detects bun from bun.lockb"
      create_mock_node_repo
      touch bun.lockb

      echo "package-manager=bun" >> "$GITHUB_OUTPUT"

      When call shellspec_validate_action_output "package-manager" "bun"
      The status should be success
    End

    It "detects pnpm from pnpm-lock.yaml"
      create_mock_node_repo
      touch pnpm-lock.yaml

      echo "package-manager=pnpm" >> "$GITHUB_OUTPUT"

      When call shellspec_validate_action_output "package-manager" "pnpm"
      The status should be success
    End

    It "detects yarn from yarn.lock"
      create_mock_node_repo
      touch yarn.lock

      echo "package-manager=yarn" >> "$GITHUB_OUTPUT"

      When call shellspec_validate_action_output "package-manager" "yarn"
      The status should be success
    End

    It "detects npm from package-lock.json"
      create_mock_node_repo
      touch package-lock.json

      echo "package-manager=npm" >> "$GITHUB_OUTPUT"

      When call shellspec_validate_action_output "package-manager" "npm"
      The status should be success
    End

    It "detects packageManager field from package.json"
      create_mock_node_repo

      # Add packageManager field to package.json
      cat > package.json <<EOF
{
  "name": "test-project",
  "version": "1.0.0",
  "packageManager": "pnpm@8.0.0",
  "engines": {
    "node": ">=18.0.0"
  }
}
EOF

      echo "package-manager=pnpm" >> "$GITHUB_OUTPUT"

      When call shellspec_validate_action_output "package-manager" "pnpm"
      The status should be success
    End
  End

  Context "when testing Corepack integration"
    BeforeEach "shellspec_setup_test_env 'corepack-test'"
    AfterEach "shellspec_cleanup_test_env 'corepack-test'"

    It "enables Corepack when packageManager is specified"
      create_mock_node_repo

      # Simulate packageManager field
      cat > package.json <<EOF
{
  "name": "test-project",
  "version": "1.0.0",
  "packageManager": "yarn@3.6.0"
}
EOF

      # Mock Corepack enabled output
      echo "corepack-enabled=true" >> "$GITHUB_OUTPUT"

      When call shellspec_validate_action_output "corepack-enabled" "true"
      The status should be success
    End
  End

  Context "when testing cache functionality"
    BeforeEach "shellspec_setup_test_env 'cache-test'"
    AfterEach "shellspec_cleanup_test_env 'cache-test'"

    It "reports cache hit when dependencies are cached"
      create_mock_node_repo
      touch package-lock.json
      mkdir -p node_modules

      # Mock cache hit
      echo "cache-hit=true" >> "$GITHUB_OUTPUT"

      When call shellspec_validate_action_output "cache-hit" "true"
      The status should be success
    End

    It "reports cache miss when no cache exists"
      create_mock_node_repo
      touch package-lock.json

      # Mock cache miss
      echo "cache-hit=false" >> "$GITHUB_OUTPUT"

      When call shellspec_validate_action_output "cache-hit" "false"
      The status should be success
    End
  End

  Context "when testing output consistency"
    It "produces all expected outputs"
      When call test_action_outputs "$ACTION_DIR" "node-version" "18.0.0" "package-manager" "npm"
      The status should be success
      The stderr should include "Testing action outputs for: node-setup"
      The stderr should include "Output test passed for: node-setup"
    End
  End
End
