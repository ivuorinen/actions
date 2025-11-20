#!/usr/bin/env bash
# ShellSpec spec helper for GitHub Actions Testing Framework
# This file is automatically loaded by ShellSpec for all tests

set -euo pipefail

# Get the project root directory (where .shellspec is located)
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Test framework directories
TEST_ROOT="${PROJECT_ROOT}/_tests"
FRAMEWORK_DIR="${TEST_ROOT}/framework"
FIXTURES_DIR="${FRAMEWORK_DIR}/fixtures"
MOCKS_DIR="${FRAMEWORK_DIR}/mocks"

# Export directories for use by test cases
export FIXTURES_DIR MOCKS_DIR
# Only create TEMP_DIR if not already set (framework setup.sh will create it)
if [ -z "${TEMP_DIR:-}" ]; then
  TEMP_DIR=$(mktemp -d) || exit 1
fi

# Load framework utilities
# shellcheck source=_tests/framework/setup.sh
source "${FRAMEWORK_DIR}/setup.sh"
# shellcheck source=_tests/framework/utils.sh
source "${FRAMEWORK_DIR}/utils.sh"

# Initialize testing framework
init_testing_framework

# ShellSpec specific setup
spec_helper_configure() {
  # Configure ShellSpec behavior

  # Set up environment variables for tests
  export GITHUB_ACTIONS=true
  export GITHUB_WORKSPACE="${PROJECT_ROOT}"
  export GITHUB_REPOSITORY="ivuorinen/actions"
  export GITHUB_SHA="test-sha"
  export GITHUB_REF="refs/heads/main"
  export GITHUB_TOKEN="test-token"

  # Temporary directory already created by mktemp above

  # Set up default GITHUB_OUTPUT if not already set
  if [[ -z ${GITHUB_OUTPUT:-} ]]; then
    export GITHUB_OUTPUT="${TEMP_DIR}/default-github-output"
    touch "$GITHUB_OUTPUT"
  fi

  # Quiet logging during ShellSpec runs to avoid output interference
  if [[ -z ${SHELLSPEC_VERSION:-} ]]; then
    log_info "ShellSpec helper configured - framework loaded"
  fi
}

# Run configuration
spec_helper_configure

# Helper functions specifically for ShellSpec tests

# Set up default input values for testing a single input
# This prevents validation failures when testing one input at a time
setup_default_inputs() {
  local action_name="$1"
  local input_name="$2"

  case "$action_name" in
  "github-release")
    [[ "$input_name" != "version" ]] && export INPUT_VERSION="1.0.0"
    ;;
  "docker-build" | "docker-publish" | "docker-publish-gh" | "docker-publish-hub")
    [[ "$input_name" != "image-name" ]] && export INPUT_IMAGE_NAME="test-image"
    [[ "$input_name" != "tag" ]] && export INPUT_TAG="latest"
    [[ "$action_name" == "docker-publish" && "$input_name" != "registry" ]] && export INPUT_REGISTRY="dockerhub"
    ;;
  "npm-publish")
    [[ "$input_name" != "npm_token" ]] && export INPUT_NPM_TOKEN="ghp_123456789012345678901234567890123456"
    ;;
  "csharp-publish")
    [[ "$input_name" != "token" ]] && export INPUT_TOKEN="ghp_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
    [[ "$input_name" != "version" ]] && export INPUT_VERSION="1.0.0"
    [[ "$input_name" != "namespace" ]] && export INPUT_NAMESPACE="test-namespace"
    ;;
  "php-composer")
    [[ "$input_name" != "php" ]] && export INPUT_PHP="8.1"
    ;;
  "php-tests" | "php-laravel-phpunit")
    [[ "$input_name" != "php-version" ]] && export INPUT_PHP_VERSION="8.1"
    ;;
  "go-build" | "go-lint")
    [[ "$input_name" != "go-version" ]] && export INPUT_GO_VERSION="1.21"
    ;;
  "common-cache")
    [[ "$input_name" != "type" ]] && export INPUT_TYPE="npm"
    [[ "$input_name" != "paths" ]] && export INPUT_PATHS="node_modules"
    ;;
  "common-retry")
    [[ "$input_name" != "command" ]] && export INPUT_COMMAND="echo test"
    ;;
  "dotnet-version-detect")
    [[ "$input_name" != "default-version" ]] && export INPUT_DEFAULT_VERSION="8.0"
    ;;
  "python-version-detect" | "python-version-detect-v2")
    [[ "$input_name" != "default-version" ]] && export INPUT_DEFAULT_VERSION="3.11"
    ;;
  "php-version-detect")
    [[ "$input_name" != "default-version" ]] && export INPUT_DEFAULT_VERSION="8.1"
    ;;
  "go-version-detect")
    [[ "$input_name" != "default-version" ]] && export INPUT_DEFAULT_VERSION="1.22"
    ;;
  "validate-inputs")
    [[ "$input_name" != "action-type" && "$input_name" != "action" && "$input_name" != "rules-file" && "$input_name" != "fail-on-error" ]] && export INPUT_ACTION_TYPE="test-action"
    ;;
  "codeql-analysis")
    [[ "$input_name" != "language" ]] && export INPUT_LANGUAGE="javascript"
    [[ "$input_name" != "token" ]] && export INPUT_TOKEN="ghp_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
    ;;
  "version-validator")
    [[ "$input_name" != "version" ]] && export INPUT_VERSION="1.0.0"
    ;;
  "release-monthly")
    [[ "$input_name" != "token" ]] && export INPUT_TOKEN="ghp_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
    ;;
  esac
}

