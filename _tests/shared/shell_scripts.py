"""The shell scripts an action.yml runs, parsed by shfmt, for the static checks under _tests/unit.

A step runs a script through its run: key, or through nick-fields/retry's with: command:,
new_command_on_retry: and on_retry_command:. Files are parsed as YAML, so each value is the
script GitHub runs, with YAML quoting, escapes and line folding already decoded. shfmt
(`shfmt --to-json`) parses each script into its syntax tree, so quoting, comments,
here-documents, redirections and arithmetic are read the way the shell reads them, not matched
as text.

command_names() reads the commands one simple command runs: its first word, past assignments and
redirections; the command a wrapper such as sudo, env, timeout, xargs, exec, nice, ionice, watch,
stdbuf, flock, chroot or corepack runs, past the wrapper's options and their arguments (read as
getopt does, so -uroot and -u root both name a user); the commands after find's -exec; and the
word after `set --`, which builds a command that "$@" runs later. A command named by a path is
read by its last component. It also returns the scripts the command runs as code: the script a
shell it runs is given with -c (or -ec, or after -o pipefail), eval's operands, trap's action and
the command line `env -S` runs: the words it splits its string into, then the operands after the
string. A shell that is only an argument, as in `printf '%s' sh -c x`, runs nothing. In those
scripts each expansion is read as a placeholder word. heredoc_scripts() returns the
here-documents a shell reads as its script, given to it directly or through a pipe.

Not read: a command named through a variable, an alias or a function the script defines; a script
a shell reads from a pipe other than a here-document (`printf ... | sh`), from a here-string or
from a file; `su -c`, `flock ... -c` and coproc; the escapes and comments of env -S's own string
syntax (`\\_`, `\\c`, `#`), as its string is read as shell words; and steps whose shell: is not sh
or bash, such as node. The checks that use this module describe what they make of each command.
"""

from __future__ import annotations

import json
import re
import shlex
import shutil
import subprocess

import yaml

