"""GENERATED — DO NOT EDIT. Input validation for the terraform-lint-fix action.

Produced by _validation/generate.py from _validation/kit.py + _validation/spec.py.
Run `make update-validators` to regenerate. Pure stdlib, no third-party deps — the action
runs it with `python3 validate.py`.

Each check returns None when the value is acceptable or a short reason otherwise. Empty
values pass (inputs are optional unless listed in REQUIRED), except where a check says it
refuses them, and `${{ ... }}` expressions pass unchecked (their value is substituted at
runtime).
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


def _enum(value: str, *allowed: str) -> str | None:
    """Accept ``value`` iff it is exactly one of ``allowed`` (case-sensitive)."""
    if _skip(value) or value in allowed:
        return None
    return "must be one of: " + ", ".join(allowed)


def _int_in_range(value: str, low: int, high: int) -> str | None:
    """Accept ``value`` iff it is plain digits within ``[low, high]``.

    ``int()`` alone is too lenient: it takes ``1_0`` and non-ASCII digits, on which a shell
    integer test errors, and inside a ``while`` condition that error just ends the loop.
    """
    if _skip(value):
        return None
    if re.fullmatch(r"[0-9]{1,9}", value) and low <= int(value) <= high:
        return None
    return f"must be an integer between {low} and {high}"


def check_boolean(value: str) -> str | None:
    """Boolean flag — exactly ``true`` or ``false``.

    Shell steps test ``[ "$FLAG" = "true" ]``, which is case-sensitive, while ``if:`` expressions
    are not, so ``True`` or a blank would have the two halves of an action disagree. A blank is
    refused for the reason in the module contract.
    """
    if _is_expr(value) or value in ("true", "false"):
        return None
    return 'must be "true" or "false" (lowercase)'


def check_email(value: str) -> str | None:
    """Email address."""
    if _skip(value):
        return None
    if re.match(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$", value):
        return None
    return "must be a valid email address (e.g. user@example.com)"


def check_file_path(value: str) -> str | None:
    """Relative file path — rejects absolute paths, ``..`` traversal and ``~`` expansion."""
    if _skip(value):
        return None
    import urllib.parse

    decoded = urllib.parse.unquote(value)
    if decoded.startswith("/") or (len(decoded) > 1 and decoded[1] == ":"):
        return "absolute paths are not allowed"
    if ".." in decoded:
        return "path traversal (..) is not allowed"
    if value.startswith("~"):
        return "home directory expansion (~) is not allowed"
    if re.match(r"^[a-zA-Z0-9._/\-@+~!#=:]+$", value):
        return None
    return "contains invalid path characters"


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


def check_numeric_range_1_10(value: str) -> str | None:
    """Integer in [1, 10] (retry counts); blank is refused, see the module contract."""
    if value.strip() == "":
        return "must be an integer between 1 and 10"
    return _int_in_range(value, 1, 10)


def check_report_format(value: str) -> str | None:
    """Lint/report output format."""
    return _enum(
        value,
        "checkstyle",
        "colored-line-number",
        "compact",
        "github-actions",
        "html",
        "json",
        "junit",
        "junit-xml",
        "line-number",
        "sarif",
        "stylish",
        "tab",
        "teamcity",
        "xml",
    )


def check_terraform_version(value: str) -> str | None:
    """Terraform/tflint version: ``X.Y.Z`` with optional ``-prerelease``, or ``latest``."""
    if _skip(value) or value.strip().lower() == "latest":
        return None
    if re.match(r"^v?\d+\.\d+\.\d+(-[0-9A-Za-z.-]+)?$", value.strip()):
        return None
    return 'must be a version like 1.5.7 or "latest"'


def check_username(value: str) -> str | None:
    """Username/handle — alphanumeric with internal ``-``/``_``, at most 39 characters."""
    if _skip(value):
        return None
    if len(value) > 39:
        return "must be at most 39 characters"
    if re.match(r"^[a-zA-Z0-9](?:[a-zA-Z0-9_-]*[a-zA-Z0-9])?$", value):
        return None
    return "may only contain letters, digits, and internal - or _"


ACTION = "terraform-lint-fix"

CHECKS = {
    "auto-fix": check_boolean,
    "config-file": check_file_path,
    "email": check_email,
    "fail-on-error": check_boolean,
    "format": check_report_format,
    "max-retries": check_numeric_range_1_10,
    "terraform-version": check_terraform_version,
    "tflint-version": check_terraform_version,
    "token": check_github_token,
    "username": check_username,
    "working-directory": check_file_path,
}


REQUIRED: set[str] = set()


def main() -> None:
    """Validate every declared input from its INPUT_* env var; fail with all reasons."""
    errors = []
    for input_name, check in CHECKS.items():
        variable = "INPUT_" + input_name.upper().replace("-", "_")
        value = os.environ.get(variable, "")
        if input_name in REQUIRED and value.strip() == "":
            errors.append(f"{input_name}: required input is missing")
            continue
        # action.yml forwards every input, so only a standalone run leaves a variable unset.
        reason = check(value) if variable in os.environ else None
        if reason is not None:
            errors.append(f"{input_name}: {reason}")
    if errors:
        for error in errors:
            sys.stdout.write(f"::error::{ACTION}: {error}\n")
        sys.exit(1)


if __name__ == "__main__":
    main()
