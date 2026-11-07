"""GENERATED — DO NOT EDIT. Input validation for the docker-build action.

Produced by _validation/generate.py from _validation/kit.py + _validation/spec.py.
Run `make update-validators` to regenerate. Pure stdlib, no third-party deps — the action
runs it with `python3 validate.py`.

Each check returns None when the value is acceptable or a short reason otherwise. Empty
values pass (inputs are optional unless listed in REQUIRED). The runner has already expanded
every expression in INPUT_*, so all other values are checked as literal data. Inputs named in
MASKED_INPUTS are masked in the job's logs before any check runs.
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


def _enum_list(value: str, allowed: tuple[str, ...], *, fold: bool = False) -> list[str]:
    """Return the comma-split items of value not in allowed (optionally case-folded)."""
    items = _split_items(value)
    if fold:
        items = [item.lower() for item in items]
    return [item for item in items if item and item not in allowed]


def _int_in_range(value: str, low: int, high: int) -> str | None:
    """Accept ``value`` iff it is an integer within ``[low, high]``."""
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


def _comma_key_value_error(value: str, value_pattern: str) -> str | None:
    """Check a one-line list of comma-separated ``KEY=VALUE`` items.

    Mirrors the consumer, which splits on commas only and trims each item: a VALUE may hold
    spaces but no comma, and whitespace around items (``A=1, B=2``, a YAML block scalar's
    trailing newline) is ignored. A line break anywhere else is rejected. Bad items are named
    by position, so a build argument's value never reaches the log.
    """
    if _skip(value):
        return None
    if meta := _shell_meta_error(value):
        return meta
    if re.search(r"[\x00-\x08\x0a-\x1f\x7f]", value.strip()):
        return "must be a single line without control characters"
    for position, item in enumerate(value.split(","), start=1):
        item = item.strip()
        if item and not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*=" + value_pattern, item):
            return f"item {position} is not a valid KEY=VALUE pair"
    return None


def check_boolean(value: str) -> str | None:
    """Boolean flag — ``true`` or ``false`` (any case)."""
    if _skip(value) or value.lower() in ("true", "false"):
        return None
    return 'must be "true" or "false"'


def check_cache_config(value: str) -> str | None:
    """One buildx cache spec: ``type=<backend>[,key=value...]`` (e.g. ``type=gha,mode=max``).

    The spec reaches buildx as one argument, which parses it as one CSV record, so a value
    holds no whitespace, comma or quote. Keys are the ones each backend documents at
    https://docs.docker.com/build/cache/backends/ and in the BuildKit README.
    """
    if _skip(value):
        return None
    match = re.fullmatch(
        r"type=([a-z0-9-]+)((?:,[a-z0-9._-]+=[A-Za-z0-9._~:;/@+=%#?&\[\]-]+)*)", value.strip()
    )
    if not match:
        return "must be one spec, type=<backend>[,key=value...], without spaces or newlines"
    common = ("mode", "ignore-error")
    compression = ("compression", "compression-level", "force-compression")
    image = ("oci-mediatypes", "image-manifest")
    storage = ("prefix", "blobs_prefix", "manifests_prefix", "name", "secret_access_key")
    backends = {
        "registry": (*common, *compression, *image, "ref", "registry.insecure"),
        "local": (*common, *compression, *image, "src", "dest", "digest", "tag", "reset"),
        "gha": (
            *common,
            *compression,
            "url",
            "url_v2",
            "token",
            "scope",
            "timeout",
            "repository",
            "ghtoken",
            "version",
        ),
        "inline": common,
        "s3": (
            *common,
            *compression,
            *storage,
            "region",
            "bucket",
            "endpoint_url",
            "use_path_style",
            "access_key_id",
            "session_token",
            "touch_refresh",
            "upload_parallelism",
            "disable_accept_encoding",
            "retry_mode",
            "retry_max_attempts",
        ),
        "azblob": (*common, *compression, *storage, "account_url", "account_name", "container"),
    }
    backend = match.group(1)
    if backend not in backends:
        return "cache backend must be one of: " + ", ".join(backends)
    for field in match.group(2).split(",")[1:]:
        key = field.split("=", 1)[0]
        if key not in backends[backend]:
            return f"type={backend} does not accept the key {key}"
    return None


def check_cache_mode(value: str) -> str | None:
    """Docker buildx cache mode."""
    return _enum(value, "max", "min", "inline")


def check_comma_key_value_list(value: str) -> str | None:
    """One line of comma-separated ``KEY=VALUE`` items; a VALUE may be empty or hold spaces."""
    return _comma_key_value_error(value, ".*")


def check_comma_name_path_list(value: str) -> str | None:
    """One line of comma-separated ``name=path`` items; the path may hold spaces."""
    return _comma_key_value_error(value, ".+")


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


def check_docker_tag(value: str) -> str | None:
    """Docker tag: alphanumeric start/end with ``-._:/@`` inside (e.g. ``v1.0.0``, ``latest``)."""
    if _skip(value):
        return None
    if re.fullmatch(r"[a-zA-Z0-9]([-a-zA-Z0-9._:/@]*[a-zA-Z0-9])?", value):
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
    if _skip(value) or value.lower() == "latest":
        return None
    core = value[1:] if value[:1] in ("v", "V") else value
    if _is_semver(core):
        return None
    return 'must be a semantic version (e.g. 1.2.3, 1.2.3-rc.1, 1.2, 1, or "latest")'


ACTION = "docker-build"

CHECKS = {
    "architectures": check_docker_architectures,
    "auto-detect-platforms": check_boolean,
    "build-args": check_comma_key_value_list,
    "build-contexts": check_comma_name_path_list,
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
    "secrets": check_comma_name_path_list,
    "sign-image": check_boolean,
    "tag": check_docker_tag,
    "token": check_github_token,
    "verbose": check_boolean,
}


REQUIRED = {"tag"}


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
