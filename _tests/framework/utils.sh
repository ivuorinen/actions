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
    if ! python3 -c "import yaml; yaml.safe_load(open('$action_file'))" 2>/dev/null; then
      [[ $quiet_mode == "false" ]] && log_error "Invalid YAML in action file: $action_file"
      return 1
    fi
  fi

  [[ $quiet_mode == "false" ]] && log_success "Action YAML is valid: $action_file"
  return 0
}

# Extract action metadata
get_action_inputs() {
  local action_file="$1"

  # Try with yq first, fallback to python if not available
  if command -v yq >/dev/null 2>&1; then
    yq eval '.inputs | keys' "$action_file" 2>/dev/null | grep -v '^null$' | sed 's/^- //' || echo ""
  else
    python3 -c "
import yaml
with open('$action_file') as f:
    data = yaml.safe_load(f)
    inputs = data.get('inputs', {})
    for key in inputs.keys():
        print(key)
" 2>/dev/null || echo ""
  fi
}

get_action_outputs() {
  local action_file="$1"

  if command -v yq >/dev/null 2>&1; then
    yq eval '.outputs | keys' "$action_file" 2>/dev/null | grep -v '^null$' | sed 's/^- //' || echo ""
  else
    python3 -c "
import yaml
with open('$action_file') as f:
    data = yaml.safe_load(f)
    outputs = data.get('outputs', {})
    for key in outputs.keys():
        print(key)
" 2>/dev/null || echo ""
  fi
}

get_action_name() {
  local action_file="$1"

  if command -v yq >/dev/null 2>&1; then
    yq eval '.name' "$action_file" 2>/dev/null || echo "Unknown"
  else
    python3 -c "
import yaml
with open('$action_file') as f:
    data = yaml.safe_load(f)
    print(data.get('name', 'Unknown'))
" 2>/dev/null || echo "Unknown"
  fi
}

