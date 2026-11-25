"""GENERATED — DO NOT EDIT. Input validation for the security-scan action.

Produced by _validation/generate.py from the _validation/kit package + _validation/spec.py.
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
    """Empty values bypass format checks (see the module contract).

    Blank means ASCII whitespace only, what a step's `tr -d '[:space:]'` removes in the C
    locale. str.strip() alone also removes U+00A0 and other Unicode spaces, so a value of only
    those would skip its check while the step went on to use it.
    """
    return value.strip(" \t\n\v\f\r") == ""


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


def _enum(value: str, *allowed: str) -> str | None:
    """Accept ``value`` iff it is exactly one of ``allowed`` (case-sensitive)."""
    if _skip(value) or value in allowed:
        return None
    return "must be one of: " + ", ".join(allowed)


def _enum_list(value: str, allowed: tuple[str, ...], *, fold: bool = False) -> list[str]:
    """Return the comma-split items of value not in allowed (optionally case-folded)."""
    items = _split_items(value)
    if fold:
        items = [item.lower() for item in items]
    return [item for item in items if item and item not in allowed]


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


def check_boolean(value: str) -> str | None:
    """Boolean flag — exactly ``true`` or ``false``.

    Shell steps test ``[ "$FLAG" = "true" ]``, which is case-sensitive, while ``if:`` expressions
    are not, so ``True`` or a blank would have the two halves of an action disagree. A blank is
    refused for the reason in the module contract.
    """
    if value in ("true", "false"):
        return None
    return 'must be "true" or "false" (lowercase)'


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


def check_jactionlint_profile(value: str) -> str | None:
    """Rule profile for jactionlint: correctness, or default with its other rules."""
    return _enum(value, "correctness", "default")


def check_opaque_token(value: str) -> str | None:
    """Token whose format its issuer owns (npm, Docker Hub): rejects only what cannot be one.

    No prefix, length or alphabet is enforced, so a real token never fails on a format this
    repo guessed. Whitespace and control characters are refused because a line break would add
    lines to any line-based file the token is written to, such as a config file or
    ``GITHUB_OUTPUT``. Shell metacharacters
    are not refused: consumers read the value from a quoted env var and never parse it as shell.
    """
    if _skip(value):
        return None
    if re.search(r"[\s\x00-\x1f\x7f-\x9f]", value):
        return "must not contain whitespace or control characters"
    return None


def check_scanner_list(value: str) -> str | None:
    """Comma-separated Trivy scanners.

    ``config`` is Trivy's older, deprecated name for ``misconfig``.
    """
    if _skip(value):
        return None
    allowed = ("vuln", "misconfig", "config", "secret", "license")
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
    if re.fullmatch(r"[0-9]+(ns|us|µs|ms|s|m|h)", value):
        return None
    return "must be a duration with a unit (e.g. 30s, 5m, 1h)"


ACTION = "security-scan"

CHECKS = {
    "actionlint-enabled": check_boolean,
    "gitleaks-config": check_file_path,
    "gitleaks-license": check_opaque_token,
    "jactionlint-profile": check_jactionlint_profile,
    "token": check_github_token,
    "trivy-scanners": check_scanner_list,
    "trivy-severity": check_severity_enum,
    "trivy-timeout": check_timeout_with_unit,
}


REQUIRED: set[str] = set()


MASKED_INPUTS: list[str] = ["gitleaks-license", "token"]


def _variable(name: str) -> str:
    """Return the name of the INPUT_* env var that carries an input."""
    return "INPUT_" + name.upper().replace("-", "_")


def _input(name: str) -> str:
    """Return an input's raw value from its INPUT_* env var."""
    return os.environ.get(_variable(name), "")


def _mask_secrets() -> None:
    """Register every line of each secret input with the runner's log masker."""
    # The runner decodes %25 in command data, so a literal % has to be encoded to register the
    # real value.
    for input_name in MASKED_INPUTS:
        for line in _input(input_name).splitlines():
            if line.strip():
                sys.stdout.write("::add-mask::" + line.strip().replace("%", "%25") + "\n")


def _input_error(input_name: str) -> str | None:
    """Return why an input's value is refused, or None when it passes."""
    value = _input(input_name)
    if input_name in REQUIRED and _skip(value):
        return "required input is missing"
    # The runner applies a default only when the caller leaves the input out, and `||` in an
    # expression takes any non-empty string as set, so `${{ inputs.x || default }}` and
    # with: would pass a value of only whitespace on as it is. Empty means unset.
    if value and _skip(value):
        return "is only whitespace: leave the input out for its default"
    # action.yml forwards every input, so only a standalone run leaves a variable unset.
    if _variable(input_name) not in os.environ:
        return None
    return CHECKS[input_name](value)


def main() -> None:
    """Mask secret inputs, then validate every declared input; fail with all reasons."""
    # Masks come first so nothing printed below can reveal a secret.
    _mask_secrets()
    errors = [
        f"{input_name}: {reason}"
        for input_name in CHECKS
        if (reason := _input_error(input_name)) is not None
    ]
    if errors:
        for error in errors:
            # Encode as workflow-command data: a rejected value must not start a new command.
            data = error.replace("%", "%25").replace("\r", "%0D").replace("\n", "%0A")
            sys.stdout.write(f"::error::{ACTION}: {data}\n")
        sys.exit(1)


if __name__ == "__main__":
    main()
