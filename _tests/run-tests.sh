#!/usr/bin/env bash
# GitHub Actions Testing Framework - Main Test Runner
# Executes tests across all levels: unit, integration, and e2e

set -euo pipefail

# Script directory and test root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_ROOT="$SCRIPT_DIR"

# Source framework utilities
# shellcheck source=_tests/framework/setup.sh
source "${TEST_ROOT}/framework/setup.sh"

# Configuration
DEFAULT_TEST_TYPE="all"
DEFAULT_ACTION_FILTER=""
PARALLEL_JOBS=4
COVERAGE_ENABLED=true
REPORT_FORMAT="console"

# Usage information
usage() {
  cat <<EOF
GitHub Actions Testing Framework

Usage: $0 [OPTIONS] [ACTION_NAME...]

OPTIONS:
    -t, --type TYPE         Test type: unit, integration, e2e, all (default: all)
    -a, --action ACTION     Filter by specific action name
    -j, --jobs JOBS         Number of parallel jobs (default: 4)
    -c, --coverage          Enable coverage reporting (default: true)
    --no-coverage           Disable coverage reporting
    -f, --format FORMAT     Report format: console, json, junit (default: console)
    -v, --verbose           Enable verbose output
    -h, --help              Show this help message

EXAMPLES:
    $0                                  # Run all tests for all actions
    $0 -t unit                          # Run only unit tests
    $0 -a node-setup                    # Test only node-setup action
    $0 -t integration docker-build      # Integration tests for docker-build
    $0 --format json --coverage         # Full tests with JSON output and coverage

TEST TYPES:
    unit         - Fast unit tests for action validation and logic
    integration  - Integration tests using nektos/act or workflows
    e2e          - End-to-end tests with complete workflows
    all          - All test types (default)

EOF
}

# Parse command line arguments
parse_args() {
  local test_type="$DEFAULT_TEST_TYPE"
  local action_filter="$DEFAULT_ACTION_FILTER"
  local actions=()

  while [[ $# -gt 0 ]]; do
    case $1 in
    -t | --type)
      test_type="$2"
      shift 2
      ;;
    -a | --action)
      action_filter="$2"
      shift 2
      ;;
    -j | --jobs)
      PARALLEL_JOBS="$2"
      shift 2
      ;;
    -c | --coverage)
      COVERAGE_ENABLED=true
      shift
      ;;
    --no-coverage)
      COVERAGE_ENABLED=false
      shift
      ;;
    -f | --format)
      REPORT_FORMAT="$2"
      shift 2
      ;;
    -v | --verbose)
      set -x
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    --)
      shift
      actions+=("$@")
      break
      ;;
    -*)
      log_error "Unknown option: $1"
      usage
      exit 1
      ;;
    *)
      actions+=("$1")
      shift
      ;;
    esac
  done

  # Export for use in other functions
  export TEST_TYPE="$test_type"
  export ACTION_FILTER="$action_filter"
  export TARGET_ACTIONS=("${actions[@]}")
}

