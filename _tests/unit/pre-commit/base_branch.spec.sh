#!/usr/bin/env shellspec
# base-branch mode runs pre-commit over `<from-ref>...HEAD`. That range only
# resolves when the checkout holds the base branch as origin/<base> with history
# back to the merge base, so the checkout must be full-depth in that mode and the
# from-ref must name the remote-tracking branch.

Describe "pre-commit base-branch mode"
ACTION_DIR="${PROJECT_ROOT}/pre-commit"

before() {
  shellspec_setup_test_env "pre-commit-base-branch-$$"
  harness_reset
}
BeforeEach 'before'

after() {
  shellspec_cleanup_test_env "pre-commit-base-branch-$$"
  harness_reset
}
AfterEach 'after'

# Builds an upstream repo (main + feature branch) and a full clone of the
# feature branch, which is the state actions/checkout leaves with fetch-depth 0.
make_full_clone() {
  git init -q up
  git -C up config user.email test@example.com
  git -C up config user.name test
  git -C up commit -q --allow-empty -m base
  git -C up branch -M main
  git -C up switch -q -c feature
  printf 'x\n' >up/changed.txt
  git -C up add changed.txt
  git -C up commit -q -m change
  git clone -q --branch feature "file://${PWD}/up" work
}

checkout_fetch_depth() {
  python3 -c '
import sys, yaml
steps = yaml.safe_load(open(sys.argv[1], encoding="utf-8"))["runs"]["steps"]
print(next(s for s in steps if s["uses"].startswith("actions/checkout@"))["with"]["fetch-depth"])
' "${ACTION_DIR}/action.yml"
}

It "fetches full history only when base-branch is set"
When call checkout_fetch_depth
The output should equal "\${{ inputs.base-branch != '' && 0 || 1 }}"
End

It "emits a from-ref that resolves in a full checkout"
make_full_clone
export INPUT_BASE_BRANCH="main"
cd work || return 1
run_step "${ACTION_DIR}" "set-option" >/dev/null
from_ref=$(sed -n 's/^from-ref=//p' "$GITHUB_OUTPUT")
When call git diff --name-only "${from_ref}...HEAD"
The status should be success
The output should equal "changed.txt"
End

It "prefixes a base branch containing a slash"
export INPUT_BASE_BRANCH="release/1.0"
When call run_step "${ACTION_DIR}" "set-option"
The status should be success
Assert expect_output from-ref "origin/release/1.0"
End
End