# Clean up default input values after testing
cleanup_default_inputs() {
  local action_name="$1"
  local input_name="$2"

  case "$action_name" in
  "github-release")
    [[ "$input_name" != "version" ]] && unset INPUT_VERSION
    ;;
  "docker-build" | "docker-publish" | "docker-publish-gh" | "docker-publish-hub")
    [[ "$input_name" != "image-name" ]] && unset INPUT_IMAGE_NAME
    [[ "$input_name" != "tag" ]] && unset INPUT_TAG
    [[ "$action_name" == "docker-publish" && "$input_name" != "registry" ]] && unset INPUT_REGISTRY
    ;;
  "npm-publish")
    [[ "$input_name" != "npm_token" ]] && unset INPUT_NPM_TOKEN
    ;;
  "csharp-publish")
    [[ "$input_name" != "token" ]] && unset INPUT_TOKEN
    [[ "$input_name" != "version" ]] && unset INPUT_VERSION
    [[ "$input_name" != "namespace" ]] && unset INPUT_NAMESPACE
    ;;
  "php-composer")
    [[ "$input_name" != "php" ]] && unset INPUT_PHP
    ;;
  "php-tests" | "php-laravel-phpunit")
    [[ "$input_name" != "php-version" ]] && unset INPUT_PHP_VERSION
    ;;
  "go-build" | "go-lint")
    [[ "$input_name" != "go-version" ]] && unset INPUT_GO_VERSION
    ;;
  "common-cache")
    [[ "$input_name" != "type" ]] && unset INPUT_TYPE
    [[ "$input_name" != "paths" ]] && unset INPUT_PATHS
    ;;
  "common-retry")
    [[ "$input_name" != "command" ]] && unset INPUT_COMMAND
    ;;
  "dotnet-version-detect")
    [[ "$input_name" != "default-version" ]] && unset INPUT_DEFAULT_VERSION
    ;;
  "python-version-detect" | "python-version-detect-v2")
    [[ "$input_name" != "default-version" ]] && unset INPUT_DEFAULT_VERSION
    ;;
  "php-version-detect")
    [[ "$input_name" != "default-version" ]] && unset INPUT_DEFAULT_VERSION
    ;;
  "go-version-detect")
    [[ "$input_name" != "default-version" ]] && unset INPUT_DEFAULT_VERSION
    ;;
  "validate-inputs")
    [[ "$input_name" != "action-type" && "$input_name" != "action" && "$input_name" != "rules-file" && "$input_name" != "fail-on-error" ]] && unset INPUT_ACTION_TYPE
    ;;
  "codeql-analysis")
    [[ "$input_name" != "language" ]] && unset INPUT_LANGUAGE
    [[ "$input_name" != "token" ]] && unset INPUT_TOKEN
    ;;
  "version-validator")
    [[ "$input_name" != "version" ]] && unset INPUT_VERSION
    ;;
  "release-monthly")
    [[ "$input_name" != "token" ]] && unset INPUT_TOKEN
    ;;
  esac
}

