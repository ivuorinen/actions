#!/usr/bin/env shellspec
# The README drift step of docs-check.yml, run as the workflow writes it, in a scratch
# repository standing in for the checkout after make docs: a README that make docs changed,
# or wrote back after the pull request deleted it, must fail the step.

Describe "docs-check README drift step"
WORKFLOW="${PROJECT_ROOT}/.github/workflows/docs-check.yml"

drift_step() {
  yq -r '.jobs["docs-drift"].steps[] | select(.name == "Check for action README drift") | .run' "$WORKFLOW"
}

commit_all() {
  git -C "$repo" add -- act
  git -C "$repo" -c user.email=test@example.com -c user.name=test commit -q -m "$1"
}

setup_repo() {
  repo=$(mktemp -d "${SHELLSPEC_TMPBASE}/docs-check.XXXXXX")
  git -C "$repo" init -q
  mkdir -p "$repo/act"
  printf 'name: act\n' >"$repo/act/action.yml"
  printf '# act\n' >"$repo/act/README.md"
  commit_all init
}

run_drift() {
  (cd "$repo" && bash -c "$(drift_step)")
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
End
