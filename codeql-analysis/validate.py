"""GENERATED — DO NOT EDIT. Input validation for the codeql-analysis action.

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


def check_boolean(value: str) -> str | None:
    """Boolean flag — ``true`` or ``false`` (any case)."""
    if _skip(value) or value.strip().lower() in ("true", "false"):
        return None
    return 'must be "true" or "false"'


def check_branch_name(value: str) -> str | None:
    """Git branch/ref name — conservative subset that rejects ref-injection characters."""
    if _skip(value):
        return None
    if any(token in value for token in ("..", "~", "^", ":")):
        return "must not contain .. ~ ^ or :"
    if value.startswith((".", "-", "/")) or value.endswith((".", "/")):
        return "must not start with . - / or end with . /"
    if re.match(r"^[a-zA-Z0-9/_.\-]+$", value):
        return None
    return "may only contain letters, digits, and / _ . -"


def check_category_format(value: str) -> str | None:
    """SARIF analysis category — letters, digits and ``_./:-`` only."""
    if _skip(value):
        return None
    if re.match(r"^[A-Za-z0-9_./:-]+$", value):
        return None
    return "must contain only letters, digits, and _./:- characters"


def check_codeql_build_mode(value: str) -> str | None:
    """CodeQL build mode."""
    return _enum(value, "none", "manual", "autobuild")


def check_codeql_config(value: str) -> str | None:
    """Inline CodeQL YAML config — rejects unsafe YAML deserialization tags."""
    if _skip(value):
        return None
    for tag in ("!!python/", "!!ruby/", "!!perl/", "!!js/"):
        if tag in value:
            return f"must not contain unsafe YAML tag {tag}"
    return None


def check_codeql_language(value: str) -> str | None:
    """Comma-separated CodeQL language(s)."""
    if _skip(value):
        return None
    allowed = (
        "actions",
        "c",
        "cpp",
        "csharp",
        "go",
        "java",
        "javascript",
        "kotlin",
        "python",
        "ruby",
        "swift",
        "typescript",
    )
    bad = _enum_list(value, allowed, fold=True)
    if bad:
        return "unsupported language(s): " + ", ".join(bad)
    return None


def check_codeql_packs(value: str) -> str | None:
    """Comma-separated CodeQL packs (``scope/name`` with optional ``@version``)."""
    if _skip(value):
        return None
    for item in (part.strip() for part in value.split(",")):
        if not item:
            return "pack list must not contain empty entries"
        if not re.match(r"^[a-zA-Z0-9._/-]+(@[a-zA-Z0-9._-]+)?$", item):
            return f"invalid pack reference: {item}"
    return None


def check_codeql_queries(value: str) -> str | None:
    """Comma-separated CodeQL query suites or query/pack references."""
    if _skip(value):
        return None
    suites = {"security-extended", "security-and-quality", "code-scanning", "default"}
    for item in (part.strip() for part in value.split(",")):
        if not item:
            return "query list must not contain empty entries"
        if item not in suites and not re.match(r"^[A-Za-z0-9._/@-]+$", item):
            return f"invalid query reference: {item}"
    return None


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


def check_numeric_range_1_128(value: str) -> str | None:
    """Integer in [1, 128] (e.g. CodeQL threads)."""
    return _int_in_range(value, 1, 128)


def check_numeric_range_256_32768(value: str) -> str | None:
    """Integer in [256, 32768] (e.g. CodeQL RAM in MB)."""
    return _int_in_range(value, 256, 32768)


def check_output_path(value: str) -> str | None:
    """Output path — like file_path but allows parent-relative .. (no absolute path or ~)."""
    if _skip(value):
        return None
    import urllib.parse

    decoded = urllib.parse.unquote(value)
    if decoded.startswith("/") or (len(decoded) > 1 and decoded[1] == ":"):
        return "absolute paths are not allowed"
    if value.startswith("~"):
        return "home directory expansion (~) is not allowed"
    if re.fullmatch(r"[a-zA-Z0-9._/\-@+]+", value):
        return None
    return "contains invalid path characters"


ACTION = "codeql-analysis"

CHECKS = {
    "build-mode": check_codeql_build_mode,
    "category": check_category_format,
    "checkout-ref": check_branch_name,
    "config": check_codeql_config,
    "config-file": check_file_path,
    "language": check_codeql_language,
    "output": check_output_path,
    "packs": check_codeql_packs,
    "queries": check_codeql_queries,
    "ram": check_numeric_range_256_32768,
    "skip-queries": check_boolean,
    "source-root": check_file_path,
    "threads": check_numeric_range_1_128,
    "token": check_github_token,
    "upload-results": check_boolean,
    "working-directory": check_file_path,
}


REQUIRED = {"language"}


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
