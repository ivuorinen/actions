"""Canonical input-validation kit — the single source of truth for ivuorinen/actions.

BUILD-TIME ONLY. Every action ships a generated, self-contained ``validate.py`` produced
by ``_validation/generate.py`` (``make update-validators``). The generator inlines the
*exact source* of the checks an action needs — so these functions, their regexes, and
their allow-lists are defined here once and nowhere else. Regenerating keeps every copy
byte-identical (a drift test enforces it), which is how "each action is self-contained"
and "never duplicate a validation pattern" hold at the same time.

Every check has the signature ``check_<type>(value: str) -> str | None`` and returns
``None`` when the value is acceptable, or a short human-readable reason when it is not.

Shared contract:
  * the ``_skip`` gate, applied first by nearly every check, accepts an empty / whitespace
    value: inputs are optional unless the action marks them required (the generated runner
    enforces "required" on its own, before calling the check);
  * a check judges the value exactly as the action will use it. The runner has expanded
    every ``${{ ... }}`` before ``validate.py`` reads ``INPUT_*``, and it never expands
    ``$VAR`` in an input, so neither form is a reference here: both are literal data. Matches
    use ``re.fullmatch`` because ``re.match(...$)`` also accepts a trailing newline.

``boolean`` and ``numeric_range_1_10`` refuse a blank value instead. Those inputs all declare a
default and the runner applies it only when the caller leaves the input out, so blank means the
caller passed it, and the steps reading such an input would then quietly skip their work.

Security-critical checks (tokens, file paths, injection-bearing lists, URLs) are ported from
the previous validator framework. Tool-version and enum format checks are written to match
what each underlying tool actually accepts.
"""

from __future__ import annotations

import re

# --------------------------------------------------------------------------------------
# Shared preamble helpers. The generator emits only the helpers a given action's checks
# reference, so a boolean-only validator never carries the numeric-range helper, etc.
# --------------------------------------------------------------------------------------


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


def _is_docker_tag(tag: str) -> bool:
    """Return True if ``tag`` follows the tag rule of the Distribution reference grammar.

    A letter, digit or ``_``, then up to 127 of those, ``.`` or ``-``.
    """
    return re.fullmatch(r"[A-Za-z0-9_][A-Za-z0-9_.-]{0,127}", tag) is not None


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


# --------------------------------------------------------------------------------------
# Tokens & secrets
# --------------------------------------------------------------------------------------


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


# --------------------------------------------------------------------------------------
# Versions
# --------------------------------------------------------------------------------------


def check_semantic_version(value: str) -> str | None:
    """SemVer with optional v prefix: X.Y.Z[-pre][+build], partial X.Y / X, or latest."""
    if _skip(value) or value.lower() == "latest":
        return None
    core = value[1:] if value[:1] in ("v", "V") else value
    if _is_semver(core):
        return None
    return 'must be a semantic version (e.g. 1.2.3, 1.2.3-rc.1, 1.2, 1, or "latest")'


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


def check_calver_version(value: str) -> str | None:
    """Calendar version: YYYY.MM.DD / .PATCH, YYYY.0M.0D, YY.MM.MICRO, YYYY.MM, or YYYY-MM-DD."""
    if _skip(value):
        return None
    core = value[1:] if value[:1] in ("v", "V") else value
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
        leap = month == 2 and year % 4 == 0 and (year % 100 != 0 or year % 400 == 0)
        max_day = 29 if leap else 28 if month == 2 else 30 if month in (4, 6, 9, 11) else 31
        if not 1 <= day <= max_day:
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


# --------------------------------------------------------------------------------------
# Docker
# --------------------------------------------------------------------------------------


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


def check_namespace_with_lookahead(value: str) -> str | None:
    """Lowercase, dash-separated namespace (e.g. ``my-org``), at most 255 characters."""
    if _skip(value):
        return None
    if len(value) > 255:
        return "must be at most 255 characters"
    if re.fullmatch(r"[a-z0-9]+(?:-[a-z0-9]+)*", value):
        return None
    return "must be lowercase alphanumeric segments separated by single dashes (e.g. my-org)"