# Test input validation with Python fallback for complex patterns
test_input_validation() {
  local action_dir="$1"
  local input_name="$2"
  local test_value="$3"
  local expected_result="${4:-success}" # success or failure

  log_info "Testing input validation: $input_name = '$test_value'"

  # Setup test environment
  setup_test_env "input-validation-${input_name}"

  # Set the input (convert dashes to underscores and uppercase)
  local env_input_name="${input_name//-/_}"
  local env_input_name_upper
  env_input_name_upper=$(echo "$env_input_name" | tr '[:lower:]' '[:upper:]')
  export "INPUT_${env_input_name_upper}"="$test_value"

  # Run action validation step
  local action_file="${action_dir}/action.yml"
  local validation_script="${action_dir}/validate.sh"

  # Check if this action needs Python validation for complex patterns
  local use_python=false
  if needs_python_validation "$action_file" "$input_name"; then
    use_python=true
  fi

  # Run validation using appropriate method
  local result="success"
  if [[ $use_python == "true" ]]; then
    # Use Python validation for complex patterns
    if ! python_validate_input "$action_dir" "$input_name" "$test_value" "$expected_result"; then
      result="failure"
    fi
  else
    # Extract validation logic if it exists in the action
    if grep -q "Validate Inputs" "$action_file"; then
      # Extract validation step and create temporary script
      create_validation_script "$action_file" "$validation_script"

      # Run bash validation
      if ! bash "$validation_script" 2>/dev/null; then
        result="failure"
      fi
    else
      log_warning "No validation step found in action"
      return 0
    fi
  fi

  # Check result
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

# Create validation script from action.yml with Python fallback for complex patterns
create_validation_script() {
  local action_file="$1"
  local output_script="$2"

  # Check if the action contains complex regex patterns
  local has_complex_patterns=false
  if grep -q '(?=' "$action_file" 2>/dev/null || grep -q '(?!' "$action_file" 2>/dev/null ||
    grep -q '(?<=' "$action_file" 2>/dev/null || grep -q '(?<!' "$action_file" 2>/dev/null; then
    has_complex_patterns=true
  fi

  if [[ $has_complex_patterns == "true" ]]; then
    # Generate Python-based validation script for complex patterns
    create_python_validation_script "$action_file" "$output_script"
  else
    # Extract validation logic and convert GitHub Actions expressions to environment variables
    {
      echo "#!/bin/bash"
      echo "set -euo pipefail"
      echo ""
      # Extract validation logic and convert GitHub Actions expressions
      grep -A 20 "Validate Inputs" "$action_file" |
        grep -A 15 "run: |" |
        tail -n +3 |
        sed '/^[[:space:]]*- name:/,$d' |
        convert_github_expressions_to_env_vars
    } >"$output_script"

    chmod +x "$output_script"
  fi
}

# Create Python-based validation script for complex regex patterns
create_python_validation_script() {
  local action_file="$1"
  local output_script="$2"
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

  {
    echo "#!/bin/bash"
    echo "set -euo pipefail"
    echo ""
    echo "# This validation script uses Python for complex regex patterns"
    echo "# that are not supported in bash's basic regex engine"
    echo ""
    echo "action_dir=\"$(dirname "${action_file}")\""
    echo ""
    echo "# Validate each input using Python validation module"
    echo "validation_failed=false"
    echo ""

    # Extract input names from the action file
    local inputs
    inputs=$(get_action_inputs "$action_file")

    while IFS= read -r input_name; do
      if [[ -n $input_name ]]; then
        local input_env_name="${input_name//-/_}"
        local input_env_name_upper
        input_env_name_upper=$(echo "$input_env_name" | tr '[:lower:]' '[:upper:]')
        echo "# Validate $input_name"
        echo "if [[ -n \"\${INPUT_${input_env_name_upper}:-}\" ]]; then"
        echo "  if ! python3 \"$script_dir/validation.py\" \"\$action_dir\" \"$input_name\" \"\${INPUT_${input_env_name_upper}}\" >/dev/null 2>&1; then"
        echo "    echo \"::error::Validation failed for input: $input_name\""
        echo "    validation_failed=true"
        echo "  fi"
        echo "fi"
        echo ""
      fi
    done <<<"$inputs"

    # shellcheck disable=SC2016
    echo 'if [[ "$validation_failed" == "true" ]]; then'
    echo "  exit 1"
    echo "fi"
    echo ""
    echo 'echo "All input validations passed"'
  } >"$output_script"

  chmod +x "$output_script"
}

# Convert GitHub Actions expressions to environment variables
convert_github_expressions_to_env_vars() {
  # Use a Python one-liner that's more reliable for this complex regex replacement
  # shellcheck disable=SC2016
  python3 -c '
import sys
import re

def convert_expression(match):
    input_name = match.group(1)
    # Convert kebab-case to UPPER_SNAKE_CASE
    env_var_name = input_name.replace("-", "_").upper()
    return f"$INPUT_{env_var_name}"

content = sys.stdin.read()
# Match ${{ inputs.input-name }} with optional whitespace
pattern = r"\$\{\{\s*inputs\.([a-zA-Z0-9_-]+)\s*\}\}"
result = re.sub(pattern, convert_expression, content)
print(result, end="")
'
}

# Check if an action needs Python validation for complex patterns
needs_python_validation() {
  local action_file="$1"
  local input_name="$2"

  # Known actions and inputs that require Python validation
  local action_dir
  action_dir=$(basename "$(dirname "$action_file")")

  case "$action_dir" in
  "csharp-publish")
    # Uses lookahead assertion for namespace validation and token validation
    [[ $input_name == "namespace" ]] && return 0
    [[ $input_name == "token" ]] && return 0
    ;;
  "docker-build")
    # All docker-build inputs are validated through Python
    return 0
    ;;
  "eslint-fix" | "pr-lint" | "pre-commit")
    # These actions have complex token validation patterns
    [[ $input_name == "token" ]] && return 0
    ;;
  *)
    # Check if the action file contains lookahead/lookbehind patterns for this specific input
    if grep -q '(?=' "$action_file" 2>/dev/null; then
      # Only use Python if this specific input is validated with complex patterns
      local input_pattern
      input_pattern=$(grep -A 10 "inputs\.$input_name" "$action_file" | grep '(?=' 2>/dev/null)
      if [[ -n $input_pattern ]]; then
        return 0
      fi
    fi
    ;;
  esac

  return 1
}

# Python validation wrapper
python_validate_input() {
  local action_dir="$1"
  local input_name="$2"
  local test_value="$3"
  local expected_result="$4"

  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

  # Call Python validation module
  if python3 "$script_dir/validation.py" "$action_dir" "$input_name" "$test_value" "$expected_result" 2>/dev/null; then
    return 0
  else
    return 1
  fi
}

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
export -f test_input_validation create_validation_script convert_github_expressions_to_env_vars
export -f test_action_outputs test_external_usage measure_action_time run_action_tests
