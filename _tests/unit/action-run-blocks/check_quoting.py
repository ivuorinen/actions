"""Report the run: blocks of actions and workflows that leave a variable open to word splitting.

Nothing else runs shellcheck over these blocks: `make lint-shell` reads *.sh files, and the
jactionlint pre-commit hook runs with its shellcheck integration off. The sh and bash scripts
come from _tests/shared/shell_scripts.py, which reads the shell each step runs: its own, its
job's or workflow's defaults.run.shell, its container's, or its runner's, and the scripts
nick-fields/retry runs. Lines between `set -f` and `set +f` are exempt from the word-splitting
rules. That is the documented form of a deliberate split (.claude/rules/posix-shell.md), and
shellcheck reports it the same as an accidental one. `set -f` stops pathname expansion only, so
an unquoted pattern in `${x#$y}` is still reported there.

Usage: check_quoting.py <root>. Exits 1 and prints each finding when any are found.
"""

from __future__ import annotations

import importlib.util
import json
from pathlib import Path
import re
import shutil
import subprocess
import sys

SHARED = Path(__file__).resolve().parents[2] / "shared" / "shell_scripts.py"

# Unquoted variable, the same for a value shellcheck infers is safe, and ${x#$y}.
CODES = {2086, 2248, 2295}
# The codes a deliberate split between `set -f` and `set +f` answers.
SPLIT_CODES = {2086, 2248}
# `set -f` or `set +f` where a command starts. Quoted text is removed first, so that
# printing the words does not count, while `IFS=','; set -f` still does.
NOGLOB_TOGGLE = re.compile(r"^(?:[^#]*[;&|])?\s*set ([-+])f\b")
QUOTED = re.compile(r"'[^']*'|\"(?:\\.|[^\"\\])*\"")
# shellcheck's dialect for each language shell_scripts names.
DIALECTS = {"posix": "sh", "bash": "bash"}


def load_shared():
    """Import _tests/shared/shell_scripts.py, which is not on sys.path."""
    spec = importlib.util.spec_from_file_location("shell_scripts", SHARED)
    if spec is None or spec.loader is None:
        sys.exit(f"{SHARED}: cannot be loaded")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


sh = load_shared()


def in_deliberate_split(lines: list[str], line_number: int) -> bool:
    """Return whether a `set -f` is still in force on the given 1-based line."""
    noglob = False
    for line in lines[:line_number]:
        toggle = NOGLOB_TOGGLE.match(QUOTED.sub("", line))
        if toggle:
            noglob = toggle.group(1) == "-"
    return noglob


def findings(shellcheck: str, path: Path, scripts) -> list[str]:
    """Return one description per unquoted expansion in the given (script, language, line_of)."""
    results = []
    for text, language, line_of in scripts:
        script = re.sub(r"\$\{\{.*?\}\}", "EXPR", text)
        checked = subprocess.run(
            [
                shellcheck,
                "--norc",
                "-s",
                DIALECTS[language],
                "-f",
                "json",
                "-o",
                "quote-safe-variables",
                "-",
            ],
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
            results.append(f"{path}:{line_of(comment['line'])}: SC{code}: {source}")
    return results


def workflow_findings(shellcheck: str, path: Path) -> list[str]:
    """Return the findings in a workflow, or the reason its scripts cannot be read."""
    try:
        scripts = list(sh.workflow_scripts(path.read_text(encoding="utf-8")))
    except sh.ParseError as error:
        return [f"{path}: {error}"]
    return findings(shellcheck, path, scripts)


def main() -> int:
    """Check every composite action and workflow under the root given on the command line."""
    shellcheck = shutil.which("shellcheck")
    if shellcheck is None:
        sys.exit("shellcheck required")
    root = Path(sys.argv[1])
    actions = [*root.glob("*/action.yml"), *root.glob(".github/actions/*/action.yml")]
    workflows = [
        path
        for directory in (".github/workflows", "_tests/integration/workflows")
        for pattern in ("*.yml", "*.yaml")
        for path in root.glob(f"{directory}/{pattern}")
    ]
    results = []
    for path in sorted(actions):
        results.extend(
            findings(shellcheck, path, sh.step_scripts(path.read_text(encoding="utf-8")))
        )
    for path in sorted(workflows):
        results.extend(workflow_findings(shellcheck, path))
    for result in results:
        print(result)
    return 1 if results else 0


if __name__ == "__main__":
    sys.exit(main())
