#!/usr/bin/env shellspec
# Unit tests for _tools/fix-local-action-refs.py (N-118 repoint, N-121 wiring).
#
# Verifies the tool scans WORKFLOW files (.github/workflows + _tests/integration/
# workflows) and rewrites `uses: ../action` → `uses: ./action`, while NEVER
# touching action.yml files (which must use SHA-pinned refs) or external refs.
# Runs the tool against a throwaway fixture root via the --root flag so the real
# repository is never modified.

Describe "fix-local-action-refs.py"
TOOL="${PROJECT_ROOT}/_tools/fix-local-action-refs.py"

setup_fixture() {
  FIX_ROOT="$(mktemp -d)"

  # Real internal action so `node-setup` is in available_actions.
  mkdir -p "$FIX_ROOT/node-setup"
  printf 'name: node-setup\n' >"$FIX_ROOT/node-setup/action.yml"

  # Workflow with a list-item ../ ref plus an external ref that must be left alone.
  mkdir -p "$FIX_ROOT/.github/workflows"
  printf 'jobs:\n  t:\n    steps:\n      - uses: ../node-setup\n      - uses: actions/checkout@v4\n' \
    >"$FIX_ROOT/.github/workflows/wf.yml"

  # Integration test workflow with the same issue.
  mkdir -p "$FIX_ROOT/_tests/integration/workflows"
  printf 'jobs:\n  t:\n    steps:\n      - uses: ../node-setup\n' \
    >"$FIX_ROOT/_tests/integration/workflows/it-test.yml"

  # action.yml that (wrongly) contains a ../ ref — the tool must NOT rewrite it,
  # because action.yml requires ivuorinen/actions/<name>@<sha>, never ./.
  mkdir -p "$FIX_ROOT/docker-build"
  printf 'runs:\n  steps:\n    - uses: ../node-setup\n' >"$FIX_ROOT/docker-build/action.yml"
}
cleanup_fixture() { rm -rf "$FIX_ROOT"; }
BeforeEach 'setup_fixture'
AfterEach 'cleanup_fixture'

Describe "--check"
It "exits 1 and reports the workflow refs that need fixing"
When run python3 "$TOOL" --check --root "$FIX_ROOT"
The status should equal 1
The output should include "wf.yml"
The output should include "../node-setup → ./node-setup"
End
End

Describe "fix mode"
It "rewrites workflow ../action refs but leaves action.yml and external refs alone"
When run python3 "$TOOL" --root "$FIX_ROOT"
The status should be success
The output should include "Fixed 2 local action references"
# Workflow refs rewritten to ./
The contents of file "$FIX_ROOT/.github/workflows/wf.yml" should include "uses: ./node-setup"
The contents of file "$FIX_ROOT/_tests/integration/workflows/it-test.yml" should include "uses: ./node-setup"
# action.yml local ref left untouched (must keep ../, never ./ — needs a SHA pin)
The contents of file "$FIX_ROOT/docker-build/action.yml" should include "uses: ../node-setup"
# External ref left untouched
The contents of file "$FIX_ROOT/.github/workflows/wf.yml" should include "actions/checkout@v4"
End
End

Describe "--dry-run"
It "reports planned fixes without modifying files"
When run python3 "$TOOL" --dry-run --root "$FIX_ROOT"
The status should be success
The output should include "Would fix"
The contents of file "$FIX_ROOT/.github/workflows/wf.yml" should include "uses: ../node-setup"
End
End
End
