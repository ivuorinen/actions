"""GENERATED — DO NOT EDIT. Input validation for the stale action.

Produced by _validation/generate.py from _validation/kit.py + _validation/spec.py.
Run `make update-validators` to regenerate. Pure stdlib, no third-party deps — the action
runs it with `python3 validate.py`.

Each check returns None when the value is acceptable or a short reason otherwise. Empty
values pass (inputs are optional unless listed in REQUIRED). The runner has already expanded
every expression in INPUT_*, so all other values are checked as literal data. Inputs listed in
SECRETS are masked in the job's logs before any check runs.
"""

from __future__ import annotations

import os
import re
import sys


def _skip(value: str) -> bool:
    """Empty values bypass format checks (see the module contract)."""
    return value.strip() == ""


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


def check_positive_integer(value: str) -> str | None:
    """Positive integer (> 0)."""
    if _skip(value):
        return None
    if re.fullmatch(r"[0-9]{1,18}", value) and int(value) > 0:
        return None
    return "must be a positive integer (> 0)"


ACTION = "stale"

CHECKS = {
    "days-before-close": check_positive_integer,
    "days-before-stale": check_positive_integer,
    "token": check_github_token,
}


REQUIRED: set[str] = set()


SECRETS: list[str] = ["token"]


def _input(name: str) -> str:
    """Return an input's raw value from its INPUT_* env var."""
    return os.environ.get("INPUT_" + name.upper().replace("-", "_"), "")


def main() -> None:
    """Mask secret inputs, then validate every declared input; fail with all reasons."""
    # Masks come first so nothing printed below can reveal a secret. The runner decodes %25
    # in command data, so a literal % has to be encoded to register the real value.
    for input_name in SECRETS:
        for line in _input(input_name).splitlines():
            if line.strip():
                sys.stdout.write("::add-mask::" + line.strip().replace("%", "%25") + "\n")
    errors = []
    for input_name, check in CHECKS.items():
        value = _input(input_name)
        if input_name in REQUIRED and value.strip() == "":
            errors.append(f"{input_name}: required input is missing")
            continue
        reason = check(value)
        if reason is not None:
            errors.append(f"{input_name}: {reason}")
    if errors:
        for error in errors:
            # Encode as workflow-command data: a rejected value must not start a new command.
            data = error.replace("%", "%25").replace("\r", "%0D").replace("\n", "%0A")
            sys.stdout.write(f"::error::{ACTION}: {data}\n")
        sys.exit(1)


if __name__ == "__main__":
    main()
