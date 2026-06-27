"""Canonical input-validation kit — the single source of truth for ivuorinen/actions.

BUILD-TIME ONLY. Every action ships a generated, self-contained ``validate.py`` produced
by ``_validation/generate.py`` (``make update-validators``). The generator inlines the
*exact source* of the checks an action needs — so these functions, their regexes, and
their allow-lists are defined here once and nowhere else. Regenerating keeps every copy
byte-identical (a drift test enforces it), which is how "each action is self-contained"
and "never duplicate a validation pattern" hold at the same time.

Every check has the signature ``check_<type>(value: str) -> str | None`` and returns
``None`` when the value is acceptable, or a short human-readable reason when it is not.

Shared contract — the ``_skip`` gate, applied first by nearly every check:
  * an empty / whitespace value is accepted: inputs are optional unless the action marks
    them required (the generated runner enforces "required" on its own, before calling
    the check), and
  * a GitHub Actions expression (``${{ ... }}``) is accepted unchanged, because its real
    value is substituted at runtime and cannot be inspected here.

Security-critical checks (tokens, file paths, injection-bearing lists, URLs) are ported
faithfully from the previous validator framework so external callers see no change in what
is accepted or rejected. Tool-version and enum format checks are written to match what each
underlying tool actually accepts.
"""

from __future__ import annotations

import re

# --------------------------------------------------------------------------------------
# Shared preamble helpers. The generator emits only the helpers a given action's checks
# reference, so a boolean-only validator never carries the numeric-range helper, etc.
# --------------------------------------------------------------------------------------


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


# --------------------------------------------------------------------------------------
# Tokens & secrets
# --------------------------------------------------------------------------------------


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


# --------------------------------------------------------------------------------------
# Versions
# --------------------------------------------------------------------------------------


def check_semantic_version(value: str) -> str | None:
    """SemVer with optional v prefix: X.Y.Z[-pre][+build], partial X.Y / X, or latest."""
    if _skip(value) or value.strip().lower() == "latest":
        return None
    core = value.strip()
    core = core[1:] if core[:1] in ("v", "V") else core
    if _is_semver(core):
        return None
    return 'must be a semantic version (e.g. 1.2.3, 1.2.3-rc.1, 1.2, 1, or "latest")'


def check_strict_semantic_version(value: str) -> str | None:
    """Strict SemVer: exactly ``X.Y.Z`` with optional ``-prerelease`` / ``+build`` (no partials)."""
    if _skip(value) or value.strip().lower() == "latest":
        return None
    if re.match(r"^\d+\.\d+\.\d+(-[0-9A-Za-z.-]+)?(\+[0-9A-Za-z.-]+)?$", value.strip()):
        return None
    return "must be a strict semantic version X.Y.Z (optionally -prerelease / +build)"


def check_no_prefix_version(value: str) -> str | None:
    """SemVer-style version that must NOT carry a leading ``v`` (use ``1.2.3``, not ``v1.2.3``)."""
    if _skip(value):
        return None
    core = value.strip()
    if core[:1] in ("v", "V"):
        return 'must not start with "v" (use 1.2.3, not v1.2.3)'
    if _is_semver(core):
        return None
    return "must be a semantic version without a v prefix (e.g. 1.2.3, 1.2, 1)"


def check_calver_version(value: str) -> str | None:
    """Calendar version: YYYY.MM.DD / .PATCH, YYYY.0M.0D, YY.MM.MICRO, YYYY.MM, or YYYY-MM-DD."""
    if _skip(value):
        return None
    core = value.strip()
    core = core[1:] if core[:1] in ("v", "V") else core
    patterns = (
        r"^\d{4}\.\d{1,2}\.\d{1,2}$",  # YYYY.MM.DD
        r"^\d{4}\.0\d\.0\d$",  # YYYY.0M.0D
        r"^\d{2}\.\d{1,2}\.\d{1,2}$",  # YY.MM.MICRO (micro doubles as a day)
        r"^\d{4}-\d{2}-\d{2}$",  # YYYY-MM-DD
        r"^\d{4}\.\d{1,2}\.\d{3,}$",  # YYYY.MM.PATCH (3+ digit patch, never a day)
        r"^\d{4}\.\d{1,2}$",  # YYYY.MM
    )
    if not any(re.match(pattern, core) for pattern in patterns):
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
    if re.match(r"^\d+(\.\d+)?(\.(\d+|x))?(-[0-9A-Za-z.-]+)?$", value.strip()):
        return None
    return "must be a .NET version (e.g. 8.0, 8.0.100, 8.0.x)"


