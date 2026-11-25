#!/usr/bin/env python3
"""Generate a self-contained ``validate.py`` for every action from ``kit`` + ``spec.py``.

This is the codegen behind ``make update-validators``. For each action in ``spec.py`` it:

*   selects the kit checks that action's inputs use,
*   inlines the *exact source* of those checks (and only the preamble helpers they
    reference) via :func:`inspect.getsource`, and
*   writes ``<action>/validate.py`` — a pure-stdlib, dependency-free validator that the
    action runs with ``python3 validate.py``.

Because every pattern is defined once in the ``kit`` package and copied verbatim, the per-action
validators stay self-contained *and* never drift: ``--check`` regenerates in memory and
fails if any committed file differs, or if a top-level ``validate.py`` is not one the spec
generates (used by CI and ``tests/test_generate.py``).

Usage::

    python3 _validation/generate.py            # write every validate.py
    python3 _validation/generate.py --check     # verify every validate.py is generated and current
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

# Preamble helpers: the private functions each kit module defines, module by module in
# kit.MODULES order and in source order within a module. Each is emitted only when a selected
# check (or an included helper) calls it, so a boolean-only validator stays tiny. Taken from the
# kit itself, a helper a new check calls cannot be left out of the validators. A helper a module
# imports from common is common's, so it is taken once.
_HELPER_SOURCES = {
    helper.__name__: inspect.getsource(helper).strip()
    for module in kit.MODULES
    for helper in sorted(
        (
            obj
            for name, obj in vars(module).items()
            if name.startswith("_")
            and not name.startswith("__")
            and inspect.isfunction(obj)
            and obj.__module__ == module.__name__
        ),
        key=lambda function: function.__code__.co_firstlineno,
    )
}
_HELPERS = tuple(_HELPER_SOURCES)

_HEADER = '''\
"""GENERATED — DO NOT EDIT. Input validation for the {action} action.

Produced by _validation/generate.py from the _validation/kit package + _validation/spec.py.
Run `make update-validators` to regenerate. Pure stdlib, no third-party deps — the action
runs it with `python3 validate.py`.

Each check returns None when the value is acceptable or a short reason otherwise. Empty
values pass (inputs are optional unless listed in REQUIRED), except where a check says it
refuses them. The runner has already expanded every expression in INPUT_*, so all other values
are checked as literal data. Inputs named in MASKED_INPUTS are masked in the job's logs before
any check runs.
"""

from __future__ import annotations

import os
import re
import sys
'''

_RUNNER = '''\
def _variable(name: str) -> str:
    """Return the name of the INPUT_* env var that carries an input."""
    return "INPUT_" + name.upper().replace("-", "_")


def _input(name: str) -> str:
    """Return an input's raw value from its INPUT_* env var."""
    return os.environ.get(_variable(name), "")


def _mask_secrets() -> None:
    """Register every line of each secret input with the runner's log masker."""
    # The runner decodes %25 in command data, so a literal % has to be encoded to register the
    # real value.
    for input_name in MASKED_INPUTS:
        for line in _input(input_name).splitlines():
            if line.strip():
                sys.stdout.write("::add-mask::" + line.strip().replace("%", "%25") + "\\n")


def _input_error(input_name: str) -> str | None:
    """Return why an input's value is refused, or None when it passes."""
    value = _input(input_name)
    if input_name in REQUIRED and _skip(value):
        return "required input is missing"
    # The runner applies a default only when the caller leaves the input out, and `||` in an
    # expression takes any non-empty string as set, so `${{ inputs.x || default }}` and
    # with: would pass a value of only whitespace on as it is. Empty means unset.
    if value and _skip(value):
        return "@WHITESPACE_ONLY_REASON@"
    # action.yml forwards every input, so only a standalone run leaves a variable unset.
    if _variable(input_name) not in os.environ:
        return None
    return CHECKS[input_name](value)


def main() -> None:
    """Mask secret inputs, then validate every declared input; fail with all reasons."""
    # Masks come first so nothing printed below can reveal a secret.
    _mask_secrets()
    errors = [
        f"{input_name}: {reason}"
        for input_name in CHECKS
        if (reason := _input_error(input_name)) is not None
    ]
    if errors:
        for error in errors:
            # Encode as workflow-command data: a rejected value must not start a new command.
            data = error.replace("%", "%25").replace("\\r", "%0D").replace("\\n", "%0A")
            sys.stdout.write(f"::error::{ACTION}: {data}\\n")
        sys.exit(1)
