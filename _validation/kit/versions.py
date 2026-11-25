"""Checks for versions, and the rules for versions read from repository files."""

from __future__ import annotations

import re

from .common import _is_semver, _skip, _strip_v


def check_semantic_version(value: str) -> str | None:
    """SemVer with optional v prefix: X.Y.Z[-pre][+build], partial X.Y / X, or latest."""
    if _skip(value) or value.lower() == "latest":
        return None
    if _is_semver(_strip_v(value)):
        return None
    return 'must be a semantic version (e.g. 1.2.3, 1.2.3-rc.1, 1.2, 1, or "latest")'


def check_golangci_lint_version(value: str) -> str | None:
    """``semantic_version`` at major 2.

    go-lint installs the ``/v2`` module path, which Go requires to match the version's major,
    and v1 also has other CLI flags.
    """
    if _skip(value) or value.lower() == "latest":
        return None
    core = _strip_v(value)
    if _is_semver(core) and int(re.split(r"\D", core, maxsplit=1)[0]) == 2:
        return None
    return 'must be golangci-lint v2 (e.g. 2.1.0, v2.1.0, or "latest")'


def check_strict_semantic_version(value: str) -> str | None:
    """Strict SemVer: ``[v]X.Y.Z`` with optional ``-prerelease`` / ``+build`` (no partials)."""
    if _skip(value) or value.lower() == "latest":
        return None
    if re.fullmatch(r"[vV]?[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?(\+[0-9A-Za-z.-]+)?", value):
        return None
    return "must be a strict semantic version X.Y.Z or vX.Y.Z (optionally -prerelease / +build)"


def check_no_prefix_version(value: str) -> str | None:
    """SemVer-style version that must NOT carry a leading ``v`` (use ``1.2.3``, not ``v1.2.3``)."""
    if _skip(value):
        return None
    if value[:1] in ("v", "V"):
        return 'must not start with "v" (use 1.2.3, not v1.2.3)'
    if _is_semver(value):
        return None
    return "must be a semantic version without a v prefix (e.g. 1.2.3, 1.2, 1)"


def _days_in_month(year: int, month: int) -> int:
    """Return how many days ``month`` has in ``year`` of the Gregorian calendar."""
    if month == 2:
        leap = year % 4 == 0 and (year % 100 != 0 or year % 400 == 0)
        return 29 if leap else 28
    return 30 if month in (4, 6, 9, 11) else 31


def check_calver_version(value: str) -> str | None:
    """Calendar version: YYYY.MM.DD / .PATCH, YYYY.0M.0D, YY.MM.MICRO, YYYY.MM, or YYYY-MM-DD."""
    if _skip(value):
        return None
    core = _strip_v(value)
    patterns = (
        r"[0-9]{4}\.[0-9]{1,2}\.[0-9]{1,2}",  # YYYY.MM.DD
        r"[0-9]{4}\.0[0-9]\.0[0-9]",  # YYYY.0M.0D
        r"[0-9]{2}\.[0-9]{1,2}\.[0-9]{1,2}",  # YY.MM.MICRO (micro doubles as a day)
        r"[0-9]{4}-[0-9]{2}-[0-9]{2}",  # YYYY-MM-DD
        r"[0-9]{4}\.[0-9]{1,2}\.[0-9]{3,}",  # YYYY.MM.PATCH (3+ digit patch, never a day)
        r"[0-9]{4}\.[0-9]{1,2}",  # YYYY.MM
    )
    if not any(re.fullmatch(pattern, core) for pattern in patterns):
        return "must be a calendar version (e.g. 2025.04.05, 2025.4.5, 2025.04, 2025-04-05)"
    parts = re.split(r"[.-]", core)
    month = int(parts[1])
    if not 1 <= month <= 12:
        return f"month must be 1-12, got {month}"
    # The third component is a calendar day only when it is 1-2 digits; a 3+ digit
    # third component is a PATCH number, not a day, so it is not range-checked.
    if len(parts) == 3 and len(parts[2]) <= 2:
        year = int(parts[0]) if len(parts[0]) == 4 else 2000 + int(parts[0])
        day = int(parts[2])
        if not 1 <= day <= _days_in_month(year, month):
            return f"day {day} is invalid for month {month}"
    return None


