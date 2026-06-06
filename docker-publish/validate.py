"""GENERATED — DO NOT EDIT. Input validation for the docker-publish action.

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
    if re.match(r"^[a-z0-9]+((\.|_|__|-+)[a-z0-9]+)*(/[a-z0-9]+((\.|_|__|-+)[a-z0-9]+)*)*$", value):
        return None
    return "must be a lowercase Docker image name (e.g. myapp, registry.example.com/ns/app)"


def check_docker_tag(value: str) -> str | None:
    """Docker tag: alphanumeric start/end with ``-._:/@`` inside (e.g. ``v1.0.0``, ``latest``)."""
    if _skip(value):
        return None
    if re.match(r"^[a-zA-Z0-9][-a-zA-Z0-9._:/@]*[a-zA-Z0-9]$", value) or re.match(
        r"^[a-zA-Z0-9]$", value
    ):
        return None
    return "must be a valid Docker tag (e.g. v1.0.0, latest, sha-1234567)"


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

    Accepts every GitHub token shape (classic, OAuth, user-to-server, installation,
    refresh, enterprise, and fine-grained PATs). Installation tokens cover both the
    legacy 40-char ``ghs_`` form and the stateless ``ghs_<app-id>_<JWT>`` form rolled
    out 2026-04-27: the JWT is base64url (so it may contain ``-`` and ``_``) joined by
    ``.`` and has no fixed length, so that pattern allows ``-`` and sets no upper bound
    (GitHub warns against relying on token length). Tokens are almost always passed as
    ``${{ secrets.* }}`` or ``$VAR`` references, both of which pass through unchecked.
    """
    if _skip(value) or _is_env_ref(value):
        return None
    patterns = (
        r"^ghp_[A-Za-z0-9]{36}$",  # classic personal access token
        r"^gho_[A-Za-z0-9]{36}$",  # OAuth token
        r"^ghu_[A-Za-z0-9]{36}$",  # user-to-server token
        r"^ghs_[A-Za-z0-9._-]{36,}$",  # installation token (stateful ghs_+36 or stateless JWT)
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
        if not re.match(r"^[A-Za-z_][A-Za-z0-9_]*$", key):
            return f"invalid key: {key}"
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
    if re.match(r"^[a-zA-Z0-9](?:[a-zA-Z0-9_-]*[a-zA-Z0-9])?$", value):
        return None
    return "may only contain letters, digits, and internal - or _"


ACTION = "docker-publish"

CHECKS = {
    "build-args": check_key_value_list,
    "context": check_file_path,
    "dockerfile": check_file_path,
    "dockerhub-token": check_github_token,
    "dockerhub-username": check_username,
    "image-name": check_docker_image_name,
    "platforms": check_docker_architectures,
    "push": check_boolean,
    "registry": check_registry_enum,
    "tags": check_docker_tag,
    "token": check_github_token,
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
