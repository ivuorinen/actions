"""Check how every ``<root>/*/action.yml`` pins the tools it installs.

Prints one line per violation and exits 1. A clean tree prints the number of Renovate comments
it checked, and a tree with none of them fails, so the check cannot pass by finding nothing.
"""

from __future__ import annotations

from pathlib import Path
import re
import sys

# customManagers:githubActionsVersions, from renovatebot/renovate's
# lib/config/presets/internal/custom-managers.preset.ts. A comment outside this shape is never
# seen by Renovate, so its pin goes stale silently. Copied here because the contract lives
# upstream; only the named-group syntax differs (JavaScript's ?<x> is Python's ?P<x>).
RENOVATE_PRESET = re.compile(
    r"# renovate: datasource=(?P<datasource>[a-zA-Z0-9-._]+?) depName=(?P<depName>[^\s]+?)"
    r"(?: (?:lookupName|packageName)=(?P<packageName>[^\s]+?))?"
    r"(?: versioning=(?P<versioning>[^\s]+?))?"
    r"(?: extractVersion=(?P<extractVersion>[^\s]+?))?"
    r"(?: registryUrl=(?P<registryUrl>[^\s]+?))?"
    r"\s+[A-Za-z0-9_]+?_VERSION\s*:\s*[\"']?(?P<currentValue>.+?)[\"']?\s"
)

# An exact version, or for setup-php and tonistiigi/binfmt the exact form they publish.
EXACT_VERSION = re.compile(r"^(qemu-)?v?\d+\.\d+(\.\d+)?$")

# Fetching a tool at whatever upstream published last.
FLOATING_LINE = re.compile(
    r"@(latest|stable)\b|\bnpx\s+(--yes|-y)\b|\bnpx\s+[^-\s]|\bbun-version:\s*latest\b"
)

VERSION_INPUT_DEFAULT = re.compile(
    r"^  ([\w-]*version):\n(?:    .*\n)*?    default: ['\"]?(latest|stable)['\"]?$", re.MULTILINE
)

# The env context, not a script's process.env.
ENV_REFERENCE = re.compile(r"(?<![\w.])env\.([A-Z][A-Z0-9_]*)")
STEP_START = re.compile(r"^    - ", re.MULTILINE)


def check_action(action: Path) -> tuple[list[str], int]:
    """Return the violations in one action.yml and the number of Renovate comments in it."""
    text = action.read_text(encoding="utf-8")
    label = action.parent.name
    problems: list[str] = []

    problems += [
        f"{label}:{number}: floating tool reference: {line.strip()}"
        for number, line in enumerate(text.splitlines(), 1)
        if FLOATING_LINE.search(line)
    ]

    problems += [
        f"{label}: input {match.group(1)} defaults to {match.group(2)}"
        for match in VERSION_INPUT_DEFAULT.finditer(text)
    ]

    comments = list(re.finditer(r"^[ \t]*# renovate:.*$", text, re.MULTILINE))
    for comment in comments:
        start = comment.group(0).index("#") + comment.start()
        found = RENOVATE_PRESET.match(text, start)
        if found is None:
            problems.append(f"{label}: outside the preset's shape: {comment.group(0).strip()}")
        elif not EXACT_VERSION.match(found.group("currentValue")):
            problems.append(f"{label}: not an exact version: {found.group('currentValue')}")

    # A misspelt env reference is empty at run time, and an empty version input means upstream's
    # default: the floating version again, with nothing failing to say so.
    for block in STEP_START.split(text)[1:]:
        problems += [
            f"{label}: env.{name} is not defined on the step that reads it"
            for name in ENV_REFERENCE.findall(block)
            if not re.search(rf"^\s+{name}\s*:", block, re.MULTILINE)
        ]

    return problems, len(comments)


def main() -> int:
    root = Path(sys.argv[1])
    problems: list[str] = []
    comments = 0
    for action in sorted(root.glob("*/action.yml")):
        action_problems, action_comments = check_action(action)
        problems += action_problems
        comments += action_comments

    if comments == 0:
        problems.append("no renovate comments found")
    for problem in problems:
        print(problem)
    if problems:
        return 1
    print(f"checked {comments} renovate comments")
    return 0


if __name__ == "__main__":
    sys.exit(main())
