"""The shell scripts an action.yml runs, parsed by shfmt, for the static checks under _tests/unit.

A step runs a script through its run: key, or through nick-fields/retry's with: command:. Files
are parsed as YAML, so each value is the script GitHub runs, with YAML quoting, escapes and line
folding already decoded. shfmt (`shfmt --to-json`) parses each script into its syntax tree, so
quoting, comments, here-documents, redirections and arithmetic are read the way the shell reads
them, not matched as text.

command_names() reads the commands one simple command runs: its first word, past assignments and
redirections; the command a wrapper such as sudo, env, timeout, xargs, exec, nice, stdbuf, flock
or chroot runs, past the wrapper's options and their arguments; the commands after find's -exec;
and the word after `set --`, which builds a command that "$@" runs later. A command named by a
path is read by its last component. It also returns the scripts the command runs as code: the
script given to `sh -c` (or `-ec` and the like), eval's operands, trap's action and the string
`env -S` splits. A word with an expansion, such as "$@", names no command and is no script.
"""

from __future__ import annotations

import json
import re
import shutil
import subprocess

import yaml

# shfmt's language for each shell a step or a command can name.
SHELLS = {"sh": "posix", "dash": "posix", "bash": "bash"}
RETRY = "nick-fields/retry"
SHFMT = shutil.which("shfmt")
# Stands for an expansion in a word's text, so the word matches no command name.
EXPANSION = "\x00"
# For each wrapper that runs the command after its options: the options that take an argument.
WRAPPERS = {
    "chroot": {"--userspec", "--groups"},
    "command": set(),
    "doas": {"-u", "-C"},
    "env": {"-u", "-C", "--unset", "--chdir"},
    "exec": {"-a"},
    "flock": {"-w", "-E", "--timeout", "--conflict-exit-code"},
    "nice": {"-n", "--adjustment"},
    "nohup": set(),
    "setsid": set(),
    "stdbuf": {"-i", "-o", "-e", "--input", "--output", "--error"},
    "sudo": {
        "-u",
        "-g",
        "-C",
        "-D",
        "-h",
        "-p",
        "-r",
        "-t",
        "-U",
        "-T",
        "--user",
        "--group",
        "--chdir",
    },
    "time": {"-f", "-o", "--format", "--output"},
    "timeout": {"-s", "-k", "--signal", "--kill-after"},
    "xargs": {
        "-n",
        "-L",
        "-P",
        "-s",
        "-I",
        "-E",
        "-d",
        "-a",
        "--max-args",
        "--max-lines",
        "--max-procs",
    },
}
# Operands a wrapper reads before the command: timeout's duration, chroot's root, flock's lock.
OPERANDS_BEFORE_COMMAND = {"timeout": 1, "chroot": 1, "flock": 1}
# Wrappers that also take NAME=value words before the command.
TAKE_ASSIGNMENTS = {"env", "sudo"}
# Options whose argument is a command line: `env -S 'tool args'`.
SCRIPT_OPTIONS = {"env": {"-S", "--split-string"}}
FIND_EXEC = {"-exec", "-execdir", "-ok", "-okdir"}
ASSIGNMENT = re.compile(r"[A-Za-z_][A-Za-z0-9_]*=")


class ParseError(Exception):
    """shfmt could not parse a script."""


def parse(text: str, language: str) -> dict:
    """Return shfmt's syntax tree of a script, or raise ParseError with shfmt's message."""
    if SHFMT is None:
        message = "shfmt is required to parse run: scripts; see _tests/README.md"
        raise ParseError(message)
    result = subprocess.run(
        [SHFMT, "--to-json", "-ln", language],
        input=text,
        capture_output=True,
        text=True,
        check=False,
    )
    if result.returncode != 0:
        message = result.stderr.strip()
        raise ParseError(message)
    return json.loads(result.stdout)


def shape(word: dict | None) -> str:
    """Return a word's text, with each expansion in it replaced by EXPANSION."""
    text = []
    for part in (word or {}).get("Parts") or []:
        kind = part.get("Type")
        # shfmt leaves an empty Value out of its JSON.
        if kind == "Lit":
            text.append(re.sub(r"\\(.)", r"\1", part.get("Value", "")))
        elif kind == "SglQuoted":
            text.append(part.get("Value", ""))
        elif kind == "DblQuoted":
            text.append(shape(part))
        else:
            text.append(EXPANSION)
    return "".join(text)


def fields(node) -> dict:
    """Return a mapping node's scalar keys and their value nodes; any other node has none."""
    if not isinstance(node, yaml.MappingNode):
        return {}
    return {key.value: value for key, value in node.value if isinstance(key, yaml.ScalarNode)}


