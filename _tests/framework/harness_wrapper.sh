#!/usr/bin/env bash
# Public bash API for the composite-step harness.
#
# Functions:
#   run_step <action-dir> <step-id>    -- execute one run: step
#   run_all_owned_steps <action-dir>   -- execute every run: step in order
#   mock_command <cmd> <argv-glob> <stdout> [exit-code]
#   expect_output <key> <value>        -- whole-line grep on $GITHUB_OUTPUT
#
# $GITHUB_OUTPUT and $GITHUB_ENV must be set by the spec (shellspec_setup_test_env).

# shellcheck disable=SC2155
_harness_py() {
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  echo "${script_dir}/harness/harness.py"
}

_harness_project_root() {
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  (cd "${script_dir}/.." && pwd)
}

# Invoke Python via uv so PyYAML resolves. Falls back to plain python3 if uv
# isn't installed (CI images that ship pyyaml system-wide).
#
# Preserves the caller's $PWD so action `run:` blocks that rely on CWD
# (e.g. ansible-lint-fix's `find .`) see the test workspace, not the
# repo root. `uv run --project <dir>` anchors uv to the project without
# changing cwd.
_harness_python() {
  if command -v uv >/dev/null 2>&1; then
    uv run --project "$(_harness_project_root)" python3 "$@"
  else
    python3 "$@"
  fi
}

# Ensures $HARNESS_SESSION is set and exported. Creates a fresh tempdir on
# first call in the current shell scope. Idempotent within a test.
_harness_ensure_session() {
  if [[ -z "${HARNESS_SESSION:-}" ]]; then
    HARNESS_SESSION="$(mktemp -d "${TEMP_DIR:-/tmp}/harness.XXXXXXXX")"
    export HARNESS_SESSION
    echo "[]" > "${HARNESS_SESSION}/mocks.json"
  fi
}

harness_reset() {
  if [[ -n "${HARNESS_SESSION:-}" && -d "${HARNESS_SESSION}" ]]; then
    rm -rf "${HARNESS_SESSION}"
  fi
  unset HARNESS_SESSION
}

mock_command() {
  local cmd="$1"
  local glob="$2"
  local stdout="$3"
  local exit_code="${4:-0}"
  _harness_ensure_session
  local session="${HARNESS_SESSION}"
  python3 - "$session" "$cmd" "$glob" "$stdout" "$exit_code" <<'PY'
import json, sys
session, cmd, glob, stdout, exit_code = sys.argv[1:6]
path = f"{session}/mocks.json"
with open(path, encoding="utf-8") as f:
    mocks = json.load(f)
mocks.append({
    "command": cmd,
    "argv_glob": glob,
    "stdout": stdout,
    "exit": int(exit_code),
})
with open(path, "w", encoding="utf-8") as f:
    json.dump(mocks, f)
PY
}

run_step() {
  local action_dir="$1"
  local step_id="$2"
  _harness_ensure_session
  local session="${HARNESS_SESSION}"
  _harness_python "$(_harness_py)" run-step "$action_dir" "$step_id" \
    --session "$session" \
    --github-output "${GITHUB_OUTPUT:?GITHUB_OUTPUT not set}" \
    --github-env "${GITHUB_ENV:?GITHUB_ENV not set}"
}

run_all_owned_steps() {
  local action_dir="$1"
  _harness_ensure_session
  local session="${HARNESS_SESSION}"
  _harness_python "$(_harness_py)" run-owned "$action_dir" \
    --session "$session" \
    --github-output "${GITHUB_OUTPUT:?GITHUB_OUTPUT not set}" \
    --github-env "${GITHUB_ENV:?GITHUB_ENV not set}"
}

expect_output() {
  local key="$1"
  local value="$2"
  local file="${3:-$GITHUB_OUTPUT}"
  if ! grep -Fxq "${key}=${value}" "$file"; then
    echo "expect_output: missing '${key}=${value}' in ${file}" >&2
    echo "--- actual ---" >&2
    cat "$file" >&2
    echo "--- end ---" >&2
    return 1
  fi
  return 0
}

export -f run_step run_all_owned_steps mock_command expect_output harness_reset
export -f _harness_py _harness_ensure_session _harness_python _harness_project_root