# Discover available actions
discover_actions() {
  local actions=()

  if [[ ${#TARGET_ACTIONS[@]} -gt 0 ]]; then
    # Use provided actions
    actions=("${TARGET_ACTIONS[@]}")
  elif [[ -n $ACTION_FILTER ]]; then
    # Filter by pattern
    while IFS= read -r action_dir; do
      local action_name
      action_name=$(basename "$action_dir")
      if [[ $action_name == *"$ACTION_FILTER"* ]]; then
        actions+=("$action_name")
      fi
    done < <(find "${TEST_ROOT}/.." -mindepth 1 -maxdepth 1 -type d -name "*-*" | sort)
  else
    # All actions
    while IFS= read -r action_dir; do
      local action_name
      action_name=$(basename "$action_dir")
      actions+=("$action_name")
    done < <(find "${TEST_ROOT}/.." -mindepth 1 -maxdepth 1 -type d -name "*-*" | sort)
  fi

  log_info "Discovered ${#actions[@]} actions to test: ${actions[*]}"
  printf '%s\n' "${actions[@]}"
}

# Check if required tools are available
check_dependencies() {
  # Check for ShellSpec
  if ! command -v shellspec >/dev/null 2>&1; then
    log_warning "ShellSpec not found, attempting to install..."
    install_shellspec
  fi

  # Check for act (if running integration tests)
  if [[ $TEST_TYPE == "integration" || $TEST_TYPE == "all" ]]; then
    if ! command -v act >/dev/null 2>&1; then
      log_warning "nektos/act not found, integration tests will be limited"
    fi
  fi

  # Check for coverage tools (if enabled)
  if [[ $COVERAGE_ENABLED == "true" ]]; then
    if ! command -v kcov >/dev/null 2>&1; then
      log_warning "kcov not found, coverage reporting disabled"
      COVERAGE_ENABLED=false
    fi
  fi

  log_success "Dependency check completed"
}

# Install ShellSpec if not available
install_shellspec() {
  log_info "Installing ShellSpec testing framework..."

  local shellspec_version="0.28.1"
  local install_dir="${HOME}/.local"

  # Download and install ShellSpec
  curl -fsSL "https://github.com/shellspec/shellspec/archive/refs/tags/${shellspec_version}.tar.gz" |
    tar -xzC /tmp/

  cd "/tmp/shellspec-${shellspec_version}"
  make install PREFIX="$install_dir"

  # Add to PATH if not already there
  if [[ ":$PATH:" != *":${install_dir}/bin:"* ]]; then
    export PATH="${install_dir}/bin:$PATH"
    echo "export PATH=\"${install_dir}/bin:\$PATH\"" >>~/.bashrc
  fi

  if command -v shellspec >/dev/null 2>&1; then
    log_success "ShellSpec installed successfully"
  else
    log_error "Failed to install ShellSpec"
    exit 1
  fi
}

# Run unit tests
run_unit_tests() {
  local actions=("$@")
  local failed_tests=()
  local passed_tests=()

  log_info "Running unit tests for ${#actions[@]} actions..."

  # Create test results directory
  mkdir -p "${TEST_ROOT}/reports/unit"

  for action in "${actions[@]}"; do
    local unit_test_dir="${TEST_ROOT}/unit/${action}"

    if [[ -d $unit_test_dir ]]; then
      log_info "Running unit tests for: $action"

      # Run ShellSpec tests
      local test_result=0
      local output_file="${TEST_ROOT}/reports/unit/${action}.txt"

      if (cd "$TEST_ROOT/.." && shellspec \
        --format documentation \
        "$unit_test_dir") >"$output_file" 2>&1; then

        log_success "Unit tests passed: $action"
        passed_tests+=("$action")
      else
        log_error "Unit tests failed: $action"
        failed_tests+=("$action")
        test_result=1
      fi

      # Show summary if verbose or on failure
      if [[ $test_result -ne 0 || ${BASHOPTS:-} == *"xtrace"* || $- == *x* ]]; then
        echo "--- Test output for $action ---"
        cat "$output_file"
        echo "--- End test output ---"
      fi
    else
      log_warning "No unit tests found for: $action"
    fi
  done

  # Report results
  log_info "Unit test results:"
  log_success "  Passed: ${#passed_tests[@]} actions"
  if [[ ${#failed_tests[@]} -gt 0 ]]; then
    log_error "  Failed: ${#failed_tests[@]} actions (${failed_tests[*]})"
    return 1
  fi

  return 0
}

# Run integration tests using nektos/act
run_integration_tests() {
  local actions=("$@")
  local failed_tests=()
  local passed_tests=()

  log_info "Running integration tests for ${#actions[@]} actions..."

  # Create test results directory
  mkdir -p "${TEST_ROOT}/reports/integration"

  for action in "${actions[@]}"; do
    local workflow_file="${TEST_ROOT}/integration/workflows/${action}-test.yml"

    if [[ -f $workflow_file ]]; then
      log_info "Running integration test workflow for: $action"

      # Run with act if available, otherwise skip
      if command -v act >/dev/null 2>&1; then
        local output_file="${TEST_ROOT}/reports/integration/${action}.txt"

        # Create temp directory for artifacts
        local artifacts_dir
        artifacts_dir=$(mktemp -d) || exit 1

        if act workflow_dispatch \
          -W "$workflow_file" \
          --container-architecture linux/amd64 \
          --artifact-server-path "$artifacts_dir" \
          >"$output_file" 2>&1; then

          log_success "Integration tests passed: $action"
          passed_tests+=("$action")
        else
          log_error "Integration tests failed: $action"
          failed_tests+=("$action")

          # Show output on failure
          echo "--- Integration test output for $action ---"
          cat "$output_file"
          echo "--- End integration test output ---"
        fi

        # Clean up artifacts directory
        rm -rf "$artifacts_dir"
      else
        log_warning "Skipping integration test for $action (act not available)"
      fi
    else
      log_warning "No integration test workflow found for: $action"
    fi
  done

  # Report results
  log_info "Integration test results:"
  log_success "  Passed: ${#passed_tests[@]} actions"
  if [[ ${#failed_tests[@]} -gt 0 ]]; then
    log_error "  Failed: ${#failed_tests[@]} actions (${failed_tests[*]})"
    return 1
  fi

  return 0
}

# Generate test coverage report
generate_coverage_report() {
  if [[ $COVERAGE_ENABLED != "true" ]]; then
    return 0
  fi

  log_info "Generating coverage report..."

  local coverage_dir="${TEST_ROOT}/coverage"
  mkdir -p "$coverage_dir"

  # This is a simplified coverage implementation
  # In practice, you'd integrate with kcov or similar tools

  # Count tested vs total actions
  local total_actions
  total_actions=$(find "${TEST_ROOT}/.." -mindepth 1 -maxdepth 1 -type d -name "*-*" | wc -l)

  local tested_actions
  tested_actions=$(find "${TEST_ROOT}/unit" -mindepth 1 -maxdepth 1 -type d | wc -l)

  local coverage_percent
  coverage_percent=$(((tested_actions * 100) / total_actions))

  cat >"${coverage_dir}/summary.json" <<EOF
{
  "total_actions": $total_actions,
  "tested_actions": $tested_actions,
  "coverage_percent": $coverage_percent,
  "generated_at": "$(date -Iseconds)"
}
EOF

  log_success "Coverage report generated: ${coverage_percent}% ($tested_actions/$total_actions actions)"
}

# Generate test report
generate_test_report() {
  log_info "Generating test report in format: $REPORT_FORMAT"

  local report_dir="${TEST_ROOT}/reports"
  mkdir -p "$report_dir"

  case "$REPORT_FORMAT" in
  "json")
    generate_json_report
    ;;
  "junit")
    log_warning "JUnit report format not yet implemented, using JSON instead"
    generate_json_report
    ;;
  "console" | *)
    generate_console_report
    ;;
  esac
}

# Generate JSON test report
generate_json_report() {
  local report_file="${TEST_ROOT}/reports/test-results.json"

  cat >"$report_file" <<EOF
{
  "test_run": {
    "timestamp": "$(date -Iseconds)",
    "type": "$TEST_TYPE",
    "action_filter": "$ACTION_FILTER",
    "parallel_jobs": $PARALLEL_JOBS,
    "coverage_enabled": $COVERAGE_ENABLED
  },
  "results": {
    "unit_tests": "$(find "${TEST_ROOT}/reports/unit" -name "*.txt" 2>/dev/null | wc -l)",
    "integration_tests": "$(find "${TEST_ROOT}/reports/integration" -name "*.txt" 2>/dev/null | wc -l)"
  }
}
EOF

  log_success "JSON report generated: $report_file"
}

# Generate console test report
generate_console_report() {
  echo ""
  echo "========================================"
  echo "  GitHub Actions Test Framework Report"
  echo "========================================"
  echo "Test Type: $TEST_TYPE"
  echo "Timestamp: $(date)"
  echo "Coverage Enabled: $COVERAGE_ENABLED"
  echo ""

  if [[ -d "${TEST_ROOT}/reports/unit" ]]; then
    local unit_tests
    unit_tests=$(find "${TEST_ROOT}/reports/unit" -name "*.txt" 2>/dev/null | wc -l)
    echo "Unit Tests Run: $unit_tests"
  fi

  if [[ -d "${TEST_ROOT}/reports/integration" ]]; then
    local integration_tests
    integration_tests=$(find "${TEST_ROOT}/reports/integration" -name "*.txt" 2>/dev/null | wc -l)
    echo "Integration Tests Run: $integration_tests"
  fi

  if [[ -f "${TEST_ROOT}/coverage/summary.json" ]]; then
    local coverage
    coverage=$(jq -r '.coverage_percent' "${TEST_ROOT}/coverage/summary.json" 2>/dev/null || echo "N/A")
    echo "Test Coverage: ${coverage}%"
  fi

  echo "========================================"
}

# Main test execution function
main() {
  log_info "Starting GitHub Actions Testing Framework"

  # Parse arguments
  parse_args "$@"

  # Initialize framework
  init_testing_framework

  # Check dependencies
  check_dependencies

  # Discover actions to test
  local actions
  mapfile -t actions < <(discover_actions)

  if [[ ${#actions[@]} -eq 0 ]]; then
    log_error "No actions found to test"
    exit 1
  fi

  # Run tests based on type
  local test_failed=false

  case "$TEST_TYPE" in
  "unit")
    if ! run_unit_tests "${actions[@]}"; then
      test_failed=true
    fi
    ;;
  "integration")
    if ! run_integration_tests "${actions[@]}"; then
      test_failed=true
    fi
    ;;
  "e2e")
    log_warning "E2E tests not yet implemented"
    ;;
  "all")
    if ! run_unit_tests "${actions[@]}"; then
      test_failed=true
    fi
    if ! run_integration_tests "${actions[@]}"; then
      test_failed=true
    fi
    ;;
  *)
    log_error "Unknown test type: $TEST_TYPE"
    exit 1
    ;;
  esac

  # Generate coverage report
  generate_coverage_report

  # Generate test report
  generate_test_report

  # Final status
  if [[ $test_failed == "true" ]]; then
    log_error "Some tests failed"
    exit 1
  else
    log_success "All tests passed!"
    exit 0
  fi
}

# Run main function if script is executed directly
if [[ ${BASH_SOURCE[0]} == "${0}" ]]; then
  main "$@"
fi
