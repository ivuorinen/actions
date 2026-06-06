"""GENERATED — DO NOT EDIT. Input validation for the npm-semantic-release action.

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


def check_scope(value: str) -> str | None:
    """Npm scope — ``@`` followed by a lowercase name (e.g. ``@my-org``)."""
    if _skip(value):
        return None
    if not value.startswith("@"):
        return 'must start with "@" (e.g. @my-org)'
    if re.match(r"^[a-z][a-z0-9._~-]*$", value[1:]):
        return None
    return "scope name must start with a lowercase letter (e.g. @my-org)"


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


ACTION = "npm-semantic-release"

CHECKS = {
    "extra_plugins": check_plugin_list,
    "github_token": check_github_token,
    "node-version": check_node_version,
    "npm_token": check_github_token,
    "registry-url": check_url,
    "scope": check_scope,
}


REQUIRED = {"npm_token"}


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
