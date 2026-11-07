"""GENERATED — DO NOT EDIT. Input validation for the npm-publish action.

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


def check_scope(value: str) -> str | None:
    """Npm scope — ``@`` followed by a lowercase name (e.g. ``@my-org``)."""
    if _skip(value):
        return None
    if not value.startswith("@"):
        return 'must start with "@" (e.g. @my-org)'
    if re.fullmatch(r"[a-z][a-z0-9._~-]*", value[1:]):
        return None
    return "scope name must start with a lowercase letter (e.g. @my-org)"


def check_strict_semantic_version(value: str) -> str | None:
    """Strict SemVer: exactly ``X.Y.Z`` with optional ``-prerelease`` / ``+build`` (no partials)."""
    if _skip(value) or value.lower() == "latest":
        return None
    if re.fullmatch(r"\d+\.\d+\.\d+(-[0-9A-Za-z.-]+)?(\+[0-9A-Za-z.-]+)?", value):
        return None
    return "must be a strict semantic version X.Y.Z (optionally -prerelease / +build)"


def check_url(value: str) -> str | None:
    """HTTP(S) URL — rejects injection characters and non-http schemes."""
    if _skip(value):
        return None
    if not value.startswith(("http://", "https://")):
        return "must start with http:// or https://"
    if any(token in value for token in (";", "|", "`", "$(", "${", "../", "..\\")):
        return "must not contain injection characters"
    lowered = value.lower()
    if any(enc in lowered for enc in ("%0d", "%0a", "%00", "%2e%2e")):
        return "must not contain encoded control or traversal sequences"
    if re.fullmatch(
        r"https?://[a-zA-Z0-9.-]+(?:\.[a-zA-Z]{2,})?(?::\d{1,5})?(?:[/?#][^\s<>]*)?", value
    ):
        return None
    return "must be a valid http(s) URL"


ACTION = "npm-publish"

CHECKS = {
    "npm_token": check_github_token,
    "package-version": check_strict_semantic_version,
    "registry-url": check_url,
    "scope": check_scope,
    "token": check_github_token,
}


REQUIRED = {"npm_token"}


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
