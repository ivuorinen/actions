"""Print the commands the repository's own tooling runs that break a pin: a package fetched at a
floating version, uv run against uv.lock without --locked, a download that accepts plain HTTP or
old TLS, or an npm install that runs the packages' install scripts.

    repo_commands.py fetches|unlocked|insecure-downloads|install-scripts FILE...

shfmt parses each script FILE runs as the shell reads it: a Makefile's recipes and the
$(shell ...) calls make runs, a package.json's scripts, an action's or a workflow's run steps, a
Dockerfile's RUN instructions, or a whole shell script. Quoting, escapes, comments, command
substitutions and the scripts a shell runs therefore count as they do when the shell runs them.
Prints "FILE:WHERE: COMMAND" for each match, WHERE being a line or a script's name, and exits 2
when shfmt cannot parse a file.
"""

from __future__ import annotations

from itertools import pairwise
import json
from pathlib import Path
import re
import sys

import check_pins
import yaml

sh = check_pins.sh

# A make variable assignment: its name, its operator and its value.
ASSIGNMENT = re.compile(
    r"(?:(?:export|override)\s+)*([A-Za-z_.][\w.-]*)\s*(:::=|::=|:=|\?=|\+=|!=|=)(.*)", re.DOTALL
)
# The operators that expand the value once, where it is assigned.
SIMPLE = {":=", "::=", ":::="}
VARIABLE = re.compile(r"[A-Za-z_.][\w.-]*")
DEFINE = re.compile(r"(?:(?:export|override)\s+)*define\s")
ENDEF = re.compile(r"\s*endef\b")

# What a make reference reads as in a shell script: a word that names no command.
REFERENCE = "MAKEREF"

# npm's install commands and their aliases, as `npm <command> --help` lists them (npm 11).
NPM_INSTALLS = {
    "install",
    "add",
    "i",
    "in",
    "ins",
    "inst",
    "insta",
    "instal",
    "isnt",
    "isnta",
    "isntal",
    "isntall",
    "ci",
    "clean-install",
    "ic",
    "install-clean",
    "isntall-clean",
    "install-test",
    "it",
    "install-ci-test",
    "cit",
    "clean-install-test",
    "sit",
}


def reresolves(name: str, args: list[str]) -> bool:
    """Whether a command is a uv run or uv sync whose own options leave --locked off, so it
    updates an out-of-date uv.lock instead of failing on it. The last of --locked and
    --no-locked wins."""
    if name != "uv":
        return False
    command, rest = check_pins.subcommand(name, args)
    if command not in ("run", "sync"):
        return False
    locked = False
    for option in check_pins.own_options(rest, check_pins.UV_OPTIONS):
        if option in ("--locked", "--no-locked"):
            locked = option == "--locked"
    return not locked


def insecure_download(name: str, args: list[str]) -> bool:
    """Whether a curl command lacks --proto =https or --tlsv1.2 (or --tlsv1.3), so a redirect
    can take it to plain HTTP or an old TLS version."""
    if name != "curl":
        return False
    https = any(
        word == "--proto==https" or (word == "--proto" and following == "=https")
        for word, following in pairwise([*args, ""])
    )
    return not (https and {"--tlsv1.2", "--tlsv1.3"} & set(args))


def runs_install_scripts(name: str, args: list[str]) -> bool:
    """Whether an npm install runs the packages' install scripts: --ignore-scripts is off unless
    the last setting of it among the words turns it on."""
    if name != "npm" or check_pins.subcommand(name, args)[0] not in NPM_INSTALLS:
        return False
    ignored = False
    for word in args:
        if word in ("--ignore-scripts", "--ignore-scripts=true"):
            ignored = True
        elif word in ("--ignore-scripts=false", "--no-ignore-scripts"):
            ignored = False
    return not ignored


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


def rebuild(text: str, replace) -> str:
    """Return text with each make reference in it replaced by replace(reference, inner)."""
    out = []
    index = 0
    for start, end, inner in references(text):
        out += [text[index:start], replace(text[start:end], inner)]
        index = end
    out.append(text[index:])
    return "".join(out)


