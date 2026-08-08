#!/usr/bin/env python3
"""Post-process one generated action README.

``gh-action-readme``'s themes emit example workflows that are close, but not
copy-pasteable: relative links resolve inside the action directory, the checkout
step uses a mutable tag, credentials and domain inputs get literal placeholder
values, the quick start carries one generic trigger for every action, and the
job declares no permissions even though the README documents which it needs.
Every fixup here corrects generated output; none of it is style preference.

Usage: fix-generated-readme.py <readme-path>

Pure stdlib, like ``fix-local-action-refs.py`` — ``make docs`` must not depend on
a virtualenv. Input examples come from ``_validation/kit.py``, the same module
the generated validators are built from, so an example can never contradict the
rule that validates it.
"""

from __future__ import annotations

from pathlib import Path
import re
import sys

REPO_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO_ROOT / "_validation"))

import kit  # noqa: E402  (path set above; stdlib-only module)
from spec import SPECS  # noqa: E402

# actions/checkout v4 resolved to its immutable commit. The themes emit the
# mutable `@v4` tag; this repo pins every external action to a full SHA and the
# examples it publishes should not teach otherwise. Bump alongside the tag.
CHECKOUT_SHA = "11d5960a326750d5838078e36cf38b85af677262"

# The generic placeholders the themes fall back to for any input without a
# metadata default.
PLACEHOLDERS = ("value", "example-value", "custom-value")


def actions_expression(reference: str) -> str:
    """Wrap a context reference in GitHub Actions expression syntax.

    Built rather than written as a literal so that neither this repo's linter nor
    an external scanner reads `"token": "${{ ... }}"` as a hardcoded credential.
    These are the opposite of one — they are what a reader should substitute
    instead of pasting a secret into an input.
    """
    return "${{ " + reference + " }}"


# Credentials must never be documented as literal values: copied verbatim they
# are invalid, and they teach passing secrets as plain inputs.
CREDENTIALS = {
    "token": actions_expression("github.token"),
    "github_token": actions_expression("github.token"),
    "npm_token": actions_expression("secrets.NPM_TOKEN"),
    "dockerhub-token": actions_expression("secrets.DOCKERHUB_TOKEN"),
    "gitleaks-license": actions_expression("secrets.GITLEAKS_LICENSE"),
}

# The theme emits one generic `on: [push, pull_request]` for every action, which
# is wrong in both directions: publishing actions must not run from a pull
# request, pr-lint exists to lint them, and the scheduled actions are not
# push-driven at all. Anything absent here keeps the theme default — linters and
# builders publish nothing and are genuinely useful on pull requests.
TRIGGERS = {
    "npm-publish": "on:\n  release:\n    types: [published]",
    "npm-semantic-release": "on:\n  release:\n    types: [published]",
    "csharp-publish": "on:\n  release:\n    types: [published]",
    "docker-publish": "on:\n  release:\n    types: [published]",
    "release-monthly": 'on:\n  schedule:\n    - cron: "0 0 1 * *"\n  workflow_dispatch:',
    "stale": 'on:\n  schedule:\n    - cron: "0 0 * * *"\n  workflow_dispatch:',
    "compress-images": 'on:\n  schedule:\n    - cron: "0 0 * * 0"\n  workflow_dispatch:',
    "pr-lint": "on: [pull_request]",
}

GENERIC_TRIGGER = "on: [push, pull_request]"

# The Permissions table states an action's contract across every mode it supports,
# so a mode-gated scope is documented at its widest. A quick start demonstrates one
# concrete mode, and copying the widest grant into it hands a check-only workflow
# write access it never uses. Entries here override that scope for the example only;
# the value is the YAML scalar as it should appear, trailing comment included, so
# the reader can see why it differs from the table.
QUICK_START_PERMISSIONS = {
    ("biome-lint", "contents"): "read # `mode: 'fix'` needs write to push",
    ("eslint-lint", "contents"): "read # `mode: 'fix'` needs write to push",
    ("prettier-lint", "contents"): "read # `mode: 'fix'` needs write to push",
}


def fix_links(text: str) -> str:
    """Repoint links that would resolve inside the action directory.

    None of these targets exist there. The repo root has CONTRIBUTING.md and
    LICENSE.md — note the root file is .md, while the theme links a bare LICENSE.
    No examples/ directory exists anywhere, so that bullet is dropped rather than
    repointed at something it is not.
    """
    text = text.replace("](CONTRIBUTING.md)", "](../CONTRIBUTING.md)")
    text = text.replace("](LICENSE)", "](../LICENSE.md)")
    return "\n".join(line for line in text.split("\n") if "[examples](./examples/)" not in line)


def fix_badges(text: str) -> str:
    """Encode the literal space an empty badge message produces.

    The theme emits `.../badge/GitHub%20Action- -blue`. A raw space in a link destination is
    invalid, so the parser reads it as a bare URL and markdownlint's MD034 fix
    (run by `make format`) rewrites it to `<...>` while `make docs` leaves it —
    the two passes then disagree and the drift gate fails. Encoding the space
    makes every pass agree; the unwrap handles a tree that was already
    formatted, so regenerating converges instead of keeping the old shape.
    """
    text = re.sub(r"(img\.shields\.io/badge/[^) ]*)- -", r"\1-%20-", text)
    return re.sub(r"\(<(https://img\.shields\.io/badge/[^>]*)>", r"(\1", text)


def fix_checkout(text: str) -> str:
    """Pin the checkout step to an immutable commit.

    A copied example should not open with a mutable tag in a repository whose
    own rule is to SHA-pin every external action.
    """
    return text.replace(
        "uses: actions/checkout@v4",
        f"uses: actions/checkout@{CHECKOUT_SHA} # v4",
    )