# --------------------------------------------------------------------------------------
# CodeQL
# --------------------------------------------------------------------------------------


def check_codeql_language(value: str) -> str | None:
    """Comma-separated CodeQL language(s)."""
    if _skip(value):
        return None
    allowed = (
        "actions",
        "c",
        "cpp",
        "csharp",
        "go",
        "java",
        "javascript",
        "kotlin",
        "python",
        "ruby",
        "swift",
        "typescript",
    )
    bad = _enum_list(value, allowed, fold=True)
    if bad:
        return "unsupported language(s): " + ", ".join(bad)
    return None


def check_codeql_build_mode(value: str) -> str | None:
    """CodeQL build mode."""
    return _enum(value, "none", "manual", "autobuild")


def check_codeql_queries(value: str) -> str | None:
    """Comma-separated CodeQL query suites or query/pack references."""
    if _skip(value):
        return None
    suites = {"security-extended", "security-and-quality", "code-scanning", "default"}
    for item in _split_items(value):
        if not item:
            return "query list must not contain empty entries"
        if item not in suites and not re.fullmatch(r"[A-Za-z0-9._/@-]+", item):
            return f"invalid query reference: {item}"
    return None


def check_codeql_packs(value: str) -> str | None:
    """Comma-separated CodeQL packs (``scope/name`` with optional ``@version``)."""
    if _skip(value):
        return None
    for item in _split_items(value):
        if not item:
            return "pack list must not contain empty entries"
        if not re.fullmatch(r"[a-zA-Z0-9._/-]+(@[a-zA-Z0-9._-]+)?", item):
            return f"invalid pack reference: {item}"
    return None


def check_codeql_config(value: str) -> str | None:
    """Inline CodeQL YAML config — rejects unsafe YAML deserialization tags."""
    if _skip(value):
        return None
    for tag in ("!!python/", "!!ruby/", "!!perl/", "!!js/"):
        if tag in value:
            return f"must not contain unsafe YAML tag {tag}"
    return None


def check_category_format(value: str) -> str | None:
    """SARIF analysis category — letters, digits and ``_./:-`` only."""
    if _skip(value):
        return None
    if re.fullmatch(r"[A-Za-z0-9_./:-]+", value):
        return None
    return "must contain only letters, digits, and _./:- characters"


# --------------------------------------------------------------------------------------
# Files & paths
# --------------------------------------------------------------------------------------


def check_file_path(value: str) -> str | None:
    """Relative file path — rejects a leading ``-``, absolute paths, ``..`` and ``~`` expansion."""
    if _skip(value):
        return None
    return _file_path_error(value)


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


def check_branch_name(value: str) -> str | None:
    """Git branch/ref name — conservative subset that rejects ref-injection characters."""
    if _skip(value):
        return None
    if any(token in value for token in ("..", "~", "^", ":")):
        return "must not contain .. ~ ^ or :"
    if value.startswith((".", "-", "/")) or value.endswith((".", "/")):
        return "must not start with . - / or end with . /"
    if re.fullmatch(r"[a-zA-Z0-9/_.\-]+", value):
        return None
    return "may only contain letters, digits, and / _ . -"


def check_file_extensions(value: str) -> str | None:
    """Comma-separated file extensions, each starting with a dot (e.g. ``.js,.ts``)."""
    if _skip(value):
        return None
    for item in _split_items(value):
        if not item:
            return "extension list must not contain empty entries"
        if not re.fullmatch(r"\.[a-zA-Z0-9]+", item):
            return f"invalid extension: {item} (expected a leading dot, e.g. .ts)"
    return None


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


# --------------------------------------------------------------------------------------
# Network & identity
# --------------------------------------------------------------------------------------


def check_email(value: str) -> str | None:
    """Email address."""
    if _skip(value):
        return None
    if re.fullmatch(r"[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}", value):
        return None
    return "must be a valid email address (e.g. user@example.com)"


