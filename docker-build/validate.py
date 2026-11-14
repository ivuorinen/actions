"""GENERATED — DO NOT EDIT. Input validation for the docker-build action.

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


def _strip_v(version: str) -> str:
    """Return version without one leading ``v`` or ``V``."""
    return version[1:] if version[:1] in ("v", "V") else version


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
    """Accept ``value`` iff it is plain digits within ``[low, high]``.

    ``int()`` alone is too lenient: it takes ``1_0`` and non-ASCII digits, on which a shell
    integer test errors, and inside a ``while`` condition that error just ends the loop.
    """
    if _skip(value):
        return None
    if re.fullmatch(r"[0-9]{1,18}", value) and low <= int(value) <= high:
        return None
    return f"must be an integer between {low} and {high}"


def _is_docker_tag(tag: str) -> bool:
    """Return True if ``tag`` follows the tag rule of the Distribution reference grammar.

    A letter, digit or ``_``, then up to 127 of those, ``.`` or ``-``.
    """
    return re.fullmatch(r"[A-Za-z0-9_][A-Za-z0-9_.-]{0,127}", tag) is not None


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
        # Only what the action's shell trim removes, so the name checked is the name used.
        item = item.strip(" \t\n\v\f\r")
        if item and not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*=" + value_pattern, item):
            return f"item {position} is not a valid KEY=VALUE pair"
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


def check_boolean(value: str) -> str | None:
    """Boolean flag — exactly ``true`` or ``false``.

    Shell steps test ``[ "$FLAG" = "true" ]``, which is case-sensitive, while ``if:`` expressions
    are not, so ``True`` or a blank would have the two halves of an action disagree. A blank is
    refused for the reason in the module contract.
    """
    if value in ("true", "false"):
        return None
    return 'must be "true" or "false" (lowercase)'


def check_cache_config(value: str) -> str | None:
    """One buildx cache spec: ``type=<backend>[,key=value...]`` (e.g. ``type=gha,mode=max``).

    The spec reaches buildx as one argument, which parses it as one CSV record, so a value
    holds no comma or quote, and only a local ``src`` or ``dest`` path may hold spaces. Keys
    are the ones each backend documents at https://docs.docker.com/build/cache/backends/ and
    in the BuildKit README.
    """
    if _skip(value):
        return None
    match = re.fullmatch(
        r"type=([a-z0-9-]+)((?:,[a-z0-9._-]+=[A-Za-z0-9._~:;/@+=%#?&\[\] -]+)*)", value.strip()
    )
    if not match:
        return "must be one spec, type=<backend>[,key=value...], on one line"
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
        key, field_value = field.split("=", 1)
        if key not in backends[backend]:
            return f"type={backend} does not accept the key {key}"
        if " " in field_value and key not in ("src", "dest"):
            return f"the value of {key} must not contain spaces"
    return None


def check_cache_mode(value: str) -> str | None:
    """Docker buildx cache mode."""
    return _enum(value, "max", "min", "inline")


def check_comma_key_value_list(value: str) -> str | None:
    """One line of comma-separated ``KEY=VALUE`` items; a VALUE may be empty or hold spaces."""
    return _comma_key_value_error(value, ".*")


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


def check_docker_build_contexts(value: str) -> str | None:
    """``name=source`` build contexts — paths stay in the workspace, references pass through."""
    return _docker_named_sources_error(value, contexts=True)


def check_docker_image_name(value: str) -> str | None:
    """Docker image reference: lowercase name with optional registry/namespace path."""
    if _skip(value):
        return None
    if re.fullmatch(
        r"[a-z0-9]+((\.|_|__|-+)[a-z0-9]+)*(/[a-z0-9]+((\.|_|__|-+)[a-z0-9]+)*)*", value
    ):
        return None
    return "must be a lowercase Docker image name (e.g. myapp, registry.example.com/ns/app)"


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


def check_docker_local_path(value: str) -> str | None:
    """Docker ``context`` / ``dockerfile`` — a path in the workspace, never a remote source."""
    if _skip(value):
        return None
    return _docker_local_path_error(value)


def check_docker_secrets(value: str) -> str | None:
    """``id=path`` build secrets — each path is a file in the workspace."""
    return _docker_named_sources_error(value, contexts=False)


def check_docker_tag(value: str) -> str | None:
    """Docker tag, per the Distribution reference grammar (e.g. ``v1.0.0``, ``latest``).

    A letter, digit or ``_``, then up to 127 of those, ``.`` or ``-``. So no registry or path
    part, and no SemVer ``+build`` metadata.
    """
    if _skip(value) or _is_docker_tag(value):
        return None
    return "must be a valid Docker tag (e.g. v1.0.0, latest, sha-1234567)"


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
    """Integer in [1, 10] (retry counts); blank is refused, see the module contract."""
    if value.strip() == "":
        return "must be an integer between 1 and 10"
    return _int_in_range(value, 1, 10)


def check_sbom_format(value: str) -> str | None:
    """SBOM format: BuildKit attestations are SPDX JSON only, so no other value can be honored."""
    return _enum(value, "spdx-json")


def check_semantic_version(value: str) -> str | None:
    """SemVer with optional v prefix: X.Y.Z[-pre][+build], partial X.Y / X, or latest."""
    if _skip(value) or value.lower() == "latest":
        return None
    if _is_semver(_strip_v(value)):
        return None
    return 'must be a semantic version (e.g. 1.2.3, 1.2.3-rc.1, 1.2, 1, or "latest")'


ACTION = "docker-build"

CHECKS = {
    "architectures": check_docker_architectures,
    "auto-detect-platforms": check_boolean,
    "build-args": check_comma_key_value_list,
    "build-contexts": check_docker_build_contexts,
    "buildkit-version": check_docker_image_version,
    "buildx-version": check_semantic_version,
    "cache-export": check_cache_config,
    "cache-from": check_cache_config,
    "cache-import": check_cache_config,
    "cache-mode": check_cache_mode,
    "context": check_docker_local_path,
    "dockerfile": check_docker_local_path,
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
    "secrets": check_docker_secrets,
    "sign-image": check_boolean,
    "tag": check_docker_tag,
    "token": check_github_token,
    "verbose": check_boolean,
}


REQUIRED = {"tag"}


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
