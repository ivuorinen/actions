"""Check how every ``<root>/*/action.yml`` pins the tools it installs.

Prints one line per violation and exits 1. A clean tree prints the number of Renovate comments
it checked, and a tree with none of them fails, so the check cannot pass by finding nothing.
"""

from __future__ import annotations

import json
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

# An exact version: three components, or qemu-vX.Y.Z as tonistiigi/binfmt publishes it.
EXACT_VERSION = re.compile(r"^(qemu-)?v?\d+\.\d+\.\d+$")

# setup-php takes major.minor and installs that line's newest patch, so a PHP pin can be no finer.
# For every other tool a two-component value is a range: npm reads 1.2 as 1.2.x.
MAJOR_MINOR_DEPS = {"php/php-src"}
MAJOR_MINOR = re.compile(r"^\d+\.\d+$")

# Fetching a tool at whatever upstream published last. npx and bunx fetch a package they do
# not find, whatever comes before its name (-p, --package=, --, a redirection), unless
# --no-install (npx: --no) says not to; `command -v npx` only looks npx up. pnpm dlx and
# yarn dlx always fetch.
FLOATING_LINE = re.compile(
    r"@(latest|stable)\b"
    r"|(?<!command -v )\b(npx|bunx)\b(?!\s+--no(-install)?\b)(?=[\s<>|&;)]|$)"
    r"|\b(pnpm|yarn)\s+dlx\b"
    r"|\bbun-version:\s*latest\b"
)

VERSION_INPUT_DEFAULT = re.compile(
    r"^  ([\w-]*version):\n(?:    .*\n)*?    default: ['\"]?(latest|stable)['\"]?$", re.MULTILINE
)

# The env context, not a script's process.env.
ENV_REFERENCE = re.compile(r"(?<![\w.])env\.([A-Z][A-Z0-9_]*)")
STEP_START = re.compile(r"^    - ", re.MULTILINE)


def repository_managers(root: Path) -> list[re.Pattern[str]]:
    """Return the matchStrings of the repository's own regex managers in .github/renovate.json.

    Renovate reads these as well as the preset, so a comment one of them matches is tracked.
    """
    config = root / ".github" / "renovate.json"
    if not config.is_file():
        return []
    managers = json.loads(config.read_text(encoding="utf-8")).get("customManagers", [])
    return [
        re.compile(pattern.replace("(?<", "(?P<"))
        for manager in managers
        for pattern in manager.get("matchStrings", [])
    ]


def pinned_value(text: str, comment_end: int) -> str:
    """Return the whole value on the line after a renovate comment, without its quotes.

    Renovate's match captures only a prefix of a value it cannot parse, so `1.2.3 - 2.0.0`
    would pass a check of that capture; the exact-version check reads the whole scalar.
    """
    start = text.find("\n", comment_end) + 1
    end = text.find("\n", start)
    line = text[start : end if end != -1 else len(text)]
    value = line.split(":", 1)[1].strip() if ":" in line else ""
    if len(value) >= 2 and value[0] == value[-1] and value[0] in "'\"":
        value = value[1:-1]
    return value


def check_action(action: Path, managers: list[re.Pattern[str]]) -> tuple[list[str], int]:
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
        found = RENOVATE_PRESET.match(text, start) or next(
            (match for match in (manager.match(text, start) for manager in managers) if match),
            None,
        )
        if found is None:
            problems.append(f"{label}: outside the preset's shape: {comment.group(0).strip()}")
            continue
        value = pinned_value(text, comment.end())
        if found.groupdict().get("currentDigest"):
            value = value.split("@", 1)[0]
        major_minor = found.group("depName") in MAJOR_MINOR_DEPS and MAJOR_MINOR.match(value)
        if not (EXACT_VERSION.match(value) or major_minor):
            problems.append(f"{label}: not an exact version: {value}")

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
    managers = repository_managers(root)
    problems: list[str] = []
    comments = 0
    for action in sorted(root.glob("*/action.yml")):
        action_problems, action_comments = check_action(action, managers)
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