def check_url(value: str) -> str | None:
    """HTTP(S) URL — rejects injection characters and non-http schemes."""
    if _skip(value):
        return None
    if not value.startswith(("http://", "https://")):
        return "must start with http:// or https://"
    if any(token in value for token in (";", "|", "`", "$(", "${", "../", "..\\")):
        return "must not contain injection characters"
    lowered = value.lower()
    if any(enc in lowered for enc in ("%0d", "%0a", "%00", "%2e%2e")):
        return "must not contain encoded control or traversal sequences"
    if re.fullmatch(
        r"https?://[a-zA-Z0-9.-]+(?:\.[a-zA-Z]{2,})?(?::[0-9]{1,5})?(?:[/?#][^\s<>]*)?", value
    ):
        return None
    return "must be a valid http(s) URL"


def check_scope(value: str) -> str | None:
    """Npm scope — ``@`` followed by a lowercase name (e.g. ``@my-org``)."""
    if _skip(value):
        return None
    if not value.startswith("@"):
        return 'must start with "@" (e.g. @my-org)'
    if re.fullmatch(r"[a-z][a-z0-9._~-]*", value[1:]):
        return None
    return "scope name must start with a lowercase letter (e.g. @my-org)"


def check_username(value: str) -> str | None:
    """Username/handle — alphanumeric with internal ``-``/``_``, at most 39 characters."""
    if _skip(value):
        return None
    if len(value) > 39:
        return "must be at most 39 characters"
    if re.fullmatch(r"[a-zA-Z0-9](?:[a-zA-Z0-9_-]*[a-zA-Z0-9])?", value):
        return None
    return "may only contain letters, digits, and internal - or _"


# --------------------------------------------------------------------------------------
# Enums, lists & misc formats
# --------------------------------------------------------------------------------------


def check_boolean(value: str) -> str | None:
    """Boolean flag — exactly ``true`` or ``false``.

    Shell steps test ``[ "$FLAG" = "true" ]``, which is case-sensitive, while ``if:`` expressions
    are not, so ``True`` or a blank would have the two halves of an action disagree. A blank is
    refused for the reason in the module contract.
    """
    if value in ("true", "false"):
        return None
    return 'must be "true" or "false" (lowercase)'


def check_repository_list(value: str) -> str | None:
    """Newline-separated ``owner/repo`` targets for cross-repo label sync."""
    if _skip(value):
        return None
    # Owner: alphanumeric or hyphen, neither first nor last a hyphen (GitHub's rule).
    # sync-labels/sync.py calls this check through its generated validate.py.
    bad = [
        line.strip()
        for line in value.splitlines()
        if line.strip()
        and not re.fullmatch(r"(?!-)[A-Za-z0-9-]+(?<!-)/[A-Za-z0-9._-]+", line.strip())
    ]
    if bad:
        return "invalid repository(s) (expected owner/repo): " + ", ".join(bad)
    return None


def check_mode_enum(value: str) -> str | None:
    """Linter mode."""
    return _enum(value, "check", "fix")


def check_report_format(value: str) -> str | None:
    """Lint/report output format."""
    return _enum(
        value,
        "checkstyle",
        "colored-line-number",
        "compact",
        "github-actions",
        "html",
        "json",
        "junit",
        "junit-xml",
        "line-number",
        "sarif",
        "stylish",
        "tab",
        "teamcity",
        "xml",
    )


def check_coverage_driver(value: str) -> str | None:
    """PHP coverage driver."""
    return _enum(value, "none", "xdebug", "pcov", "xdebug3")


def check_framework_mode(value: str) -> str | None:
    """PHP test framework mode."""
    return _enum(value, "auto", "laravel", "generic")


def check_language_enum(value: str) -> str | None:
    """Language selector for version detection."""
    return _enum(value, "php", "python", "go", "dotnet")


