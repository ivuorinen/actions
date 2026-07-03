#!/usr/bin/env shellspec
# Unit tests for sync-labels/sync.py — the Docker-free label reconciler.
#
# sync.py shells out to `gh` (mocked here) for every API call and to `yq` (real,
# present on runners and dev) to parse YAML. The mock `gh` returns a configurable
# current-label set for `label list` and logs every create/edit/delete call, so we
# assert the exact reconciliation behaviour without touching GitHub.

Describe "sync-labels sync.py"
SYNC="${PROJECT_ROOT}/sync-labels/sync.py"

before() {
  shellspec_setup_test_env "sync-labels-sync-$$"
  BIN="${SHELLSPEC_TEST_WORKSPACE}/bin"
  mkdir -p "$BIN" .github
  GH_CALL_LOG="${SHELLSPEC_TEST_WORKSPACE}/gh-calls.log"
  : >"$GH_CALL_LOG"
  # Mock gh: `label list` echoes $GH_LIST_JSON; everything else is logged verbatim.
  {
    echo '#!/bin/sh'
    echo 'if [ "$1" = "label" ] && [ "$2" = "list" ]; then printf "%s" "${GH_LIST_JSON:-[]}"; exit 0; fi'
    echo 'printf "%s\n" "$*" >> "$GH_CALL_LOG"'
    echo 'exit 0'
  } >"$BIN/gh"
  chmod +x "$BIN/gh"
  export PATH="${BIN}:${PATH}"
  export GH_CALL_LOG
  export GITHUB_REPOSITORY="acme/widget"
  export INPUT_LABELS=".github/labels.yml"
  export INPUT_PRUNE="true"
  unset INPUT_REPOSITORY 2>/dev/null || true
}
BeforeEach 'before'

after() {
  unset GH_LIST_JSON INPUT_LABELS INPUT_PRUNE INPUT_REPOSITORY GITHUB_REPOSITORY 2>/dev/null || true
  shellspec_cleanup_test_env "sync-labels-sync-$$"
}
AfterEach 'after'

run_sync() { python3 "$SYNC"; }

Context "reconciling against existing labels"
It "creates new, updates changed, prunes missing, and skips unchanged labels"
%text >".github/labels.yml"
#|- name: bug
#|  color: d73a4a
#|  description: Something
#|- name: docs
#|  color: 0075ca
#|  description: Documentation
#|- name: feature
#|  color: aabbcc
#|  description: New
export GH_LIST_JSON='[{"name":"bug","color":"d73a4a","description":"Something"},{"name":"old","color":"cccccc","description":"x"},{"name":"docs","color":"000000","description":"old"}]'
When call run_sync
The status should be success
The output should include "1 created, 1 updated, 1 deleted, 1 unchanged"
The contents of file "$GITHUB_OUTPUT" should include "created=1"
The contents of file "$GITHUB_OUTPUT" should include "updated=1"
The contents of file "$GITHUB_OUTPUT" should include "deleted=1"
The contents of file "$GITHUB_OUTPUT" should include "unchanged=1"
# Label names are passed as the trailing "-- <name>" positional (flag-injection guard).
The contents of file "$GH_CALL_LOG" should include "label create"
The contents of file "$GH_CALL_LOG" should include "-- feature"
The contents of file "$GH_CALL_LOG" should include "label edit"
The contents of file "$GH_CALL_LOG" should include "-- docs"
The contents of file "$GH_CALL_LOG" should include "label delete"
The contents of file "$GH_CALL_LOG" should include "-- old"
End
End

Context "with prune disabled"
It "keeps labels not present in the manifest"
%text >".github/labels.yml"
#|- name: bug
#|  color: d73a4a
#|  description: Something
export GH_LIST_JSON='[{"name":"bug","color":"d73a4a","description":"Something"},{"name":"old","color":"cccccc","description":"x"}]'
export INPUT_PRUNE="false"
When call run_sync
The status should be success
The output should include "0 deleted"
The contents of file "$GITHUB_OUTPUT" should include "deleted=0"
The contents of file "$GH_CALL_LOG" should not include "label delete"
End
End

Context "syncing multiple repositories"
It "iterates every repository in the repository input"
%text >".github/labels.yml"
#|- name: bug
#|  color: d73a4a
#|  description: Something
export GH_LIST_JSON='[]'
export INPUT_REPOSITORY="acme/one
acme/two"
When call run_sync
The status should be success
The output should include "across 2 repo(s)"
The contents of file "$GITHUB_OUTPUT" should include "repositories=2"
The contents of file "$GITHUB_OUTPUT" should include "created=2"
The contents of file "$GH_CALL_LOG" should include "-R acme/one"
The contents of file "$GH_CALL_LOG" should include "-R acme/two"
End

