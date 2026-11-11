"""GENERATED — DO NOT EDIT. Input validation for the docker-publish action.

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


def check_boolean(value: str) -> str | None:
    """Boolean flag — exactly ``true`` or ``false``.

    Shell steps test ``[ "$FLAG" = "true" ]``, which is case-sensitive, while ``if:`` expressions
    are not, so ``True`` or a blank would have the two halves of an action disagree. A blank is
    refused for the reason in the module contract.
    """
    if value in ("true", "false"):
        return None
    return 'must be "true" or "false" (lowercase)'


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


def check_docker_local_path(value: str) -> str | None:
    """Docker ``context`` / ``dockerfile`` — a path in the workspace, never a remote source."""
    if _skip(value):
        return None
    return _docker_local_path_error(value)


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


def check_registry_enum(value: str) -> str | None:
    """Container registry selector."""
    return _enum(value, "dockerhub", "github", "both")


def check_username(value: str) -> str | None:
    """Username/handle — alphanumeric with internal ``-``/``_``, at most 39 characters."""
    if _skip(value):
        return None
    if len(value) > 39:
        return "must be at most 39 characters"
    if re.fullmatch(r"[a-zA-Z0-9](?:[a-zA-Z0-9_-]*[a-zA-Z0-9])?", value):
        return None
    return "may only contain letters, digits, and internal - or _"


ACTION = "docker-publish"

CHECKS = {
    "build-args": check_key_value_list,
    "context": check_docker_local_path,
    "dockerfile": check_docker_local_path,
    "dockerhub-token": check_opaque_token,
    "dockerhub-username": check_username,
    "image-name": check_docker_image_name,
    "platforms": check_docker_architectures,
    "push": check_boolean,
    "registry": check_registry_enum,
    "tags": check_docker_tag_list,
    "token": check_github_token,
}


REQUIRED: set[str] = set()


MASKED_INPUTS: list[str] = ["dockerhub-token", "token"]


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