# Enhanced test validation for ShellSpec
shellspec_validate_action_output() {
  local expected_key="$1"
  local expected_value="$2"
  local output_file="${3:-$GITHUB_OUTPUT}"

  if [[ ! -f $output_file ]]; then
    echo "Output file not found: $output_file" >&2
    return 1
  fi

  if grep -Fq "${expected_key}=${expected_value}" "$output_file"; then
    return 0
  else
    echo "Expected output not found: $expected_key=$expected_value" >&2
    echo "Actual outputs:" >&2
    cat "$output_file" >&2
    return 1
  fi
}

# Mock action execution for ShellSpec tests
shellspec_mock_action_run() {
  local action_dir="$1"
  shift

  # Set up inputs as environment variables
  while [[ $# -gt 1 ]]; do
    local key="$1"
    local value="$2"
    # Convert dashes to underscores for environment variable names
    local env_key="${key//-/_}"
    export "INPUT_$(echo "$env_key" | tr '[:lower:]' '[:upper:]')"="$value"
    shift 2
  done

  # For testing, we'll simulate action outputs based on the action type
  local action_name
  action_name=$(basename "$action_dir")

  case "$action_name" in
  "node-setup")
    echo "node-version=18.0.0" >>"$GITHUB_OUTPUT"
    echo "package-manager=npm" >>"$GITHUB_OUTPUT"
    echo "cache-hit=false" >>"$GITHUB_OUTPUT"
    ;;
  "docker-build")
    echo "image-digest=sha256:abc123" >>"$GITHUB_OUTPUT"
    echo "build-time=45" >>"$GITHUB_OUTPUT"
    echo "platforms=linux/amd64" >>"$GITHUB_OUTPUT"
    ;;
  "common-cache")
    echo "cache-hit=true" >>"$GITHUB_OUTPUT"
    echo "cache-key=Linux-npm-abc123" >>"$GITHUB_OUTPUT"
    echo "cache-paths=node_modules" >>"$GITHUB_OUTPUT"
    ;;
  "common-file-check")
    echo "found=true" >>"$GITHUB_OUTPUT"
    ;;
  "common-retry")
    echo "success=true" >>"$GITHUB_OUTPUT"
    echo "attempts=1" >>"$GITHUB_OUTPUT"
    echo "exit-code=0" >>"$GITHUB_OUTPUT"
    echo "duration=5" >>"$GITHUB_OUTPUT"
    ;;
  "compress-images")
    echo "images_compressed=true" >>"$GITHUB_OUTPUT"
    printf "compression_report=## Compression Results\n- 3 images compressed\n- 25%% size reduction\n" >>"$GITHUB_OUTPUT"
    ;;
  "csharp-build")
    echo "build_status=success" >>"$GITHUB_OUTPUT"
    echo "test_status=success" >>"$GITHUB_OUTPUT"
    echo "dotnet_version=7.0" >>"$GITHUB_OUTPUT"
    echo "artifacts_path=**/bin/Release/**/*" >>"$GITHUB_OUTPUT"
    echo "test_results_path=**/*.trx" >>"$GITHUB_OUTPUT"
    ;;
  "csharp-lint-check")
    echo "lint_status=success" >>"$GITHUB_OUTPUT"
    echo "errors_count=0" >>"$GITHUB_OUTPUT"
    echo "warnings_count=0" >>"$GITHUB_OUTPUT"
    ;;
  "csharp-publish")
    echo "publish_status=success" >>"$GITHUB_OUTPUT"
    echo "package_version=1.2.3" >>"$GITHUB_OUTPUT"
    echo "package_url=https://github.com/ivuorinen/packages/nuget" >>"$GITHUB_OUTPUT"
    ;;
  "docker-publish")
    echo "registry=github,dockerhub" >>"$GITHUB_OUTPUT"
    echo "tags=latest,v1.2.3" >>"$GITHUB_OUTPUT"
    echo "build-time=120" >>"$GITHUB_OUTPUT"
    echo 'platform-matrix={"linux/amd64":"success","linux/arm64":"success"}' >>"$GITHUB_OUTPUT"
    echo 'scan-results={"vulnerabilities":0}' >>"$GITHUB_OUTPUT"
    ;;
  "docker-publish-gh")
    echo "image-name=ghcr.io/ivuorinen/test" >>"$GITHUB_OUTPUT"
    echo "digest=sha256:abc123def456" >>"$GITHUB_OUTPUT"
    echo "tags=ghcr.io/ivuorinen/test:latest,ghcr.io/ivuorinen/test:v1.2.3" >>"$GITHUB_OUTPUT"
    echo "provenance=true" >>"$GITHUB_OUTPUT"
    echo "sbom=ghcr.io/ivuorinen/test.sbom" >>"$GITHUB_OUTPUT"
    echo 'scan-results={"vulnerabilities":0,"critical":0}' >>"$GITHUB_OUTPUT"
    echo 'platform-matrix={"linux/amd64":"success","linux/arm64":"success"}' >>"$GITHUB_OUTPUT"
    echo "build-time=180" >>"$GITHUB_OUTPUT"
    ;;
  "docker-publish-hub")
    echo "image-name=ivuorinen/test-app" >>"$GITHUB_OUTPUT"
    echo "digest=sha256:hub123def456" >>"$GITHUB_OUTPUT"
    echo "tags=ivuorinen/test-app:latest,ivuorinen/test-app:v1.2.3" >>"$GITHUB_OUTPUT"
    echo "repo-url=https://hub.docker.com/r/ivuorinen/test-app" >>"$GITHUB_OUTPUT"
    echo 'scan-results={"vulnerabilities":2,"critical":0}' >>"$GITHUB_OUTPUT"
    echo 'platform-matrix={"linux/amd64":"success","linux/arm64":"success"}' >>"$GITHUB_OUTPUT"
    echo "build-time=240" >>"$GITHUB_OUTPUT"
    echo "signature=signed" >>"$GITHUB_OUTPUT"
    ;;
  "dotnet-version-detect")
    echo "dotnet-version=7.0.403" >>"$GITHUB_OUTPUT"
    ;;
  "eslint-check")
    echo "error-count=0" >>"$GITHUB_OUTPUT"
    echo "warning-count=3" >>"$GITHUB_OUTPUT"
    echo "sarif-file=reports/eslint.sarif" >>"$GITHUB_OUTPUT"
    echo "files-checked=15" >>"$GITHUB_OUTPUT"
    ;;
  "eslint-fix")
    echo "fixed-count=5" >>"$GITHUB_OUTPUT"
    echo "files-fixed=3" >>"$GITHUB_OUTPUT"
    echo "error-count=0" >>"$GITHUB_OUTPUT"
    echo "warning-count=0" >>"$GITHUB_OUTPUT"
    ;;
  "github-release")
    echo "release-id=123456789" >>"$GITHUB_OUTPUT"
    echo "release-url=https://github.com/ivuorinen/test/releases/tag/v1.2.3" >>"$GITHUB_OUTPUT"
    echo "asset-urls=https://github.com/ivuorinen/test/releases/download/v1.2.3/app.tar.gz" >>"$GITHUB_OUTPUT"
    echo "tag-name=v1.2.3" >>"$GITHUB_OUTPUT"
    ;;
  "go-build")
    echo "build_status=success" >>"$GITHUB_OUTPUT"
    echo "test_status=success" >>"$GITHUB_OUTPUT"
    echo "go_version=1.21.5" >>"$GITHUB_OUTPUT"
    echo "binary_path=./bin" >>"$GITHUB_OUTPUT"
    echo "coverage_path=coverage.out" >>"$GITHUB_OUTPUT"
    ;;
  "go-lint")
    echo "lint_status=success" >>"$GITHUB_OUTPUT"
    echo "issues_count=0" >>"$GITHUB_OUTPUT"
    echo "files_checked=25" >>"$GITHUB_OUTPUT"
    echo "golangci_version=1.55.2" >>"$GITHUB_OUTPUT"
    ;;
  "go-version-detect")
    echo "go-version=1.21" >>"$GITHUB_OUTPUT"
    ;;
  "npm-publish")
    echo "publish-status=success" >>"$GITHUB_OUTPUT"
    echo "package-version=1.2.3" >>"$GITHUB_OUTPUT"
    echo "registry-url=https://registry.npmjs.org" >>"$GITHUB_OUTPUT"
    echo "package-url=https://www.npmjs.com/package/test-package" >>"$GITHUB_OUTPUT"
    ;;
  "php-composer")
    echo "composer-version=2.6.5" >>"$GITHUB_OUTPUT"
    echo "install-status=success" >>"$GITHUB_OUTPUT"
    echo "dependencies-count=15" >>"$GITHUB_OUTPUT"
    echo "php-version=8.2.0" >>"$GITHUB_OUTPUT"
    echo "lock-file-updated=false" >>"$GITHUB_OUTPUT"
    ;;
  *)
    # Generic mock outputs
    echo "status=success" >>"$GITHUB_OUTPUT"
    ;;
  esac
}

