#!/usr/bin/env shellspec
# Static checks for .github/workflows and .github/actions:
# no ${{ }} expression inside a run: block, no floating checkout ref, and a
# pr-lint job that only writes where MegaLinter reports.
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

# Prints the scopes the pr-lint job holds at write level, sorted.
pr_lint_write_scopes() {
  python3 -I - <<'PY'
import re

with open(".github/workflows/pr-lint.yml", encoding="utf-8") as handle:
    lines = handle.read().splitlines()
scopes = []
inside = False
for text in lines:
    if re.match(r"^    permissions:\s*$", text):
        inside = True
        continue
    if inside:
        match = re.match(r"^      ([a-z-]+):\s*(\S+)", text)
        if not match:
            break
        if match.group(2) == "write":
            scopes.append(match.group(1))
print(" ".join(sorted(scopes)))
PY
}

# Prints every line that names actions/checkout by a floating version tag.
find_floating_checkout_refs() {
  grep -En 'actions/checkout@v[0-9]' .github/workflows/*.yml || true
}

Describe "GitHub workflows"
It "contain no \${{ }} expression inside a run: block"
When call find_expressions_in_run
The status should be success
The output should equal ""
End

It "name no floating actions/checkout ref"
When call find_floating_checkout_refs
The status should be success
The output should equal ""
End

It "give the pr-lint job write access only to what MegaLinter reports through"
When call pr_lint_write_scopes
The status should be success
The output should equal "pull-requests security-events statuses"
End
End
