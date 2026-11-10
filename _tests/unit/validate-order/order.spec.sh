#!/usr/bin/env shellspec
# Every action that ships a validate.py must run it before actions/checkout. The
# validator lives in the action directory (github.action_path), so it needs no
# checkout, and checkout consumes inputs such as token that have to be validated first.
# Scans the repository rather than a list of actions, so a new action is covered too.

Describe "validate.py step order"
list_order_violations() {
  _harness_python - "$PROJECT_ROOT" <<'PY'
import re
import sys
from pathlib import Path

import yaml

# The command itself: a step that only mentions the file validates nothing.
invocation = re.compile(r"^\s*python3 validate\.py\s*$", re.MULTILINE)


def first_step(steps, matches):
    return next((i for i, step in enumerate(steps) if matches(step)), None)


validators = sorted(Path(sys.argv[1]).glob("*/validate.py"))
if not validators:
    sys.exit("no validate.py found")

for validator in validators:
    action = yaml.safe_load(validator.with_name("action.yml").read_text(encoding="utf-8"))
    steps = action["runs"].get("steps", [])
    validate = first_step(steps, lambda step: invocation.search(step.get("run", "")))
    checkout = first_step(steps, lambda step: step.get("uses", "").startswith("actions/checkout@"))
    name = validator.parent.name
    if validate is None:
        print(f"{name}: no step runs validate.py")
        continue
    if "if" in steps[validate]:
        print(f"{name}: step {validate} runs validate.py only under a condition")
    if checkout is not None and checkout < validate:
        print(f"{name}: step {checkout} runs actions/checkout before step {validate} runs validate.py")
PY
}

# Makes a repository of one action, whose steps come from stdin, the one to scan.
order_fixture() {
  mkdir -p "${SHELLSPEC_TMPBASE}/order/x"
  : >"${SHELLSPEC_TMPBASE}/order/x/validate.py"
  {
    printf 'runs:\n  using: composite\n  steps:\n'
    cat
  } >"${SHELLSPEC_TMPBASE}/order/x/action.yml"
  PROJECT_ROOT="${SHELLSPEC_TMPBASE}/order"
}

It "runs validate.py before actions/checkout in every action"
When call list_order_violations
The status should be success
The output should equal ""
End

It "does not take a step that only mentions validate.py for the validator"
order_fixture <<'YAML'
    - shell: sh
      run: echo 'run validate.py later'
    - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1
    - shell: sh
      run: |
        set -eu
        python3 validate.py
YAML
When call list_order_violations
The output should equal "x: step 1 runs actions/checkout before step 2 runs validate.py"
End

It "reports a validator step that a condition can skip"
order_fixture <<'YAML'
    - if: false
      shell: sh
      run: python3 validate.py
    - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1
YAML
When call list_order_violations
The output should equal "x: step 0 runs validate.py only under a condition"
End
End
