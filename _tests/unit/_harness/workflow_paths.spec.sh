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
# Writes a copy of the workflow with the first push-trigger `_tools/**` entry edited.
copy_workflow() {
  python3 - "$WORKFLOW" "${SHELLSPEC_TMPBASE}/test-actions.yml" "$1" <<'PY'
import sys

source, target, edit = sys.argv[1:]
lines = open(source, encoding="utf-8").read().split("\n")
entry = lines.index("      - '_tools/**'")
if edit == "double-quote":
    lines[entry] = '      - "_tools/**"'
elif edit == "move-to-branches":
    del lines[entry]
    lines.insert(lines.index("      - main") + 1, "      - '_tools/**'")
open(target, "w", encoding="utf-8").write("\n".join(lines))
PY
  WORKFLOW="${SHELLSPEC_TMPBASE}/test-actions.yml"
}

It "accepts an entry written with double quotes"
copy_workflow double-quote
When call trigger_lists_path push "_tools/**"
The status should be success
End

It "does not count an entry that moved from paths to branches"
copy_workflow move-to-branches
When call trigger_lists_path push "_tools/**"
The status should be failure
End
End
End
