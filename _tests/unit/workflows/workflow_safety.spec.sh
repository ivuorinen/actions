#!/usr/bin/env shellspec
# Static checks for .github/workflows and .github/actions:
# no ${{ }} expression inside a run: block, actions/checkout pinned by full SHA, and
# a pr-lint job that reads contents and only writes where MegaLinter reports.
# The checks read the YAML as text so they need nothing beyond python3.

# Prints "<file>:<line>: <text>" for every ${{ }} found in a run: block.
find_expressions_in_run() {
  python3 -I - <<'PY'
import glob
import re

files = sorted(
    glob.glob(".github/workflows/*.yml") + glob.glob(".github/actions/*/action.yml")
)
key = re.compile(r"^(\s*)(?:- )?run:\s*(.*)$")
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
        if re.match(r"^[|>][-+]?$", match.group(2)):
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
# workflows, the local composite actions and the published actions.
find_floating_checkout_refs() {
  grep -HnE 'actions/checkout@' .github/workflows/*.yml .github/actions/*/action.yml ./*/action.yml |
    grep -vE 'actions/checkout@[0-9a-f]{40}([[:space:]]|$)' || true
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
