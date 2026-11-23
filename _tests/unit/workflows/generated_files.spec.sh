#!/usr/bin/env shellspec
# The README steps of generated-files.yml, run as the workflow writes them, in a scratch
# repository standing in for the checkout after make docs: a README that make docs changed,
# or wrote back after the pull request deleted it, must fail the drift step, and a README the
# review skips that is not an action's README.md must fail the other.

Describe "generated-files README drift step"
WORKFLOW="${PROJECT_ROOT}/.github/workflows/generated-files.yml"

drift_step() {
  yq -r '.jobs["docs-drift"].steps[] | select(.name == "Check for action README drift") | .run' "$WORKFLOW"
}

commit_all() {
  git -C "$repo" add -- act
  git -C "$repo" -c user.email=test@example.com -c user.name=test commit -q -m "$1"
}

setup_repo() {
  repo=$(mktemp -d "${SHELLSPEC_TMPBASE}/generated-files.XXXXXX")
  git -C "$repo" init -q
  mkdir -p "$repo/act"
  printf 'name: act\n' >"$repo/act/action.yml"
  printf '# act\n' >"$repo/act/README.md"
  commit_all init
}

run_drift() {
  (cd "$repo" && bash -c "$(drift_step)")
}

skipped_readmes_step() {
  yq -r '.jobs["docs-drift"].steps[] | select(.name == "Check that review skips only generated READMEs") | .run' "$WORKFLOW"
}

run_skipped_readmes() {
  (cd "$repo" && bash -c "$(skipped_readmes_step)")
}

# Commits the file at the path given, holding a heading.
add_file() {
  mkdir -p "$repo/$(dirname "$1")"
  printf '# x\n' >"$repo/$1"
  git -C "$repo" add -- "$1"
  git -C "$repo" -c user.email=test@example.com -c user.name=test commit -q -m "add $1"
}

It "passes when every action README is as committed"
setup_repo
When call run_drift
The status should be success
The stdout should include "All action READMEs are up to date."
End

It "names a README make docs changed"
setup_repo
printf 'regenerated\n' >>"$repo/act/README.md"
When call run_drift
The status should be failure
The stderr should include "Stale: ./act/README.md"
End

# The pull request deleted the README; make docs wrote it back as an untracked file.
It "names a README the pull request deleted, which make docs wrote back"
setup_repo
git -C "$repo" rm -q --cached -- act/README.md
git -C "$repo" -c user.email=test@example.com -c user.name=test commit -q -m "delete README"
When call run_drift
The status should be failure
The stderr should include "Stale: ./act/README.md"
End

# Both jobs are meant to be required checks, and a required check that a paths filter skips
# never reports, so the pull request it skipped could never merge.
It "runs on every pull request and in the merge queue, with no paths filter"
When call yq -r '.on | keys | join(" "), (.pull_request.paths // "no paths filter")' "$WORKFLOW"
The line 1 of output should equal "pull_request merge_group"
The line 2 of output should equal "no paths filter"
End

It "checks the validators and the action READMEs"
When call yq -r '.jobs[].name' "$WORKFLOW"
The output should include "Validator drift"
The output should include "Action README drift"
End

Describe "the README review coverage step"
It "passes when every README the review skips is an action's README.md"
setup_repo
add_file _tests/README.md
add_file README.md
When call run_skipped_readmes
The status should be success
The stdout should include "Every README the review skips is an action's generated README.md."
End

It "fails on a README in a top-level directory that is no action"
setup_repo
add_file docs/README.md
When call run_skipped_readmes
The status should be failure
The stderr should include "Unchecked: docs/README.md"
End

# The review filter matches case-insensitively; the drift step compares README.md only.
It "fails on an action's README in another case"
setup_repo
add_file act/readme.md
When call run_skipped_readmes
The status should be failure
The stderr should include "Unchecked: act/readme.md"
End
End
End