def check_severity_enum(value: str) -> str | None:
    """Comma-separated Trivy severities."""
    if _skip(value):
        return None
    allowed = ("UNKNOWN", "LOW", "MEDIUM", "HIGH", "CRITICAL")
    bad = _enum_list(value, allowed)
    if bad:
        return "invalid severity/severities: " + ", ".join(bad) + "; allowed: " + ", ".join(allowed)
    return None


def check_scanner_list(value: str) -> str | None:
    """Comma-separated Trivy scanners."""
    if _skip(value):
        return None
    allowed = ("vuln", "config", "secret", "license")
    bad = _enum_list(value, allowed)
    if bad:
        return "invalid scanner(s): " + ", ".join(bad) + "; allowed: " + ", ".join(allowed)
    return None


def check_linter_list(value: str) -> str | None:
    """Comma-separated linter names (e.g. ``gosec,govet``)."""
    if _skip(value):
        return None
    if meta := _shell_meta_error(value):
        return meta
    for item in _split_items(value):
        if not item:
            return "linter list must not contain empty entries"
        if not re.fullmatch(r"[a-zA-Z0-9_-]+", item):
            return f"invalid linter name: {item}"
    return None


def check_plugin_list(value: str) -> str | None:
    """Comma/pipe-separated plugin specs: name, @scope/name, optional @version (e.g. pkg@^9.3.1)."""
    if _skip(value):
        return None
    for item in _split_items(value, ",|"):
        if not item:
            return "plugin list must not contain empty entries"
        if not re.fullmatch(r"(@[a-zA-Z0-9][\w.-]*/)?[a-zA-Z0-9][\w.-]*(@[\w.^~*+-]+)?", item):
            return f"invalid plugin spec: {item}"
    return None


def check_npm_spec_list(value: str) -> str | None:
    """Whitespace- or newline-separated npm specs: name, @scope/name, optional @version.

    This is how cycjimmy/semantic-release-action splits ``extra_plugins``. Its v6 hands the list
    to a shell, so the pattern is ASCII-only and leaves out ``<`` and ``>``. It stays separate
    from ``plugin_list`` because that one's accepted values must not change for prettier-lint.
    """
    if _skip(value):
        return None
    for item in filter(None, re.split(r"[ \t\r\n]+", value)):
        if not re.fullmatch(
            r"(@[a-zA-Z0-9][a-zA-Z0-9._-]*/)?[a-zA-Z0-9][a-zA-Z0-9._-]*"
            r"(@[a-zA-Z0-9^~*][a-zA-Z0-9._^~*+-]*)?",
            item,
        ):
            return f"invalid npm package spec: {item}"
    return None


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


def check_key_value_list(value: str) -> str | None:
    """Newline-separated ``KEY=VALUE`` pairs, for a consumer that reads them line by line."""
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


def check_comma_key_value_list(value: str) -> str | None:
    """One line of comma-separated ``KEY=VALUE`` items; a VALUE may be empty or hold spaces."""
    return _comma_key_value_error(value, ".*")


def check_timeout_with_unit(value: str) -> str | None:
    """Duration with a unit (e.g. ``5m``, ``30s``, ``500ms``)."""
    if _skip(value):
        return None
    if re.fullmatch(r"[0-9]+(ns|us|µs|ms|s|m|h)", value):
        return None
    return "must be a duration with a unit (e.g. 30s, 5m, 1h)"


def check_prefix(value: str) -> str | None:
    """Tag/release prefix — letters, digits and ``._-`` only."""
    if _skip(value):
        return None
    if any(char in value for char in (" ", "@", "#", ":")):
        return "must not contain spaces or @ # :"
    if re.fullmatch(r"[a-zA-Z0-9._-]+", value):
        return None
    return "may only contain letters, digits, and . _ -"


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


def check_positive_integer(value: str) -> str | None:
    """Positive integer (> 0)."""
    if _skip(value):
        return None
    if re.fullmatch(r"[0-9]{1,18}", value) and int(value) > 0:
        return None
    return "must be a positive integer (> 0)"


