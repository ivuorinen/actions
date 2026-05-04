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

# Export directories for use by test cases and harness_wrapper functions
export PROJECT_ROOT TEST_ROOT FRAMEWORK_DIR FIXTURES_DIR MOCKS_DIR
# Only create TEMP_DIR if not already set (framework setup.sh will create it).
# Track ownership so the EXIT trap only deletes what this script created.
# A caller-provided TEMP_DIR (e.g. an inherited env var pointing to scratch
# space) MUST NOT be rm -rf'd.
if [ -z "${TEMP_DIR:-}" ]; then
  TEMP_DIR=$(mktemp -d) || exit 1
  _SPEC_HELPER_OWNS_TEMP_DIR=1
fi

# Clean TEMP_DIR on shell exit ONLY if we created it ourselves.
_spec_helper_cleanup_tempdir() {
  if [[ "${_SPEC_HELPER_OWNS_TEMP_DIR:-}" == "1" && -n "${TEMP_DIR:-}" && -d "${TEMP_DIR}" ]]; then
    rm -rf "${TEMP_DIR}"
  fi
}
trap _spec_helper_cleanup_tempdir EXIT

# Load framework utilities
# shellcheck source=_tests/framework/setup.sh
source "${FRAMEWORK_DIR}/setup.sh"
# shellcheck source=_tests/framework/utils.sh
source "${FRAMEWORK_DIR}/utils.sh"
# shellcheck source=_tests/framework/harness_wrapper.sh
source "${FRAMEWORK_DIR}/harness_wrapper.sh"

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
  "docker-build" | "docker-publish")
    [[ "$input_name" != "image-name" ]] && export INPUT_IMAGE_NAME="test-image"
    [[ "$input_name" != "tag" ]] && export INPUT_TAG="latest"
    [[ "$action_name" == "docker-publish" && "$input_name" != "registry" ]] && export INPUT_REGISTRY="dockerhub"
    ;;
  "npm-publish" | "npm-semantic-release")
    [[ "$input_name" != "npm_token" ]] && export INPUT_NPM_TOKEN="ghp_123456789012345678901234567890123456"
    ;;
  "csharp-publish")
    [[ "$input_name" != "token" ]] && export INPUT_TOKEN="ghp_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
    [[ "$input_name" != "version" ]] && export INPUT_VERSION="1.0.0"
    [[ "$input_name" != "namespace" ]] && export INPUT_NAMESPACE="test-namespace"
    ;;
  "php-tests")
    [[ "$input_name" != "php-version" ]] && export INPUT_PHP_VERSION="8.1"
    ;;
  "go-build" | "go-lint")
    [[ "$input_name" != "go-version" ]] && export INPUT_GO_VERSION="1.21"
    ;;
  "validate-inputs")
    [[ "$input_name" != "action-type" && "$input_name" != "action" && "$input_name" != "rules-file" && "$input_name" != "fail-on-error" ]] && export INPUT_ACTION_TYPE="test-action"
    ;;
  "codeql-analysis")
    [[ "$input_name" != "language" ]] && export INPUT_LANGUAGE="javascript"
    [[ "$input_name" != "token" ]] && export INPUT_TOKEN="ghp_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
    ;;
  "release-monthly")
    [[ "$input_name" != "token" ]] && export INPUT_TOKEN="ghp_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
    ;;
  "language-version-detect")
    [ "$input_name" != "language" ] && export INPUT_LANGUAGE="php"
    ;;
  esac
}

