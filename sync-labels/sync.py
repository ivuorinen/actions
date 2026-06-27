"""Declarative GitHub label sync — a Docker-free reimplementation of action-label-syncer.

Reads a YAML (or JSON) manifest of desired labels and reconciles one or more
repositories to match it, using the GitHub CLI (``gh``) for every API call.

Design notes
------------
* **No Docker, no PyYAML.** GitHub-hosted runners ship ``yq`` and ``gh`` but not
  PyYAML in the system ``python3``; we shell out to ``yq -o=json`` (a real YAML
  parser) and parse the JSON with the standard library. JSON manifests are read
  directly when ``yq`` is unavailable.
* **Batch by diff.** REST/``gh label`` operations are inherently per-label (there
  is no bulk label endpoint), so the only way to "batch" is to issue the fewest
  requests possible: list each repo's labels once (``gh label list -L 9999``),
  then create/edit/delete *only* what actually differs. Unchanged labels cost
  zero requests.

Inputs (read from ``INPUT_*`` env vars, set by action.yml):
  INPUT_LABELS      manifest path (default ``.github/labels.yml``)
  INPUT_REPOSITORY  newline-separated ``owner/repo`` list (default: current repo)
  INPUT_PRUNE       ``true``/``false`` — delete labels not in the manifest (default true)

``GH_TOKEN`` (set by action.yml from the ``token`` input) authenticates ``gh``.
"""

from __future__ import annotations

import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
from typing import NoReturn

DEFAULT_MANIFEST = ".github/labels.yml"
DEFAULT_COLOR = "ededed"  # GitHub's own default label color
LIST_LIMIT = "9999"  # fetch every label in one paginated call (avoid silent truncation)
# sync.py ships standalone in the action dir and cannot import _validation.kit, so these
# two patterns are local copies. _REPO mirrors kit.check_repository_list's owner/repo
# regex and must be kept in lockstep with it; _HEX6 validates manifest *content* (label
# colors), which has no canonical home in kit. See .claude/rules/code-quality.md.
_HEX6 = re.compile(r"^[0-9a-f]{6}$")
_REPO = re.compile(r"^[A-Za-z0-9._-]+/[A-Za-z0-9._-]+$")


def fail(message: str) -> NoReturn:
    """Emit a GitHub Actions error annotation and exit non-zero."""
    sys.stderr.write(f"::error::sync-labels: {message}\n")
    sys.exit(1)


def _bool(value: str, *, default: bool) -> bool:
    """Parse a ``true``/``false`` string, falling back to ``default`` when empty."""
    value = (value or "").strip().lower()
    if value == "":
        return default
    return value == "true"


def _run(argv: list[str]) -> str:
    """Run a command, returning stdout; fail loudly on non-zero exit."""
    try:
        result = subprocess.run(argv, capture_output=True, text=True, check=False)
    except FileNotFoundError:
        fail(f"required command not found: {argv[0]}")
    if result.returncode != 0:
        detail = (result.stderr or result.stdout or "").strip()
        fail(f"command failed ({' '.join(argv[:2])}): {detail}")
    return result.stdout


def load_manifest(path: str) -> list[dict]:
    """Load the manifest as a list of dicts. YAML via ``yq``, JSON via stdlib."""
    if not Path(path).is_file():
        fail(f'manifest not found: "{path}"')
    if shutil.which("yq"):
        raw = _run(["yq", "-o=json", "-I=0", ".", path])
    elif path.endswith(".json"):
        raw = Path(path).read_text(encoding="utf-8")
    else:
        fail("yq is required to parse YAML manifests (install yq or use a .json manifest)")
    try:
        data = json.loads(raw)
    except json.JSONDecodeError as exc:
        fail(f"could not parse manifest as JSON: {exc}")
    if not isinstance(data, list):
        fail("manifest must be a list of label entries")
    return data


def normalize(entries: list[dict]) -> list[dict]:
    """Validate and normalize manifest entries into {name, color, description}."""
    labels: list[dict] = []
    seen: set[str] = set()
    for index, entry in enumerate(entries):
        where = f"entry #{index + 1}"
        if not isinstance(entry, dict):
            fail(f"{where}: each label must be a mapping with a 'name'")
        name = entry.get("name")
        if not isinstance(name, str) or name.strip() == "":
            fail(f"{where}: 'name' is required and must be a non-empty string")
        if name.startswith("-"):
            # gh parses a leading-dash positional as a flag, so the label would never
            # be created — reject it up front rather than silently miscounting.
            fail(f"{where}: label name '{name}' must not start with '-'")
        key = name.lower()
        if key in seen:
            fail(f"{where}: duplicate label name '{name}'")
        seen.add(key)
        color = str(entry.get("color", DEFAULT_COLOR)).lstrip("#").lower()
        if color.isdigit():
            # YAML coerces all-digit colors (e.g. 000000) to ints, dropping leading
            # zeros; restore the 6-digit hex form before validating. This is best-effort:
            # a too-short numeric color (e.g. 010) is also zero-padded to 000010 rather
            # than rejected, because the original width is unrecoverable from the int.
            # Quote colors in the manifest (color: "000000") to pass them verbatim.
            color = color.zfill(6)
        if not _HEX6.match(color):
            fail(f"{where} ('{name}'): color must be a 6-digit hex value, got '{color}'")
        description = entry.get("description") or ""
        if not isinstance(description, str):
            fail(f"{where} ('{name}'): description must be a string")
        labels.append({"name": name, "color": color, "description": description})
    if not labels:
        fail("manifest contains no labels — refusing to run (would prune every label)")
    return labels


