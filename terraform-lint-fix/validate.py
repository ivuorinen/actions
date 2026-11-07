"""GENERATED — DO NOT EDIT. Input validation for the terraform-lint-fix action.

Produced by _validation/generate.py from _validation/kit.py + _validation/spec.py.
Run `make update-validators` to regenerate. Pure stdlib, no third-party deps — the action
runs it with `python3 validate.py`.

Each check returns None when the value is acceptable or a short reason otherwise. Empty
values pass (inputs are optional unless listed in REQUIRED). The runner has already expanded
every expression in INPUT_*, so all other values are checked as literal data.
"""

from __future__ import annotations

import os
import re
import sys


def _skip(value: str) -> bool:
    """Empty values bypass format checks (see the module contract)."""
    return value.strip() == ""


def _enum(value: str, *allowed: str) -> str | None:
    """Accept ``value`` iff it is exactly one of ``allowed`` (case-sensitive)."""
    if _skip(value) or value in allowed:
        return None
    return "must be one of: " + ", ".join(allowed)


def _int_in_range(value: str, low: int, high: int) -> str | None:
    """Accept ``value`` iff it is an integer within ``[low, high]``."""
    if _skip(value):
        return None
    if re.fullmatch(r"[0-9]{1,18}", value) and low <= int(value) <= high:
        return None
    return f"must be an integer between {low} and {high}"


def check_boolean(value: str) -> str | None:
    """Boolean flag — ``true`` or ``false`` (any case)."""
    if _skip(value) or value.lower() in ("true", "false"):
        return None
    return 'must be "true" or "false"'


def check_email(value: str) -> str | None:
    """Email address."""
    if _skip(value):
        return None
    if re.fullmatch(r"[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}", value):
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
    if re.fullmatch(r"[a-zA-Z0-9._/\-@+~!#=:]+", value):
        return None
    return "contains invalid path characters"


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


def check_numeric_range_1_10(value: str) -> str | None:
    """Integer in [1, 10] (e.g. retry counts)."""
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
    if _skip(value) or value.lower() == "latest":
        return None
    if re.fullmatch(r"v?\d+\.\d+\.\d+(-[0-9A-Za-z.-]+)?", value):
        return None
    return 'must be a version like 1.5.7 or "latest"'


def check_username(value: str) -> str | None:
    """Username/handle — alphanumeric with internal ``-``/``_``, at most 39 characters."""
    if _skip(value):
        return None
    if len(value) > 39:
        return "must be at most 39 characters"
    if re.fullmatch(r"[a-zA-Z0-9](?:[a-zA-Z0-9_-]*[a-zA-Z0-9])?", value):
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
        value = os.environ.get("INPUT_" + input_name.upper().replace("-", "_"), "")
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
