"""GENERATED — DO NOT EDIT. Input validation for the language-version-detect action.

Produced by _validation/generate.py from _validation/kit.py + _validation/spec.py.
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


def _skip(value: str) -> bool:
    """Empty values bypass format checks (see the module contract)."""
    return value.strip() == ""


def _is_semver(core: str) -> bool:
    """Return True if core is a semantic version: X.Y.Z[-pre][+build], or partial X.Y / X."""
    full = (
        r"(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)"
        r"(?:-(?:0|[1-9][0-9]*|[0-9]*[A-Za-z-][0-9A-Za-z-]*)"
        r"(?:\.(?:0|[1-9][0-9]*|[0-9]*[A-Za-z-][0-9A-Za-z-]*))*)?"
        r"(?:\+[0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*)?"
    )
    return bool(
        re.fullmatch(full, core)
        or re.fullmatch(r"(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)", core)
        or re.fullmatch(r"(0|[1-9][0-9]*)", core)
    )


def _enum(value: str, *allowed: str) -> str | None:
    """Accept ``value`` iff it is exactly one of ``allowed`` (case-sensitive)."""
    if _skip(value) or value in allowed:
        return None
    return "must be one of: " + ", ".join(allowed)


def check_github_token(value: str) -> str | None:
    """GitHub/registry token in a known token format.

    Accepts every GitHub token shape (classic, OAuth, user-to-server, installation,
    refresh, enterprise, and fine-grained PATs). Installation tokens cover both the
    legacy 40-char ``ghs_`` form and the stateless ``ghs_<app-id>_<JWT>`` form rolled
    out 2026-04-27: the JWT is base64url (so it may contain ``-`` and ``_``) joined by
    ``.`` and has no fixed length, so that pattern allows ``-`` and sets no upper bound
    (GitHub warns against relying on token length).
    """
    if _skip(value):
        return None
    patterns = (
        r"ghp_[A-Za-z0-9]{36}",  # classic personal access token
        r"gho_[A-Za-z0-9]{36}",  # OAuth token
        r"ghu_[A-Za-z0-9]{36}",  # user-to-server token
        r"ghs_[A-Za-z0-9._-]{36,}",  # installation token (stateful ghs_+36 or stateless JWT)
        r"ghr_[A-Za-z0-9]{36}",  # refresh token
        r"ghe_[A-Za-z0-9]{36}",  # enterprise token
        r"github_pat_[A-Za-z0-9_]{50,255}",  # fine-grained PAT
    )
    if any(re.fullmatch(pattern, value) for pattern in patterns):
        return None
    return "must be a GitHub token (ghp_/gho_/ghu_/ghs_/ghr_/ghe_/github_pat_)"


def check_language_enum(value: str) -> str | None:
    """Language selector for version detection."""
    return _enum(value, "php", "python", "go", "dotnet")


def check_no_prefix_version(value: str) -> str | None:
    """SemVer-style version that must NOT carry a leading ``v`` (use ``1.2.3``, not ``v1.2.3``)."""
    if _skip(value):
        return None
    if value[:1] in ("v", "V"):
        return 'must not start with "v" (use 1.2.3, not v1.2.3)'
    if _is_semver(value):
        return None
    return "must be a semantic version without a v prefix (e.g. 1.2.3, 1.2, 1)"


def is_detected_version(value: str) -> bool:
    """Dotted version with an optional suffix: 8.4, 1.22.3, 1.25.x, 1.23rc1, 3.13-dev, 1.0.0+b."""
    pattern = r"[0-9]+\.[0-9][0-9A-Za-z]*(\.[0-9A-Za-z]+)*([-+][0-9A-Za-z.+-]+)?"
    return re.fullmatch(pattern, value) is not None


ACTION = "language-version-detect"

CHECKS = {
    "default-version": check_no_prefix_version,
    "language": check_language_enum,
    "token": check_github_token,
}


REQUIRED = {"language"}


MASKED_INPUTS: list[str] = ["token"]


def _variable(name: str) -> str:
    """Return the name of the INPUT_* env var that carries an input."""
    return "INPUT_" + name.upper().replace("-", "_")


def _input(name: str) -> str:
    """Return an input's raw value from its INPUT_* env var."""
    return os.environ.get(_variable(name), "")


def main() -> None:
    """Mask secret inputs, then validate every declared input; fail with all reasons."""
    # Masks come first so nothing printed below can reveal a secret. The runner decodes %25
    # in command data, so a literal % has to be encoded to register the real value.
    for input_name in MASKED_INPUTS:
        for line in _input(input_name).splitlines():
            if line.strip():
                sys.stdout.write("::add-mask::" + line.strip().replace("%", "%25") + "\n")
    errors = []
    for input_name, check in CHECKS.items():
        value = _input(input_name)
        if input_name in REQUIRED and value.strip() == "":
            errors.append(f"{input_name}: required input is missing")
            continue
        # action.yml forwards every input, so only a standalone run leaves a variable unset.
        reason = check(value) if _variable(input_name) in os.environ else None
        if reason is not None:
            errors.append(f"{input_name}: {reason}")
    if errors:
        for error in errors:
            # Encode as workflow-command data: a rejected value must not start a new command.
            data = error.replace("%", "%25").replace("\r", "%0D").replace("\n", "%0A")
            sys.stdout.write(f"::error::{ACTION}: {data}\n")
        sys.exit(1)


if __name__ == "__main__":
    if sys.argv[1:2] == ["--detected-version"]:
        sys.exit(0 if len(sys.argv) > 2 and is_detected_version(sys.argv[2]) else 1)
    main()
