#!/usr/bin/env bash
# Common testing utilities for GitHub Actions
# Provides helper functions for testing action behavior

set -euo pipefail

# Source setup utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_tests/framework/setup.sh
# shellcheck disable=SC1091
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
    # Compute path relative to this script for CWD independence
    local utils_dir
    utils_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if ! uv run "$utils_dir/../shared/validation_core.py" --validate-yaml "$action_file" 2>/dev/null; then
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
  uv run "$script_dir/../shared/validation_core.py" --inputs "$action_file"
}

get_action_outputs() {
  local action_file="$1"
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  uv run "$script_dir/../shared/validation_core.py" --outputs "$action_file"
}

get_action_name() {
  local action_file="$1"
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  uv run "$script_dir/../shared/validation_core.py" --name "$action_file"
}

get_action_runs_using() {
  local action_file="$1"
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  uv run "$script_dir/../shared/validation_core.py" --runs-using "$action_file"
}

# Check if an input is required in an action.yml file
is_input_required() {
  local action_file="$1"
  local input_name="$2"
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

  # Get the 'required' property for the input
  local required_status
  required_status=$(uv run "$script_dir/../shared/validation_core.py" --property "$action_file" "$input_name" "required")

  # Return 0 (success) if input is required, 1 (failure) if optional
  [[ "$required_status" == "required" ]]
}

