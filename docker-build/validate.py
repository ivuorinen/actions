"""GENERATED — DO NOT EDIT. Input validation for the docker-build action.

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


def check_cache_config(value: str) -> str | None:
    """Docker buildx cache spec: ``type=<backend>[,key=value...]`` (e.g. ``type=gha,mode=max``)."""
    if _skip(value):
        return None
    match = re.match(r"^type=([a-z0-9-]+)", value)
    if not match:
        return "must start with type=<backend> (e.g. type=gha, type=registry,ref=...)"
    allowed = ("registry", "local", "gha", "inline", "s3", "azblob", "oci")
    if match.group(1) not in allowed:
        return "cache backend must be one of: " + ", ".join(allowed)
    return None


def check_cache_mode(value: str) -> str | None:
    """Docker buildx cache mode."""
    return _enum(value, "max", "min", "inline")


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


def check_json_format(value: str) -> str | None:
    """A well-formed JSON document."""
    if _skip(value):
        return None
    import json

    try:
        json.loads(value)
    except ValueError:
        return "must be valid JSON"
    return None


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


def check_network_mode(value: str) -> str | None:
    """Docker build network mode."""
    return _enum(value, "host", "none", "default")


def check_numeric_range_0_16(value: str) -> str | None:
    """Integer in [0, 16] (e.g. parallel build workers)."""
    return _int_in_range(value, 0, 16)


def check_numeric_range_1_10(value: str) -> str | None:
    """Integer in [1, 10] (e.g. retry counts)."""
    return _int_in_range(value, 1, 10)


def check_sbom_format(value: str) -> str | None:
    """SBOM output format."""
    return _enum(value, "spdx-json", "cyclonedx-json")


def check_semantic_version(value: str) -> str | None:
    """SemVer with optional v prefix: X.Y.Z[-pre][+build], partial X.Y / X, or latest."""
    if _skip(value) or value.strip().lower() == "latest":
        return None
    core = value.strip()
    core = core[1:] if core[:1] in ("v", "V") else core
    if _is_semver(core):
        return None
    return 'must be a semantic version (e.g. 1.2.3, 1.2.3-rc.1, 1.2, 1, or "latest")'


ACTION = "docker-build"

CHECKS = {
    "architectures": check_docker_architectures,
    "auto-detect-platforms": check_boolean,
    "build-args": check_key_value_list,
    "build-contexts": check_key_value_list,
    "buildkit-version": check_semantic_version,
    "buildx-version": check_semantic_version,
    "cache-export": check_cache_config,
    "cache-from": check_cache_config,
    "cache-import": check_cache_config,
    "cache-mode": check_cache_mode,
    "context": check_file_path,
    "dockerfile": check_file_path,
    "dry-run": check_boolean,
    "image-name": check_docker_image_name,
    "max-retries": check_numeric_range_1_10,
    "network": check_network_mode,
    "parallel-builds": check_numeric_range_0_16,
    "platform-build-args": check_json_format,
    "platform-fallback": check_boolean,
    "push": check_boolean,
    "sbom-format": check_sbom_format,
    "scan-image": check_boolean,
    "secrets": check_key_value_list,
    "sign-image": check_boolean,
    "tag": check_docker_tag,
    "token": check_github_token,
    "verbose": check_boolean,
}


REQUIRED = {"tag"}


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