def check_dotnet_version(value: str) -> str | None:
    """.NET version: 8, 8.0, 8.0.100, or 8.0.x feature band, with optional -preview suffix."""
    if _skip(value):
        return None
    if re.fullmatch(r"[0-9]+(\.[0-9]+)?(\.([0-9]+|x))?(-[0-9A-Za-z.-]+)?", value):
        return None
    return "must be a .NET version (e.g. 8.0, 8.0.100, 8.0.x)"


def check_terraform_version(value: str) -> str | None:
    """Terraform/tflint version: ``X.Y.Z`` with optional ``-prerelease``, or ``latest``."""
    if _skip(value) or value.lower() == "latest":
        return None
    if re.fullmatch(r"v?[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?", value):
        return None
    return 'must be a version like 1.5.7 or "latest"'


def check_node_version(value: str) -> str | None:
    """Node version: 20, 20.1, 20.1.0, latest/current/node, or an LTS alias.

    The aliases are what actions/setup-node resolves: lts/<name>, lts/* and lts/-n. It matches the
    keywords and the ``lts/`` prefix case-sensitively, and only the <name> in any case.
    """
    if _skip(value):
        return None
    if re.fullmatch(r"latest|current|node|lts/(\*|-[1-9][0-9]*|[a-zA-Z]+)", value):
        return None
    if re.fullmatch(r"v?[0-9]+(\.[0-9]+(\.[0-9]+)?)?", value):
        return None
    return "must be a Node version (e.g. 20, 20.11.0, lts/*, latest)"


def check_go_version(value: str) -> str | None:
    """Go version: ``1.21``, ``1.21.0``, ``1.21.x``, or a channel keyword (stable/oldstable)."""
    if _skip(value):
        return None
    if value.lower() in ("stable", "oldstable"):
        return None
    if re.fullmatch(r"v?[0-9]+\.[0-9]+(\.[0-9]+|\.x)?", value):
        return None
    return "must be a Go version (e.g. 1.21, 1.21.5, stable)"


# --------------------------------------------------------------------------------------
# Versions read from repository files
#
# These are not input checks, so they are not ``check_*`` and not in ``CHECKS``: the ``_skip``
# contract is wrong for them. The value comes from a file in the checked-out repository, so
# an empty string or a ``${{ }}`` is just more untrusted text. An action reaches one through
# ``validate.py --detected-version VALUE`` (``detected_version`` in ``spec.py``) and moves on
# to its next version source when the answer is no.
#
# Both allow only ASCII digits, letters and ``.+-``, so nothing a shell, a ``with:`` input or
# ``$GITHUB_OUTPUT`` treats as syntax can pass. ``fullmatch`` also refuses a trailing newline,
# which ``$`` would let through, and ``[0-9]`` refuses the non-ASCII digits ``\d`` matches.
# --------------------------------------------------------------------------------------


def is_detected_version(value: str) -> bool:
    """Dotted version with an optional suffix: 8.4, 1.22.3, 1.25.x, 1.23rc1, 3.13-dev, 1.0.0+b."""
    pattern = r"[0-9]+\.[0-9][0-9A-Za-z]*(\.[0-9A-Za-z]+)*([-+][0-9A-Za-z.+-]+)?"
    return re.fullmatch(pattern, value) is not None


def is_detected_dotnet_version(value: str) -> bool:
    """The dotted forms, plus the bare majors setup-dotnet documents: 8 and 8.x."""
    pattern = r"[0-9]+(\.[0-9A-Za-z]+)*([-+][0-9A-Za-z.+-]+)?"
    return re.fullmatch(pattern, value) is not None
