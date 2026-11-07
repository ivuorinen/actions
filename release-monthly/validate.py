"""GENERATED — DO NOT EDIT. Input validation for the release-monthly action.

Produced by _validation/generate.py from _validation/kit.py + _validation/spec.py.
Run `make update-validators` to regenerate. Pure stdlib, no third-party deps — the action
runs it with `python3 validate.py`.

Each check returns None when the value is acceptable or a short reason otherwise. Empty
values pass (inputs are optional unless listed in REQUIRED) and `${{ ... }}` expressions
pass unchecked (their value is substituted at runtime). Inputs named in MASKED_INPUTS are
masked in the job's logs before any check runs.
"""

from __future__ import annotations

import os
import re
import sys


def _is_expr(value: str) -> bool:
    """Return ``True`` if ``value`` is a GitHub Actions ``${{ ... }}`` expression.

    The whole value must start with ``${{``; after removing every ``${{...}}`` span, any
    leftover ``..`` re-fails the check so an expression can never smuggle path traversal
    (e.g. ``${{ env.X }}/../etc`` is *not* treated as a safe expression).
    """
    if not value.startswith("${{"):
        return False
    return ".." not in re.sub(r"\$\{\{[^}]*\}\}", "", value)


def _skip(value: str) -> bool:
    """Empty or expression values bypass format checks (see the module contract)."""
    return value.strip() == "" or _is_expr(value)


def _is_env_ref(value: str) -> bool:
    """Return True if value is a plain shell env-var reference (``$NAME`` or ``${NAME}``).

    Deliberately strict: command substitution ``$(...)`` and brace expansion ``${ ... }``
    do NOT match, so a token field can accept ``$NPM_TOKEN`` without also accepting
    ``$(rm -rf /)``.
    """
    return re.fullmatch(r"\$([A-Za-z_][A-Za-z0-9_]*|\{[A-Za-z_][A-Za-z0-9_]*\})", value) is not None


def check_boolean(value: str) -> str | None:
    """Boolean flag — ``true`` or ``false`` (any case)."""
    if _skip(value) or value.strip().lower() in ("true", "false"):
        return None
    return 'must be "true" or "false"'


def check_github_token(value: str) -> str | None:
    """GitHub/registry token: a known token format, a ``${{ }}`` expression, or ``$VAR``.

    Accepts every GitHub token shape (classic, OAuth, user-to-server, installation,
    refresh, enterprise, and fine-grained PATs). Installation tokens cover both the
    legacy 40-char ``ghs_`` form and the stateless ``ghs_<app-id>_<JWT>`` form rolled
    out 2026-04-27: the JWT is base64url (so it may contain ``-`` and ``_``) joined by
    ``.`` and has no fixed length, so that pattern allows ``-`` and sets no upper bound
    (GitHub warns against relying on token length). Tokens are almost always passed as
    ``${{ secrets.* }}`` or ``$VAR`` references, both of which pass through unchecked.
    """
    if _skip(value) or _is_env_ref(value):
        return None
    patterns = (
        r"^ghp_[A-Za-z0-9]{36}$",  # classic personal access token
        r"^gho_[A-Za-z0-9]{36}$",  # OAuth token
        r"^ghu_[A-Za-z0-9]{36}$",  # user-to-server token
        r"^ghs_[A-Za-z0-9._-]{36,}$",  # installation token (stateful ghs_+36 or stateless JWT)
        r"^ghr_[A-Za-z0-9]{36}$",  # refresh token
        r"^ghe_[A-Za-z0-9]{36}$",  # enterprise token
        r"^github_pat_[A-Za-z0-9_]{50,255}$",  # fine-grained PAT
    )
    if any(re.match(pattern, value) for pattern in patterns):
        return None
    return (
        "must be a GitHub token (ghp_/gho_/ghu_/ghs_/ghr_/ghe_/github_pat_), "
        "a ${{ ... }} expression, or a $VAR env reference"
    )


def check_prefix(value: str) -> str | None:
    """Tag/release prefix — letters, digits and ``._-`` only."""
    if _skip(value):
        return None
    if any(char in value for char in (" ", "@", "#", ":")):
        return "must not contain spaces or @ # :"
    if re.match(r"^[a-zA-Z0-9._-]+$", value):
        return None
    return "may only contain letters, digits, and . _ -"


ACTION = "release-monthly"

CHECKS = {
    "dry-run": check_boolean,
    "prefix": check_prefix,
    "token": check_github_token,
}


REQUIRED = {"token"}


MASKED_INPUTS: list[str] = ["token"]


def _input(name: str) -> str:
    """Return an input's raw value from its INPUT_* env var."""
    return os.environ.get("INPUT_" + name.upper().replace("-", "_"), "")


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
        reason = check(value)
        if reason is not None:
            errors.append(f"{input_name}: {reason}")
    if errors:
        for error in errors:
            sys.stdout.write(f"::error::{ACTION}: {error}\n")
        sys.exit(1)


if __name__ == "__main__":
    main()
