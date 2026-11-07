#!/usr/bin/env shellspec
# Directories whose ShellSpec tests run in test-actions.yml must be in its paths
# filter, for both the push and the pull_request trigger. Otherwise a change there
# skips its own tests.

Describe "test-actions.yml paths filter"
WORKFLOW="${PROJECT_ROOT}/.github/workflows/test-actions.yml"

# Succeeds when the trigger's own list holds the entry: the lines under `  <trigger>:`
# up to the next trigger, so an entry listed twice under one trigger does not count
# for the other.
trigger_lists_path() {
  awk -v trigger="  $1:" '
    $0 == trigger { inside = 1; next }
    inside && /^  [a-z_]+:/ { exit }
    inside && /^      - / { sub(/^      - /, ""); print }
  ' "$WORKFLOW" | grep -qxF "'$2'"
}

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
