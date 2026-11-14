#!/usr/bin/env shellspec
# Unit tests: go-lint keeps its reports outside the repository tree

Describe "go-lint report directory"
ACTION_FILE="$PWD/go-lint/action.yml"

step_script() {
  yq ".runs.steps[] | select(.name == \"$1\") | .run" "$ACTION_FILE"
}

step_upload_path() {
  yq '.runs.steps[] | select(.name == "Upload Lint Results") | .with.sarif_file' "$ACTION_FILE"
}

# Runs the lint and cleanup steps in a workspace whose `reports` entry is a
# symlink to a directory holding a marker file, then prints what survived.
symlinked_reports_scenario() {
  _root=$(mktemp -d)
  mkdir -p "$_root/workspace" "$_root/victim" "$_root/runner" "$_root/home" "$_root/bin"
  : >"$_root/victim/marker"
  ln -s "$_root/victim" "$_root/workspace/reports"
  printf '#!/bin/sh\nprintf "{}\\n"\n' >"$_root/bin/golangci-lint"
  chmod +x "$_root/bin/golangci-lint"
  step_script "Run golangci-lint" >"$_root/lint.sh"
  step_script "Cleanup" >"$_root/cleanup.sh"
  : >"$_root/output"

  (
    cd "$_root/workspace"
    env PATH="$_root/bin:$PATH" HOME="$_root/home" RUNNER_TEMP="$_root/runner" \
      GITHUB_OUTPUT="$_root/output" WORKING_DIRECTORY=. DISABLE_ALL=false \
      ENABLE_LINTERS= DISABLE_LINTERS= CONFIG_FILE=.golangci.yml TIMEOUT=5m \
      CACHE=true ONLY_NEW_ISSUES=false REPORT_FORMAT=sarif FAIL_ON_ERROR=false \
      sh "$_root/lint.sh" >/dev/null 2>&1
  )
  _sarif=$(sed -n 's/^sarif_file=//p' "$_root/output")
  _reports_dir=$(sed -n 's/^reports_dir=//p' "$_root/output")
  [ -f "$_sarif" ] && echo "report written: yes" || echo "report written: no"
  case "$_sarif" in "$_root/runner"/*) echo "report in runner temp: yes" ;; *) echo "report in runner temp: no" ;; esac
  [ -z "$(ls "$_root/victim" | grep -v '^marker$')" ] && echo "symlink target untouched: yes" || echo "symlink target untouched: no"

  (
    cd "$_root/workspace"
    env HOME="$_root/home" WORKING_DIRECTORY=. CACHE=true REPORTS_DIR="$_reports_dir" \
      sh "$_root/cleanup.sh" >/dev/null 2>&1
  )
  [ -f "$_root/victim/marker" ] && echo "marker survives cleanup: yes" || echo "marker survives cleanup: no"
  [ -e "$_reports_dir" ] && echo "reports removed: no" || echo "reports removed: yes"
  rm -rf "$_root"
}

It "writes reports under RUNNER_TEMP and never follows a reports symlink"
When call symlinked_reports_scenario
The line 1 of output should equal "report written: yes"
The line 2 of output should equal "report in runner temp: yes"
The line 3 of output should equal "symlink target untouched: yes"
The line 4 of output should equal "marker survives cleanup: yes"
The line 5 of output should equal "reports removed: yes"
End

It "uploads the SARIF file the lint step reports"
When call step_upload_path
The output should equal '${{ steps.lint.outputs.sarif_file }}'
End

It "skips the upload when the lint step wrote no report"
When call yq '.runs.steps[] | select(.name == "Upload Lint Results") | .if' "$ACTION_FILE"
The output should include "steps.lint.outputs.sarif_file != ''"
End

It "does not set issues.new in the default config"
When call step_script "Prepare Configuration"
The output should not include "new: true"
End
End
