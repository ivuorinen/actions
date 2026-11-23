#!/usr/bin/env shellspec
# Behavior test for ansible-lint-fix: file detection must see the
# checked-out workspace. The harness skips the actions/checkout step, so
# the spec simulates a post-checkout state by running the check-files
# step from a workspace that already contains .yml files.

Describe "ansible-lint-fix check-files"
ACTION_DIR="${PROJECT_ROOT}/ansible-lint-fix"

before() {
  shellspec_setup_test_env "ansible-lint-fix-behavior-$$"
  harness_reset
}
BeforeEach 'before'

after() {
  shellspec_cleanup_test_env "ansible-lint-fix-behavior-$$"
  harness_reset
}
AfterEach 'after'

It "detects .yml files in the checked-out workspace"
mkdir -p playbooks
printf -- '- hosts: all\n  tasks: []\n' >playbooks/site.yml

When call run_step "${ACTION_DIR}" "check-files"
The status should be success
The stdout should include "Found Ansible files"
Assert expect_output files_found true
End

It "reports files_found=false in an empty workspace"
When call run_step "${ACTION_DIR}" "check-files"
The status should be success
The stdout should include "No Ansible files detected"
Assert expect_output files_found false
End

Describe "play syntax in a YAML file"
Parameters
'- hosts: all' true
'- name: play\n  hosts: all' true
'hosts: all' false
'- hostsfile: all' false
'    hosts: all' false
End

It "reports files_found=$2 for: $1"
mkdir -p deploy
printf '%b\n' "$1" >deploy/main.yml

When call run_step "${ACTION_DIR}" "check-files"
The status should be success
The stdout should be present
Assert expect_output files_found "$2"
End
End

It "finds a play in a file whose name has a space and a quote"
mkdir -p deploy
printf -- '- hosts: all\n' >"deploy/it's a play.yml"

When call run_step "${ACTION_DIR}" "check-files"
The status should be success
The stdout should be present
Assert expect_output files_found true
End

# Step-order regression check: run_step looks up steps by id regardless
# of position, so the harness cannot detect order issues on its own.
# Assert textually that Checkout Repository appears before
# Check for Ansible Files in action.yml.
It "declares Checkout Repository before Check for Ansible Files"
checkout_line=$(grep -n '^    - name: Checkout Repository' "${ACTION_DIR}/action.yml" | cut -d: -f1)
check_line=$(grep -n '^    - name: Check for Ansible Files' "${ACTION_DIR}/action.yml" | cut -d: -f1)
When call test "$checkout_line" -lt "$check_line"
The status should be success
End

# The SARIF report is written to the workspace, so the commit step must stage
# tracked files only (git add -u) or it commits the report to the caller's
# repository, and must exclude the report in case an older run already did.
It "commits tracked files only and never the SARIF report"
commit_block=$(sed -n '/^    - name: Commit Fixes/,/^    - name: Upload SARIF Report/p' "${ACTION_DIR}/action.yml")
When call printf '%s\n' "$commit_block"
The output should include "add_options: '-u'"
The output should include "file_pattern: '. :(exclude)ansible-lint.sarif'"
End

Describe "Run ansible-lint"
before_lint() {
  mock_command git "diff --name-only" "site.yml"
}
BeforeEach 'before_lint'

It "commits and uploads after a clean run"
mock_command ansible-lint "--write --format sarif" '{"runs": []}'
When call run_step "${ACTION_DIR}" "lint"
The status should be success
Assert expect_output status success
Assert expect_output finished true
Assert expect_output files_changed 1
End

# Violations --write could not fix: what it fixed is still committed and the findings uploaded,
# and Fail on Violations ends the job.
It "finishes, with a failure status, when violations remain"
mock_command ansible-lint "--write --format sarif" '{"runs": []}' 2
When call run_step "${ACTION_DIR}" "lint"
The status should be success
Assert expect_output status failure
Assert expect_output finished true
End

# 3 invalid config, 4 lock timeout, 5 no files matched, 1 a crash: ansible-lint did not finish.
Parameters
1
3
4
5
End

It "fails on exit status $1, with nothing to commit or upload"
mock_command ansible-lint "--write --format sarif" "" "$1"
When call run_step "${ACTION_DIR}" "lint"
The status should equal "$1"
The stdout should include "::error::ansible-lint failed with exit status $1"
Assert expect_output status failure
The contents of file "$GITHUB_OUTPUT" should not include "finished="
The contents of file "$GITHUB_OUTPUT" should not include "files_changed="
End
End

It "writes the report in place of a symlink a branch commits at its path"
mock_command git "diff --name-only" ""
mock_command ansible-lint "--write --format sarif" '{"runs": []}'
printf 'kept\n' >"${SHELLSPEC_TEST_TEMP_DIR}/target"
ln -s "${SHELLSPEC_TEST_TEMP_DIR}/target" ansible-lint.sarif
When call run_step "${ACTION_DIR}" "lint"
The status should be success
The path ansible-lint.sarif should not be symlink
The contents of file "${SHELLSPEC_TEST_TEMP_DIR}/target" should equal "kept"
End

It "commits, uploads and fails on violations only after a run that finished"
When call yq -r '.runs.steps[] | select(.name == "Commit Fixes" or .name == "Upload SARIF Report" or .name == "Fail on Violations") | .if' "${ACTION_DIR}/action.yml"
The line 1 of output should equal "steps.check-files.outputs.files_found == 'true' && steps.lint.outputs.finished == 'true'"
The line 2 of output should equal "steps.check-files.outputs.files_found == 'true' && steps.lint.outputs.finished == 'true'"
The line 3 of output should equal "steps.lint.outputs.finished == 'true' && steps.lint.outputs.status == 'failure'"
End

It "names the report in sarif_path only after a run that finished"
When call yq -r '.outputs.sarif_path.value' "${ACTION_DIR}/action.yml"
The output should equal "\${{ steps.lint.outputs.finished == 'true' && 'ansible-lint.sarif' || '' }}"
End
End