# Test input validation using Python validation module
test_input_validation() {
  local action_dir="$1"
  local input_name="$2"
  local test_value="$3"
  local expected_result="${4:-success}" # success or failure

  # Normalize action_dir to absolute path before setup_test_env changes working directory
  action_dir="$(cd "$action_dir" && pwd)"

  log_info "Testing input validation: $input_name = '$test_value'"

  # Setup test environment
  setup_test_env "input-validation-${input_name}"

  # Use Python validation module via CLI
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

  local result="success"
  # Call validation_core CLI with proper argument passing (no injection risk)
  if ! uv run "$script_dir/../shared/validation_core.py" --validate "$action_dir" "$input_name" "$test_value" 2>&1; then
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

  # Normalize action_dir to absolute path before setup_test_env changes working directory
  action_dir="$(cd "$action_dir" && pwd)"

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
      printf '%s=mock-value-%s\n' "$output" "$(date +%s)" >>"$GITHUB_OUTPUT"
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

  # Normalize action_dir to absolute path for consistent behavior
  action_dir="$(cd "$action_dir" && pwd)"

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

  # Normalize action_dir to absolute path for consistent behavior
  action_dir="$(cd "$action_dir" && pwd)"

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

# Print each problem with the hash-locked requirements an action ships: a line in
# requirements.lock.txt without an exact pin and a sha256 hash, or an exact pin
# from requirements.in that the lock does not hold. Prints nothing for a complete
# lock.
requirements_lock_problems() {
  python3 - "$1" <<'PY'
import pathlib
import re
import sys

action_dir = pathlib.Path(sys.argv[1])
locked = set()
lock_text = (action_dir / "requirements.lock.txt").read_text(encoding="utf-8")
for line in lock_text.replace("\\\n", " ").splitlines():
    line = line.strip()
    if not line or line.startswith("#"):
        continue
    pin = re.match(r"[A-Za-z0-9._-]+==[^\s;]+", line)
    if pin is None or "--hash=sha256:" not in line:
        print(f"not locked: {line[:80]}")
    else:
        locked.add(pin.group().lower())
if not locked:
    print("requirements.lock.txt holds no requirements")
for line in (action_dir / "requirements.in").read_text(encoding="utf-8").splitlines():
    line = line.strip()
    if "==" in line and not line.startswith("#") and line.lower() not in locked:
        print(f"missing from requirements.lock.txt: {line}")
PY
}

# Print each problem with the npm lock an action ships for npm ci: a dependency in
# package.json that is not an exact version or that the lock's root entry does not
# hold, a package in the lock without an integrity hash or resolved from anywhere but
# registry.npmjs.org, one with an install script, a dependency or optional dependency
# of any package (such as Biome's platform binaries) that the lock does not hold where
# Node would look for it, or, by npm ls, a locked version outside the range the package
# that needs it declares. Prints nothing for a complete lock.
package_lock_problems() {
  python3 - "$1" <<'PY'
import json
import pathlib
import re
import sys

action_dir = pathlib.Path(sys.argv[1])
manifest = json.loads((action_dir / "package.json").read_text(encoding="utf-8"))
lock = json.loads((action_dir / "package-lock.json").read_text(encoding="utf-8"))
wanted = manifest.get("dependencies", {})
if not wanted:
    print("package.json declares no dependencies")
for name, spec in wanted.items():
    if not re.fullmatch(r"\d+\.\d+\.\d+", spec):
        print(f"not an exact version in package.json: {name}@{spec}")
packages = lock.get("packages", {})
if packages.get("", {}).get("dependencies", {}) != wanted:
    print("the lock's root dependencies differ from package.json")
for name, spec in wanted.items():
    if packages.get(f"node_modules/{name}", {}).get("version") != spec:
        print(f"the lock does not install {name}@{spec}")
for path, entry in packages.items():
    if not path:
        continue
    if not entry.get("integrity"):
        print(f"no integrity hash: {path}")
    if not entry.get("resolved", "").startswith("https://registry.npmjs.org/"):
        print(f"not from registry.npmjs.org: {path}")
    if entry.get("hasInstallScript"):
        print(f"has an install script: {path}")


def resolve(path, name):
    """Return the lock entry Node finds for name from path: its own node_modules, then each
    parent's, as require() walks up."""
    base = path
    while True:
        entry = packages.get(f"{base}/node_modules/{name}" if base else f"node_modules/{name}")
        if entry is not None or not base:
            return entry
        cut = base.rfind("/node_modules/")
        base = base[:cut] if cut >= 0 else ""


# npm ls below checks versions against their ranges, but takes a missing optional dependency
# for one this platform skips, so presence is checked here.
for path, entry in packages.items():
    for kind in ("dependencies", "optionalDependencies"):
        for name in entry.get(kind, {}):
            if resolve(path, name) is None:
                print(f"{path or 'the root'} needs {name}, which the lock does not hold")
PY
  # npm's own resolver, from the lock alone: a locked version outside the range the package
  # that needs it declares is "invalid".
  # The output options are given here, since an npm_config_depth or npm_config_parseable in
  # the environment would otherwise cut the walk short or change what it prints.
  if ! _npm_ls=$(npm ls --prefix "$1" --package-lock-only --all --depth=Infinity --no-parseable --no-json 2>&1); then
    printf '%s\n' "$_npm_ls" | grep -E 'invalid|missing|ERR' | sed -E 's/^/npm ls: /'
  fi
}

# Print the setup-dotnet cache line of an action.yml, and fail unless it turns the
# cache on only when a lock file exists: with `cache: true` and no matching file,
# setup-dotnet fails the step.
lock_aware_dotnet_cache() {
  ! grep -Fq 'cache: true' "$1" && grep -F "cache: \${{ hashFiles('**/packages.lock.json') != '' }}" "$1"
}

# cache_key_misses ACTION_YML FILE...: print each root-level FILE that no hashFiles() pattern
# in a cache `key:` of ACTION_YML matches, or that a `!` pattern there excludes, so a glob
# such as 'bun.lock*' counts for every file it names. Prints nothing when the patterns cover
# them all. A key written as a block scalar over several lines is not read, so its files are
# reported as misses.
cache_key_misses() {
  python3 - "$@" <<'PY'
import fnmatch
import re
import sys


def matches(name, pattern):
    """Match like hashFiles for a root-level name: its **/ also matches at the root."""
    return fnmatch.fnmatchcase(name, pattern) or (
        pattern.startswith("**/") and fnmatch.fnmatchcase(name, pattern[3:])
    )


keys = [line for line in open(sys.argv[1], encoding="utf-8") if re.match(r"\s*(-\s+)?key:", line)]
patterns = [p for line in keys for call in re.findall(r"hashFiles\(([^)]*)\)", line) for p in re.findall(r"'([^']+)'", call)]
included = [p for p in patterns if not p.startswith("!")]
excluded = [p[1:] for p in patterns if p.startswith("!")]
for name in sys.argv[2:]:
    if not any(matches(name, p) for p in included) or any(matches(name, p) for p in excluded):
        print(name)
PY
}

# hook_run HOOK INPUT: pipe INPUT, a Claude Code hook's JSON, into the hook script HOOK.
# INPUT stays one argument, so a quote in it cannot end a shell string.
hook_run() {
  printf '%s' "$2" | sh "$1"
}

# hook_field HOOK INPUT FILTER: run HOOK on INPUT and print what jq's FILTER selects from
# the decision it prints; the status is jq's, which fails when the field is null or absent.
hook_field() {
  printf '%s' "$2" | sh "$1" | jq -er "$3"
}

# Export all functions
export -f validate_action_yml get_action_inputs get_action_outputs get_action_name get_action_runs_using is_input_required
export -f test_input_validation test_action_outputs test_external_usage measure_action_time run_action_tests
export -f requirements_lock_problems package_lock_problems lock_aware_dotnet_cache cache_key_misses hook_run hook_field
