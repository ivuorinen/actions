"""Checks for network addresses and identities."""

from __future__ import annotations

import re

from .common import _skip


def check_email(value: str) -> str | None:
    """Email address."""
    if _skip(value):
        return None
    if re.fullmatch(r"[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}", value):
        return None
    return "must be a valid email address (e.g. user@example.com)"


def check_registry_url(value: str) -> str | None:
    """Npm registry URL — the publish token is sent to it, so it must be encrypted.

    Requires ``https://``. Plain ``http://`` is accepted only for the exact loopback hosts
    ``localhost`` and ``127.0.0.1`` (a local test registry such as Verdaccio), where the
    token stays on the machine. Only a host, port and path are accepted: credentials in the
    URL leak into logs, and npm appends package names to the URL, so a query or fragment
    cannot be part of a working registry.
    """
    if _skip(value):
        return None
    if any(token in value for token in (";", "|", "`", "$(", "${", "..")):
        return "must not contain injection characters"
    lowered = value.lower()
    if any(enc in lowered for enc in ("%0d", "%0a", "%00", "%2e")):
        return "must not contain encoded control or traversal sequences"
    match = re.fullmatch(
        r"(?:https://[a-zA-Z0-9.-]+|http://(?:localhost|127\.0\.0\.1))"
        r"(?::([0-9]{1,5}))?(?:/[^\s<>?#\\]*)?",
        value,
    )
    if match and int(match[1] or 0) <= 65535:
        return None
    return "must be https://host[:port][/path] (http:// only for localhost or 127.0.0.1)"


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