def list_labels(repo: str) -> list[dict]:
    """Return the repository's current labels via the GitHub CLI."""
    out = _run(
        ["gh", "label", "list", "-R", repo, "--json", "name,color,description", "-L", LIST_LIMIT]
    )
    return json.loads(out) if out.strip() else []


def sync_repo(repo: str, desired: list[dict], *, prune: bool) -> dict[str, int]:
    """Reconcile a single repository to ``desired``; return per-action counts."""
    current = list_labels(repo)
    by_key = {label["name"].lower(): label for label in current}
    desired_keys = {label["name"].lower() for label in desired}
    counts = {"created": 0, "updated": 0, "deleted": 0, "unchanged": 0}

    for label in desired:
        existing = by_key.get(label["name"].lower())
        if existing is None:
            _run(
                [
                    "gh",
                    "label",
                    "create",
                    label["name"],
                    "-R",
                    repo,
                    "--color",
                    label["color"],
                    "--description",
                    label["description"],
                ]
            )
            counts["created"] += 1
            print(f"  + created '{label['name']}' in {repo}")
            continue
        cur_color = (existing.get("color") or "").lstrip("#").lower()
        cur_desc = existing.get("description") or ""
        if (
            cur_color == label["color"]
            and cur_desc == label["description"]
            and existing["name"] == label["name"]
        ):
            counts["unchanged"] += 1
            continue
        # --name handles case-only renames (GitHub treats names case-insensitively).
        _run(
            [
                "gh",
                "label",
                "edit",
                existing["name"],
                "-R",
                repo,
                "--name",
                label["name"],
                "--color",
                label["color"],
                "--description",
                label["description"],
            ]
        )
        counts["updated"] += 1
        print(f"  ~ updated '{label['name']}' in {repo}")

    if prune:
        for label in current:
            if label["name"].lower() not in desired_keys:
                _run(["gh", "label", "delete", label["name"], "-R", repo, "--yes"])
                counts["deleted"] += 1
                print(f"  - deleted '{label['name']}' from {repo}")

    return counts


def resolve_repos() -> list[str]:
    """Return the target repositories: the repository input, else the current repo."""
    raw = os.environ.get("INPUT_REPOSITORY", "").strip()
    if not raw:
        current = os.environ.get("GITHUB_REPOSITORY", "").strip()
        if not current:
            fail("could not determine the current repository (GITHUB_REPOSITORY unset)")
        return [current]
    seen: set[str] = set()
    repos: list[str] = []
    for line in raw.splitlines():
        repo = line.strip()
        if not repo or repo in seen:
            continue  # skip blanks and duplicate targets (avoid double-syncing)
        if not _REPO.match(repo):
            fail(f"invalid repository '{repo}' — expected 'owner/repo'")
        seen.add(repo)
        repos.append(repo)
    return repos


def main() -> int:
    """Entry point: load the manifest and reconcile every target repository."""
    manifest = os.environ.get("INPUT_LABELS", "").strip() or DEFAULT_MANIFEST
    prune = _bool(os.environ.get("INPUT_PRUNE", ""), default=True)
    desired = normalize(load_manifest(manifest))
    repos = resolve_repos()

    totals = {"created": 0, "updated": 0, "deleted": 0, "unchanged": 0}
    for repo in repos:
        print(f"Syncing {len(desired)} labels to {repo} (prune={'true' if prune else 'false'})")
        for key, value in sync_repo(repo, desired, prune=prune).items():
            totals[key] += value

    summary = (
        f"{totals['created']} created, {totals['updated']} updated, "
        f"{totals['deleted']} deleted, {totals['unchanged']} unchanged "
        f"across {len(repos)} repo(s)"
    )
    print(f"::notice::sync-labels: {summary}")

    output = os.environ.get("GITHUB_OUTPUT")
    if output:
        with Path(output).open("a", encoding="utf-8") as handle:
            handle.write(f"created={totals['created']}\n")
            handle.write(f"updated={totals['updated']}\n")
            handle.write(f"deleted={totals['deleted']}\n")
            handle.write(f"unchanged={totals['unchanged']}\n")
            handle.write(f"repositories={len(repos)}\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