def step_scripts(text: str):
    """Yield (script, language, line_of) for each sh or bash script an action's steps run.

    line_of maps a line of the script to its line in the file. A literal block keeps its lines,
    so each maps to its own source line; other styles fold or decode their lines, so those all
    map to the line where the value starts. Only runs.steps runs scripts, so a key named run
    anywhere else, such as in env:, is not one.
    """
    steps = fields(fields(yaml.compose(text)).get("runs")).get("steps")
    if not isinstance(steps, yaml.SequenceNode):
        return
    for step in steps.value:
        step_fields = fields(step)
        uses = step_fields.get("uses")
        if isinstance(uses, yaml.ScalarNode) and uses.value.split("@", 1)[0] == RETRY:
            # nick-fields/retry runs its command with bash unless with: shell: names another.
            options = fields(step_fields.get("with"))
            script, shell, default = options.get("command"), options.get("shell"), "bash"
        else:
            script, shell, default = step_fields.get("run"), step_fields.get("shell"), "sh"
        words = shell.value.split() if isinstance(shell, yaml.ScalarNode) else [default]
        name = words[0].rsplit("/", 1)[-1] if words else default
        if not isinstance(script, yaml.ScalarNode) or name not in SHELLS:
            continue
        start = script.start_mark.line
        if script.style == "|":
            yield script.value, SHELLS[name], lambda line, first=start + 1: first + line
        else:
            yield script.value, SHELLS[name], lambda _line, first=start + 1: first


def shell_c_script(words: list[str], at: int) -> str | None:
    """Return the script a shell at words[at] runs with -c (or a cluster such as -ec), if any."""
    for index in range(at + 1, len(words)):
        word = words[index]
        if word == "--" or not word.startswith("-"):
            return None
        if not word.startswith("--") and "c" in word[1:]:
            script = words[index + 1] if index + 1 < len(words) else EXPANSION
            return None if EXPANSION in script else script
    return None


def _skip_options(words: list[str], index: int, wrapper: str, scripts: list) -> int | None:
    """Return the index of the command after a wrapper's options, or None when there is none."""
    options = WRAPPERS[wrapper]
    while index < len(words):
        word = words[index]
        if word == "--":
            return index + 1
        if word in SCRIPT_OPTIONS.get(wrapper, ()):
            if index + 1 < len(words) and EXPANSION not in words[index + 1]:
                scripts.append((words[index + 1], "posix"))
            return None
        if word.startswith("-") and len(word) > 1:
            # -u USER, --user USER, or a cluster such as -Eu USER, whose last letter takes one.
            takes = word in options or (
                not word.startswith("--") and "=" not in word and "-" + word[-1] in options
            )
            index += 2 if takes else 1
        elif wrapper in TAKE_ASSIGNMENTS and ASSIGNMENT.match(word):
            index += 1
        else:
            break
    return index + OPERANDS_BEFORE_COMMAND.get(wrapper, 0)


def command_names(words: list[str]) -> tuple[list[tuple[int, str]], list[tuple[str, str]]]:
    """Return the commands a simple command runs and the scripts it runs as code.

    words are the command's words as shape() gives them. The first list holds (index, name),
    the index of each command's word in words; the second holds (script, shfmt language).
    """
    calls: list[tuple[int, str]] = []
    scripts: list[tuple[str, str]] = []
    index: int | None = 2 if len(words) > 2 and words[0] == "set" and words[1] == "--" else 0
    while index is not None and index < len(words):
        word = words[index]
        name = word.rsplit("/", 1)[-1]
        calls.append((index, name))
        if EXPANSION in word:
            break
        if name in SHELLS:
            script = shell_c_script(words, index)
            if script is not None:
                scripts.append((script, SHELLS[name]))
            break
        if name == "find":
            for at in range(index, len(words) - 1):
                if words[at] in FIND_EXEC:
                    end = next(
                        (k for k in range(at + 1, len(words)) if words[k] in (";", "+")), len(words)
                    )
                    inner_calls, inner_scripts = command_names(words[at + 1 : end])
                    calls.extend((at + 1 + offset, inner) for offset, inner in inner_calls)
                    scripts.extend(inner_scripts)
            break
        if name in ("eval", "trap"):
            operands = words[index + 1 :] if name == "eval" else words[index + 1 : index + 2]
            if operands and operands != ["-"] and all(EXPANSION not in w for w in operands):
                scripts.append((" ".join(operands), "posix"))
            break
        if name not in WRAPPERS or (
            name == "command" and index + 1 < len(words) and words[index + 1] in ("-v", "-V")
        ):
            break
        index = _skip_options(words, index + 1, name, scripts)
    return calls, scripts


def simple_commands(node):
    """Yield every simple command (CallExpr) anywhere in a syntax tree, in source order."""
    if isinstance(node, dict):
        if node.get("Type") == "CallExpr":
            yield node
        for value in node.values():
            yield from simple_commands(value)
    elif isinstance(node, list):
        for value in node:
            yield from simple_commands(value)