'''

_ENTRY = """\
if __name__ == "__main__":
    main()
"""

# Answers by exit status alone: a rejected file value is not an error, the calling step
# moves on to its next version source.
_DETECTED_VERSION_ENTRY = """\
if __name__ == "__main__":
    if sys.argv[1:2] == ["--detected-version"]:
        sys.exit(0 if len(sys.argv) > 2 and {rule}(sys.argv[2]) else 1)
    main()
"""


def _check_name(check_type: str) -> str:
    return f"check_{check_type}"


def _needed_helpers(sources: list[str]) -> list[str]:
    """Return the preamble helpers transitively referenced by the given source blocks.

    A helper is included when a check calls it, or when an included helper does; the set grows
    until no helper adds another. Every definition runs before any check is called, so the
    order the helpers are emitted in does not matter for correctness.
    """
    texts = list(sources)
    needed: set[str] = set()
    while added := {
        name
        for name in _HELPERS
        if name not in needed and any(f"{name}(" in text for text in texts)
    }:
        needed |= added
        texts.extend(_HELPER_SOURCES[name] for name in added)
    return [name for name in _HELPERS if name in needed]


def _tables(action: str) -> list[str]:
    """Return the ACTION and CHECKS, REQUIRED and MASKED_INPUTS blocks of an action's validator."""
    spec = SPECS[action]
    checks = sorted(spec["checks"].items())
    check_lines = "\n".join(f'    "{name}": {_check_name(check)},' for name, check in checks)
    required = ", ".join(f'"{name}"' for name in sorted(spec["required"]))
    masked = ", ".join(f'"{name}"' for name, check in checks if check in kit.MASKED_CHECKS)
    return [
        f'ACTION = "{action}"\n\nCHECKS = {{\n{check_lines}\n}}',
        f"REQUIRED = {{{required}}}" if required else "REQUIRED: set[str] = set()",
        f"MASKED_INPUTS: list[str] = [{masked}]",
    ]


def render(action: str) -> str:
    """Return the full source text of ``<action>/validate.py``."""
    spec = SPECS[action]
    detected_rule = spec.get("detected_version")
    used_types = sorted(set(spec["checks"].values()))
    check_sources = [inspect.getsource(kit.CHECKS[check]).strip() for check in used_types]
    # The detected-version rule comes after the checks, and the helper scan reads it too.
    if detected_rule:
        check_sources.append(inspect.getsource(getattr(kit.versions, detected_rule)).strip())
    # The runner tests a required input with _skip, so blank means the same there as in a check.
    helper_names = _needed_helpers([*check_sources, _RUNNER])
    blocks = [
        _HEADER.format(action=action).rstrip(),
        *(_HELPER_SOURCES[name] for name in helper_names),
        *check_sources,
        *_tables(action),
    ]
    # The reason text lives in the kit, which validation_core.py also reads.
    reason = kit.common.WHITESPACE_ONLY_REASON
    blocks.append(_RUNNER.replace("@WHITESPACE_ONLY_REASON@", reason).rstrip())
    entry = _DETECTED_VERSION_ENTRY.format(rule=detected_rule) if detected_rule else _ENTRY
    blocks.append(entry.rstrip())
    return "\n\n\n".join(blocks) + "\n"


def target(action: str) -> Path:
    """Return the path of the generated validator for ``action``."""
    return ROOT / action / "validate.py"


def stray_validators() -> list[str]:
    """Return each top-level ``validate.py``, in any case, that the spec does not generate.

    CodeRabbit skips every such file as generated (``.coderabbit.yaml``), so one the spec does not
    produce would go unreviewed; ``--check`` fails on it as it fails on a stale one.
    """
    return sorted(
        f"{entry.parent.name}/{entry.name}"
        for entry in ROOT.glob("*/*")
        if entry.name.lower() == "validate.py"
        and (entry.name != "validate.py" or entry.parent.name not in SPECS)
    )


def _current(action: str) -> bool:
    """Return whether the committed validator for ``action`` is the one the spec generates."""
    path = target(action)
    return path.exists() and path.read_text(encoding="utf-8") == render(action)


def _check(actions: list[str], *, strays: bool) -> int:
    """Name each stale validator, and with ``strays`` each stray one; return 1 if there is any."""
    stray = stray_validators() if strays else []
    if stray:
        sys.stderr.write(
            "::error::not generated from _validation/spec.py: "
            + ", ".join(stray)
            + " — add the action to the spec, or remove the file\n",
        )
    drifted = [action for action in actions if not _current(action)]
    if drifted:
        sys.stderr.write(
            "::error::validate.py out of date for: "
            + ", ".join(drifted)
            + " — run `make update-validators`\n",
        )
    if stray or drifted:
        return 1
    sys.stdout.write(f"validators up to date ({len(actions)} actions)\n")
    return 0


def _write(actions: list[str]) -> int:
    """Write the validator of each action."""
    for action in actions:
        target(action).write_text(render(action), encoding="utf-8")
    sys.stdout.write(f"generated {len(actions)} validators\n")
    return 0


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
    # A single action's run checks only that action, so it cannot name a stray file.
    return _check(actions, strays=not args.action) if args.check else _write(actions)


if __name__ == "__main__":
    raise SystemExit(main())
