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
    # Compute path relative to this script for CWD independence
    local utils_dir
    utils_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if ! uv run --locked "$utils_dir/../shared/validation_core.py" --validate-yaml "$action_file" 2>/dev/null; then
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
  uv run --locked "$script_dir/../shared/validation_core.py" --inputs "$action_file"
}

get_action_outputs() {
  local action_file="$1"
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  uv run --locked "$script_dir/../shared/validation_core.py" --outputs "$action_file"
}

get_action_name() {
  local action_file="$1"
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  uv run --locked "$script_dir/../shared/validation_core.py" --name "$action_file"
}

get_action_runs_using() {
  local action_file="$1"
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  uv run --locked "$script_dir/../shared/validation_core.py" --runs-using "$action_file"
}

# Check if an input is required in an action.yml file
is_input_required() {
  local action_file="$1"
  local input_name="$2"
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

  # Get the 'required' property for the input
  local required_status
  required_status=$(uv run --locked "$script_dir/../shared/validation_core.py" --property "$action_file" "$input_name" "required")

  # Return 0 (success) if input is required, 1 (failure) if optional
  [[ "$required_status" == "required" ]]
}

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

# nuget_cache_steps ACTION_YML: the conditions of the action's Restore NuGet Packages and Save
# NuGet Packages steps, one per line, then the restore's key, then each step's path.
nuget_cache_steps() {
  yq -r '.runs.steps[] | select(.name == "Restore NuGet Packages" or .name == "Save NuGet Packages") | .if' "$1"
  yq -r '.runs.steps[] | select(.name == "Restore NuGet Packages") | .with.key' "$1"
  yq -r '.runs.steps[] | select(.name == "Restore NuGet Packages" or .name == "Save NuGet Packages") | .with.path' "$1"
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

# fixture_repo [DIR]: make DIR, the current directory by default, a git repository for a
# spec's own commits and tags. The identity and signing settings are local, because a CI
# runner has no global ones, and the commits never leave the test, so they need no signature.
fixture_repo() {
  local dir="${1:-.}"
  git init -q "$dir"
  git -C "$dir" config user.email test@example.com
  git -C "$dir" config user.name test
  git -C "$dir" config commit.gpgsign false
  git -C "$dir" config tag.gpgSign false
}

# Export all functions
export -f validate_action_yml get_action_inputs get_action_outputs get_action_name get_action_runs_using is_input_required
export -f test_action_outputs
export -f requirements_lock_problems package_lock_problems nuget_cache_steps hook_run hook_field
export -f fixture_repo
