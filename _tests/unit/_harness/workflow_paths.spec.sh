#!/usr/bin/env shellspec
# Directories whose ShellSpec tests run in test-actions.yml must be in its paths
# filter, for both the push and the pull_request trigger. Otherwise a change there
# skips its own tests.

Describe "test-actions.yml paths filter"
WORKFLOW="${PROJECT_ROOT}/.github/workflows/test-actions.yml"

# Succeeds when the trigger's own `paths` list holds the entry. The workflow is parsed,
# so quoting style does not matter and entries under other keys, such as branches, do
# not count.
trigger_lists_path() {
  uv run python - "$WORKFLOW" "$1" "$2" <<'PY'
import sys

import yaml

path, trigger, entry = sys.argv[1:]
with open(path, encoding="utf-8") as handle:
    workflow = yaml.safe_load(handle)
# PyYAML reads the bare key `on` as the boolean True.
triggers = workflow.get("on", workflow.get(True)) or {}
paths = (triggers.get(trigger) or {}).get("paths") or []
sys.exit(0 if entry in paths else 1)
PY
}

Describe "each trigger"
Parameters
"push" "_tools/**"
"push" ".claude/hooks/**"
"pull_request" "_tools/**"
"pull_request" ".claude/hooks/**"
End

It "lists $2 under $1"
When call trigger_lists_path "$1" "$2"
The status should be success
End
End

Describe "the check itself"
# A fixed workflow whose push trigger lists the entry in double quotes.
double_quote_workflow() {
  cat >"${SHELLSPEC_TMPBASE}/test-actions.yml" <<'YAML'
on:
  push:
    paths:
      - "_tools/**"
YAML
  WORKFLOW="${SHELLSPEC_TMPBASE}/test-actions.yml"
}

# A fixed workflow whose push trigger lists the entry under branches, not paths.
branches_only_workflow() {
  cat >"${SHELLSPEC_TMPBASE}/test-actions.yml" <<'YAML'
on:
  push:
    branches:
      - main
      - '_tools/**'
    paths:
      - '*/action.yml'
YAML
  WORKFLOW="${SHELLSPEC_TMPBASE}/test-actions.yml"
}

It "accepts an entry written with double quotes"
double_quote_workflow
When call trigger_lists_path push "_tools/**"
The status should be success
End

It "does not count an entry listed under branches"
branches_only_workflow
When call trigger_lists_path push "_tools/**"
The status should be failure
End

# The positive half of the fixture: a check that rejects every workflow would pass the
# negative example above, but not this one.
It "finds the entry the same fixture lists under paths"
branches_only_workflow
When call trigger_lists_path push "*/action.yml"
The status should be success
End
End
End