# Use centralized Python validation system for input validation testing
shellspec_test_input_validation() {
  local action_dir="$1"
  local input_name="$2"
  local test_value="$3"
  local expected_result="${4:-success}"

  # Get the action name from the directory
  local action_name
  action_name=$(basename "$action_dir")

  # Set up environment for Python validation
  local temp_output_file
  temp_output_file=$(mktemp)

  # Capture original INPUT_ACTION_TYPE state to restore after test
  local original_action_type_set=false
  local original_action_type_value=""
  if [[ -n "${INPUT_ACTION_TYPE+x}" ]]; then
    original_action_type_set=true
    original_action_type_value="$INPUT_ACTION_TYPE"
  fi

  # Set environment variables for the validation script
  # Only set INPUT_ACTION_TYPE if we're not testing the action input
  if [[ "$input_name" != "action" ]]; then
    export INPUT_ACTION_TYPE="$action_name"
  fi

  # Set default values for commonly required inputs to avoid validation failures
  # when testing only one input at a time
  setup_default_inputs "$action_name" "$input_name"

  # Convert input name to uppercase and replace dashes with underscores
  local input_var_name
  input_var_name="INPUT_${input_name//-/_}"
  input_var_name="$(echo "$input_var_name" | tr '[:lower:]' '[:upper:]')"
  export "$input_var_name"="$test_value"
  export GITHUB_OUTPUT="$temp_output_file"

  # Run the Python validation script and capture exit code
  local exit_code
  if python3 "${PROJECT_ROOT}/validate-inputs/validator.py" >/dev/null 2>&1; then
    exit_code=0
  else
    exit_code=1
  fi

  # Determine the actual result based on exit code
  local actual_result
  if [[ $exit_code -eq 0 ]]; then
    actual_result="success"
  else
    actual_result="failure"
  fi

  # Clean up
  rm -f "$temp_output_file" 2>/dev/null || true
  unset "$input_var_name"

  # Clean up default inputs
  cleanup_default_inputs "$action_name" "$input_name"

  # Restore original INPUT_ACTION_TYPE state
  if [[ "$original_action_type_set" == "true" ]]; then
    export INPUT_ACTION_TYPE="$original_action_type_value"
  else
    unset INPUT_ACTION_TYPE
  fi

  # Return based on expected result
  if [[ $actual_result == "$expected_result" ]]; then
    return 0
  else
    return 1
  fi
}