def check_terraform_version(value: str) -> str | None:
    """Terraform/tflint version: ``X.Y.Z`` with optional ``-prerelease``, or ``latest``."""
    if _skip(value) or value.strip().lower() == "latest":
        return None
    if re.match(r"^v?\d+\.\d+\.\d+(-[0-9A-Za-z.-]+)?$", value.strip()):
        return None
    return 'must be a version like 1.5.7 or "latest"'


def check_node_version(value: str) -> str | None:
    """Node version: 20, 20.1, 20.1.0, a keyword (latest/lts/current/node), or lts/<name>."""
    if _skip(value):
        return None
    low = value.strip().lower()
    if low in ("latest", "lts", "current", "node") or low.startswith("lts/"):
        return None
    if re.match(r"^v?\d+(\.\d+(\.\d+)?)?$", value.strip()):
        return None
    return "must be a Node version (e.g. 20, 20.11.0, lts/*, latest)"


def check_go_version(value: str) -> str | None:
    """Go version: ``1.21``, ``1.21.0``, ``1.21.x``, or a channel keyword (stable/oldstable)."""
    if _skip(value):
        return None
    if value.strip().lower() in ("stable", "oldstable"):
        return None
    if re.match(r"^v?\d+\.\d+(\.\d+|\.x)?$", value.strip()):
        return None
    return "must be a Go version (e.g. 1.21, 1.21.5, stable)"


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


def check_cache_mode(value: str) -> str | None:
    """Docker buildx cache mode."""
    return _enum(value, "max", "min", "inline")


def check_network_mode(value: str) -> str | None:
    """Docker build network mode."""
    return _enum(value, "host", "none", "default")


def check_sbom_format(value: str) -> str | None:
    """SBOM output format."""
    return _enum(value, "spdx-json", "cyclonedx-json")


def check_registry_enum(value: str) -> str | None:
    """Container registry selector."""
    return _enum(value, "dockerhub", "github", "both")


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


def check_namespace_with_lookahead(value: str) -> str | None:
    """Lowercase, dash-separated namespace (e.g. ``my-org``), at most 255 characters."""
    if _skip(value):
        return None
    if len(value) > 255:
        return "must be at most 255 characters"
    if re.match(r"^[a-z0-9]+(?:-[a-z0-9]+)*$", value):
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
    for item in (part.strip() for part in value.split(",")):
        if not item:
            return "query list must not contain empty entries"
        if item not in suites and not re.match(r"^[A-Za-z0-9._/@-]+$", item):
            return f"invalid query reference: {item}"
    return None


def check_codeql_packs(value: str) -> str | None:
    """Comma-separated CodeQL packs (``scope/name`` with optional ``@version``)."""
    if _skip(value):
        return None
    for item in (part.strip() for part in value.split(",")):
        if not item:
            return "pack list must not contain empty entries"
        if not re.match(r"^[a-zA-Z0-9._/-]+(@[a-zA-Z0-9._-]+)?$", item):
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
    if re.match(r"^[A-Za-z0-9_./:-]+$", value):
        return None
    return "must contain only letters, digits, and _./:- characters"


# --------------------------------------------------------------------------------------
# Files & paths
# --------------------------------------------------------------------------------------


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


def check_branch_name(value: str) -> str | None:
    """Git branch/ref name — conservative subset that rejects ref-injection characters."""
    if _skip(value):
        return None
    if any(token in value for token in ("..", "~", "^", ":")):
        return "must not contain .. ~ ^ or :"
    if value.startswith((".", "-", "/")) or value.endswith((".", "/")):
        return "must not start with . - / or end with . /"
    if re.match(r"^[a-zA-Z0-9/_.\-]+$", value):
        return None
    return "may only contain letters, digits, and / _ . -"


def check_file_extensions(value: str) -> str | None:
    """Comma-separated file extensions, each starting with a dot (e.g. ``.js,.ts``)."""
    if _skip(value):
        return None
    for item in (part.strip() for part in value.split(",")):
        if not item:
            return "extension list must not contain empty entries"
        if not re.match(r"^\.[a-zA-Z0-9]+$", item):
            return f"invalid extension: {item} (expected a leading dot, e.g. .ts)"
    return None


def check_path_list(value: str) -> str | None:
    """Comma-separated paths/globs — blocks injection characters and ``..`` traversal."""
    if _skip(value):
        return None
    if meta := _shell_meta_error(value):
        return meta
    for item in (part.strip() for part in value.split(",")):
        if not item:
            continue
        if ".." in item:
            return f"path traversal (..) is not allowed: {item}"
        if not re.match(r"^[a-zA-Z0-9_\-./*?\[\]{},@~+]+$", item):
            return f"invalid path or glob: {item}"
    return None


