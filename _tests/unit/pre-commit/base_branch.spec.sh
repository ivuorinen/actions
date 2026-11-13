#!/usr/bin/env shellspec
# base-branch mode runs pre-commit over `<from-ref>...HEAD`. That range only
# resolves when the checkout holds the base branch as origin/<base> with history
# back to the merge base, so the checkout must be full-depth in that mode and the
# from-ref must name the remote-tracking branch.

Describe "pre-commit base-branch mode"
ACTION_DIR="${PROJECT_ROOT}/pre-commit"
RUN_PREFIX="-P -m pre_commit run --show-diff-on-failure --color=always --config .pre-commit-config.yaml"

before() {
  shellspec_setup_test_env "pre-commit-base-branch-$$"
  harness_reset
  export INPUT_PRE_COMMIT_CONFIG=".pre-commit-config.yaml"
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
  # A fixture repository: its commits never leave the test, so they need no signature.
  git -C up config commit.gpgsign false
  git -C up commit -q --allow-empty -m base
  git -C up branch -M main
  git -C up switch -q -c feature
  printf 'x\n' >up/changed.txt
  git -C up add changed.txt
  git -C up commit -q -m change
  git clone -q --branch feature "file://${PWD}/up" work
}

# Evaluates the checkout's fetch-depth expression for one base-branch value. It is the
# `cond && A || B` idiom, which GitHub evaluates by returning operands: A when cond holds
# and A is truthy, otherwise B. false, 0, -0, '' and null are falsy, so A has to be a
# non-empty string for the idiom to pick it.
fetch_depth_for() {
  python3 - "${ACTION_DIR}/action.yml" "$1" <<'PY'
import re
import sys

path, base_branch = sys.argv[1:]
line = next(l for l in open(path, encoding="utf-8") if re.match(r"\s+fetch-depth: ", l))
match = re.fullmatch(r"\s+fetch-depth: \$\{\{ inputs\.base-branch != '' && (\S+) \|\| (\S+) \}\}\s*", line)
if not match:
    sys.exit(f"unexpected fetch-depth expression: {line.strip()}")


def operand(token):
    """Return the operand's value and whether GitHub treats it as truthy."""
    if token.startswith("'") and token.endswith("'"):
        return token[1:-1], token[1:-1] != ""
    return token, float(token) != 0


chosen, fallback = (operand(token) for token in match.groups())
print(chosen[0] if base_branch != "" and chosen[1] else fallback[0])
PY
}

It "fetches full history when base-branch is set"
When call fetch_depth_for "main"
The output should equal "0"
End

It "fetches a single commit when base-branch is empty"
When call fetch_depth_for ""
The output should equal "1"
End

# The mock's glob is the whole argv pre-commit receives, and an unregistered argv exits
# 127, so the example fails unless the step passes exactly this from-ref.
run_with_from_ref() {
  mock_command python3 "${RUN_PREFIX} --from-ref $1 --to-ref HEAD" "hooks ran"
  run_step "${ACTION_DIR}" "pre-commit"
}

diff_names_equal() {
  [ "$(git diff --name-only "$1...HEAD")" = "$2" ]
}

It "passes a from-ref that resolves in a full checkout"
make_full_clone
export INPUT_BASE_BRANCH="main"
cd work || return 1
When call run_with_from_ref "origin/main"
The status should be success
The stdout should include "hooks ran"
Assert diff_names_equal "origin/main" "changed.txt"
End

It "prefixes a base branch containing a slash"
make_full_clone
git -C work update-ref refs/remotes/origin/release/1.0 HEAD
export INPUT_BASE_BRANCH="release/1.0"
cd work || return 1
When call run_with_from_ref "origin/release/1.0"
The status should be success
The stdout should include "hooks ran"
End

It "keeps a base-branch that already names a ref instead of prefixing it again"
make_full_clone
export INPUT_BASE_BRANCH="origin/main"
cd work || return 1
When call run_with_from_ref "origin/main"
The status should be success
The stdout should include "hooks ran"
End

It "keeps origin/main when a branch actually named origin/main exists as well"
make_full_clone
git -C work update-ref refs/remotes/origin/origin/main HEAD
export INPUT_BASE_BRANCH="origin/main"
cd work || return 1
When call run_with_from_ref "origin/main"
The status should be success
The stdout should include "hooks ran"
End

It "still prefixes a base branch that merely starts with origin/ but is no remote ref"
make_full_clone
git -C work update-ref refs/remotes/origin/origin/only-nested HEAD
export INPUT_BASE_BRANCH="origin/only-nested"
cd work || return 1
When call run_with_from_ref "origin/origin/only-nested"
The status should be success
The stdout should include "hooks ran"
End

It "fails before running pre-commit when the base branch is not in the checkout"
make_full_clone
export INPUT_BASE_BRANCH="no-such-branch"
cd work || return 1
When call run_step "${ACTION_DIR}" "pre-commit"
The status should be failure
The stdout should include "::error::base-branch 'no-such-branch' is neither origin/no-such-branch nor a ref in the checkout"
End
End
