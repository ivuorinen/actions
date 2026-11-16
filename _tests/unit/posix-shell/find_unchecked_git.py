"""Report run: steps in the given files that call git before checking that it exists.

.claude/rules/posix-shell.md lists git among the external tools and requires
`command -v <tool>` before any of them is used. Without the check a missing git does not
always stop the step: `count=$(git diff --name-only | wc -l)` takes its status from wc,
so the count is 0, and `if git rev-parse ...` takes the else branch.

Files are parsed as YAML, so each run: value is the script GitHub runs, with YAML quoting,
escapes and line folding already decoded. Steps whose shell: is not sh or bash are skipped.
In each script the first git call must come after a `command -v git` check, in the order
the shell runs them, a call and a check on one line included. Each line is read
quote-aware: a comment starts at a `#` that begins a word outside quotes, quoted text is
neither a call nor a check, and a `$(...)` inside double quotes still runs. `"git"` and
`'git'` are the word git. A word that only contains git, such as gitleaks or .git, is not a
call. Shell quotes that span lines are not followed.
"""

from pathlib import Path
import re
import sys

import yaml

GIT_CALL = re.compile(r"(?<![\w./:$-])git(?=\s)")
GIT_CHECK = re.compile(r"\bcommand\s+-v\s+git\b")
# `"git"` and `'git'` are the word git to the shell, as a command name or as the name
# `command -v` looks up, so they are unquoted before quoted text is blanked.
QUOTED_GIT = re.compile(r"""(["'])git\1""")
SHELLS = {"sh", "bash"}


def executable_text(line):
    """Return the line without its comment and with quoted text blanked, keeping each
    character's position. A command substitution inside double quotes is kept."""
    out = []
    quote = None
    depth = 0
    index = 0
    while index < len(line):
        char = line[index]
        if quote == "'":
            quote = None if char == "'" else quote
            out.append(char if char == "'" else " ")
        elif quote == '"':
            if char == "\\" and index + 1 < len(line):
                out.append("  ")
                index += 2
                continue
            if line.startswith("$(", index):
                depth += 1
                out.append("$(")
                index += 2
                continue
            if depth:
                depth -= char == ")"
                out.append(char)
            elif char == '"':
                quote = None
                out.append(char)
            else:
                out.append(" ")
        elif char == "\\" and index + 1 < len(line):
            out.append(line[index : index + 2])
            index += 2
            continue
        elif char in "'\"":
            quote = char
            out.append(char)
        elif char == "#" and (index == 0 or line[index - 1].isspace()):
            break
        else:
            out.append(char)
        index += 1
    return "".join(out)


def shell_scripts(text):
    """Yield the (line number, text) pairs of each sh or bash run: value in the YAML text.

    A literal block keeps its lines, so each maps to its own source line. Other styles fold
    or decode their lines, so those all carry the line where the value starts.
    """
    stack = [yaml.compose(text)]
    while stack:
        node = stack.pop()
        if isinstance(node, yaml.SequenceNode):
            stack.extend(node.value)
            continue
        if not isinstance(node, yaml.MappingNode):
            continue
        fields = {key.value: value for key, value in node.value if isinstance(key, yaml.ScalarNode)}
        run, shell = fields.get("run"), fields.get("shell")
        shell_words = shell.value.split() if isinstance(shell, yaml.ScalarNode) else []
        if isinstance(run, yaml.ScalarNode) and (not shell_words or shell_words[0] in SHELLS):
            lines = run.value.split("\n")
            if run.style == "|":
                first = run.start_mark.line + 2
                yield [(first + offset, line) for offset, line in enumerate(lines)]
            else:
                yield [(run.start_mark.line + 1, line) for line in lines]
        stack.extend(value for _, value in node.value)


def unchecked_calls(text):
    """Return the line numbers of the first unchecked git call in each run: script."""
    found = []
    for script in shell_scripts(text):
        for number, line in script:
            code = executable_text(QUOTED_GIT.sub("git", line))
            check = GIT_CHECK.search(code)
            call = GIT_CALL.search(code)
            # The git in `command -v git` matches GIT_CALL too, so a check counts only when it
            # starts before the first call on the line.
            if call and (check is None or call.start() < check.start()):
                found.append(number)
                break
            if check:
                break
    return sorted(found)


def main(paths):
    status = 0
    for path in paths:
        text = Path(path).read_text(encoding="utf-8")
        for number in unchecked_calls(text):
            print(f"{path}:{number}: git is called before `command -v git` checks for it")
            status = 1
    return status


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
