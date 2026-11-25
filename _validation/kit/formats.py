"""Checks for enums, lists, numbers and other formats.

The module contract a docstring names is the kit's, in ``__init__.py``, and each generated
validator restates it in its own docstring.
"""

from __future__ import annotations

import re

from .common import _enum, _enum_list, _shell_meta_error, _skip, _split_items


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


def check_jactionlint_profile(value: str) -> str | None:
    """Rule profile for jactionlint: correctness, or default with its other rules."""
    return _enum(value, "correctness", "default")


def check_report_format(value: str) -> str | None:
    """Lint/report output format. A blank is refused for the reason in the module contract."""
    if _skip(value):
        return "must not be blank: leave the input out for its default"
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


def check_golangci_report_format(value: str) -> str | None:
    """A go-lint report format: golangci-lint v2's sarif, json or text, or a v1 name for text.

    go-lint counts the issues in these three; v2 has no github-actions, line-number or
    colored-line-number format, so go-lint writes text for them. A blank is refused for the
    reason in the module contract.
    """
    if _skip(value):
        return "must not be blank: leave the input out for its default"
    return _enum(
        value, "colored-line-number", "github-actions", "json", "line-number", "sarif", "text"
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


def _npm_tarball(item: str) -> bool:
    """Whether npm reads a package spec as a tarball on disk rather than a registry package.

    It does for one ending in .tgz, .tar.gz or .tar (npm-package-arg's isFilespec).
    """
    return re.search(r"\.(?:tgz|tar\.gz|tar)$", item, re.IGNORECASE) is not None


def check_plugin_list(value: str) -> str | None:
    """Comma-separated plugin specs: name, @scope/name, optional @version (e.g. pkg@^9.3.1).

    A spec npm would read as a tarball on disk (``x.tgz``, ``x@1.tgz``) is not a registry plugin.
    """
    if _skip(value):
        return None
    for item in _split_items(value):
        if not item:
            return "plugin list must not contain empty entries"
        if not re.fullmatch(r"(@[a-zA-Z0-9][\w.-]*/)?[a-zA-Z0-9][\w.-]*(@[\w.^~*+-]+)?", item):
            return f"invalid plugin spec: {item}"
        if _npm_tarball(item):
            return f"plugin spec names a tarball file, not a registry package: {item}"
    return None


def check_npm_spec_list(value: str) -> str | None:
    """Whitespace- or newline-separated npm specs: name, @scope/name, optional @version.

    This is how cycjimmy/semantic-release-action splits ``extra_plugins``. Its v6 hands the list
    to a shell, so the pattern is ASCII-only and leaves out ``<`` and ``>``. It stays separate
    from ``plugin_list``, whose pattern prettier-lint relies on. A spec npm would read as a
    tarball on disk is refused, as there.
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
        if _npm_tarball(item):
            return f"npm package spec names a tarball file, not a registry package: {item}"
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
    """Tag/release prefix — letters, digits and ``._-`` only, and no leading ``-``.

    The prefix begins the release tag, so a leading ``-`` would make a command read the tag as
    an option.
    """
    if _skip(value):
        return None
    if value.startswith("-"):
        return "must not start with -"
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
    if _skip(value):
        return "must be an integer between 1 and 10"
    return _int_in_range(value, 1, 10)


def check_numeric_range_1_100(value: str) -> str | None:
    """Integer in [1, 100] (image quality, which sharp takes from 1)."""
    return _int_in_range(value, 1, 100)


def check_numeric_range_1_128(value: str) -> str | None:
    """Integer in [1, 128] (e.g. CodeQL threads)."""
    return _int_in_range(value, 1, 128)


def check_numeric_range_256_32768(value: str) -> str | None:
    """Integer in [256, 32768] (e.g. CodeQL RAM in MB)."""
    return _int_in_range(value, 256, 32768)


def check_numeric_range_0_10000(value: str) -> str | None:
    """Integer in [0, 10000] (e.g. max lint warnings)."""
    return _int_in_range(value, 0, 10000)


def check_composer_args(value: str) -> str | None:
    """Space-separated ``composer install`` options, each one on an allow-list.

    An allow-list because Composer accepts abbreviated long options, so a block-list could
    not catch every spelling of an option that moves the install. Left out on purpose:
    options that change the working directory, turn off Composer's security blocking, or
    leave no usable ``vendor/`` for the rest of the action.
    """
    if _skip(value):
        return None
    flags = (
        "--ansi",
        "--apcu-autoloader",
        "--audit",
        "--classmap-authoritative",
        "--dev",
        "--ignore-platform-reqs",
        "--no-ansi",
        "--no-cache",
        "--no-dev",
        "--no-interaction",
        "--no-plugins",
        "--no-progress",
        "--no-scripts",
        "--no-suggest",
        "--optimize-autoloader",
        "--prefer-dist",
        "--prefer-source",
        "--profile",
        "--quiet",
        "--strict-psr-autoloader",
        "--verbose",
        "-a",
        "-n",
        "-o",
        "-q",
        "-v",
        "-vv",
        "-vvv",
    )
    flags_with_value = (
        r"--apcu-autoloader-prefix=[A-Za-z0-9._-]+"
        r"|--audit-format=(?:table|plain|json|summary)"
        r"|--ignore-platform-req=[A-Za-z0-9*._-]+\+?"
        r"|--prefer-install=(?:dist|source|auto)"
    )
    for word in value.split(" "):
        if word and word not in flags and not re.fullmatch(flags_with_value, word):
            return f"{word!r} is not an accepted Composer install option"
    return None


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
    """Output directory below the workspace — no absolute path, ``..``, ``~`` or the workspace.

    ``github/codeql-action/analyze`` deletes this directory before writing to it, so a value
    that leaves the workspace, or names the workspace itself, deletes that instead.
    """
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
    if not re.fullmatch(r"[a-zA-Z0-9._/\-@+]+", value):
        return "contains invalid path characters"
    if not value.strip("./"):
        return "must name a directory below the workspace, not the workspace itself"
    return None
