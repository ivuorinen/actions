#!/usr/bin/env bash
# Public bash API for the composite-step harness.
#
# Functions:
#   run_step <action-dir> <step-id>    -- execute one run: step
#   run_all_owned_steps <action-dir>   -- execute every run: step in order
#   run_retry_step <action-dir> <step-name> -- execute a nick-fields/retry step's command once
#   list_unguarded_retry_commands <root>    -- name multi-line retry commands lacking set -eu
#   list_retry_steps_without_bash <root>    -- name retry steps whose with: shell is not bash
#   mock_command <cmd> <argv-glob> <stdout> [exit-code]
#   expect_output <key> <value>        -- the value GitHub stores for <key> in $GITHUB_OUTPUT is <value>
#   expect_argv <cmd> <arg>...         -- exact, consecutive argv entries of a mocked call
#   step_value <action-dir> <step> <path> -- print a field of a step, by name or id, such as its run: script
#   harness_reset                      -- drop the session's mocks and recorded calls
#
# $GITHUB_OUTPUT and $GITHUB_ENV must be set by the spec (shellspec_setup_test_env).

_harness_py() {
  echo "${FRAMEWORK_DIR:?FRAMEWORK_DIR not set by spec_helper}/harness/harness.py"
}

_harness_project_root() {
  echo "${PROJECT_ROOT:?PROJECT_ROOT not set by spec_helper}"
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
    uv run --locked --project "$(_harness_project_root)" python3 "$@"
  else
    python3 "$@"
  fi
}

# Ensures $HARNESS_SESSION is set and exported. Creates a fresh tempdir on
# first call in the current shell scope. Idempotent within a test.
_harness_ensure_session() {
  if [ -z "${HARNESS_SESSION:-}" ]; then
    HARNESS_SESSION="$(mktemp -d "${TEMP_DIR:-/tmp}/harness.XXXXXXXX")"
    export HARNESS_SESSION
    printf '[]' >"${HARNESS_SESSION}/mocks.json"
  fi
}

harness_reset() {
  if [ -n "${HARNESS_SESSION:-}" ] && [ -d "${HARNESS_SESSION}" ]; then
    rm -rf "${HARNESS_SESSION}"
  fi
  unset HARNESS_SESSION HARNESS_STEP_OUTPUTS
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

_harness_execute() {
  _harness_ensure_session
  _harness_python "$(_harness_py)" "$@" \
    --session "${HARNESS_SESSION}" \
    --github-output "${GITHUB_OUTPUT:?GITHUB_OUTPUT not set}" \
    --github-env "${GITHUB_ENV:?GITHUB_ENV not set}"
}

run_step() {
  _harness_execute run-step "$1" "$2"
}

run_all_owned_steps() {
  _harness_execute run-owned "$1"
}

run_retry_step() {
  _harness_execute run-retry-step "$1" "$2"
}

list_unguarded_retry_commands() {
  _harness_python "$(_harness_py)" list-unguarded-retry-commands "$1"
}

list_retry_steps_without_bash() {
  _harness_python "$(_harness_py)" list-retry-steps-without-bash "$1"
}

# Compares the value GitHub stores for the key, read by the parser the harness uses for
# step outputs: the last value written wins, and heredoc bodies are values, not keys.
# The comparison runs in the harness, so the value never passes through $(...). The `--`
# keeps a value such as `--help` from being read as an option.
expect_output() {
  local file="${3:-$GITHUB_OUTPUT}"
  if ! _harness_python "$(_harness_py)" expect-output -- "$file" "$1" "$2"; then
    printf '%s\n' '--- actual ---' >&2
    cat "$file" >&2
    printf '%s\n' '--- end ---' >&2
    return 1
  fi
  return 0
}

# mock_command matches a space-joined argv, so it cannot tell `--flag "a b"` from
# `--flag a b`. This compares the entries the mocked command really received.
expect_argv() {
  python3 - "${HARNESS_SESSION:?HARNESS_SESSION not set}/calls.jsonl" "$@" <<'PY'
import json, sys
path, cmd, *want = sys.argv[1:]
with open(path, encoding="utf-8") as f:
    argvs = [call[1:] for call in map(json.loads, f) if call[0] == cmd]
if any(argv[i : i + len(want)] == want for argv in argvs for i in range(len(argv))):
    sys.exit(0)
sys.stderr.write(f"expect_argv: {want} not found in calls to {cmd}: {argvs}\n")
sys.exit(1)
PY
}

# Prints the field <path> of the step whose name, or else id, is <step> in
# <action-dir>/action.yml, or an empty line when it has none. Dotted paths reach into env:
# and with:. A string prints as it is, a boolean as true or false, and a mapping as JSON. A
# spec runs a step the harness cannot, such as one that reads the steps context, with its
# run: script.
step_value() {
  _harness_python - "$1/action.yml" "$2" "$3" <<'PY'
import json
import sys

import yaml

action_file, step, path = sys.argv[1:4]
with open(action_file, encoding="utf-8") as f:
    steps = yaml.safe_load(f)["runs"]["steps"]
value = next((s for s in steps if s.get("name") == step), None) or next(s for s in steps if s.get("id") == step)
for key in path.split("."):
    value = value.get(key) if isinstance(value, dict) else None
if value is None:
    print("")
elif isinstance(value, bool):
    print("true" if value else "false")
elif isinstance(value, (dict, list)):
    print(json.dumps(value))
else:
    print(value)
PY
}

export -f run_step run_all_owned_steps run_retry_step list_unguarded_retry_commands list_retry_steps_without_bash
export -f mock_command expect_output expect_argv harness_reset step_value
export -f _harness_py _harness_ensure_session _harness_execute _harness_python _harness_project_root
