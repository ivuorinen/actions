"""GENERATED — DO NOT EDIT. Input validation for the go-lint action.

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


def _is_semver(core: str) -> bool:
    """Return True if core is a semantic version: X.Y.Z[-pre][+build], or partial X.Y / X."""
    full = (
        r"^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)"
        r"(?:-(?:0|[1-9]\d*|\d*[A-Za-z-][0-9A-Za-z-]*)"
        r"(?:\.(?:0|[1-9]\d*|\d*[A-Za-z-][0-9A-Za-z-]*))*)?"
        r"(?:\+[0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*)?$"
    )
    return bool(
        re.match(full, core)
        or re.match(r"^(0|[1-9]\d*)\.(0|[1-9]\d*)$", core)
        or re.match(r"^(0|[1-9]\d*)$", core)
    )


def _enum(value: str, *allowed: str) -> str | None:
    """Accept ``value`` iff it is exactly one of ``allowed`` (case-sensitive)."""
    if _skip(value) or value in allowed:
        return None
    return "must be one of: " + ", ".join(allowed)


def _int_in_range(value: str, low: int, high: int) -> str | None:
    """Accept ``value`` iff it is an integer within ``[low, high]``."""
    if _skip(value):
        return None
    try:
        number = int(value.strip())
    except ValueError:
        return f"must be an integer between {low} and {high}"
    if low <= number <= high:
        return None
    return f"must be an integer between {low} and {high}"


def _shell_meta_error(value: str) -> str | None:
    """Reject shell metacharacters ; & | ` $ ( ) (returns an error message or None)."""
    if re.search(r"[;&|`$()]", value):
        return "must not contain shell metacharacters ; & | ` $ ( )"
    return None


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


def check_go_version(value: str) -> str | None:
    """Go version: ``1.21``, ``1.21.0``, ``1.21.x``, or a channel keyword (stable/oldstable)."""
    if _skip(value):
        return None
    if value.strip().lower() in ("stable", "oldstable"):
        return None
    if re.match(r"^v?\d+\.\d+(\.\d+|\.x)?$", value.strip()):
        return None
    return "must be a Go version (e.g. 1.21, 1.21.5, stable)"


def check_linter_list(value: str) -> str | None:
    """Comma-separated linter names (e.g. ``gosec,govet``)."""
    if _skip(value):
        return None
    if meta := _shell_meta_error(value):
        return meta
    for item in (part.strip() for part in value.split(",")):
        if not item:
            return "linter list must not contain empty entries"
        if not re.match(r"^[a-zA-Z0-9_-]+$", item):
            return f"invalid linter name: {item}"
    return None


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


def check_semantic_version(value: str) -> str | None:
    """SemVer with optional v prefix: X.Y.Z[-pre][+build], partial X.Y / X, or latest."""
    if _skip(value) or value.strip().lower() == "latest":
        return None
    core = value.strip()
    core = core[1:] if core[:1] in ("v", "V") else core
    if _is_semver(core):
        return None
    return 'must be a semantic version (e.g. 1.2.3, 1.2.3-rc.1, 1.2, 1, or "latest")'


def check_timeout_with_unit(value: str) -> str | None:
    """Duration with a unit (e.g. ``5m``, ``30s``, ``500ms``)."""
    if _skip(value):
        return None
    if re.match(r"^[0-9]+(ns|us|µs|ms|s|m|h)$", value):
        return None
    return "must be a duration with a unit (e.g. 30s, 5m, 1h)"


ACTION = "go-lint"

CHECKS = {
    "cache": check_boolean,
    "config-file": check_file_path,
    "disable-all": check_boolean,
    "disable-linters": check_linter_list,
    "enable-linters": check_linter_list,
    "fail-on-error": check_boolean,
    "go-version": check_go_version,
    "golangci-lint-version": check_semantic_version,
    "max-retries": check_numeric_range_1_10,
    "only-new-issues": check_boolean,
    "report-format": check_report_format,
    "timeout": check_timeout_with_unit,
    "token": check_github_token,
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
            sys.stdout.write(f"::error::{ACTION}: {error}\n")
        sys.exit(1)


if __name__ == "__main__":
    main()
