"""Checks for Docker images, tags, build sources and buildx settings."""

from __future__ import annotations

import re

from .common import (
    _enum,
    _enum_list,
    _file_path_error,
    _is_semver,
    _shell_meta_error,
    _skip,
    _strip_v,
)


def _is_docker_tag(tag: str) -> bool:
    """Return True if ``tag`` follows the tag rule of the Distribution reference grammar.

    A letter, digit or ``_``, then up to 127 of those, ``.`` or ``-``.
    """
    return re.fullmatch(r"[A-Za-z0-9_][A-Za-z0-9_.-]{0,127}", tag) is not None


def _is_docker_remote_source(value: str) -> bool:
    """Return True for a value buildx fetches instead of reading from the runner.

    Matches buildx ``urlutil.IsRemoteURL`` exactly, because a match skips the path checks: an
    http(s), git or ssh URL, scp-style ``user@host:path``, or a bare ``github.com/...``.
    """
    remote = r"(https?|git|ssh)://|github\.com/|[A-Za-z0-9_-]+@[A-Za-z0-9.-]+:"
    return re.match(remote, value) is not None


def _docker_local_path_error(value: str, *, spaces: bool = False) -> str | None:
    """Return why buildx would not read ``value`` as a path inside the workspace, or None.

    ``://`` and ``@host:`` cover more than buildx fetches today, any scheme and any user part.
    """
    if "://" in value or re.search(r"@[^/]*:", value) or _is_docker_remote_source(value):
        return "remote sources are not allowed, use a path relative to the workspace"
    return _file_path_error(value, spaces=spaces)


def _docker_context_runner_path(source: str) -> str | None:
    """Return the path buildx reads from the runner for a ``--build-context`` value, or None.

    Only a local directory and the path in ``oci-layout://<path>[:tag][@digest]`` are read
    from the runner. buildx hands remote sources, ``docker-image://`` and ``target:`` to the
    builder, so those hold no runner path. docker-build's Check Build Paths step calls this
    through its generated validate.py.
    """
    if source.startswith("oci-layout://"):
        return re.sub(
            r"(:\w[\w.-]*)?(@[\w+.-]+:[0-9a-fA-F]{32,})?$", "", source[len("oci-layout://") :]
        )
    if source.startswith(("docker-image://", "target:")) or _is_docker_remote_source(source):
        return None
    return source


def _docker_context_source_error(source: str) -> str | None:
    """Return why ``source`` is not acceptable as a ``--build-context`` value, or None."""
    path = _docker_context_runner_path(source)
    if path is None:
        # An image reference, build target or URL never holds whitespace.
        return "must not contain whitespace" if re.search(r"\s", source) else None
    return _docker_local_path_error(path, spaces=True)


def _docker_entry_error(entry: str, *, contexts: bool) -> str | None:
    """Return why one ``name=source`` entry is invalid, or None.

    Names are image references for build contexts (``alpine:3.20``) and free-form ids for
    secrets. The action always passes a secret's source as ``src=``, which buildx reads as
    a file even for a value such as ``env=NAME``, so every secret source is a path.
    """
    name, separator, source = entry.partition("=")
    if not separator or not source:
        return f"invalid entry (expected NAME=SOURCE): {entry}"
    if not re.fullmatch(r"[A-Za-z0-9_][A-Za-z0-9_.+/:@-]*", name):
        return f"invalid name: {name}"
    if contexts:
        error = _docker_context_source_error(source)
    else:
        error = _file_path_error(source, spaces=True)
    return f"{name}: {error}" if error else None


def _docker_named_sources_error(value: str, *, contexts: bool) -> str | None:
    """Return why a one-line, comma-separated ``name=source`` list is invalid, or None.

    Mirrors the action, which splits on commas only and trims each entry: whitespace around
    the value (a YAML block scalar's trailing newline) and around entries is ignored, and a
    line break anywhere else is rejected.
    """
    if _skip(value):
        return None
    if meta := _shell_meta_error(value):
        return meta
    if re.search(r"[\x00-\x08\x0a-\x1f\x7f]", value.strip()):
        return "must be a single line without control characters"
    # Only what the action's shell trim removes, so the entry checked is the entry used.
    for entry in (part.strip(" \t\n\v\f\r") for part in value.split(",")):
        if entry and (error := _docker_entry_error(entry, contexts=contexts)):
            return error
    return None


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
    """Docker tag, per the Distribution reference grammar (e.g. ``v1.0.0``, ``latest``).

    A letter, digit or ``_``, then up to 127 of those, ``.`` or ``-``. So no registry or path
    part, and no SemVer ``+build`` metadata.
    """
    if _skip(value) or _is_docker_tag(value):
        return None
    return "must be a valid Docker tag (e.g. v1.0.0, latest, sha-1234567)"