# Clean up default input values after testing
cleanup_default_inputs() {
  local action_name="$1"
  local input_name="$2"

  case "$action_name" in
  "docker-build" | "docker-publish")
    [[ "$input_name" != "image-name" ]] && unset INPUT_IMAGE_NAME
    [[ "$input_name" != "tag" ]] && unset INPUT_TAG
    [[ "$action_name" == "docker-publish" && "$input_name" != "registry" ]] && unset INPUT_REGISTRY
    ;;
  "npm-publish" | "npm-semantic-release")
    [[ "$input_name" != "npm_token" ]] && unset INPUT_NPM_TOKEN
    ;;
  "csharp-publish")
    [[ "$input_name" != "token" ]] && unset INPUT_TOKEN
    [[ "$input_name" != "version" ]] && unset INPUT_VERSION
    [[ "$input_name" != "namespace" ]] && unset INPUT_NAMESPACE
    ;;
  "php-tests")
    [[ "$input_name" != "php-version" ]] && unset INPUT_PHP_VERSION
    ;;
  "go-build" | "go-lint")
    [[ "$input_name" != "go-version" ]] && unset INPUT_GO_VERSION
    ;;
  "validate-inputs")
    [[ "$input_name" != "action-type" && "$input_name" != "action" && "$input_name" != "rules-file" && "$input_name" != "fail-on-error" ]] && unset INPUT_ACTION_TYPE
    ;;
  "codeql-analysis")
    [[ "$input_name" != "language" ]] && unset INPUT_LANGUAGE
    [[ "$input_name" != "token" ]] && unset INPUT_TOKEN
    ;;
  "release-monthly")
    [[ "$input_name" != "token" ]] && unset INPUT_TOKEN
    ;;
  "language-version-detect")
    [ "$input_name" != "language" ] && unset INPUT_LANGUAGE
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

  # Whole-line match (-x) so a prefix like "status=success" doesn't
  # falsely match "status=successfully-failed".
  if grep -Fxq "${expected_key}=${expected_value}" "$output_file"; then
    return 0
  else
    echo "Expected output not found: $expected_key=$expected_value" >&2
    echo "Actual outputs:" >&2
    cat "$output_file" >&2
    return 1
  fi
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

  # Run the Python validation script and capture exit code. Use uv when
  # available so PyYAML resolves consistently across both helpers.
  local exit_code
  if _harness_python "${PROJECT_ROOT}/validate-inputs/validator.py" >/dev/null 2>&1; then
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
export -f shellspec_validate_action_output
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

  # Save INPUT_ACTION_TYPE set-vs-unset state so we can restore it exactly.
  local _saved_action_type_set=false
  local _saved_action_type=""
  if [ -n "${INPUT_ACTION_TYPE+x}" ]; then
    _saved_action_type_set=true
    _saved_action_type="$INPUT_ACTION_TYPE"
  fi

  # When the `action` input itself is being tested, don't pre-set
  # INPUT_ACTION_TYPE — the test is simulating a caller that passes only
  # `action:` and expects its value to flow through validator.py's
  # action_type fallback (where format validation kicks in).
  if [[ "$input_name" != "action" ]]; then
    export INPUT_ACTION_TYPE="$action_type"
  fi
  export VALIDATOR_QUIET="1" # Suppress success messages for tests

  # Set default values for commonly required inputs to avoid validation failures
  # when testing only one input at a time
  setup_default_inputs "$action_type" "$input_name"

  # When testing the `action` input with a value that names a real action,
  # also apply that action's default inputs so downstream validation has
  # the required fields populated (e.g. INPUT_IMAGE_NAME for docker-build).
  # Normalize underscores → dashes so e.g. npm_publish resolves to the
  # npm-publish case branch in setup_default_inputs.
  if [[ "$input_name" == "action" && -n "$input_value" ]]; then
    local normalized_action="${input_value//_/-}"
    setup_default_inputs "$normalized_action" "_action_test_sentinel"
  fi

  # Set the target input
  local input_var_name="INPUT_${input_name//-/_}"
  input_var_name="$(echo "$input_var_name" | tr '[:lower:]' '[:upper:]')"
  export "$input_var_name"="$input_value"

  # T-M3: save caller's GITHUB_OUTPUT (set vs unset) so we can restore it exactly.
  local _saved_github_output_set=false
  local _saved_github_output=""
  if [ -n "${GITHUB_OUTPUT+x}" ]; then
    _saved_github_output_set=true
    _saved_github_output="$GITHUB_OUTPUT"
  fi

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
  # Use || to capture non-zero exit without triggering set -e, ensuring cleanup runs
  local exit_code=0
  _harness_python "${PROJECT_ROOT}/validate-inputs/validator.py" 2>&1 || exit_code=$?

  # Clean up target input
  unset "$input_var_name" VALIDATOR_QUIET
  rm -f "$temp_output" 2>/dev/null || true

  # T-M3: restore GITHUB_OUTPUT exactly (handles set-to-empty vs unset)
  if [ "$_saved_github_output_set" = "true" ]; then
    export GITHUB_OUTPUT="$_saved_github_output"
  else
    unset GITHUB_OUTPUT
  fi

  # Restore INPUT_ACTION_TYPE exactly (handles set-to-empty vs unset)
  if [ "$_saved_action_type_set" = "true" ]; then
    export INPUT_ACTION_TYPE="$_saved_action_type"
  else
    unset INPUT_ACTION_TYPE
  fi

  # Clean up default inputs
  cleanup_default_inputs "$action_type" "$input_name"
  if [ "$input_name" = "action" ] && [ -n "$input_value" ]; then
    local normalized_action
    normalized_action=$(echo "$input_value" | tr '_' '-')
    cleanup_default_inputs "$normalized_action" "_action_test_sentinel"
  fi

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