# --------------------------------------------------------------------------------------
# Network & identity
# --------------------------------------------------------------------------------------


def check_email(value: str) -> str | None:
    """Email address."""
    if _skip(value):
        return None
    if re.match(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$", value):
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
    if re.match(
        r"^https?://[a-zA-Z0-9.-]+(?:\.[a-zA-Z]{2,})?(?::\d{1,5})?(?:[/?#][^\s<>]*)?$", value
    ):
        return None
    return "must be a valid http(s) URL"


def check_scope(value: str) -> str | None:
    """Npm scope — ``@`` followed by a lowercase name (e.g. ``@my-org``)."""
    if _skip(value):
        return None
    if not value.startswith("@"):
        return 'must start with "@" (e.g. @my-org)'
    if re.match(r"^[a-z][a-z0-9._~-]*$", value[1:]):
        return None
    return "scope name must start with a lowercase letter (e.g. @my-org)"


def check_username(value: str) -> str | None:
    """Username/handle — alphanumeric with internal ``-``/``_``, at most 39 characters."""
    if _skip(value):
        return None
    if len(value) > 39:
        return "must be at most 39 characters"
    if re.match(r"^[a-zA-Z0-9](?:[a-zA-Z0-9_-]*[a-zA-Z0-9])?$", value):
        return None
    return "may only contain letters, digits, and internal - or _"


# --------------------------------------------------------------------------------------
# Enums, lists & misc formats
# --------------------------------------------------------------------------------------


def check_boolean(value: str) -> str | None:
    """Boolean flag — ``true`` or ``false`` (any case)."""
    if _skip(value) or value.strip().lower() in ("true", "false"):
        return None
    return 'must be "true" or "false"'


def check_repository_list(value: str) -> str | None:
    """Newline-separated ``owner/repo`` targets for cross-repo label sync."""
    if _skip(value):
        return None
    bad = [
        line.strip()
        for line in value.splitlines()
        if line.strip() and not re.fullmatch(r"[A-Za-z0-9._-]+/[A-Za-z0-9._-]+", line.strip())
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
    for item in (part.strip() for part in value.split(",")):
        if not item:
            return "linter list must not contain empty entries"
        if not re.match(r"^[a-zA-Z0-9_-]+$", item):
            return f"invalid linter name: {item}"
    return None


def check_plugin_list(value: str) -> str | None:
    """Comma/pipe-separated plugin specs: name, @scope/name, optional @version (e.g. pkg@^9.3.1)."""
    if _skip(value):
        return None
    for item in (part.strip() for part in re.split(r"[,|]", value)):
        if not item:
            return "plugin list must not contain empty entries"
        if not re.fullmatch(r"(@[a-zA-Z0-9][\w.-]*/)?[a-zA-Z0-9][\w.-]*(@[\w.^~*+-]+)?", item):
            return f"invalid plugin spec: {item}"
    return None


def check_php_extensions(value: str) -> str | None:
    """Comma-separated PHP extension names."""
    if _skip(value):
        return None
    for item in (part.strip() for part in value.split(",")):
        if not item:
            return "extension list must not contain empty entries"
        if not re.match(r"^[a-zA-Z0-9_ ]+$", item):
            return f"invalid PHP extension: {item}"
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


def check_timeout_with_unit(value: str) -> str | None:
    """Duration with a unit (e.g. ``5m``, ``30s``, ``500ms``)."""
    if _skip(value):
        return None
    if re.match(r"^[0-9]+(ns|us|µs|ms|s|m|h)$", value):
        return None
    return "must be a duration with a unit (e.g. 30s, 5m, 1h)"


def check_prefix(value: str) -> str | None:
    """Tag/release prefix — letters, digits and ``._-`` only."""
    if _skip(value):
        return None
    if any(char in value for char in (" ", "@", "#", ":")):
        return "must not contain spaces or @ # :"
    if re.match(r"^[a-zA-Z0-9._-]+$", value):
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
    try:
        number = int(value.strip())
    except ValueError:
        return "must be a positive integer (> 0)"
    if number > 0:
        return None
    return "must be a positive integer (> 0)"


def check_numeric_range_1_10(value: str) -> str | None:
    """Integer in [1, 10] (e.g. retry counts)."""
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
    """Opaque license key — a ``${{ }}`` expression, a ``$VAR`` reference, or a single token."""
    if _skip(value) or _is_env_ref(value):
        return None
    if re.fullmatch(r"[A-Za-z0-9+/=._-]+", value):
        return None
    return (
        "must be an opaque key (letters, digits, + / = . _ -), "
        "a ${{ }} expression, or a $VAR reference"
    )


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
