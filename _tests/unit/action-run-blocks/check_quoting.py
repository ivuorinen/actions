"""Report composite action run: blocks that leave a variable open to word splitting.

Nothing else runs shellcheck over these blocks: `make lint-shell` reads *.sh files, and
actionlint reads workflows only. Lines between `set -f` and `set +f` are exempt from the
word-splitting rules. That is the documented form of a deliberate split
(.claude/rules/posix-shell.md), and shellcheck reports it the same as an accidental one.
`set -f` stops pathname expansion only, so an unquoted pattern in `${x#$y}` is still
reported there.

Usage: check_quoting.py <root>. Exits 1 and prints each finding when any are found.
"""

from __future__ import annotations

import json
from pathlib import Path
import re
import shutil
import subprocess
import sys

import yaml

# Unquoted variable, the same for a value shellcheck infers is safe, and ${x#$y}.
CODES = {2086, 2248, 2295}
# The codes a deliberate split between `set -f` and `set +f` answers.
SPLIT_CODES = {2086, 2248}
# `set -f` or `set +f` where a command starts. Quoted text is removed first, so that
# printing the words does not count, while `IFS=','; set -f` still does.
NOGLOB_TOGGLE = re.compile(r"^(?:[^#]*[;&|])?\s*set ([-+])f\b")
QUOTED = re.compile(r"'[^']*'|\"(?:\\.|[^\"\\])*\"")


def in_deliberate_split(lines: list[str], line_number: int) -> bool:
    """Return whether a `set -f` is still in force on the given 1-based line."""
    noglob = False
    for line in lines[:line_number]:
        toggle = NOGLOB_TOGGLE.match(QUOTED.sub("", line))
        if toggle:
            noglob = toggle.group(1) == "-"
    return noglob


def findings(shellcheck: str, path: Path) -> list[str]:
    """Return one description per unquoted expansion in the action's run: blocks."""
    action = yaml.safe_load(path.read_text(encoding="utf-8"))
    results = []
    for step in action["runs"].get("steps", []):
        # A shell can be a template such as `sh -e {0}`.
        shell = step.get("shell", "").partition(" ")[0]
        if "run" not in step or shell not in ("sh", "bash"):
            continue
        script = re.sub(r"\$\{\{.*?\}\}", "EXPR", step["run"])
        checked = subprocess.run(
            [shellcheck, "--norc", "-s", shell, "-f", "json", "-o", "quote-safe-variables", "-"],
            input=script,
            capture_output=True,
            text=True,
            check=False,
        )
        if checked.returncode > 1:
            sys.exit(f"shellcheck failed on {path}: {checked.stderr}")
        lines = script.splitlines()
        for comment in json.loads(checked.stdout):
            code = comment["code"]
            if code not in CODES or (
                code in SPLIT_CODES and in_deliberate_split(lines, comment["line"])
            ):
                continue
            source = lines[comment["line"] - 1].strip()
            results.append(f"{path}: SC{comment['code']} in '{step.get('name')}': {source}")
    return results


def main() -> int:
    """Check every composite action under the root given on the command line."""
    shellcheck = shutil.which("shellcheck")
    if shellcheck is None:
        sys.exit("shellcheck required")
    root = Path(sys.argv[1])
    results = []
    for path in sorted([*root.glob("*/action.yml"), *root.glob(".github/actions/*/action.yml")]):
        results.extend(findings(shellcheck, path))
    for result in results:
        print(result)
    return 1 if results else 0


if __name__ == "__main__":
    sys.exit(main())
