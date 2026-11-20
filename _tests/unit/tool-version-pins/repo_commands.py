"""Print the commands the repository's own tooling runs that fetch a package at a floating
version, or that run uv without --locked.

    repo_commands.py fetches|unlocked FILE...

shfmt parses each FILE as the shell reads it: a Makefile's recipe lines and variable values, a
package.json's scripts, or a whole shell script. Quoting, escapes, comments, command
substitutions and the scripts a shell runs therefore count as they do when the shell runs them.
Prints "FILE:WHERE: COMMAND" for each match, WHERE being a line or a script's name, and exits 2
when shfmt cannot parse a file.
"""

from __future__ import annotations

import json
from pathlib import Path
import re
import sys

import check_pins

sh = check_pins.sh

# uv run and uv sync options that take an argument, so the word after one is not the command
# uv run runs.
UV_OPTIONS = {
    "--cache-dir",
    "--config-file",
    "--default-index",
    "--directory",
    "--env-file",
    "--extra",
    "--extra-index-url",
    "--find-links",
    "-f",
    "--group",
    "--index",
    "--index-url",
    "--no-group",
    "--only-group",
    "--package",
    "--project",
    "--python",
    "-p",
    "--with",
    "--with-editable",
    "--with-requirements",
}

# A make variable assignment, with its value in the group.
ASSIGNMENT = re.compile(
    r"(?:export\s+|override\s+)?[A-Za-z_.][\w.-]*\s*(?::::=|::?=|\?=|\+=|!=|=)(.*)", re.DOTALL
)

# What a make reference reads as in a shell script: a word that names no command.
REFERENCE = "MAKEREF"


def reresolves(name: str, args: list[str]) -> bool:
    """Whether a command is a uv run or uv sync without --locked among its own options, which
    updates an out-of-date uv.lock instead of failing on it."""
    if name != "uv":
        return False
    command, rest = check_pins.subcommand(name, args)
    if command not in ("run", "sync"):
        return False
    index = 0
    while index < len(rest):
        if rest[index] == "--locked":
            return False
        is_option, needs_next = sh.takes_argument(rest[index], UV_OPTIONS)
        if not is_option:
            break
        index += 2 if needs_next else 1
    return True


def shell_text(text: str) -> str:
    """Return a Makefile recipe line or variable value as the shell gets it: $$ is $,
    $(shell X) is the command substitution $(X), and any other make reference is MAKEREF."""
    out = []
    index = 0
    while index < len(text):
        if text.startswith("$$", index):
            out.append("$")
            index += 2
        elif text.startswith(("$(", "${"), index):
            opener = text[index + 1]
            closer = ")" if opener == "(" else "}"
            depth, end = 1, index + 2
            while end < len(text) and depth:
                depth += (text[end] == opener) - (text[end] == closer)
                end += 1
            inner = text[index + 2 : end - 1]
            out.append(f"$({shell_text(inner[6:])})" if inner.startswith("shell ") else REFERENCE)
            index = end
        elif text[index] == "$" and index + 1 < len(text):
            # $@, $< and the other one-character references.
            out.append(REFERENCE)
            index += 2
        else:
            out.append(text[index])
            index += 1
    return "".join(out)


def make_script(text: str) -> tuple[str, list[int]]:
    """Return a Makefile's recipe lines and variable values as one shell script, one statement
    each, and the Makefile line each line of it comes from. make runs each recipe line in a
    shell of its own, after taking off its @, - and + prefixes."""
    lines = text.split("\n")
    script: list[str] = []
    origin: list[int] = []
    index = 0
    while index < len(lines):
        first = index
        while lines[index].endswith("\\") and index + 1 < len(lines):
            index += 1
        logical = "\n".join(lines[first : index + 1])
        index += 1
        if logical.startswith("\t"):
            body = logical[1:].lstrip("@-+ \t")
        elif match := ASSIGNMENT.fullmatch(logical):
            body = match.group(1)
        else:
            continue
        statement = shell_text(body)
        script.append(statement)
        origin += range(first + 1, first + 2 + statement.count("\n"))
    return "\n".join(script), origin


def commands(path: Path, matches) -> list[tuple[int | str, str]]:
    """Return (where, command) for each command FILE runs that matches(name, args) holds for."""
    text = path.read_text(encoding="utf-8")
    if path.name == "package.json":
        return [
            (name, command)
            for name, script in json.loads(text).get("scripts", {}).items()
            for _line, command in check_pins.find_commands(script, "posix", int, matches)
        ]
    if path.name == "Makefile":
        script, origin = make_script(text)
        return list(
            check_pins.find_commands(script, "posix", lambda line: origin[line - 1], matches)
        )
    return list(check_pins.find_commands(text, "bash", int, matches))


CHECKS = {"fetches": check_pins.fetches_floating, "unlocked": reresolves}


def main(argv: list[str]) -> int:
    if len(argv) < 2 or argv[0] not in CHECKS:
        print(f"usage: repo_commands.py {'|'.join(CHECKS)} FILE...", file=sys.stderr)
        return 2
    mode, *paths = argv
    for path in paths:
        try:
            found = commands(Path(path), CHECKS[mode])
        except sh.ParseError as error:
            print(f"{path}: shfmt cannot parse it: {error}", file=sys.stderr)
            return 2
        for where, command in found:
            print(f"{path}:{where}: {command}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