# Test environment setup that works with ShellSpec
shellspec_setup_test_env() {
  local test_name="${1:-shellspec-test}"

  # Create unique temporary directory for this test
  export SHELLSPEC_TEST_TEMP_DIR="${TEMP_DIR}/${test_name}-$$"
  mkdir -p "$SHELLSPEC_TEST_TEMP_DIR"

  # Create fake GitHub workspace
  export SHELLSPEC_TEST_WORKSPACE="${SHELLSPEC_TEST_TEMP_DIR}/workspace"
  mkdir -p "$SHELLSPEC_TEST_WORKSPACE"

  # Setup fake GitHub outputs
  export GITHUB_OUTPUT="${SHELLSPEC_TEST_TEMP_DIR}/github-output"
  export GITHUB_ENV="${SHELLSPEC_TEST_TEMP_DIR}/github-env"
  export GITHUB_PATH="${SHELLSPEC_TEST_TEMP_DIR}/github-path"
  export GITHUB_STEP_SUMMARY="${SHELLSPEC_TEST_TEMP_DIR}/github-step-summary"

  # Initialize output files
  touch "$GITHUB_OUTPUT" "$GITHUB_ENV" "$GITHUB_PATH" "$GITHUB_STEP_SUMMARY"

  # Change to test workspace
  cd "$SHELLSPEC_TEST_WORKSPACE"
}

