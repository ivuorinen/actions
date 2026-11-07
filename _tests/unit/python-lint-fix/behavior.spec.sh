#!/usr/bin/env shellspec
# Behavior tests for python-lint-fix: the tool install, where its virtual
# environment lives, and how the SARIF report reaches the upload step.
#
# The harness runs the action's real `run:` steps in order and carries step
# outputs between them. Its stubbed `python -m venv` builds a real virtual
# environment holding fake pip, flake8 and autopep8, so nothing is downloaded and
# a later step can only reach those tools through the path the install step
# published. The fake flake8 applies the --format string it receives with `%`,
# as flake8's own formatter does, so the format string in action.yml and the
# parser in flake8_to_sarif.py are exercised together.

Describe "python-lint-fix behavior"
ACTION_DIR="${PROJECT_ROOT}/python-lint-fix"
ACTION_FILE="${ACTION_DIR}/action.yml"

write_fake_tools() {
  local tools="$1"
  mkdir -p "$tools"
  cat >"$tools/pip" <<'EOF'
#!/bin/sh
printf 'pip %s\n' "$*" >>"$TOOL_LOG"
EOF
  cat >"$tools/autopep8" <<'EOF'
#!/bin/sh
printf 'autopep8 %s\n' "$*" >>"$TOOL_LOG"
EOF
  cat >"$tools/flake8" <<'EOF'
#!/usr/bin/env python
import json
import os
import sys

args = sys.argv[1:]
if args == ["--version"]:
    sys.exit(0)
options = dict(arg[2:].split("=", 1) for arg in args if arg.startswith("--") and "=" in arg)
with open(options["output-file"], "a", encoding="utf-8") as report:
    for violation in json.loads(os.environ.get("FAKE_FLAKE8_VIOLATIONS", "[]")):
        report.write(options["format"] % violation + "\n")
sys.exit(int(os.environ.get("FAKE_FLAKE8_EXIT", "0")))
EOF
  chmod +x "$tools/pip" "$tools/autopep8" "$tools/flake8"
}

