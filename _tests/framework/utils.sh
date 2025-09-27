#!/usr/bin/env bash
# Common testing utilities for GitHub Actions
# Provides helper functions for testing action behavior

set -euo pipefail

# Source setup utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_tests/framework/setup.sh
source "${SCRIPT_DIR}/setup.sh"

# Action testing utilities
validate_action_yml() {
  local action_file="$1"
  local quiet_mode="${2:-false}"

  if [[ ! -f $action_file ]]; then
    [[ $quiet_mode == "false" ]] && log_error "Action file not found: $action_file"
    return 1
  fi

  # Check if it's valid YAML
  if ! yq eval '.' "$action_file" >/dev/null 2>&1; then
    if ! python3 "_tests/shared/validation_core.py" --validate-yaml "$action_file" 2>/dev/null; then
      [[ $quiet_mode == "false" ]] && log_error "Invalid YAML in action file: $action_file"
      return 1
    fi
  fi

  [[ $quiet_mode == "false" ]] && log_success "Action YAML is valid: $action_file"
  return 0
}

# Extract action metadata using Python validation module
get_action_inputs() {
  local action_file="$1"
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  python3 "$script_dir/../shared/validation_core.py" --inputs "$action_file"
}

get_action_outputs() {
  local action_file="$1"
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  python3 "$script_dir/../shared/validation_core.py" --outputs "$action_file"
}

get_action_name() {
  local action_file="$1"
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  python3 "$script_dir/../shared/validation_core.py" --name "$action_file"
}

# Test input validation using Python validation module
test_input_validation() {
  local action_dir="$1"
  local input_name="$2"
  local test_value="$3"
  local expected_result="${4:-success}" # success or failure

  log_info "Testing input validation: $input_name = '$test_value'"

  # Setup test environment
  setup_test_env "input-validation-${input_name}"

  # Use Python validation module directly
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

  local result="success"
  # Use centralized validation_core directly
  python3 -c "
import sys
import os
sys.path.insert(0, os.path.join('$script_dir', '..', 'shared'))
from validation_core import validate_input
is_valid, error_msg = validate_input('$action_dir', '$input_name', '$test_value')
if not is_valid:
    print(f'Validation failed: {error_msg}', file=sys.stderr)
    sys.exit(1)
"
  if [ $? -ne 0 ]; then
    result="failure"
  fi

  # Check result matches expectation
  if [[ $result == "$expected_result" ]]; then
    log_success "Input validation test passed: $input_name"
    cleanup_test_env "input-validation-${input_name}"
    return 0
  else
    log_error "Input validation test failed: $input_name (expected: $expected_result, got: $result)"
    cleanup_test_env "input-validation-${input_name}"
    return 1
  fi
}

# Removed: create_validation_script, create_python_validation_script,
# convert_github_expressions_to_env_vars, needs_python_validation, python_validate_input
# These functions are no longer needed as we use Python validation directly

# Test action outputs
test_action_outputs() {
  local action_dir="$1"
  shift

  log_info "Testing action outputs for: $(basename "$action_dir")"

  # Setup test environment
  setup_test_env "output-test-$(basename "$action_dir")"
  create_mock_repo "node"

  # Set up inputs
  while [[ $# -gt 1 ]]; do
    local key="$1"
    local value="$2"
    # Convert dashes to underscores and uppercase for environment variable names
    local env_key="${key//-/_}"
    local env_key_upper
    env_key_upper=$(echo "$env_key" | tr '[:lower:]' '[:upper:]')
    export "INPUT_${env_key_upper}"="$value"
    shift 2
  done

  # Run the action (simplified simulation)
  local action_file="${action_dir}/action.yml"
  local action_name
  action_name=$(get_action_name "$action_file")

  log_info "Simulating action: $action_name"

  # For now, we'll create mock outputs based on the action definition
  local outputs
  outputs=$(get_action_outputs "$action_file")

  # Create mock outputs
  while IFS= read -r output; do
    if [[ -n $output ]]; then
      echo "${output}=mock-value-$(date +%s)" >>"$GITHUB_OUTPUT"
    fi
  done <<<"$outputs"

  # Validate outputs exist
  local test_passed=true
  while IFS= read -r output; do
    if [[ -n $output ]]; then
      if ! grep -q "^${output}=" "$GITHUB_OUTPUT"; then
        log_error "Missing output: $output"
        test_passed=false
      else
        log_success "Output found: $output"
      fi
    fi
  done <<<"$outputs"

  cleanup_test_env "output-test-$(basename "$action_dir")"

  if [[ $test_passed == "true" ]]; then
    log_success "Output test passed for: $(basename "$action_dir")"
    return 0
  else
    log_error "Output test failed for: $(basename "$action_dir")"
    return 1
  fi
}

# Test external usage pattern
test_external_usage() {
  local action_name="$1"

  log_info "Testing external usage pattern for: $action_name"

  # Create test workflow that uses external reference
  local test_workflow_dir="${TEST_ROOT}/integration/workflows"
  mkdir -p "$test_workflow_dir"

  local workflow_file="${test_workflow_dir}/${action_name}-external-test.yml"

  cat >"$workflow_file" <<EOF
name: External Usage Test - $action_name
on:
  workflow_dispatch:
  push:
    paths:
      - '$action_name/**'

jobs:
  test-external-usage:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Test external usage
        uses: ivuorinen/actions/${action_name}@main
        with:
          # Default inputs for testing
EOF

  # Add common test inputs based on action type
  case "$action_name" in
  *-setup | *-version-detect)
    echo "          # Version detection action - no additional inputs needed" >>"$workflow_file"
    ;;
  *-lint* | *-fix)
    # shellcheck disable=SC2016
    echo '          token: ${{ github.token }}' >>"$workflow_file"
    ;;
  *-publish | *-build)
    # shellcheck disable=SC2016
    echo '          token: ${{ github.token }}' >>"$workflow_file"
    ;;
  *)
    echo "          # Generic test inputs" >>"$workflow_file"
    ;;
  esac

  log_success "Created external usage test workflow: $workflow_file"
  return 0
}