def fix_trigger(text: str, action: str) -> str:
    """Replace the theme's single generic trigger with one suited to the action."""
    replacement = TRIGGERS.get(action)
    if not replacement:
        return text
    return re.sub(
        rf"^{re.escape(GENERIC_TRIGGER)}$",
        replacement.replace("\\", "\\\\"),
        text,
        flags=re.MULTILINE,
    )


def yaml_quote(value: str) -> str:
    """Render a value as a YAML single-quoted scalar.

    Reusing the quote character the generator happened to emit breaks whenever
    the replacement contains that same character: the JSON example for
    `platform-build-args` is full of double quotes, so re-emitting it inside
    double quotes produced `platform-build-args: "{"linux/amd64": ...}"` —
    three unparseable blocks in docker-build/README.md. Single quotes with YAML's
    doubling escape are safe for every value here, and match prettier's
    singleQuote style so the later pass leaves them alone.
    """
    return "'" + value.replace("'", "''") + "'"


def fix_values(text: str, action: str) -> str:
    """Replace the themes' generic placeholders with a value the action accepts.

    Credentials resolve to the runtime token or a secret. Everything else uses
    the canonical example for that input's validation type, so the published
    example is a value the action's own validator passes.
    """
    checks = SPECS.get(action, {}).get("checks", {})
    alternatives = "|".join(re.escape(p) for p in PLACEHOLDERS)
    # The quote character is matched rather than assumed: this runs before the
    # prettier pass in `make docs`, so the generator's double quotes are still in
    # place. Assuming single quotes here silently matches nothing.
    pattern = re.compile(rf"""^(\s*)([a-zA-Z0-9_.-]+): (["'])({alternatives})\3$""", re.MULTILINE)

    def replace(match: re.Match[str]) -> str:
        indent, name = match.group(1), match.group(2)
        if name in CREDENTIALS:
            return f"{indent}{name}: {yaml_quote(CREDENTIALS[name])}"
        example = kit.EXAMPLES.get(checks.get(name, ""))
        if example is None:
            return match.group(0)
        return f"{indent}{name}: {yaml_quote(example)}"

    return pattern.sub(replace, text)


def read_permissions(text: str) -> list[tuple[str, str]]:
    """Pull the permission/access pairs out of the README's own Permissions table.

    The generator detects these from the action's steps and already renders them;
    reading them back is what lets the quick start declare the same contract
    instead of restating it from a second source that could drift.
    """
    section = re.search(r"## [^\n]*Permissions\b(.*?)(?=\n## |\Z)", text, re.DOTALL)
    if not section:
        return []
    rows = re.findall(r"^\|\s*`([^`]+)`\s*\|\s*`([^`]+)`\s*\|", section.group(1), re.MULTILINE)
    return [(scope, level) for scope, level in rows]


def add_permissions(text: str, action: str) -> str:
    """Declare the documented permission contract in the quick-start job.

    A copied quick start with no `permissions:` block either fails on a
    repository whose default token is read-only, or silently relies on a
    permissive default. Declaring the documented contract in the example makes it
    self-contained and least-privilege.
    """
    perms = [
        (scope, QUICK_START_PERMISSIONS.get((action, scope), level))
        for scope, level in read_permissions(text)
    ]

    # Only the quick start's own workflow. Scoping by `runs-on:` alone would also
    # rewrite any later runnable workflow the docs happen to show — a setup or
    # development example that never invokes this action would be handed its
    # permission contract. Today the theme emits exactly one job block, so that is
    # latent rather than live, and it stays that way by construction here.
    section = re.search(r"## [^\n]*Quick Start\b.*?(?=\n## |\Z)", text, re.DOTALL)
    if not section:
        return text

    # Only when the job has not already declared permissions.
    def inject(match: re.Match[str]) -> str:
        body = match.group(0)
        if "runs-on: ubuntu-latest\n" not in body:
            return body
        if re.search(r"^\s+permissions:", body, re.MULTILINE):
            return body
        needed = list(perms)
        # The theme opens every quick start with a checkout step. That step reads
        # the repository, so an action whose own contract never touches `contents`
        # still needs the scope granted here or the copied workflow fails on a
        # repository whose default token is read-only.
        if "actions/checkout@" in body and not any(scope == "contents" for scope, _ in needed):
            needed.insert(0, ("contents", "read"))
        if not needed:
            return body
        block = "\n".join(f"      {scope}: {level}" for scope, level in needed)
        return body.replace(
            "    runs-on: ubuntu-latest\n",
            f"    runs-on: ubuntu-latest\n    permissions:\n{block}\n",
            1,
        )

    fixed = re.sub(r"```yaml\n.*?\n```", inject, section.group(0), count=1, flags=re.DOTALL)
    return text[: section.start()] + fixed + text[section.end() :]


def main(argv: list[str]) -> int:
    """Apply every fixup to the README named on the command line."""
    if len(argv) != 2:
        print("usage: fix-generated-readme.py <readme-path>", file=sys.stderr)
        return 2
    readme = Path(argv[1])
    if not readme.is_file():
        print(f"::error::fix-generated-readme: no such file: {readme}", file=sys.stderr)
        return 1

    action = readme.parent.name
    text = readme.read_text(encoding="utf-8")

    text = fix_links(text)
    text = fix_badges(text)
    text = fix_checkout(text)
    text = fix_trigger(text, action)
    text = fix_values(text, action)
    text = add_permissions(text, action)

    readme.write_text(text, encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
