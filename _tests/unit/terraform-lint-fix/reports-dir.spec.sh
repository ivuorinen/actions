#!/usr/bin/env shellspec
# Unit tests: terraform-lint-fix keeps its reports outside the repository tree
# and validates syntax inside working-directory

Describe "terraform-lint-fix report directory and working directory"
ACTION_FILE="$PWD/terraform-lint-fix/action.yml"

step_script() {
  yq ".runs.steps[] | select(.name == \"$1\") | .run" "$ACTION_FILE"
}

upload_path() {
  yq '.runs.steps[] | select(.name == "Upload SARIF Report") | .with.sarif_file' "$ACTION_FILE"
}

# Runs the lint and cleanup steps in a workspace whose `reports` entry is a
# symlink to a directory holding a marker file, then prints what survived.
symlinked_reports_scenario() {
  _root=$(mktemp -d)
  mkdir -p "$_root/workspace" "$_root/victim" "$_root/runner" "$_root/bin"
  : >"$_root/victim/marker"
  ln -s "$_root/victim" "$_root/workspace/reports"
  printf '#!/bin/sh\nprintf "{}\\n"\n' >"$_root/bin/tflint"
  chmod +x "$_root/bin/tflint"
  step_script "Run TFLint" >"$_root/lint.sh"
  step_script "Cleanup" >"$_root/cleanup.sh"
  : >"$_root/output"

  (
    cd "$_root/workspace"
    env PATH="$_root/bin:$PATH" RUNNER_TEMP="$_root/runner" GITHUB_OUTPUT="$_root/output" \
      VALIDATED_WORKING_DIR=. VALIDATED_CONFIG=.tflint.hcl VALIDATED_FORMAT=sarif \
      VALIDATED_FAIL=false sh "$_root/lint.sh" >/dev/null 2>&1
  )
  _sarif=$(sed -n 's/^sarif_file=//p' "$_root/output")
  _reports_dir=$(sed -n 's/^reports_dir=//p' "$_root/output")
  [ -f "$_sarif" ] && echo "report written: yes" || echo "report written: no"
  case "$_sarif" in "$_root/runner"/*) echo "report in runner temp: yes" ;; *) echo "report in runner temp: no" ;; esac
  [ -z "$(ls "$_root/victim" | grep -v '^marker$')" ] && echo "symlink target untouched: yes" || echo "symlink target untouched: no"

  # A .terraform symlink must not be followed either
  mkdir -p "$_root/tfvictim" "$_root/home"
  : >"$_root/tfvictim/marker"
  ln -s "$_root/tfvictim" "$_root/workspace/.terraform"
  # The cleanup removes ~/.tflint.d, so HOME points inside the scenario rather than at
  # the account running the suite.
  (
    cd "$_root/workspace"
    env HOME="$_root/home" RUNNER_TEMP="$_root/runner" REPORTS_DIR="$_reports_dir" sh "$_root/cleanup.sh" >/dev/null 2>&1
  )
  [ -f "$_root/victim/marker" ] && [ -f "$_root/tfvictim/marker" ] && echo "markers survive cleanup: yes" || echo "markers survive cleanup: no"
  [ -e "$_reports_dir" ] && echo "reports removed: no" || echo "reports removed: yes"
  rm -rf "$_root"
}

# The syntax step must look at working-directory, not the repository root.
syntax_scenario() {
  _root=$(mktemp -d)
  mkdir -p "$_root/workspace/sub" "$_root/bin"
  : >"$_root/workspace/root.tf"
  : >"$_root/workspace/sub/inner.tf"
  printf '#!/bin/sh\nprintf "%%s\\n" "$PWD/$*" >> "%s/calls"\nexit 1\n' "$_root" >"$_root/bin/terraform"
  chmod +x "$_root/bin/terraform"
  step_script "Validate Terraform Syntax" >"$_root/syntax.sh"
  (
    cd "$_root/workspace"
    env PATH="$_root/bin:$PATH" VALIDATED_WORKING_DIR=sub sh "$_root/syntax.sh" >/dev/null 2>&1
  )
  if grep -q 'root.tf' "$_root/calls"; then echo "root file checked: yes"; else echo "root file checked: no"; fi
  if grep -q 'inner.tf' "$_root/calls"; then echo "working-directory file checked: yes"; else echo "working-directory file checked: no"; fi
  rm -rf "$_root"
}

It "writes reports under RUNNER_TEMP and never follows repository symlinks"
When call symlinked_reports_scenario
The line 1 of output should equal "report written: yes"
The line 2 of output should equal "report in runner temp: yes"
The line 3 of output should equal "symlink target untouched: yes"
The line 4 of output should equal "markers survive cleanup: yes"
The line 5 of output should equal "reports removed: yes"
End

It "uploads the SARIF file the lint step reports"
When call upload_path
The output should equal '${{ steps.lint.outputs.sarif_file }}'
End

It "validates syntax inside working-directory"
When call syntax_scenario
The line 1 of output should equal "root file checked: no"
The line 2 of output should equal "working-directory file checked: yes"
End
End