before() {
  shellspec_setup_test_env "python-lint-fix-behavior-$$"
  harness_reset
  _harness_ensure_session

  export GITHUB_WORKSPACE="$SHELLSPEC_TEST_WORKSPACE"
  export RUNNER_TEMP="${SHELLSPEC_TEST_TEMP_DIR}/runner-temp"
  export TOOL_LOG="${SHELLSPEC_TEST_TEMP_DIR}/tools.log"
  export RUN_LOG="${SHELLSPEC_TEST_TEMP_DIR}/run.log"
  export FAKE_TOOLS="${SHELLSPEC_TEST_TEMP_DIR}/fake-tools"
  REAL_PYTHON="$(command -v python3)"
  export REAL_PYTHON
  mkdir -p "$RUNNER_TEMP"
  : >"$TOOL_LOG"

  export INPUT_FLAKE8_VERSION="7.0.0"
  export INPUT_AUTOPEP8_VERSION="2.0.4"
  export INPUT_WORKING_DIRECTORY="."
  export INPUT_FAIL_ON_ERROR="true"
  export FAKE_FLAKE8_VIOLATIONS="[]"
  export FAKE_FLAKE8_EXIT="0"

  write_fake_tools "$FAKE_TOOLS"
  mkdir -p "${HARNESS_SESSION}/bin"
  cat >"${HARNESS_SESSION}/bin/python" <<'EOF'
#!/bin/sh
"$REAL_PYTHON" "$@" --without-pip
for env_dir; do :; done
cp "$FAKE_TOOLS"/* "$env_dir/bin/"
EOF
  chmod +x "${HARNESS_SESSION}/bin/python"
  mock_command python3 "validate.py" ""

  printf 'x = 1\n' >app.py
}
BeforeEach 'before'

after() {
  unset INPUT_FLAKE8_VERSION INPUT_AUTOPEP8_VERSION INPUT_WORKING_DIRECTORY INPUT_FAIL_ON_ERROR
  unset FAKE_FLAKE8_VIOLATIONS FAKE_FLAKE8_EXIT FAKE_TOOLS TOOL_LOG RUN_LOG RUNNER_TEMP REAL_PYTHON
  shellspec_cleanup_test_env "python-lint-fix-behavior-$$"
  harness_reset
  export GITHUB_WORKSPACE="$PROJECT_ROOT"
}
AfterEach 'after'

run_action() { run_all_owned_steps "$ACTION_DIR" >"$RUN_LOG" 2>&1; }
work_dir_output() { sed -n 's/^work_dir=//p' "$GITHUB_OUTPUT"; }
sarif_file_output() { sed -n 's/^sarif_file=//p' "$GITHUB_OUTPUT"; }
sarif_result_count() { jq '.runs[0].results | length' "$(sarif_file_output)"; }
first_result_uri() {
  jq -r '.runs[0].results[0].locations[0].physicalLocation.artifactLocation.uri' "$(sarif_file_output)"
}
step_field() { yq -r ".runs.steps[] | select(.name == \"$1\") | $2" "$ACTION_FILE"; }

THREE_VIOLATIONS='[
  {"row": 1, "col": 1, "code": "F401", "path": "./app.py", "text": "'"'"'os'"'"' imported but unused"},
  {"row": 2, "col": 2, "code": "E225", "path": "./app.py", "text": "missing whitespace around operator"},
  {"row": 1, "col": 1, "code": "F401", "path": "./other.py", "text": "'"'"'sys'"'"' imported but unused"}
]'

Context "installing the lint tools"
It "installs flake8 and autopep8 at the requested versions and no SARIF plugin"
When call run_action
The status should be success
The contents of file "$TOOL_LOG" should include "pip install flake8==7.0.0"
The contents of file "$TOOL_LOG" should include "pip install autopep8==2.0.4"
The contents of file "$TOOL_LOG" should not include "sarif"
End
End

Context "placing the virtual environment"
It "creates it under RUNNER_TEMP and leaves nothing new in the workspace"
When call run_action
The status should be success
The path "${SHELLSPEC_TEST_WORKSPACE}/.venv" should not be exist
The path "${SHELLSPEC_TEST_WORKSPACE}/reports" should not be exist
The result of function work_dir_output should start with "${RUNNER_TEMP}/"
End

It "lets the lint and fix steps reach the tools through the install step's output"
When call run_action
The status should be success
Assert expect_output result success
Assert expect_output fixed_count 0
The contents of file "$TOOL_LOG" should include "autopep8 --diff ./app.py"
End

It "does not offer a venv file to the fix step"
When call run_action
The status should be success
The contents of file "$TOOL_LOG" should not include "site-packages"
End

It "does not import a venv module from the checked-out repository"
printf 'raise SystemExit("the workspace venv module ran")\n' >venv.py
When call run_action
The status should be success
The contents of file "$RUN_LOG" should not include "the workspace venv module ran"
End
End

Context "reporting results"
It "writes a SARIF log outside the workspace and counts every result"
export FAKE_FLAKE8_VIOLATIONS="$THREE_VIOLATIONS"
export FAKE_FLAKE8_EXIT="1"
export INPUT_FAIL_ON_ERROR="false"
When call run_action
The status should be success
Assert expect_output error_count 3
Assert expect_output result success
The result of function sarif_file_output should start with "${RUNNER_TEMP}/"
The result of function sarif_result_count should equal 3
End

It "fails on results when fail-on-error is true and still publishes the report"
export FAKE_FLAKE8_VIOLATIONS="$THREE_VIOLATIONS"
export FAKE_FLAKE8_EXIT="1"
When call run_action
The status should be failure
Assert expect_output error_count 3
Assert expect_output result failure
The result of function sarif_result_count should equal 3
End

It "publishes an empty log for a clean run"
When call run_action
The status should be success
Assert expect_output error_count 0
The result of function sarif_result_count should equal 0
End

It "writes URIs relative to the repository root when working-directory is a subdirectory"
mkdir -p src
printf 'x = 1\n' >src/app.py
export INPUT_WORKING_DIRECTORY="src"
export FAKE_FLAKE8_VIOLATIONS="$THREE_VIOLATIONS"
export FAKE_FLAKE8_EXIT="1"
export INPUT_FAIL_ON_ERROR="false"
When call run_action
The status should be success
The result of function first_result_uri should equal "src/app.py"
End

It "fails without publishing a report when flake8 exits non-zero with no results"
export FAKE_FLAKE8_EXIT="1"
export INPUT_FAIL_ON_ERROR="false"
When call run_action
The status should be failure
Assert expect_output result failure
The contents of file "$RUN_LOG" should include "without reporting any results"
The contents of file "$GITHUB_OUTPUT" should not include "sarif_file="
End
End

Context "when the repository has no Python files"
It "skips the install, lint and fix steps"
rm -f app.py
When call run_action
The status should be success
Assert expect_output result skipped
The contents of file "$GITHUB_OUTPUT" should not include "work_dir="
The contents of file "$TOOL_LOG" should not include "pip"
End
End

# The harness skips `uses:` steps, so their wiring is asserted on the metadata.
Context "wiring the steps the harness cannot run"
It "uploads the path the lint step published, including after a lint failure"
When call step_field "Upload SARIF Report" ".if"
The output should equal "always() && steps.lint.outputs.sarif_file != ''"
End

It "reads the SARIF path from the lint step's output"
When call step_field "Upload SARIF Report" ".with.sarif_file"
The output should equal '${{ steps.lint.outputs.sarif_file }}'
End

It "guards the commit condition so a skipped run never parses an empty count"
When call step_field "Commit Fixes" ".if"
The output should equal "steps.check-files.outputs.result == 'found' && fromJSON(steps.fix.outputs.fixed_count) > 0"
End

It "keeps no virtual environment or report path in the workspace"
When run grep -nE '\.venv|reports/|rm -rf' "$ACTION_FILE"
The status should be failure
The output should equal ""
End
End
End