def check_docker_tag_list(value: str) -> str | None:
    """Comma-separated Docker tags (e.g. ``latest,v1.0.0``), with no spaces around the commas.

    Each entry becomes the tag of an ``image:tag`` reference, so it follows the tag rule of the
    Distribution reference grammar: a letter, digit or ``_``, then up to 127 of those, ``.`` or
    ``-``.
    """
    if _skip(value):
        return None
    for tag in value.split(","):
        if not _is_docker_tag(tag):
            return f"invalid Docker tag: {tag!r} (letters, digits, _ . -, at most 128 characters)"
    return None


def check_docker_image_version(value: str) -> str | None:
    """Image tag in SemVer form or ``latest``, optionally pinned ``@sha256:<64 hex>``.

    The tag goes into an ``image:tag`` reference, so it also follows the Docker tag rule, which
    has no room for SemVer ``+build`` metadata.
    """
    if _skip(value):
        return None
    tag, at, digest = value.partition("@")
    if at and not re.fullmatch(r"sha256:[0-9a-f]{64}", digest):
        return "digest must be sha256: followed by 64 lowercase hex characters"
    if _is_docker_tag(tag) and (tag.lower() == "latest" or _is_semver(_strip_v(tag))):
        return None
    return (
        "must be a semantic version without +build metadata, with an optional @sha256 digest"
        " (e.g. v1.2.3@sha256:abc...)"
    )


def check_cache_mode(value: str) -> str | None:
    """Docker buildx cache mode."""
    return _enum(value, "max", "min", "inline")


def check_network_mode(value: str) -> str | None:
    """Docker build network mode."""
    return _enum(value, "host", "none", "default")


def check_sbom_format(value: str) -> str | None:
    """SBOM format: BuildKit attestations are SPDX JSON only, so no other value can be honored."""
    return _enum(value, "spdx-json")


def check_registry_enum(value: str) -> str | None:
    """Container registry selector."""
    return _enum(value, "dockerhub", "github", "both")


def _cache_backends() -> dict[str, tuple[str, ...]]:
    """Return the keys each buildx cache backend accepts, by backend name.

    The keys are the ones each backend documents at https://docs.docker.com/build/cache/backends/
    and in the BuildKit README.
    """
    common = ("mode", "ignore-error")
    compression = ("compression", "compression-level", "force-compression")
    image = ("oci-mediatypes", "image-manifest")
    storage = ("prefix", "blobs_prefix", "manifests_prefix", "name", "secret_access_key")
    return {
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


def check_cache_config(value: str) -> str | None:
    """One buildx cache spec: ``type=<backend>[,key=value...]`` (e.g. ``type=gha,mode=max``).

    The spec reaches buildx as one argument, which parses it as one CSV record, so a value
    holds no comma or quote, and only a local ``src`` or ``dest`` path may hold spaces.
    """
    if _skip(value):
        return None
    match = re.fullmatch(
        r"type=([a-z0-9-]+)((?:,[a-z0-9._-]+=[A-Za-z0-9._~:;/@+=%#?&\[\] -]+)*)", value.strip()
    )
    if not match:
        return "must be one spec, type=<backend>[,key=value...], on one line"
    backends = _cache_backends()
    backend = match.group(1)
    if backend not in backends:
        return "cache backend must be one of: " + ", ".join(backends)
    for field in match.group(2).split(",")[1:]:
        key, field_value = field.split("=", 1)
        if key not in backends[backend]:
            return f"type={backend} does not accept the key {key}"
        if " " in field_value and key not in ("src", "dest"):
            return f"the value of {key} must not contain spaces"
    return None


def check_namespace_with_lookahead(value: str) -> str | None:
    """Lowercase, dash-separated namespace (e.g. ``my-org``), at most 255 characters."""
    if _skip(value):
        return None
    if len(value) > 255:
        return "must be at most 255 characters"
    if re.fullmatch(r"[a-z0-9]+(?:-[a-z0-9]+)*", value):
        return None
    return "must be lowercase alphanumeric segments separated by single dashes (e.g. my-org)"


def check_docker_local_path(value: str) -> str | None:
    """Docker ``context`` / ``dockerfile`` — a path in the workspace, never a remote source."""
    if _skip(value):
        return None
    return _docker_local_path_error(value)


def check_docker_build_contexts(value: str) -> str | None:
    """``name=source`` build contexts — paths stay in the workspace, references pass through."""
    return _docker_named_sources_error(value, contexts=True)


def check_docker_secrets(value: str) -> str | None:
    """``id=path`` build secrets — each path is a file in the workspace."""
    return _docker_named_sources_error(value, contexts=False)