def expand(text: str, variables: dict[str, str], depth: int = 0) -> str:
    """Return text with each reference to a variable the Makefile defines replaced by its
    value, expanded too, at any depth. Other references keep their place."""

    def replace(reference: str, inner: str) -> str:
        name = inner or reference[1:]
        if depth < 20 and VARIABLE.fullmatch(name) and name in variables:
            return expand(variables[name], variables, depth + 1)
        if depth < 20 and inner:
            return reference[:2] + expand(inner, variables, depth + 1) + reference[-1]
        return reference

    return rebuild(text, replace)


def without_shell_calls(text: str) -> str:
    """Return text with each $(shell ...) in it, at any depth, replaced by MAKEREF: what a
    simple variable holds once make has run them."""

    def replace(reference: str, inner: str) -> str:
        if inner.startswith("shell "):
            return REFERENCE
        return reference[:2] + without_shell_calls(inner) + reference[-1] if inner else reference

    return rebuild(text, replace)


def shell_text(text: str) -> str:
    """Return expanded recipe text as the shell gets it: $$ is $, and each make reference left
    is the word MAKEREF. shell_calls returns the commands make runs for $(shell ...)."""
    out = []
    index = 0
    for start, end, _inner in references(text):
        out += [text[index:start].replace("$$", "$"), REFERENCE]
        index = end
    out.append(text[index:].replace("$$", "$"))
    return "".join(out)


def shell_calls(text: str) -> list[str]:
    """Return the command of each $(shell ...) in text, at any depth: make runs each one when
    it expands the text, inside another function or inside the shell's quotes alike."""
    calls = []
    for _start, _end, inner in references(text):
        if inner.startswith("shell "):
            calls.append(shell_text(inner[6:]))
            inner = inner[6:]
        calls += shell_calls(inner)
    return calls


def without_comment(line: str) -> str:
    """Return a Makefile line outside a recipe without its comment: make reads a # that no
    backslash escapes as one, inside a function call too."""
    match = re.search(r"(?<!\\)#", line)
    return line[: match.start()] if match else line


def logical_lines(text: str):
    """Yield (line, text) for each line of a Makefile with its backslash continuations."""
    lines = text.split("\n")
    index = 0
    while index < len(lines):
        first = index
        while lines[index].endswith("\\") and index + 1 < len(lines):
            index += 1
        yield first + 1, "\n".join(lines[first : index + 1])
        index += 1


class Makefile:
    """What make hands to a shell for one Makefile, read line by line: the variables defined so
    far, which of them are simple, the recipe lines, and the scripts found so far."""

    def __init__(self) -> None:
        self.variables: dict[str, str] = {}
        self.simple: set[str] = set()
        self.recipes: list[tuple[str, int]] = []
        self.statements: list[tuple[str, int, bool]] = []

    def run_now(self, expanded: str, line: int) -> None:
        """Add the $(shell ...) calls make runs when it expands this text at this line."""
        self.statements.extend((call, line, False) for call in shell_calls(expanded))

    def assign(self, name: str, operator: str, value: str, line: int) -> None:
        """Apply an assignment. A simple one (:=) expands its value, and runs its $(shell ...)
        calls, here; a recursive one (=) where a recipe or another line uses it; != runs its
        value as a command here. += keeps the flavor the variable has."""
        previous = self.variables.get(name)
        if operator == "?=" and previous is not None:
            return
        appended = operator == "+=" and name in self.simple
        immediate = operator in SIMPLE or operator == "!=" or appended
        if immediate:
            command = expand(value, self.variables)
            self.run_now(command, line)
            if operator == "!=":
                self.statements.append((shell_text(command), line, False))
            value = REFERENCE if operator == "!=" else without_shell_calls(command)
        if operator == "+=" and previous is not None:
            value = f"{previous} {value}"
        self.variables[name] = value
        if immediate:
            self.simple.add(name)
        elif operator != "+=":
            self.simple.discard(name)

    def read(self, line: int, logical: str) -> None:
        """Read one line outside a define block."""
        if logical.startswith("\t"):
            self.recipes.append((logical[1:].lstrip("@-+ \t"), line))
            return
        code = without_comment(logical)
        if match := ASSIGNMENT.fullmatch(code):
            self.assign(match.group(1), match.group(2), match.group(3).strip(), line)
            return
        semicolon = code.find(";")
        if semicolon != -1 and ":" in code[:semicolon]:
            self.recipes.append((logical[semicolon + 1 :].lstrip("@-+ \t"), line))
            code = code[:semicolon]
        self.run_now(expand(code, self.variables), line)


