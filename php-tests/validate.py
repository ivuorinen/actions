"""GENERATED — DO NOT EDIT. Input validation for the php-tests action.

Produced by _validation/generate.py from _validation/kit.py + _validation/spec.py.
Run `make update-validators` to regenerate. Pure stdlib, no third-party deps — the action
runs it with `python3 validate.py`.

Each check returns None when the value is acceptable or a short reason otherwise. Empty
values pass (inputs are optional unless listed in REQUIRED), except where a check says it
refuses them. The runner has already expanded every expression in INPUT_*, so all other values
are checked as literal data. Inputs named in MASKED_INPUTS are masked in the job's logs before
any check runs.
"""

from __future__ import annotations

import os
import re
import sys


def _skip(value: str) -> bool:
    """Empty values bypass format checks (see the module contract)."""
    return value.strip() == ""


def _split_items(value: str, separators: str = ",", *, globs: bool = False) -> list[str]:
    """Split a list input, allowing spaces or tabs around items but not newlines.

    With ``globs``, a separator inside braces, nested or not, belongs to the glob
    (``src/{a,-b{c,d}}.js``) and does not split. An unclosed brace groups nothing.
    """
    parts, depth, start = [], 0, 0
    for index, char in enumerate(value):
        if globs and char in "{}":
            depth = depth + 1 if char == "{" else max(depth - 1, 0)
        elif depth == 0 and char in separators:
            parts.append(value[start:index])
            start = index + 1
    if depth:
        return _split_items(value, separators)
    parts.append(value[start:])
    return [part.strip(" \t") for part in parts]


def _is_semver(core: str) -> bool:
    """Return True if core is a semantic version: X.Y.Z[-pre][+build], or partial X.Y / X."""
    full = (
        r"(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)"
        r"(?:-(?:0|[1-9][0-9]*|[0-9]*[A-Za-z-][0-9A-Za-z-]*)"
        r"(?:\.(?:0|[1-9][0-9]*|[0-9]*[A-Za-z-][0-9A-Za-z-]*))*)?"
        r"(?:\+[0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*)?"
    )
    return bool(
        re.fullmatch(full, core)
        or re.fullmatch(r"(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)", core)
        or re.fullmatch(r"(0|[1-9][0-9]*)", core)
    )


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
    if re.fullmatch(r"[0-9]{1,18}", value) and low <= int(value) <= high:
        return None
    return f"must be an integer between {low} and {high}"


def check_command_args(value: str) -> str | None:
    """Free-form command-line arguments — blocks shell metacharacters and control characters."""
    if _skip(value):
        return None
    if re.search(r"[;&|`$(){}<>\\]", value):
        return "must not contain shell metacharacters ; & | ` $ ( ) { } < > \\"
    if re.search(r"[\x00-\x1f\x7f]", value):
        return "must not contain control characters or newlines"
    return None


def check_coverage_driver(value: str) -> str | None:
    """PHP coverage driver."""
    return _enum(value, "none", "xdebug", "pcov", "xdebug3")


def check_email(value: str) -> str | None:
    """Email address."""
    if _skip(value):
        return None
    if re.fullmatch(r"[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}", value):
        return None
    return "must be a valid email address (e.g. user@example.com)"


def check_framework_mode(value: str) -> str | None:
    """PHP test framework mode."""
    return _enum(value, "auto", "laravel", "generic")


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
    """Integer in [1, 10] (retry counts); blank is refused, see the module contract."""
    if value.strip() == "":
        return "must be an integer between 1 and 10"
    return _int_in_range(value, 1, 10)


def check_php_extensions(value: str) -> str | None:
    """Comma-separated PHP extension names."""
    if _skip(value):
        return None
    for item in _split_items(value):
        if not item:
            return "extension list must not contain empty entries"
        if not re.fullmatch(r"[a-zA-Z0-9_ ]+", item):
            return f"invalid PHP extension: {item}"
    return None


def check_semantic_version(value: str) -> str | None:
    """SemVer with optional v prefix: X.Y.Z[-pre][+build], partial X.Y / X, or latest."""
    if _skip(value) or value.lower() == "latest":
        return None
    core = value[1:] if value[:1] in ("v", "V") else value
    if _is_semver(core):
        return None
    return 'must be a semantic version (e.g. 1.2.3, 1.2.3-rc.1, 1.2, 1, or "latest")'


def check_username(value: str) -> str | None:
    """Username/handle — alphanumeric with internal ``-``/``_``, at most 39 characters."""
    if _skip(value):
        return None
    if len(value) > 39:
        return "must be at most 39 characters"
    if re.fullmatch(r"[a-zA-Z0-9](?:[a-zA-Z0-9_-]*[a-zA-Z0-9])?", value):
        return None
    return "may only contain letters, digits, and internal - or _"


def is_detected_version(value: str) -> bool:
    """Dotted version with an optional suffix: 8.4, 1.22.3, 1.25.x, 1.23rc1, 3.13-dev, 1.0.0+b."""
    pattern = r"[0-9]+\.[0-9][0-9A-Za-z]*(\.[0-9A-Za-z]+)*([-+][0-9A-Za-z.+-]+)?"
    return re.fullmatch(pattern, value) is not None


ACTION = "php-tests"

CHECKS = {
    "composer-args": check_command_args,
    "coverage": check_coverage_driver,
    "email": check_email,
    "extensions": check_php_extensions,
    "framework": check_framework_mode,
    "max-retries": check_numeric_range_1_10,
    "php-version": check_semantic_version,
    "token": check_github_token,
    "username": check_username,
}


REQUIRED: set[str] = set()


MASKED_INPUTS: list[str] = ["token"]


def _variable(name: str) -> str:
    """Return the name of the INPUT_* env var that carries an input."""
    return "INPUT_" + name.upper().replace("-", "_")


def _input(name: str) -> str:
    """Return an input's raw value from its INPUT_* env var."""
    return os.environ.get(_variable(name), "")


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
        # action.yml forwards every input, so only a standalone run leaves a variable unset.
        reason = check(value) if _variable(input_name) in os.environ else None
        if reason is not None:
            errors.append(f"{input_name}: {reason}")
    if errors:
        for error in errors:
            # Encode as workflow-command data: a rejected value must not start a new command.
            data = error.replace("%", "%25").replace("\r", "%0D").replace("\n", "%0A")
            sys.stdout.write(f"::error::{ACTION}: {data}\n")
        sys.exit(1)


if __name__ == "__main__":
    if sys.argv[1:2] == ["--detected-version"]:
        sys.exit(0 if len(sys.argv) > 2 and is_detected_version(sys.argv[2]) else 1)
    main()