It "de-duplicates repeated repository targets"
%text >".github/labels.yml"
#|- name: bug
#|  color: d73a4a
#|  description: Something
export GH_LIST_JSON='[]'
export INPUT_REPOSITORY="acme/one
acme/one"
When call run_sync
The status should be success
The output should include "across 1 repo(s)"
The contents of file "$GITHUB_OUTPUT" should include "repositories=1"
End
End

Context "with a JSON manifest"
It "parses JSON directly without requiring YAML"
%text >".github/labels.json"
#|[{"name": "bug", "color": "#D73A4A", "description": "Something"}]
export INPUT_LABELS=".github/labels.json"
export GH_LIST_JSON='[]'
When call run_sync
The status should be success
The output should include "1 created"
The contents of file "$GITHUB_OUTPUT" should include "created=1"
# Color is normalized (lowercased, leading # stripped) before the API call.
The contents of file "$GH_CALL_LOG" should include "--color d73a4a"
End
End

Context "with an all-digit color that YAML coerces to an integer"
It "restores the zero-padded hex form (e.g. 000000)"
%text >".github/labels.yml"
#|- name: black
#|  color: 000000
#|  description: dark
export GH_LIST_JSON='[]'
When call run_sync
The status should be success
The output should include "1 created"
The contents of file "$GH_CALL_LOG" should include "--color 000000"
End

# Documented best-effort limitation: an unquoted too-short numeric color is
# zero-padded rather than rejected (its original width is unrecoverable).
It "zero-pads a too-short numeric color (best-effort)"
%text >".github/labels.yml"
#|- name: short
#|  color: 010
export GH_LIST_JSON='[]'
When call run_sync
The status should be success
The output should include "1 created"
The contents of file "$GH_CALL_LOG" should include "--color 000010"
End
End

Context "guarding against destructive or malformed input"
It "refuses an empty manifest that would prune everything"
%text >".github/labels.yml"
#|[]
export GH_LIST_JSON='[]'
When call run_sync
The status should be failure
The error should include "no labels"
End

It "rejects an invalid label color"
%text >".github/labels.yml"
#|- name: bug
#|  color: nothex
export GH_LIST_JSON='[]'
When call run_sync
The status should be failure
The error should include "color must be a 6-digit hex"
End

It "rejects a malformed repository target"
%text >".github/labels.yml"
#|- name: bug
#|  color: d73a4a
export GH_LIST_JSON='[]'
export INPUT_REPOSITORY="not-a-repo"
When call run_sync
The status should be failure
The error should include "invalid repository"
End

It "warns and succeeds as a no-op when the manifest is missing"
export INPUT_LABELS=".github/missing.yml"
When call run_sync
The status should be success
The output should include '::warning::sync-labels: manifest not found: ".github/missing.yml"'
The contents of file "$GITHUB_OUTPUT" should include "created=0"
The contents of file "$GITHUB_OUTPUT" should include "updated=0"
The contents of file "$GITHUB_OUTPUT" should include "deleted=0"
The contents of file "$GITHUB_OUTPUT" should include "unchanged=0"
The contents of file "$GITHUB_OUTPUT" should include "repositories=0"
The contents of file "$GH_CALL_LOG" should be blank
End

# main() short-circuits before load_manifest; this covers the function's own
# guard (TOCTOU window / direct callers) which is otherwise unreachable.
It "load_manifest itself still rejects a missing path"
When call python3 -c "import sys; sys.path.insert(0, '${PROJECT_ROOT}/sync-labels'); import sync; sync.load_manifest('.github/nope.yml')"
The status should be failure
The error should include "manifest not found"
End

It "rejects a label name starting with a dash"
%text >".github/labels.yml"
#|- name: -bug
#|  color: d73a4a
export GH_LIST_JSON='[]'
When call run_sync
The status should be failure
The error should include "must not start with"
End

It "rejects a non-string description instead of coercing it"
%text >".github/labels.yml"
#|- name: bug
#|  color: d73a4a
#|  description: false
export GH_LIST_JSON='[]'
When call run_sync
The status should be failure
The error should include "description must be a string"
End

It "prunes a pre-existing label whose name starts with a dash"
%text >".github/labels.yml"
#|- name: bug
#|  color: d73a4a
export GH_LIST_JSON='[{"name":"-legacy","color":"cccccc","description":"x"}]'
When call run_sync
The status should be success
The output should include "1 deleted"
The contents of file "$GH_CALL_LOG" should include "label delete"
The contents of file "$GH_CALL_LOG" should include "-- -legacy"
End
End
End
