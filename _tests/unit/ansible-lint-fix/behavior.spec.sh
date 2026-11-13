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
End
