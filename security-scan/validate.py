"""GENERATED — DO NOT EDIT. Input validation for the security-scan action.

Produced by _validation/generate.py from _validation/kit.py + _validation/spec.py.
Run `make update-validators` to regenerate. Pure stdlib, no third-party deps — the action
runs it with `python3 validate.py`.

Each check returns None when the value is acceptable or a short reason otherwise. Empty
values pass (inputs are optional unless listed in REQUIRED) and `${{ ... }}` expressions
pass unchecked (their value is substituted at runtime).
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


def _enum_list(value: str, allowed: tuple[str, ...], *, fold: bool = False) -> list[str]:
    """Return the comma-split items of value not in allowed (optionally case-folded)."""
    items = (part.strip() for part in value.split(","))
    if fold:
        items = (item.lower() for item in items)
    return [item for item in items if item and item not in allowed]


def check_boolean(value: str) -> str | None:
    """Boolean flag — ``true`` or ``false`` (any case)."""
    if _skip(value) or value.strip().lower() in ("true", "false"):
        return None
    return 'must be "true" or "false"'


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

    Accepts every GitHub token shape (classic, OAuth, user-to-server, installation —
    including the ~520-char stateless JWT form — refresh, enterprise, and fine-grained
    PATs). Tokens are almost always passed as ``${{ secrets.* }}`` or ``$VAR`` references,
    both of which pass through unchecked.
    """
    if _skip(value) or _is_env_ref(value):
        return None
    patterns = (
        r"^ghp_[A-Za-z0-9]{36}$",  # classic personal access token
        r"^gho_[A-Za-z0-9]{36}$",  # OAuth token
        r"^ghu_[A-Za-z0-9]{36}$",  # user-to-server token
        r"^ghs_[A-Za-z0-9._]{36,1024}$",  # installation token (stateful or stateless JWT)
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


def check_license_key(value: str) -> str | None:
    """Opaque license key — a ``${{ }}`` expression, a ``$VAR`` reference, or a single token."""
    if _skip(value) or _is_env_ref(value):
        return None
    if re.fullmatch(r"[A-Za-z0-9+/=._-]+", value):
        return None
    return (
        "must be an opaque key (letters, digits, + / = . _ -), "
        "a ${{ }} expression, or a $VAR reference"
    )


def check_scanner_list(value: str) -> str | None:
    """Comma-separated Trivy scanners."""
    if _skip(value):
        return None
    allowed = ("vuln", "config", "secret", "license")
    bad = _enum_list(value, allowed)
    if bad:
        return "invalid scanner(s): " + ", ".join(bad) + "; allowed: " + ", ".join(allowed)
    return None


def check_severity_enum(value: str) -> str | None:
    """Comma-separated Trivy severities."""
    if _skip(value):
        return None
    allowed = ("UNKNOWN", "LOW", "MEDIUM", "HIGH", "CRITICAL")
    bad = _enum_list(value, allowed)
    if bad:
        return "invalid severity/severities: " + ", ".join(bad) + "; allowed: " + ", ".join(allowed)
    return None


def check_timeout_with_unit(value: str) -> str | None:
    """Duration with a unit (e.g. ``5m``, ``30s``, ``500ms``)."""
    if _skip(value):
        return None
    if re.match(r"^[0-9]+(ns|us|µs|ms|s|m|h)$", value):
        return None
    return "must be a duration with a unit (e.g. 30s, 5m, 1h)"


ACTION = "security-scan"

CHECKS = {
    "actionlint-enabled": check_boolean,
    "gitleaks-config": check_file_path,
    "gitleaks-license": check_license_key,
    "token": check_github_token,
    "trivy-scanners": check_scanner_list,
    "trivy-severity": check_severity_enum,
    "trivy-timeout": check_timeout_with_unit,
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
            sys.stdout.write(f"::error::{ACTION}: {error}\n")
        sys.exit(1)


if __name__ == "__main__":
    main()
