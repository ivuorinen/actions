"""GENERATED — DO NOT EDIT. Input validation for the docker-publish action.

Produced by _validation/generate.py from _validation/kit.py + _validation/spec.py.
Run `make update-validators` to regenerate. Pure stdlib, no third-party deps — the action
runs it with `python3 validate.py`.

Each check returns None when the value is acceptable or a short reason otherwise. Empty
<<<<<<< HEAD
values pass (inputs are optional unless listed in REQUIRED). The runner has already expanded
every expression in INPUT_*, so all other values are checked as literal data. Inputs listed in
SECRETS are masked in the job's logs before any check runs.
||||||| parent of 72e3942 (refactor(validation): name masked inputs for what they hold)
values pass (inputs are optional unless listed in REQUIRED) and `${{ ... }}` expressions
pass unchecked (their value is substituted at runtime). Inputs listed in SECRETS are masked
in the job's logs before any check runs.
=======
values pass (inputs are optional unless listed in REQUIRED) and `${{ ... }}` expressions
pass unchecked (their value is substituted at runtime). Inputs named in MASKED_INPUTS are
masked in the job's logs before any check runs.
>>>>>>> 72e3942 (refactor(validation): name masked inputs for what they hold)
"""

from __future__ import annotations

import os
import re
import sys


def _skip(value: str) -> bool:
    """Empty values bypass format checks (see the module contract)."""
    return value.strip() == ""


def _split_items(value: str, separators: str = ",") -> list[str]:
    """Split a list input, allowing spaces or tabs around items but not newlines."""
    return [part.strip(" \t") for part in re.split(f"[{separators}]", value)]


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


def _shell_meta_error(value: str) -> str | None:
    """Reject shell metacharacters ; & | ` $ ( ) (returns an error message or None)."""
    if re.search(r"[;&|`$()]", value):
        return "must not contain shell metacharacters ; & | ` $ ( )"
    return None


def check_boolean(value: str) -> str | None:
    """Boolean flag — ``true`` or ``false`` (any case)."""
    if _skip(value) or value.lower() in ("true", "false"):
        return None
    return 'must be "true" or "false"'


def check_docker_architectures(value: str) -> str | None:
    """Comma-separated Docker build platforms (e.g. ``linux/amd64,linux/arm64``)."""
    if _skip(value):
        return None
    allowed = (
        "linux/amd64",
        "linux/arm64",
        "linux/arm/v7",
        "linux/arm/v6",
        "linux/386",
        "linux/ppc64le",
        "linux/s390x",
    )
    bad = _enum_list(value, allowed)
    if bad:
        return "unsupported platform(s): " + ", ".join(bad) + "; allowed: " + ", ".join(allowed)
    return None


def check_docker_image_name(value: str) -> str | None:
    """Docker image reference: lowercase name with optional registry/namespace path."""
    if _skip(value):
        return None
    if re.fullmatch(
        r"[a-z0-9]+((\.|_|__|-+)[a-z0-9]+)*(/[a-z0-9]+((\.|_|__|-+)[a-z0-9]+)*)*", value
    ):
        return None
    return "must be a lowercase Docker image name (e.g. myapp, registry.example.com/ns/app)"


def check_docker_tag_list(value: str) -> str | None:
    """Comma-separated Docker tags (e.g. ``latest,v1.0.0``), with no spaces around the commas.

    Each entry becomes the tag of an ``image:tag`` reference, so it follows the tag rule of the
    Distribution reference grammar: a letter, digit or ``_``, then up to 127 of those, ``.`` or
    ``-``.
    """
    if _skip(value):
        return None
    for tag in value.split(","):
        if not re.fullmatch(r"[A-Za-z0-9_][A-Za-z0-9_.-]{0,127}", tag):
            return f"invalid Docker tag: {tag!r} (letters, digits, _ . -, at most 128 characters)"
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


def check_key_value_list(value: str) -> str | None:
    """Newline-separated ``KEY=VALUE`` pairs (e.g. build args / secrets)."""
    if _skip(value):
        return None
    if meta := _shell_meta_error(value):
        return meta
    for pair in (line.strip() for line in value.splitlines()):
        if not pair:
            continue
        if "=" not in pair:
            return f"invalid pair (expected KEY=VALUE): {pair}"
        key = pair.split("=", 1)[0]
        if not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", key):
            return f"invalid key: {key}"
    return None


def check_opaque_token(value: str) -> str | None:
    """Token whose format its issuer owns (npm, Docker Hub): rejects only what cannot be one.

    No prefix, length or alphabet is enforced, so a real token never fails on a format this
    repo guessed. Whitespace and control characters are refused because a line break would add
    lines to the ``.npmrc`` or ``GITHUB_OUTPUT`` file a token is written to. Shell metacharacters
    are not refused: consumers read the value from a quoted env var and never parse it as shell.
    """
    if _skip(value):
        return None
    if re.search(r"[\s\x00-\x1f\x7f-\x9f]", value):
        return "must not contain whitespace or control characters"
    return None


def check_registry_enum(value: str) -> str | None:
    """Container registry selector."""
    return _enum(value, "dockerhub", "github", "both")


def check_username(value: str) -> str | None:
    """Username/handle — alphanumeric with internal ``-``/``_``, at most 39 characters."""
    if _skip(value):
        return None
    if len(value) > 39:
        return "must be at most 39 characters"
    if re.fullmatch(r"[a-zA-Z0-9](?:[a-zA-Z0-9_-]*[a-zA-Z0-9])?", value):
        return None
    return "may only contain letters, digits, and internal - or _"


ACTION = "docker-publish"

CHECKS = {
    "build-args": check_key_value_list,
    "context": check_file_path,
    "dockerfile": check_file_path,
    "dockerhub-token": check_opaque_token,
    "dockerhub-username": check_username,
    "image-name": check_docker_image_name,
    "platforms": check_docker_architectures,
    "push": check_boolean,
    "registry": check_registry_enum,
    "tags": check_docker_tag_list,
    "token": check_github_token,
}


REQUIRED: set[str] = set()


MASKED_INPUTS: list[str] = ["token"]


def _input(name: str) -> str:
    """Return an input's raw value from its INPUT_* env var."""
    return os.environ.get("INPUT_" + name.upper().replace("-", "_"), "")


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
