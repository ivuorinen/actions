"""GENERATED — DO NOT EDIT. Input validation for the compress-images action.

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


def _shell_meta_error(value: str) -> str | None:
    """Reject shell metacharacters ; & | ` $ ( ) (returns an error message or None)."""
    if re.search(r"[;&|`$()]", value):
        return "must not contain shell metacharacters ; & | ` $ ( )"
    return None


def _file_path_error(value: str, *, spaces: bool = False) -> str | None:
    """Return why ``value`` is not a relative path below the working directory, or None.

    A leading ``-`` is refused because a command would read it as an option, and buildx reads
    ``-`` alone as stdin; ``./-name`` names the same file.

    With ``spaces``, runs of spaces may separate path characters. A leading or trailing space
    stays invalid, so the absolute-path check always sees the path's real first character.
    """
    if value.startswith("-"):
        return "must not start with -"
    import urllib.parse

    decoded = urllib.parse.unquote(value)
    if decoded.startswith("/") or (len(decoded) > 1 and decoded[1] == ":"):
        return "absolute paths are not allowed"
    if ".." in decoded:
        return "path traversal (..) is not allowed"
    if value.startswith("~"):
        return "home directory expansion (~) is not allowed"
    chars = r"[a-zA-Z0-9._/\-@+~!#=:]+"
    if re.fullmatch(f"{chars}( +{chars})*" if spaces else chars, value):
        return None
    return "contains invalid path characters"


def check_email(value: str) -> str | None:
    """Email address."""
    if _skip(value):
        return None
    if re.fullmatch(r"[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}", value):
        return None
    return "must be a valid email address (e.g. user@example.com)"


def check_file_path(value: str) -> str | None:
    """Relative file path — rejects a leading ``-``, absolute paths, ``..`` and ``~`` expansion."""
    if _skip(value):
        return None
    return _file_path_error(value)


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


def check_numeric_range_0_100(value: str) -> str | None:
    """Integer in [0, 100] (e.g. image quality percentage)."""
    return _int_in_range(value, 0, 100)


def check_path_list(value: str) -> str | None:
    """Comma-separated paths/globs — blocks injection characters, ``..`` and a leading ``-``.

    A comma inside braces belongs to the glob (``src/{a,-b}.js``), so it does not separate items.
    """
    if _skip(value):
        return None
    if meta := _shell_meta_error(value):
        return meta
    for item in _split_items(value, globs=True):
        if not item:
            continue
        if item.startswith("-"):
            return f"must not start with -: {item}"
        if ".." in item:
            return f"path traversal (..) is not allowed: {item}"
        if not re.fullmatch(r"[a-zA-Z0-9_\-./*?\[\]{},@~+]+", item):
            return f"invalid path or glob: {item}"
    return None


def check_username(value: str) -> str | None:
    """Username/handle — alphanumeric with internal ``-``/``_``, at most 39 characters."""
    if _skip(value):
        return None
    if len(value) > 39:
        return "must be at most 39 characters"
    if re.fullmatch(r"[a-zA-Z0-9](?:[a-zA-Z0-9_-]*[a-zA-Z0-9])?", value):
        return None
    return "may only contain letters, digits, and internal - or _"


ACTION = "compress-images"

CHECKS = {
    "email": check_email,
    "ignore-paths": check_path_list,
    "image-quality": check_numeric_range_0_100,
    "png-quality": check_numeric_range_0_100,
    "token": check_github_token,
    "username": check_username,
    "working-directory": check_file_path,
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
    main()
