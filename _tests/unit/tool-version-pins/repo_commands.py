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
# uv run runs: each option `uv run --help` and `uv sync --help` list with a <VALUE> (uv 0.13.6).
# One uv adds later reads as the command, which reports a locked call, never hides one.
UV_OPTIONS = {
    "--allow-insecure-host",
    "-C",
    "--cache-dir",
    "--color",
    "--config-file",
    "--config-setting",
    "--config-settings-package",
    "--default-index",
    "--directory",
    "--env-file",
    "--exclude-newer",
    "--exclude-newer-package",
    "--extra",
    "--extra-index-url",
    "-f",
    "--find-links",
    "--fork-strategy",
    "--group",
    "-i",
    "--index",
    "--index-strategy",
    "--index-url",
    "--keyring-provider",
    "--link-mode",
    "--no-binary-package",
    "--no-build-isolation-package",
    "--no-build-package",
    "--no-editable-package",
    "--no-extra",
    "--no-group",
    "--no-install-package",
    "--no-sources-package",
    "--only-group",
    "--output-format",
    "-p",
    "-P",
    "--package",
    "--prerelease",
    "--prerelease-package",
    "--project",
    "--python",
    "--python-platform",
    "--refresh-package",
    "--reinstall-package",
    "--resolution",
    "--script",
    "--upgrade-group",
    "--upgrade-package",
    "-w",
    "--with",
    "--with-editable",
    "--with-requirements",
}

# A make variable assignment, with its value in the group.
ASSIGNMENT = re.compile(
    r"(?:export\s+|override\s+)?[A-Za-z_.][\w.-]*\s*(?::::=|::?=|\?=|\+=|!=|=)(.*)", re.DOTALL
)

# A rule with its recipe on the same line, `targets: prerequisites ; recipe`, with the recipe in
# the group. A # before the semicolon starts a comment, so it holds no recipe.
RULE = re.compile(r"[^\t#][^#;=]*?::?(?!=)[^#;=]*;(.*)", re.DOTALL)

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


def references(text: str):
    """Yield (start, end, inner) for each make reference in text, $(...) or ${...}, outside
    the $$ that stands for the shell's $. One-character references such as $@ have no inner."""
    index = 0
    while index < len(text):
        if text.startswith("$$", index):
            index += 2
        elif text.startswith(("$(", "${"), index):
            opener = text[index + 1]
            closer = ")" if opener == "(" else "}"
            depth, end = 1, index + 2
            while end < len(text) and depth:
                depth += (text[end] == opener) - (text[end] == closer)
                end += 1
            yield index, end, text[index + 2 : end - 1]
            index = end
        elif text[index] == "$" and index + 1 < len(text):
            yield index, index + 2, ""
            index += 2
        else:
            index += 1


def shell_text(text: str) -> str:
    """Return a Makefile recipe line or variable value as the shell gets it: $$ is $, and each
    make reference is the word MAKEREF. make runs the $(shell ...) calls itself; shell_calls
    returns those."""
    out = []
    index = 0
    for start, end, _inner in references(text):
        out += [text[index:start].replace("$$", "$"), REFERENCE]
        index = end
    out.append(text[index:].replace("$$", "$"))
    return "".join(out)


def shell_calls(text: str) -> list[str]:
    """Return the command of each $(shell ...) in text, at any depth: make runs each one when
    it expands the line, inside another function or inside the shell's quotes alike."""
    calls = []
    for _start, _end, inner in references(text):
        if inner.startswith("shell "):
            calls.append(shell_text(inner[6:]))
            inner = inner[6:]
        calls += shell_calls(inner)
    return calls


def shell_body(logical: str) -> str | None:
    """Return the text of a Makefile line that make expands for a shell: a recipe line or the
    recipe after a rule's semicolon, without its @, - and + prefixes, or a variable's value,
    which a recipe can run. None for any other line."""
    if logical.startswith("\t"):
        return logical[1:].lstrip("@-+ \t")
    if match := ASSIGNMENT.fullmatch(logical):
        return match.group(1)
    if match := RULE.fullmatch(logical):
        return match.group(1).lstrip("@-+ \t")
    return None


def make_script(text: str) -> tuple[str, list[int]]:
    """Return what a Makefile hands to the shell as one shell script, one statement for each
    recipe line, variable value and $(shell ...) call, and the Makefile line each line of the
    script comes from. make runs each recipe line in a shell of its own."""
    lines = text.split("\n")
    script: list[str] = []
    origin: list[int] = []
    index = 0
    while index < len(lines):
        first = index
        while lines[index].endswith("\\") and index + 1 < len(lines):
            index += 1
        body = shell_body("\n".join(lines[first : index + 1]))
        index += 1
        if body is None:
            continue
        statement = shell_text(body)
        script.append(statement)
        origin += range(first + 1, first + 2 + statement.count("\n"))
        for call in shell_calls(body):
            script.append(call)
            origin += [first + 1] * (call.count("\n") + 1)
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