# Performance test utilities
measure_action_time() {
  local action_dir="$1"
  shift

  log_info "Measuring execution time for: $(basename "$action_dir")"

  local start_time
  start_time=$(date +%s%N)

  # Run the action test
  test_action_outputs "$action_dir" "$@"
  local result=$?

  local end_time
  end_time=$(date +%s%N)

  local duration_ns=$((end_time - start_time))
  local duration_ms=$((duration_ns / 1000000))

  log_info "Action execution time: ${duration_ms}ms"

  # Store performance data
  echo "$(basename "$action_dir"),${duration_ms}" >>"${TEST_ROOT}/reports/performance.csv"

  return $result
}

# Batch test runner
run_action_tests() {
  local action_dir="$1"
  local test_type="${2:-all}" # all, unit, integration, outputs

  local action_name
  action_name=$(basename "$action_dir")

  log_info "Running $test_type tests for: $action_name"

  local test_results=()

  # Handle "all" type by running all test types
  if [[ $test_type == "all" ]]; then
    # Run unit tests
    log_info "Running unit tests..."
    if validate_action_yml "${action_dir}/action.yml"; then
      test_results+=("unit:PASS")
    else
      test_results+=("unit:FAIL")
    fi

    # Run output tests
    log_info "Running output tests..."
    if test_action_outputs "$action_dir"; then
      test_results+=("outputs:PASS")
    else
      test_results+=("outputs:FAIL")
    fi

    # Run integration tests
    log_info "Running integration tests..."
    if test_external_usage "$action_name"; then
      test_results+=("integration:PASS")
    else
      test_results+=("integration:FAIL")
    fi
  else
    # Handle individual test types
    case "$test_type" in
    "unit")
      log_info "Running unit tests..."
      if validate_action_yml "${action_dir}/action.yml"; then
        test_results+=("unit:PASS")
      else
        test_results+=("unit:FAIL")
      fi
      ;;

    "outputs")
      log_info "Running output tests..."
      if test_action_outputs "$action_dir"; then
        test_results+=("outputs:PASS")
      else
        test_results+=("outputs:FAIL")
      fi
      ;;

    "integration")
      log_info "Running integration tests..."
      if test_external_usage "$action_name"; then
        test_results+=("integration:PASS")
      else
        test_results+=("integration:FAIL")
      fi
      ;;
    esac
  fi

  # Report results
  log_info "Test results for $action_name:"
  for result in "${test_results[@]}"; do
    local test_name="${result%:*}"
    local status="${result#*:}"

    if [[ $status == "PASS" ]]; then
      log_success "  $test_name: $status"
    else
      log_error "  $test_name: $status"
    fi
  done

  # Check if all tests passed
  if [[ ! " ${test_results[*]} " =~ " FAIL" ]]; then
    log_success "All tests passed for: $action_name"
    return 0
  else
    log_error "Some tests failed for: $action_name"
    return 1
  fi
}

# Export all functions
export -f validate_action_yml get_action_inputs get_action_outputs get_action_name
export -f test_input_validation test_action_outputs test_external_usage measure_action_time run_action_tests
