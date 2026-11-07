#!/usr/bin/env shellspec
# Static checks for .github/workflows and .github/actions:
# no ${{ }} expression inside a run: block, and a read-only pr-lint job.

# Prints "<file>: <step name>: <expression>" for every ${{ }} found in a run: block.
find_expressions_in_run() {
  python3 -I - <<'PY'
import glob
import re
import yaml

files = sorted(
    glob.glob(".github/workflows/*.yml") + glob.glob(".github/actions/*/action.yml")
)
for path in files:
    with open(path, encoding="utf-8") as handle:
        doc = yaml.safe_load(handle)
    steps = []
    for job in (doc.get("jobs") or {}).values():
        steps.extend(job.get("steps") or [])
    steps.extend((doc.get("runs") or {}).get("steps") or [])
    for step in steps:
        run = step.get("run")
        if isinstance(run, str):
            for expr in re.findall(r"\$\{\{.*?\}\}", run):
                print("%s: %s: %s" % (path, step.get("name", "?"), expr))
PY
}

# Prints the scopes the pr-lint job holds at write level.
pr_lint_write_scopes() {
  python3 -I - <<'PY'
import yaml

with open(".github/workflows/pr-lint.yml", encoding="utf-8") as handle:
  doc = yaml.safe_load(handle)
perms = doc["jobs"]["megalinter"]["permissions"]
print(" ".join(sorted(k for k, v in perms.items() if v == "write")))
PY
}

# Prints every line that names actions/checkout by a floating version tag.
find_floating_refs_in_run() {
  rg -n 'actions/checkout@v[0-9]' .github/workflows
}

Describe "GitHub workflows"
It "contain no \${{ }} expression inside a run: block"
When call find_expressions_in_run
The status should be success
The output should equal ""
End

It "print no floating actions/checkout ref"
When call find_floating_refs_in_run
The status should be failure
The output should equal ""
End

It "give the pr-lint job write access only to what MegaLinter reports through"
When call pr_lint_write_scopes
The status should be success
The output should equal "pull-requests security-events statuses"
End
End