def check_numeric_range_1_10(value: str) -> str | None:
    """Integer in [1, 10] (retry counts); blank is refused, see the module contract."""
    if value.strip() == "":
        return "must be an integer between 1 and 10"
    return _int_in_range(value, 1, 10)


def check_numeric_range_0_16(value: str) -> str | None:
    """Integer in [0, 16] (e.g. parallel build workers)."""
    return _int_in_range(value, 0, 16)


def check_numeric_range_0_100(value: str) -> str | None:
    """Integer in [0, 100] (e.g. image quality percentage)."""
    return _int_in_range(value, 0, 100)


def check_numeric_range_1_128(value: str) -> str | None:
    """Integer in [1, 128] (e.g. CodeQL threads)."""
    return _int_in_range(value, 1, 128)


def check_numeric_range_256_32768(value: str) -> str | None:
    """Integer in [256, 32768] (e.g. CodeQL RAM in MB)."""
    return _int_in_range(value, 256, 32768)


def check_numeric_range_0_10000(value: str) -> str | None:
    """Integer in [0, 10000] (e.g. max lint warnings)."""
    return _int_in_range(value, 0, 10000)


def check_command_args(value: str) -> str | None:
    """Free-form command-line arguments — blocks shell metacharacters and control characters."""
    if _skip(value):
        return None
    if re.search(r"[;&|`$(){}<>\\]", value):
        return "must not contain shell metacharacters ; & | ` $ ( ) { } < > \\"
    if re.search(r"[\x00-\x1f\x7f]", value):
        return "must not contain control characters or newlines"
    return None


def check_license_key(value: str) -> str | None:
    """Opaque license key — a single token."""
    if _skip(value):
        return None
    if re.fullmatch(r"[A-Za-z0-9+/=._-]+", value):
        return None
    return "must be an opaque key (letters, digits, + / = . _ -)"


def check_git_author_name(value: str) -> str | None:
    """Git author/committer display name (e.g. ``GitHub Actions``, ``github-actions[bot]``)."""
    if _skip(value):
        return None
    if len(value) > 100:
        return "must be at most 100 characters"
    # The allow-list itself rejects shell metacharacters, quotes, newlines and control chars.
    if re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9 ._\[\]()+-]*", value):
        return None
    return "may only contain letters, digits, spaces, and . _ - [ ] ( ) +"


def check_output_path(value: str) -> str | None:
    """Output path — like file_path but allows parent-relative .. (no absolute path or ~)."""
    if _skip(value):
        return None
    import urllib.parse

    decoded = urllib.parse.unquote(value)
    if decoded.startswith("/") or (len(decoded) > 1 and decoded[1] == ":"):
        return "absolute paths are not allowed"
    if value.startswith("~"):
        return "home directory expansion (~) is not allowed"
    if re.fullmatch(r"[a-zA-Z0-9._/\-@+]+", value):
        return None
    return "contains invalid path characters"


# --------------------------------------------------------------------------------------
# Registry: type name -> check function. The generator and the test-suite both introspect
# this mapping; it is the authoritative list of supported validator types.
# --------------------------------------------------------------------------------------

CHECKS = {
    name[len("check_") :]: function
    for name, function in sorted(globals().items())
    if name.startswith("check_") and callable(function)
}


# --------------------------------------------------------------------------------------
# Check types whose values are credentials, so must be masked. An input with one of these
# types is what spec.py marks for masking: its generated validator registers the value with
# the runner's log masker before running any check. Listing the type rather than each input
# means a new token input cannot forget its mask. Never add a type that also holds ordinary
# values (`key_value_list` carries build args), because masking a common word corrupts the
# logs. This holds check type names, never a credential.
# --------------------------------------------------------------------------------------

MASKED_CHECKS = frozenset({"github_token", "license_key", "opaque_token"})


