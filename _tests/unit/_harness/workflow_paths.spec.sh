#!/usr/bin/env shellspec
# Directories whose ShellSpec tests run in test-actions.yml must be in its paths
# filter, for both the push and the pull_request trigger. Otherwise a change there
# skips its own tests.

Describe "test-actions.yml paths filter"
WORKFLOW="${PROJECT_ROOT}/.github/workflows/test-actions.yml"

# Occurrences of a path entry; one per trigger (push, pull_request).
count_path_entries() {
  grep -c -F -x "      - '$1'" "$WORKFLOW"
}

Parameters
"_tools/**"
".claude/hooks/**"
End

It "lists $1 under both push and pull_request"
When call count_path_entries "$1"
The output should equal "2"
End
End
