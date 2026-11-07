#!/usr/bin/env shellspec
# Every action that ships a validate.py must run it before actions/checkout. The
# validator lives in the action directory (github.action_path), so it needs no
# checkout, and checkout consumes inputs such as token that have to be validated first.
# Scans the repository rather than a list of actions, so a new action is covered too.

Describe "validate.py step order"
list_order_violations() {
  _harness_python - "$PROJECT_ROOT" <<'PY'
import sys
from pathlib import Path

import yaml


def first_step(steps, matches):
    return next((i for i, step in enumerate(steps) if matches(step)), None)


validators = sorted(Path(sys.argv[1]).glob("*/validate.py"))
if not validators:
    sys.exit("no validate.py found")

for validator in validators:
    action = yaml.safe_load(validator.with_name("action.yml").read_text(encoding="utf-8"))
    steps = action["runs"].get("steps", [])
    validate = first_step(steps, lambda step: "validate.py" in step.get("run", ""))
    checkout = first_step(steps, lambda step: step.get("uses", "").startswith("actions/checkout@"))
    name = validator.parent.name
    if validate is None:
        print(f"{name}: no step runs validate.py")
    elif checkout is not None and checkout < validate:
        print(f"{name}: step {checkout} runs actions/checkout before step {validate} runs validate.py")
PY
}

It "runs validate.py before actions/checkout in every action"
When call list_order_violations
The status should be success
The output should equal ""
End
End