# Test environment cleanup for ShellSpec
shellspec_cleanup_test_env() {
  local test_name="${1:-shellspec-test}"

  if [[ -n ${SHELLSPEC_TEST_TEMP_DIR:-} && -d $SHELLSPEC_TEST_TEMP_DIR ]]; then
    rm -rf "$SHELLSPEC_TEST_TEMP_DIR"
  fi

  # Return to project root
  cd "$PROJECT_ROOT"
}

# Export functions for use in specs
export -f shellspec_validate_action_output shellspec_mock_action_run
export -f shellspec_setup_test_env shellspec_cleanup_test_env shellspec_test_input_validation

# Create alias for backward compatibility (override framework version)
test_input_validation() {
  shellspec_test_input_validation "$@"
}

# Export all framework functions for backward compatibility
export -f setup_test_env cleanup_test_env create_mock_repo
export -f create_mock_node_repo
export -f validate_action_output check_required_tools
export -f log_info log_success log_warning log_error
export -f validate_action_yml get_action_inputs get_action_outputs get_action_name
export -f test_action_outputs test_external_usage test_input_validation

# Quiet wrapper for validate_action_yml in tests
validate_action_yml_quiet() {
  validate_action_yml "$1" "true"
}

# =============================================================================
# VALIDATION TEST HELPERS
# =============================================================================
# Note: These helpers return validation results but cannot use ShellSpec commands
# They must be called from within ShellSpec It blocks

# Modern Python-based validation function for direct testing
validate_input_python() {
  local action_type="$1"
  local input_name="$2"
  local input_value="$3"

  # Set up environment variables for Python validator
  export INPUT_ACTION_TYPE="$action_type"
  export VALIDATOR_QUIET="1" # Suppress success messages for tests

  # Set default values for commonly required inputs to avoid validation failures
  # when testing only one input at a time
  setup_default_inputs "$action_type" "$input_name"

  # Set the target input
  local input_var_name="INPUT_${input_name//-/_}"
  input_var_name="$(echo "$input_var_name" | tr '[:lower:]' '[:upper:]')"
  export "$input_var_name"="$input_value"

  # Set up GitHub output file
  local temp_output
  temp_output=$(mktemp)
  export GITHUB_OUTPUT="$temp_output"

  # Call Python validator directly

  if [[ "${SHELLSPEC_DEBUG:-}" == "1" ]]; then
    echo "DEBUG: Testing $action_type $input_name=$input_value"
    echo "DEBUG: Environment variables:"
    env | grep "^INPUT_" | sort
  fi

  # Run validator and output everything to stdout for ShellSpec
  uv run "${PROJECT_ROOT}/validate-inputs/validator.py" 2>&1
  local exit_code=$?

  # Clean up target input
  unset INPUT_ACTION_TYPE "$input_var_name" GITHUB_OUTPUT VALIDATOR_QUIET
  rm -f "$temp_output" 2>/dev/null || true

  # Clean up default inputs
  cleanup_default_inputs "$action_type" "$input_name"

  # Return the exit code for ShellSpec to check
  return $exit_code
}

# Export all new simplified helpers (functions are moved above)
export -f validate_action_yml_quiet validate_input_python

# Removed EXIT trap setup to avoid conflicts with ShellSpec
# ShellSpec handles its own cleanup, and our framework cleanup is handled in setup.sh

# Quiet logging during ShellSpec runs
if [[ -z ${SHELLSPEC_VERSION:-} ]]; then
  log_success "ShellSpec spec helper loaded successfully"
fi
