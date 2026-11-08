#!/usr/bin/env shellspec
# Static checks for .github/workflows and .github/actions:
# no ${{ }} expression inside a run: block, actions/checkout pinned by full SHA, and
# a pr-lint job that reads contents and only writes where MegaLinter reports.
# The checks read the YAML as text so they need nothing beyond python3.

# Prints "<file>:<line>: <text>" for every ${{ }} found in a run: block of the given
# files, or of the workflows and local actions when no file is given. A location that
# matches no file fails the scan instead of dropping out of it.
find_expressions_in_run() {
  python3 -I - "$@" <<'PY'
import glob
import re
import sys

files = sys.argv[1:]
if not files:
    for pattern in (".github/workflows/*.yml", ".github/actions/*/action.yml"):
        matched = sorted(glob.glob(pattern))
        if not matched:
            sys.exit("no file matches %s" % pattern)
        files += matched
key = re.compile(r"^(\s*)(?:- )?run:\s*(.*)$")
# A block scalar header: | or >, an optional indentation indicator and chomping
# indicator in either order, then an optional comment.
block = re.compile(r"^[|>](?:[1-9][-+]?|[-+][1-9]?)?(?:\s+#.*)?\s*$")
for path in files:
    with open(path, encoding="utf-8") as handle:
        lines = handle.read().splitlines()
    index = 0
    while index < len(lines):
        match = key.match(lines[index])
        index += 1
        if not match:
            continue
        indent = len(match.group(1)) + (2 if lines[index - 1].lstrip().startswith("- ") else 0)
        body = [(index, match.group(2))]
        if block.match(match.group(2)):
            body = []
            while index < len(lines):
                text = lines[index]
                if text.strip() and len(text) - len(text.lstrip()) <= indent:
                    break
                body.append((index + 1, text))
                index += 1
        for number, text in body:
            if "${{" in text:
                print("%s:%d: %s" % (path, number, text.strip()))
PY
}

# Prints every scope the pr-lint job is granted as "scope=level", sorted. The block runs
# from the job's `permissions:` key to the next line indented as deep as that key or
# less; blank lines and comments inside it do not end it.
pr_lint_permissions() {
  python3 -I - "${1:-.github/workflows/pr-lint.yml}" <<'PY'
import re
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    lines = handle.read().splitlines()
scopes = []
inside = False
for text in lines:
    if re.match(r"^    permissions:\s*$", text):
        inside = True
        continue
    if not inside:
        continue
    content = text.split("#", 1)[0].rstrip()
    if not content:
        continue
    if len(content) - len(content.lstrip()) <= 4:
        break
    scope, _, level = content.strip().partition(":")
    scopes.append("%s=%s" % (scope.strip(), level.strip()))
print(" ".join(sorted(scopes)))
PY
}

# Prints every actions/checkout reference whose ref is not a full commit SHA, in the
# workflows, the local composite actions and the published actions. A path grep cannot
# read, or no checkout reference at all, fails the check instead of passing it empty.
find_floating_checkout_refs() {
  refs=$(grep -HnE 'actions/checkout@' .github/workflows/*.yml .github/actions/*/action.yml ./*/action.yml) ||
    return
  printf '%s\n' "$refs" | grep -vE 'actions/checkout@[0-9a-f]{40}([[:space:]]|$)' || true
}

Describe "GitHub workflows"
It "contain no \${{ }} expression inside a run: block"
When call find_expressions_in_run
The status should be success
The output should equal ""
End

It "name actions/checkout only by full commit SHA"
When call find_floating_checkout_refs
The status should be success
The output should equal ""
End

It "give the pr-lint job read on contents and write only where MegaLinter reports"
When call pr_lint_permissions
The status should be success
The output should equal "contents=read pull-requests=write security-events=write statuses=write"
End
End

Describe "the run: block scanner"
# Writes a workflow whose run: block opens with the given header and holds an
# expression on line 5, indented two past the run key as an indentation indicator
# of 2 requires.
block_header_workflow() {
  printf 'jobs:\n  test:\n    steps:\n      - run: %s\n          echo "${{ github.sha }}"\n' "$1" \
    >"${SHELLSPEC_TMPBASE}/header.yml"
}

Parameters
"|"
"| # note"
"|2"
"|-2"
">2- # folded"
End

It "reports an expression in a block opened with $1"
block_header_workflow "$1"
When call find_expressions_in_run "${SHELLSPEC_TMPBASE}/header.yml"
The status should be success
The output should include ':5: echo "${{ github.sha }}"'
End
End

Describe "the scanners in a tree without .github/actions"
# Enters a tree whose workflow and action pin checkout by SHA, so the missing
# directory is the only thing wrong with it.
enter_tree_without_local_actions() {
  tree="${SHELLSPEC_TMPBASE}/no-local-actions"
  mkdir -p "$tree/.github/workflows" "$tree/foo"
  pin='      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1\n'
  printf "jobs:\n  test:\n    steps:\n$pin" >"$tree/.github/workflows/ci.yml"
  printf "runs:\n  steps:\n$pin" >"$tree/foo/action.yml"
  cd "$tree" || return
}

It "fail the checkout check"
enter_tree_without_local_actions
When call find_floating_checkout_refs
The status should be failure
The error should include ".github/actions/*/action.yml"
End

It "fail the expression scan"
enter_tree_without_local_actions
When call find_expressions_in_run
The status should be failure
The error should equal "no file matches .github/actions/*/action.yml"
End
End
