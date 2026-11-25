"""Checks for files, paths, globs and branch names."""

from __future__ import annotations

import re

from .common import _file_path_error, _shell_meta_error, _skip, _split_items


def check_file_path(value: str) -> str | None:
    """Relative file path — rejects a leading ``-``, absolute paths, ``..`` and ``~`` expansion."""
    if _skip(value):
        return None
    return _file_path_error(value)


def check_dotnet_project(value: str) -> str | None:
    """``dotnet`` project or solution path — a relative file path that may hold spaces.

    The csharp actions pass it to dotnet as one quoted argument, so a space never splits it.
    """
    if _skip(value):
        return None
    return _file_path_error(value, spaces=True)


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


def _first_brace_pair(text: str) -> tuple[int, int] | None:
    """Return the start and end of the closed brace pair that opens first, or None.

    One pass pairs each closing brace with the nearest open one before it, so a run of unclosed
    braces is read once rather than once for each of them.
    """
    opened: list[int] = []
    first: tuple[int, int] | None = None
    for index, char in enumerate(text):
        if char == "{":
            opened.append(index)
        elif char == "}" and opened:
            start = opened.pop()
            if first is None or start < first[0]:
                first = (start, index)
    return first


def _brace_group(text: str) -> tuple[int, int, list[str]] | None:
    """Return the start, end and top-level alternatives of the first closed brace group, or None.

    An unclosed brace groups nothing and stays literal.
    """
    pair = _first_brace_pair(text)
    if pair is None:
        return None
    start, end = pair
    # Every brace between the pair is paired too, so depth 0 is the group's own level.
    depth, begin, alternatives = 0, start + 1, []
    for index in range(start + 1, end):
        if text[index] == "{":
            depth += 1
        elif text[index] == "}":
            depth -= 1
        elif text[index] == "," and depth == 0:
            alternatives.append(text[begin:index])
            begin = index + 1
    alternatives.append(text[begin:end])
    return start, end, alternatives


def _brace_expansions(item: str, limit: int = 256) -> list[str] | None:
    """Return each brace expansion of a glob item, or None when it has more than ``limit``.

    ``{/etc,src}/x`` expands to ``/etc/x`` and ``src/x``, and ``{.,a}./x`` to ``../x`` and
    ``a./x``. The expansion is iterative, so however deep the braces nest, it cannot exhaust
    the stack.
    """
    done, pending = [], [item]
    while pending:
        text = pending.pop()
        group = _brace_group(text)
        if group is None:
            done.append(text)
        else:
            start, end, alternatives = group
            pending.extend(text[:start] + alt + text[end + 1 :] for alt in alternatives)
        if len(done) + len(pending) > limit:
            return None
    return done


def _path_item_error(item: str) -> str | None:
    """Return why one path or glob of a ``path_list`` value is refused, or None."""
    if item.startswith("-"):
        return f"must not start with -: {item}"
    if not re.fullmatch(r"[a-zA-Z0-9_\-./*?\[\]{},@~+]+", item):
        return f"invalid path or glob: {item}"
    expansions = _brace_expansions(item)
    if expansions is None:
        return f"too many brace expansions: {item}"
    for expanded in expansions:
        if expanded.startswith(("/", "~")):
            return f"must be relative to the workspace, without ~: {item}"
        if ".." in expanded:
            return f"path traversal (..) is not allowed: {item}"
    return None


def check_path_list(value: str) -> str | None:
    """Comma-separated paths/globs below the workspace.

    Blocks injection characters, a leading ``-``, and ``..`` or an absolute or ``~`` path in
    any brace expansion (``{/etc,src}``, ``{.,a}./x``): a tool in fix mode writes to what the
    globs match. A comma inside braces belongs to the glob (``src/{a,-b}.js``), so it does not
    separate items.
    """
    if _skip(value):
        return None
    if meta := _shell_meta_error(value):
        return meta
    for item in _split_items(value, globs=True):
        if item and (error := _path_item_error(item)):
            return error
    return None
