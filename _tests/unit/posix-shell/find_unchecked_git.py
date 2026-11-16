"""Report run: blocks in the given files that call git before checking that it exists.

.claude/rules/posix-shell.md lists git among the external tools and requires
`command -v <tool>` before any of them is used. Without the check a missing git does not
always stop the step: `count=$(git diff --name-only | wc -l)` takes its status from wc,
so the count is 0, and `if git rev-parse ...` takes the else branch.

Files are read as text, not parsed as YAML, the same way find_gnu_regex.py reads them. A
run: block is a block scalar after `run:`, made of the lines indented deeper than the key,
or the rest of the line after `run:`. In each block, the first git call must come after a
`command -v git` check, in the order the shell runs them, a call and a check on one line
included. Each line is read quote-aware: a comment starts at a `#` that begins a word
outside quotes, quoted text is neither a call nor a check, and a `$(...)` inside double
quotes still runs. A word that only contains git, such as gitleaks or .git, is not a call.
Quotes that span lines are not followed.
"""

from pathlib import Path
import re
import sys

RUN_KEY = re.compile(r"^(?P<lead>\s*(?:-\s+)?)run:\s*(?P<rest>.*)$")
BLOCK_INDICATOR = re.compile(r"^[|>][-+0-9]*\s*(#.*)?$")
GIT_CALL = re.compile(r"(?<![\w./:$-])git(?=\s)")
GIT_CHECK = re.compile(r"\bcommand\s+-v\s+git\b")


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


def run_blocks(lines):
    """Yield the (line number, text) pairs of each run: block in the file's lines."""
    index = 0
    while index < len(lines):
        match = RUN_KEY.match(lines[index])
        if not match:
            index += 1
            continue
        rest = match.group("rest")
        if not BLOCK_INDICATOR.match(rest):
            yield [(index + 1, rest)]
            index += 1
            continue
        key_column = len(match.group("lead"))
        block = []
        index += 1
        while index < len(lines):
            line = lines[index]
            if line.strip() and len(line) - len(line.lstrip()) <= key_column:
                break
            block.append((index + 1, line))
            index += 1
        yield block


def unchecked_calls(text):
    """Return the line numbers of the first unchecked git call in each run: block."""
    found = []
    for block in run_blocks(text.splitlines()):
        for number, line in block:
            code = executable_text(line)
            check = GIT_CHECK.search(code)
            call = GIT_CALL.search(code)
            # The git in `command -v git` matches GIT_CALL too, so a check counts only when it
            # starts before the first call on the line.
            if call and (check is None or call.start() < check.start()):
                found.append(number)
                break
            if check:
                break
    return found


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
