"""GENERATED — DO NOT EDIT. Input validation for the npm-semantic-release action.

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


ACTION = "npm-semantic-release"

CHECKS = {
    "extra_plugins": check_npm_spec_list,
    "github_token": check_github_token,
    "node-version": check_node_version,
    "npm_token": check_opaque_token,
    "registry-url": check_registry_url,
    "scope": check_scope,
}


REQUIRED = {"npm_token"}


MASKED_INPUTS: list[str] = ["github_token", "npm_token"]


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