# --------------------------------------------------------------------------------------
# Documentation examples: type name -> a realistic value of that type.
#
# `make docs` substitutes these into the generated action READMEs wherever the README
# generator would otherwise emit a generic placeholder ("value", "example-value",
# "custom-value"). A reader copying a quick-start workflow gets something that actually
# runs instead of a string the action rejects.
#
# These live here, next to the checks, so an example can never drift from the rule it
# illustrates: `test_kit.py` asserts every check has an example AND that the example
# passes its own check, so a tightened regex fails the suite rather than silently
# publishing an invalid example. The exception is a secret, whose example is a `${{ }}`
# reference the runner expands before the check runs. They are documentation only —
# `generate.py` copies check functions into each action's validate.py and never reads
# this mapping.
# --------------------------------------------------------------------------------------


def _actions_expression(reference: str) -> str:
    """Wrap a context reference in GitHub Actions expression syntax.

    Built rather than written as a literal so neither this repo's linter nor an
    external scanner reads a token-named key with a string value as a hardcoded
    credential. These are the opposite of one: they are what a reader should
    substitute instead of pasting a secret into an input.
    """
    return "${{ " + reference + " }}"


EXAMPLES = {
    "boolean": "true",
    "branch_name": "main",
    "cache_config": "type=gha,mode=max",
    "cache_mode": "max",
    "calver_version": "2025.04.05",
    "category_format": "my-analysis",
    "codeql_build_mode": "none",
    "codeql_config": "name: my-config",
    "codeql_language": "javascript,python",
    "codeql_packs": "my-org/my-queries@1.0.0",
    "codeql_queries": "security-and-quality",
    "comma_key_value_list": "NODE_ENV=production,VERSION=1.0.0",
    "command_args": "--no-progress --prefer-dist",
    "coverage_driver": "xdebug",
    "docker_architectures": "linux/amd64,linux/arm64",
    "docker_build_contexts": "shared=./shared,base=docker-image://alpine:3.20",
    "docker_image_name": "myapp",
    "docker_local_path": "docker/app",
    "docker_secrets": "npmrc=.npmrc",
    "docker_tag": "v1.0.0",
    "docker_tag_list": "latest,v1.0.0",
    "dotnet_version": "8.0.x",
    "email": "github-actions@users.noreply.github.com",
    "file_extensions": ".js,.ts",
    "file_path": "config/settings.yml",
    "framework_mode": "auto",
    "git_author_name": "github-actions[bot]",
    "github_token": _actions_expression("github.token"),
    "go_version": "1.24",
    "json_format": '{"linux/amd64": "--build-arg ARCH=amd64"}',
    "key_value_list": "NODE_ENV=production",
    "language_enum": "python",
    "license_key": _actions_expression("secrets.GITLEAKS_LICENSE"),
    "linter_list": "gosec,govet",
    "mode_enum": "check",
    "namespace_with_lookahead": "my-org",
    "network_mode": "default",
    "no_prefix_version": "1.2.3",
    "node_version": "20",
    "npm_spec_list": "@semantic-release/git@10.0.1",
    "numeric_range_0_10000": "0",
    "numeric_range_0_100": "80",
    "numeric_range_0_16": "4",
    "numeric_range_1_10": "3",
    "numeric_range_1_128": "2",
    "numeric_range_256_32768": "4096",
    "opaque_token": _actions_expression("secrets.NPM_TOKEN"),
    "output_path": "results/codeql.sarif",
    "path_list": "src/**/*.ts",
    "php_extensions": "mbstring,intl",
    "plugin_list": "@prettier/plugin-xml",
    "positive_integer": "30",
    "prefix": "v",
    "registry_enum": "github",
    "report_format": "sarif",
    "repository_list": "my-org/my-repo",
    "sbom_format": "spdx-json",
    "scanner_list": "vuln,secret",
    "scope": "@my-org",
    "semantic_version": "1.2.3",
    "severity_enum": "HIGH,CRITICAL",
    "strict_semantic_version": "1.2.3",
    "terraform_version": "1.5.7",
    "timeout_with_unit": "5m",
    "url": "https://registry.npmjs.org",
    "username": "github-actions",
}