def make_statements(text: str) -> list[tuple[str, int, bool]]:
    """Return (script, line, spread) for each script a Makefile hands to a shell: each recipe
    line, a rule's recipe after its semicolon, with the variables it references expanded, and
    each $(shell ...) and != command make runs. spread says whether the script's lines follow
    the Makefile's from line on; the others all come from line. Comments outside recipes, and
    the bodies of define blocks, hand nothing to a shell."""
    makefile = Makefile()
    in_define = False
    for line, logical in logical_lines(text):
        if in_define:
            in_define = not ENDEF.match(logical)
        elif not logical.startswith("\t") and DEFINE.match(without_comment(logical)):
            in_define = True
        else:
            makefile.read(line, logical)
    for body, line in makefile.recipes:
        expanded = expand(body, makefile.variables)
        makefile.statements.append((shell_text(expanded), line, True))
        makefile.run_now(expanded, line)
    return makefile.statements


def make_script(text: str) -> tuple[str, list[int]]:
    """Return a Makefile's shell scripts as one script, a statement each, and the Makefile line
    each line of it comes from."""
    script: list[str] = []
    origin: list[int] = []
    for statement, line, spread in make_statements(text):
        count = statement.count("\n") + 1
        script.append(statement)
        origin += range(line, line + count) if spread else [line] * count
    return "\n".join(script), origin


def dockerfile_scripts(text: str):
    """Yield (script, origin) for each RUN instruction in shell form in a Dockerfile: its lines
    and continuations, without the comment lines Docker drops from them or flags such as
    --mount, and the Dockerfile line each line of the script comes from."""
    lines = text.split("\n")
    index = 0
    while index < len(lines):
        match = re.match(r"\s*RUN\s+(.*)", lines[index], re.IGNORECASE)
        index += 1
        if not match:
            continue
        body, origin = [match.group(1)], [index]
        while body[-1].endswith("\\") and index < len(lines):
            if not re.match(r"\s*#", lines[index]):
                body.append(lines[index])
                origin.append(index + 1)
            index += 1
        script = re.sub(r"^(?:--\S+\s+)+", "", "\n".join(body))
        if not script.startswith("["):
            yield script, origin


def scripts(path: Path):
    """Yield (script, language, line_of) for each script FILE runs."""
    text = path.read_text(encoding="utf-8")
    if path.name == "package.json":
        for name, script in json.loads(text).get("scripts", {}).items():
            yield script, "posix", lambda _line, name=name: name
    elif path.name == "Makefile":
        script, origin = make_script(text)
        yield script, "posix", lambda line: origin[line - 1]
    elif path.name == "Dockerfile":
        for script, origin in dockerfile_scripts(text):
            yield script, "bash", lambda line, origin=origin: origin[line - 1]
    elif path.suffix in (".yml", ".yaml"):
        root = yaml.safe_load(text)
        if isinstance(root, dict) and "runs" in root:
            yield from sh.step_scripts(text)
        else:
            yield from sh.workflow_scripts(text)
    else:
        yield text, "bash", int


def commands(path: Path, matches) -> list[tuple[int | str, str]]:
    """Return (where, command) for each command FILE runs that matches(name, args) holds for."""
    found: list[tuple[int | str, str]] = []
    for script, language, line_of in scripts(path):
        found += check_pins.find_commands(script, language, line_of, matches)
    return found


CHECKS = {
    "fetches": check_pins.fetches_floating,
    "unlocked": reresolves,
    "insecure-downloads": insecure_download,
    "install-scripts": runs_install_scripts,
}


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