# shfmt's language for each shell a step or a command can name.
SHELLS = {"sh": "posix", "dash": "posix", "bash": "bash"}
RETRY = "nick-fields/retry"
# The nick-fields/retry inputs that hold a script.
RETRY_SCRIPTS = ("command", "new_command_on_retry", "on_retry_command")
SHFMT = shutil.which("shfmt")
# Stands for an expansion in a word's text, so the word matches no command name.
EXPANSION = "\x00"
# What an expansion reads as in a script a command runs, so the script still parses.
PLACEHOLDER = "_expansion_"
# For each wrapper that runs the command after its options: the options that take an argument.
WRAPPERS = {
    "chroot": {"--userspec", "--groups"},
    "command": set(),
    "corepack": set(),
    "doas": {"-u", "-C"},
    "env": {"-u", "-C", "--unset", "--chdir"},
    "exec": {"-a"},
    "flock": {"-w", "-E", "--timeout", "--conflict-exit-code"},
    "ionice": {"-c", "-n", "-p", "-P", "-u", "--class", "--classdata", "--pid", "--pgid", "--uid"},
    "nice": {"-n", "--adjustment"},
    "watch": {"-n", "--interval"},
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


def as_script(text: str) -> str:
    """Return a word's text as a script a command runs, each expansion read as a placeholder."""
    return text.replace(EXPANSION, PLACEHOLDER)


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
    yield from steps_scripts(fields(fields(yaml.compose(text)).get("runs")).get("steps"), "sh")


def default_shell(node_fields: dict) -> str | None:
    """Return the shell a workflow's or a job's defaults.run.shell names, if any."""
    shell = fields(fields(node_fields.get("defaults")).get("run")).get("shell")
    return shell.value if isinstance(shell, yaml.ScalarNode) else None


def workflow_scripts(text: str):
    """Yield (script, language, line_of) for each sh or bash script a workflow's jobs run, as
    step_scripts does for an action. A run step that names no shell runs the one its job's or
    the workflow's defaults.run.shell names, or else bash, GitHub's default on Linux."""
    root = fields(yaml.compose(text))
    workflow = default_shell(root)
    for job in fields(root.get("jobs")).values():
        job_fields = fields(job)
        shell = default_shell(job_fields) or workflow or "bash"
        yield from steps_scripts(job_fields.get("steps"), shell)


def steps_scripts(steps, run_shell: str):
    """Yield (script, language, line_of) for each sh or bash script a list of steps runs. A
    run step without a shell of its own runs run_shell."""
    if not isinstance(steps, yaml.SequenceNode):
        return
    for step in steps.value:
        step_fields = fields(step)
        uses = step_fields.get("uses")
        if isinstance(uses, yaml.ScalarNode) and uses.value.split("@", 1)[0].lower() == RETRY:
            # nick-fields/retry runs its scripts with bash unless with: shell: names another.
            options = fields(step_fields.get("with"))
            scripts = [options.get(name) for name in RETRY_SCRIPTS]
            shell, default = options.get("shell"), "bash"
        else:
            scripts = [step_fields.get("run")]
            shell, default = step_fields.get("shell"), run_shell
        words = shell.value.split() if isinstance(shell, yaml.ScalarNode) else [default]
        name = words[0].rsplit("/", 1)[-1] if words else default
        if name not in SHELLS:
            continue
        for script in scripts:
            if not isinstance(script, yaml.ScalarNode):
                continue
            start = script.start_mark.line
            if script.style == "|":
                yield script.value, SHELLS[name], lambda line, first=start + 1: first + line
            else:
                yield script.value, SHELLS[name], lambda _line, first=start + 1: first


def takes_argument(word: str, options: set[str]) -> tuple[bool, bool]:
    """Read one option word as getopt does: return (is_option, the next word is its argument).

    A long option takes the next word when it is listed without `=value`. A cluster of short
    options ends at the first letter that takes an argument: the rest of the word is that
    argument, or the next word when nothing is left, so -uroot needs no next word and -Eu does.
    """
    if word == "-" or not word.startswith("-"):
        return False, False
    if word.startswith("--"):
        return True, "=" not in word and word in options
    for at, letter in enumerate(word[1:], 1):
        if "-" + letter in options:
            return True, at == len(word) - 1
    return True, False


def shell_c_script(words: list[str], at: int) -> str | None:
    """Return the script a shell at words[at] runs with -c (or a cluster such as -ec), if any.

    -o NAME and +o NAME take a word; any other option starting with - or + is a cluster.
    """
    index = at + 1
    while index < len(words):
        word = words[index]
        if word in ("-o", "+o"):
            index += 2
            continue
        if word == "--" or word[:1] not in ("-", "+") or word.startswith("--"):
            return None
        if "c" in word[1:]:
            return as_script(words[index + 1]) if index + 1 < len(words) else None
        index += 1
    return None


def _attached_script(word: str, options: set[str]) -> str | None:
    """Return the command line a script option carries in the same word: --split-string=... or
    -S..., or None."""
    for option in options:
        if option.startswith("--") and word.startswith(option + "="):
            return word[len(option) + 1 :]
        if not option.startswith("--") and word.startswith(option) and len(word) > len(option):
            return word[len(option) :]
    return None


def _split_string(text: str, operands: list[str]) -> str:
    """Return the command line env -S runs, as a script: env again, then the words it splits its
    string into, then the operands after the string, each kept as one word. env reads the split
    words as its own arguments, so `env -S'-i sh -c' 'git status'` runs sh -c 'git status' with
    -i taken as env's option."""
    split = [as_script(text), *(shlex.quote(as_script(word)) for word in operands)]
    return " ".join(["env", *split])


def _skip_options(words: list[str], index: int, wrapper: str, scripts: list) -> int | None:
    """Return the index of the command after a wrapper's options, or None when there is none."""
    options = WRAPPERS[wrapper]
    while index < len(words):
        word = words[index]
        if word == "--":
            return index + 1
        if word in SCRIPT_OPTIONS.get(wrapper, ()):
            if index + 1 < len(words):
                scripts.append((_split_string(words[index + 1], words[index + 2 :]), "posix"))
            return None
        attached = _attached_script(word, SCRIPT_OPTIONS.get(wrapper, set()))
        if attached is not None:
            scripts.append((_split_string(attached, words[index + 1 :]), "posix"))
            return None
        is_option, needs_next = takes_argument(word, options)
        if is_option:
            index += 2 if needs_next else 1
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
            # Only a shell this command runs: `printf '%s' sh -c '...'` prints its words.
            script = shell_c_script(words, index)
            if script is not None:
                scripts.append((script, SHELLS[name]))
            break
        if name in ("find", "eval", "trap"):
            _runs_code(name, words, index, calls, scripts)
            break
        if name not in WRAPPERS or (
            name == "command" and index + 1 < len(words) and words[index + 1] in ("-v", "-V")
        ):
            break
        index = _skip_options(words, index + 1, name, scripts)
    return calls, scripts


def _runs_code(name: str, words: list[str], index: int, calls: list, scripts: list) -> None:
    """Add the commands find runs after -exec, and the code eval and trap run."""
    if name == "find":
        for at in range(index, len(words) - 1):
            if words[at] in FIND_EXEC:
                end = next(
                    (k for k in range(at + 1, len(words)) if words[k] in (";", "+")), len(words)
                )
                inner_calls, inner_scripts = command_names(words[at + 1 : end])
                calls.extend((at + 1 + offset, inner) for offset, inner in inner_calls)
                scripts.extend(inner_scripts)
    elif name == "eval":
        if index + 1 < len(words):
            scripts.append((as_script(" ".join(words[index + 1 :])), "posix"))
    else:
        operands = words[index + 1 :]
        operands = operands[1:] if operands[:1] == ["--"] else operands
        if operands and not operands[0].startswith("-"):
            scripts.append((as_script(operands[0]), "posix"))


def stdin_shell(stmt: dict) -> str | None:
    """Return the shfmt language of a shell a statement runs that reads its script from stdin."""
    cmd = stmt.get("Cmd") or {}
    if cmd.get("Type") != "CallExpr":
        return None
    words = [shape(word) for word in cmd.get("Args") or []]
    calls, _ = command_names(words)
    if not calls or calls[-1][1] not in SHELLS:
        return None
    if shell_c_script(words, calls[-1][0]) is not None:
        return None
    return SHELLS[calls[-1][1]]


def heredoc_bodies(stmt: dict, source: bytes) -> list[tuple[str, int]]:
    """Return (body, line) for each here-document on a statement."""
    bodies = []
    for redirect in stmt.get("Redirs") or []:
        hdoc = redirect.get("Hdoc")
        if hdoc:
            body = source[hdoc["Pos"]["Offset"] : hdoc["End"]["Offset"]].decode("utf-8")
            # The byte range ends with the closing delimiter's line.
            bodies.append((body.rsplit("\n", 1)[0] if "\n" in body else "", hdoc["Pos"]["Line"]))
    return bodies


def heredoc_scripts(node, source: bytes):
    """Yield (script, language, line) for each here-document a shell in a tree reads as its
    script: given to it directly (`sh <<EOF`), or piped to it (`cat <<EOF | sh`)."""
    if isinstance(node, dict):
        language = stdin_shell(node) if "Cmd" in node else None
        if language:
            for body, line in heredoc_bodies(node, source):
                yield body, language, line
        cmd = node.get("Cmd") or {}
        if cmd.get("Type") == "BinaryCmd" and cmd.get("Op") in ("|", "|&"):
            language = stdin_shell(cmd["Y"])
            if language:
                for body, line in heredoc_bodies(cmd["X"], source):
                    yield body, language, line
        for value in node.values():
            yield from heredoc_scripts(value, source)
    elif isinstance(node, list):
        for value in node:
            yield from heredoc_scripts(value, source)


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
