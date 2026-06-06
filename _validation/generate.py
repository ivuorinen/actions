#!/usr/bin/env python3
"""Generate a self-contained ``validate.py`` for every action from ``kit.py`` + ``spec.py``.

This is the codegen behind ``make update-validators``. For each action in ``spec.py`` it:

  * selects the kit checks that action's inputs use,
  * inlines the *exact source* of those checks (and only the preamble helpers they
    reference) via :func:`inspect.getsource`, and
  * writes ``<action>/validate.py`` — a pure-stdlib, dependency-free validator that the
    action runs with ``python3 validate.py``.

Because every pattern is defined once in ``kit.py`` and copied verbatim, the per-action
validators stay self-contained *and* never drift: ``--check`` regenerates in memory and
fails if any committed file differs (used by CI and ``tests/test_generate.py``).

Usage::

    python3 _validation/generate.py            # write every validate.py
    python3 _validation/generate.py --check     # verify committed files are up to date
    python3 _validation/generate.py --action X  # (re)generate a single action
"""

from __future__ import annotations

import argparse
import inspect
from pathlib import Path
import sys

import kit
from spec import SPECS

ROOT = Path(__file__).resolve().parent.parent

# Preamble helpers in dependency order (a helper's dependencies precede it). Each is emitted
# only when a selected check (or an already-included helper) references it, so a boolean-only
# validator stays tiny. Sources are read once here and reused.
_HELPERS = (
    "_is_expr",
    "_skip",
    "_is_env_ref",
    "_is_semver",
    "_enum",
    "_enum_list",
    "_int_in_range",
    "_shell_meta_error",
)
_HELPER_SOURCES = {name: inspect.getsource(getattr(kit, name)).strip() for name in _HELPERS}

_HEADER = '''\
"""GENERATED — DO NOT EDIT. Input validation for the {action} action.

Produced by _validation/generate.py from _validation/kit.py + _validation/spec.py.
Run `make update-validators` to regenerate. Pure stdlib, no third-party deps — the action
runs it with `python3 validate.py`.

Each check returns None when the value is acceptable or a short reason otherwise. Empty
values pass (inputs are optional unless listed in REQUIRED) and `${{{{ ... }}}}` expressions
pass unchecked (their value is substituted at runtime).
"""

from __future__ import annotations

import os
import re
import sys
'''

_RUNNER = '''\
def main() -> None:
    """Validate every declared input from its INPUT_* env var; fail with all reasons."""
    errors = []
    for input_name, check in CHECKS.items():
        value = os.environ.get("INPUT_" + input_name.upper().replace("-", "_"), "")
        if input_name in REQUIRED and value.strip() == "":
            errors.append(f"{input_name}: required input is missing")
            continue
        reason = check(value)
        if reason is not None:
            errors.append(f"{input_name}: {reason}")
    if errors:
        for error in errors:
            sys.stdout.write(f"::error::{ACTION}: {error}\\n")
        sys.exit(1)


if __name__ == "__main__":
    main()
'''


def _check_name(check_type: str) -> str:
    return f"check_{check_type}"


def _needed_helpers(sources: list[str]) -> list[str]:
    """Return the preamble helpers transitively referenced by the given source blocks.

    ``_HELPERS`` is in dependency order, so one reverse pass settles the set: a helper is
    included when a check references it directly, or when an already-included helper (a
    dependent, seen earlier in reverse) references it.
    """
    blob = "\n".join(sources)
    needed: set[str] = set()
    for name in reversed(_HELPERS):
        if f"{name}(" in blob or any(f"{name}(" in _HELPER_SOURCES[other] for other in needed):
            needed.add(name)
    return [name for name in _HELPERS if name in needed]


def render(action: str) -> str:
    """Return the full source text of ``<action>/validate.py``."""
    spec = SPECS[action]
    checks = spec["checks"]
    required = spec["required"]

    used_types = sorted(set(checks.values()))
    check_sources = [inspect.getsource(getattr(kit, _check_name(t))).strip() for t in used_types]
    helper_names = _needed_helpers(check_sources)
    helper_sources = [_HELPER_SOURCES[name] for name in helper_names]

    blocks: list[str] = [_HEADER.format(action=action).rstrip()]
    blocks.extend(helper_sources)
    blocks.extend(check_sources)

    check_lines = "\n".join(
        f'    "{name}": {_check_name(check_type)},' for name, check_type in sorted(checks.items())
    )
    blocks.append(f'ACTION = "{action}"\n\nCHECKS = {{\n{check_lines}\n}}')

    if required:
        required_lines = ", ".join(f'"{name}"' for name in sorted(required))
        blocks.append(f"REQUIRED = {{{required_lines}}}")
    else:
        blocks.append("REQUIRED: set[str] = set()")

    blocks.append(_RUNNER.rstrip())
    return "\n\n\n".join(blocks) + "\n"


def target(action: str) -> Path:
    """Return the path of the generated validator for ``action``."""
    return ROOT / action / "validate.py"


def main() -> int:
    """Generate every validator, or with ``--check`` verify the committed files are current."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="verify committed files are current")
    parser.add_argument("--action", help="generate only this action")
    args = parser.parse_args()

    actions = [args.action] if args.action else sorted(SPECS)
    unknown = [a for a in actions if a not in SPECS]
    if unknown:
        sys.stderr.write(f"::error::unknown action(s): {', '.join(unknown)}\n")
        return 1

    drifted: list[str] = []
    for action in actions:
        content = render(action)
        path = target(action)
        if args.check:
            current = path.read_text(encoding="utf-8") if path.exists() else None
            if current != content:
                drifted.append(action)
        else:
            path.write_text(content, encoding="utf-8")

    if args.check:
        if drifted:
            sys.stderr.write(
                "::error::validate.py out of date for: "
                + ", ".join(drifted)
                + " — run `make update-validators`\n",
            )
            return 1
        sys.stdout.write(f"validators up to date ({len(actions)} actions)\n")
    else:
        sys.stdout.write(f"generated {len(actions)} validators\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
