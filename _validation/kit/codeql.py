"""Checks for CodeQL analysis settings."""

from __future__ import annotations

import re

from .common import _enum, _enum_list, _skip, _split_items


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


def check_codeql_build_mode(value: str) -> str | None:
    """CodeQL build mode."""
    return _enum(value, "none", "manual", "autobuild")


def check_codeql_queries(value: str) -> str | None:
    """Comma-separated CodeQL query suites or query/pack references."""
    if _skip(value):
        return None
    suites = {"security-extended", "security-and-quality", "code-scanning", "default"}
    for item in _split_items(value):
        if not item:
            return "query list must not contain empty entries"
        if item not in suites and not re.fullmatch(r"[A-Za-z0-9._/@-]+", item):
            return f"invalid query reference: {item}"
    return None


def check_codeql_packs(value: str) -> str | None:
    """Comma-separated CodeQL packs (``scope/name`` with optional ``@version``)."""
    if _skip(value):
        return None
    for item in _split_items(value):
        if not item:
            return "pack list must not contain empty entries"
        if not re.fullmatch(r"[a-zA-Z0-9._/-]+(@[a-zA-Z0-9._-]+)?", item):
            return f"invalid pack reference: {item}"
    return None


def check_codeql_config(value: str) -> str | None:
    """Inline CodeQL YAML config — rejects unsafe YAML deserialization tags."""
    if _skip(value):
        return None
    for tag in ("!!python/", "!!ruby/", "!!perl/", "!!js/"):
        if tag in value:
            return f"must not contain unsafe YAML tag {tag}"
    return None


def check_category_format(value: str) -> str | None:
    """SARIF analysis category — letters, digits and ``_./:-`` only."""
    if _skip(value):
        return None
    if re.fullmatch(r"[A-Za-z0-9_./:-]+", value):
        return None
    return "must contain only letters, digits, and _./:- characters"
