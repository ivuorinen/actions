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
    -f, --format FORMAT     Report format: console, json, junit, sarif (default: console)
    -v, --verbose           Enable verbose output
    -h, --help              Show this help message

EXAMPLES:
    $0                                  # Run all tests for all actions
    $0 -t unit                          # Run only unit tests
    $0 -a node-setup                    # Test only node-setup action
    $0 -t integration docker-build      # Integration tests for docker-build
    $0 --format json --coverage         # Full tests with JSON output and coverage
    $0 --format sarif                   # Generate SARIF report for security scanning

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
      if [[ $# -lt 2 ]]; then
        echo "Error: $1 requires an argument" >&2
        usage
        exit 1
      fi
      test_type="$2"
      shift 2
      ;;
    -a | --action)
      if [[ $# -lt 2 ]]; then
        echo "Error: $1 requires an argument" >&2
        usage
        exit 1
      fi
      action_filter="$2"
      shift 2
      ;;
    -j | --jobs)
      if [[ $# -lt 2 ]]; then
        echo "Error: $1 requires an argument" >&2
        usage
        exit 1
      fi
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
      if [[ $# -lt 2 ]]; then
        echo "Error: $1 requires an argument" >&2
        usage
        exit 1
      fi
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
  TARGET_ACTIONS=("${actions[@]+"${actions[@]}"}")
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
    done < <(find "${TEST_ROOT}/.." -mindepth 2 -maxdepth 2 -type f -name "action.yml" -exec dirname {} \; | sort)
  else
    # All actions
    while IFS= read -r action_dir; do
      local action_name
      action_name=$(basename "$action_dir")
      actions+=("$action_name")
    done < <(find "${TEST_ROOT}/.." -mindepth 2 -maxdepth 2 -type f -name "action.yml" -exec dirname {} \; | sort)
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
      log_warning "kcov not found - coverage will use alternative methods"
    fi
  fi

  log_success "Dependency check completed"
}

# Install ShellSpec if not available
install_shellspec() {
  log_info "Installing ShellSpec testing framework..."

  local shellspec_version="0.28.1"
  local install_dir="${HOME}/.local"

  # Download and install ShellSpec (download -> verify SHA256 -> extract -> install)
  local tarball
  tarball="$(mktemp /tmp/shellspec-XXXXXX.tar.gz)"

  # Pinned SHA256 checksum for ShellSpec 0.28.1
  # Source: https://github.com/shellspec/shellspec/archive/refs/tags/0.28.1.tar.gz
  local checksum="400d835466429a5fe6c77a62775a9173729d61dd43e05dfa893e8cf6cb511783"

  # Ensure cleanup of the downloaded file
  # Use ${tarball:-} to handle unbound variable when trap fires after function returns
  # T-H1: save and restore the outer EXIT trap so we don't clobber it
  _old_trap=$(trap -p EXIT)
  trap 'rm -f "${tarball:-}"; eval "${_old_trap:-:}"' EXIT

  log_info "Downloading ShellSpec ${shellspec_version} to ${tarball}..."
  if ! curl -fsSL -o "$tarball" "https://github.com/shellspec/shellspec/archive/refs/tags/${shellspec_version}.tar.gz"; then
    log_error "Failed to download ShellSpec ${shellspec_version}"
    exit 1
  fi

  # Compute SHA256 in a portable way
  local actual_sha
  if command -v sha256sum >/dev/null 2>&1; then
    actual_sha="$(sha256sum "$tarball" | awk '{print $1}')"
  elif command -v shasum >/dev/null 2>&1; then
    actual_sha="$(shasum -a 256 "$tarball" | awk '{print $1}')"
  else
    log_error "No SHA256 utility available (sha256sum or shasum required) to verify download"
    exit 1
  fi

  if [[ "$actual_sha" != "$checksum" ]]; then
    log_error "Checksum mismatch for ShellSpec ${shellspec_version} (expected ${checksum}, got ${actual_sha})"
    exit 1
  fi

  log_info "Checksum verified for ShellSpec ${shellspec_version}, extracting..."
  if ! tar -xzf "$tarball" -C /tmp/; then
    log_error "Failed to extract ShellSpec archive"
    exit 1
  fi

  if ! (cd "/tmp/shellspec-${shellspec_version}" && make install PREFIX="$install_dir"); then
    log_error "ShellSpec make install failed"
    exit 1
  fi

  # Add to PATH for this process only. A test runner must never mutate
  # the user's shell profile — print a suggestion instead.
  if [[ ":$PATH:" != *":${install_dir}/bin:"* ]]; then
    export PATH="${install_dir}/bin:$PATH"
    log_warning "ShellSpec installed to ${install_dir}/bin"
    log_warning "To persist, add to your shell profile: export PATH=\"${install_dir}/bin:\$PATH\""
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

      # Run shellspec and capture both exit code and output.
      # Pass the full relative path _tests/unit/$action so ShellSpec resolves the
      # spec directory correctly from the repo root. Passing just "$action" causes
      # ShellSpec to resolve it against CWD (repo root) and find the action source
      # directory instead — which contains no spec files → 0 examples reported.
      # --no-color: CI runners (GitHub Actions) force-enable ANSI codes via env vars
      # even when stdout is redirected to a file; without this flag the summary line
      # is wrapped in escape sequences and the grep below fails to match it.
      # T-C2: capture exit code separately so a crash doesn't silently pass.
      if (cd "$TEST_ROOT/.." && shellspec \
        --no-banner --no-warning-as-failure \
        --no-color \
        --format documentation \
        "_tests/unit/$action") >"$output_file" 2>&1; then
        shellspec_exit=0
      else
        shellspec_exit=$?
      fi

      # Parse the output to determine if tests passed.
      # col -b strips backspace overstrikes; grep matches the plain-text summary.
      # Missing summary line (spec crash / empty output) → FAIL (shellspec_exit non-zero).
      # "0 examples, 0 failures" → WARNING (no tests written yet, not a failure).
      # "N examples, 0 failures" (N≥1) → PASS.
      # T-C2: non-zero shellspec exit always fails regardless of summary content.
      _summary_line=$(col -b <"$output_file" | grep -E '^[0-9][0-9]* examples?.*0 failures?$' || true)
      if [ "$shellspec_exit" -eq 0 ] && [ -n "$_summary_line" ]; then
        if echo "$_summary_line" | grep -q '^0 examples'; then
          log_warning "No examples in spec for: $action (0 examples, 0 failures)"
          passed_tests+=("$action")
        else
          log_success "Unit tests passed: $action"
          passed_tests+=("$action")
        fi
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
          -P ubuntu-latest=catthehacker/ubuntu:act-latest \
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

  log_info "Generating spec-presence report..."

  local coverage_dir="${TEST_ROOT}/coverage"
  mkdir -p "$coverage_dir"

  # This metric measures PRESENCE of a validation.spec.sh per action, not
  # executed line coverage. For real coverage, integrate kcov (out of scope).

  # Count tested vs total actions (count directories with action.yml files, excluding hidden/internal dirs and node_modules)
  local project_root
  project_root="$(cd "${TEST_ROOT}/.." && pwd)"
  local total_actions
  total_actions=$(find "$project_root" -mindepth 2 -maxdepth 2 -type f -name "action.yml" 2>/dev/null | wc -l | tr -d ' ')

  # Count actions that have unit tests (by checking if validation.spec.sh exists)
  local tested_actions
  tested_actions=$(find "${TEST_ROOT}/unit" -mindepth 2 -maxdepth 2 -type f -name "validation.spec.sh" 2>/dev/null | wc -l | tr -d ' ')

  # T-H3: renamed from spec_presence_percent to coverage_percent (workflow reads .coverage_percent)
  local coverage_percent
  if [[ $total_actions -gt 0 ]]; then
    coverage_percent=$(((tested_actions * 100) / total_actions))
  else
    coverage_percent=0
  fi

  cat >"${coverage_dir}/summary.json" <<EOF
{
  "total_actions": $total_actions,
  "tested_actions": $tested_actions,
  "coverage_percent": $coverage_percent,
  "generated_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF

  log_success "Spec-presence report generated: ${coverage_percent}% ($tested_actions/$total_actions actions)"
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
  "sarif")
    generate_sarif_report
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
    "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "type": "$TEST_TYPE",
    "action_filter": "$ACTION_FILTER",
    "parallel_jobs": $PARALLEL_JOBS,
    "coverage_enabled": $COVERAGE_ENABLED
  },
  "results": {
    "unit_tests": $(find "${TEST_ROOT}/reports/unit" -name "*.txt" 2>/dev/null | wc -l | tr -d ' '),
    "integration_tests": $(find "${TEST_ROOT}/reports/integration" -name "*.txt" 2>/dev/null | wc -l | tr -d ' ')
  }
}
EOF

  log_success "JSON report generated: $report_file"
}

# Generate SARIF test report
generate_sarif_report() {
  # Check for jq availability
  if ! command -v jq >/dev/null 2>&1; then
    log_warning "jq not found, skipping SARIF report generation"
    return 0
  fi

  local report_file="${TEST_ROOT}/reports/test-results.sarif"
  local run_id
  run_id="github-actions-test-$(date +%s)"
  local timestamp
  timestamp="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

  # Initialize SARIF structure using jq to ensure proper escaping
  jq -n \
    --arg run_id "$run_id" \
    --arg timestamp "$timestamp" \
    --arg test_type "$TEST_TYPE" \
    '{
      "$schema": "https://json.schemastore.org/sarif-2.1.0.json",
      "version": "2.1.0",
      "runs": [
        {
          "automationDetails": {
            "id": $run_id
          },
          "tool": {
            "driver": {
              "name": "GitHub Actions Testing Framework",
              "version": "1.0.0",
              "informationUri": "https://github.com/ivuorinen/actions",
              "rules": []
            }
          },
          "results": [],
          "invocations": [
            {
              "executionSuccessful": true,
              "startTimeUtc": $timestamp,
              "arguments": ["--type", $test_type, "--format", "sarif"]
            }
          ]
        }
      ]
    }' >"$report_file"

  # T-M4: accumulate results/rules into temp files; single jq pass at end avoids O(n^2).
  local _sarif_results_file _sarif_rules_file _sarif_need_unit_rule _sarif_need_int_rule
  _sarif_results_file=$(mktemp)
  _sarif_rules_file=$(mktemp)
  temp_file=
  # N-046: clean up temp files on all exit paths (including jq failure).
  # .tmp variants guard against jq failing after creating but before mv-ing the atomic file.
  trap 'rm -f "$_sarif_results_file" "$_sarif_rules_file" \
             "${_sarif_results_file}.tmp" "${_sarif_rules_file}.tmp" \
             "${temp_file:-}"' RETURN
  printf '[]' >"$_sarif_results_file"
  printf '[]' >"$_sarif_rules_file"
  _sarif_need_unit_rule=1
  _sarif_need_int_rule=1

  # Process unit test failures
  if [[ -d "${TEST_ROOT}/reports/unit" ]]; then
    for test_file in "${TEST_ROOT}/reports/unit"/*.txt; do
      if [[ -f "$test_file" ]]; then
        local action_name
        action_name=$(basename "$test_file" .txt)

        # Check if test failed by looking for actual failures in the summary line
        if grep -qE "[0-9]+ examples?, [1-9][0-9]* failures?" "$test_file" || grep -q "Fatal error occurred" "$test_file"; then
          local failure_message
          failure_message=$(grep -E "(Fatal error|failure|FAILED)" "$test_file" | head -1 || echo "Test failed")

          # T-M4: append to temp file; single jq pass at end
          if [ "$_sarif_need_unit_rule" -eq 1 ]; then
            jq '. + [{"id":"test-failure","name":"TestFailure","shortDescription":{"text":"Test execution failed"},"fullDescription":{"text":"A unit or integration test failed during execution"},"defaultConfiguration":{"level":"error"}}]' \
              "$_sarif_rules_file" >"${_sarif_rules_file}.tmp" && mv "${_sarif_rules_file}.tmp" "$_sarif_rules_file"
            _sarif_need_unit_rule=0
          fi
          jq --arg msg "$failure_message" --arg act "$action_name" \
            '. + [{"ruleId":"test-failure","level":"error","message":{"text":$msg},"locations":[{"physicalLocation":{"artifactLocation":{"uri":($act+"/action.yml")},"region":{"startLine":1,"startColumn":1}}}]}]' \
            "$_sarif_results_file" >"${_sarif_results_file}.tmp" && mv "${_sarif_results_file}.tmp" "$_sarif_results_file"
        fi
      fi
    done
  fi

  # Process integration test failures similarly
  if [[ -d "${TEST_ROOT}/reports/integration" ]]; then
    for test_file in "${TEST_ROOT}/reports/integration"/*.txt; do
      if [[ -f "$test_file" ]]; then
        local action_name
        action_name=$(basename "$test_file" .txt)

        if grep -qE "FAILED|ERROR|error:" "$test_file"; then
          local failure_message
          failure_message=$(grep -E "(FAILED|ERROR|error:)" "$test_file" | head -1 || echo "Integration test failed")

          # T-M4: append to temp file; single jq pass at end
          if [ "$_sarif_need_int_rule" -eq 1 ]; then
            jq '. + [{"id":"integration-failure","name":"IntegrationFailure","shortDescription":{"text":"Integration test failed"},"fullDescription":{"text":"An integration test failed during workflow execution"},"defaultConfiguration":{"level":"warning"}}]' \
              "$_sarif_rules_file" >"${_sarif_rules_file}.tmp" && mv "${_sarif_rules_file}.tmp" "$_sarif_rules_file"
            _sarif_need_int_rule=0
          fi
          jq --arg msg "$failure_message" --arg act "$action_name" \
            '. + [{"ruleId":"integration-failure","level":"warning","message":{"text":$msg},"locations":[{"physicalLocation":{"artifactLocation":{"uri":($act+"/action.yml")},"region":{"startLine":1,"startColumn":1}}}]}]' \
            "$_sarif_results_file" >"${_sarif_results_file}.tmp" && mv "${_sarif_results_file}.tmp" "$_sarif_results_file"
        fi
      fi
    done
  fi

  # T-M4: single jq pass merges accumulated results and rules into SARIF file
  local temp_file
  temp_file=$(mktemp)
  jq --slurpfile rules "$_sarif_rules_file" --slurpfile results "$_sarif_results_file" \
    '.runs[0].tool.driver.rules = $rules[0] | .runs[0].results = $results[0]' \
    "$report_file" >"$temp_file" && mv "$temp_file" "$report_file"
  # N-046: reset RETURN trap before explicit cleanup so it doesn't bleed into
  # the caller's return and trigger set -u on out-of-scope locals.
  trap - RETURN
  rm -f "$_sarif_results_file" "$_sarif_rules_file"

  log_success "SARIF report generated: $report_file"
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
    unit_tests=$(find "${TEST_ROOT}/reports/unit" -name "*.txt" 2>/dev/null | wc -l | tr -d ' ')
    printf "%-25s %4s\n" "Unit Tests Run:" "$unit_tests"
  fi

  if [[ -d "${TEST_ROOT}/reports/integration" ]]; then
    local integration_tests
    integration_tests=$(find "${TEST_ROOT}/reports/integration" -name "*.txt" 2>/dev/null | wc -l | tr -d ' ')
    printf "%-25s %4s\n" "Integration Tests Run:" "$integration_tests"
  fi

  if [[ -f "${TEST_ROOT}/coverage/summary.json" ]]; then
    local spec_presence
    spec_presence=$(jq -r '.coverage_percent' "${TEST_ROOT}/coverage/summary.json" 2>/dev/null || echo "N/A")
    if [[ "$spec_presence" =~ ^[0-9]+$ ]]; then
      printf "%-25s %4s%%\n" "Action Spec Presence:" "$spec_presence"
    else
      printf "%-25s %s\n" "Action Spec Presence:" "$spec_presence"
    fi
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
  local actions=()
  while IFS= read -r action; do
    actions+=("$action")
  done < <(discover_actions)

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
