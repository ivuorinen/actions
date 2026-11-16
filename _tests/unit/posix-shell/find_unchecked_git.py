"""Report run: blocks in the given files that call git before checking that it exists.

.claude/rules/posix-shell.md lists git among the external tools and requires
`command -v <tool>` before any of them is used. Without the check a missing git does not
always stop the step: `count=$(git diff --name-only | wc -l)` takes its status from wc,
so the count is 0, and `if git rev-parse ...` takes the else branch.

Files are read as text, not parsed as YAML, the same way find_gnu_regex.py reads them. A
run: block is a block scalar after `run:`, made of the lines indented deeper than the key,
or the rest of the line after `run:`. In each block, the first line that calls git must
come after a line that runs `command -v git`. Comments are skipped, and a word that only
contains git, such as gitleaks or .git, is not a call.
"""

from pathlib import Path
import re
import sys

RUN_KEY = re.compile(r"^(?P<lead>\s*(?:-\s+)?)run:\s*(?P<rest>.*)$")
BLOCK_INDICATOR = re.compile(r"^[|>][-+0-9]*\s*(#.*)?$")
GIT_CALL = re.compile(r"(?<![\w./:$-])git(?=\s)")
GIT_CHECK = re.compile(r"\bcommand\s+-v\s+git\b")
COMMENT = re.compile(r"(^|\s)#.*$")


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
            code = COMMENT.sub("", line)
            if GIT_CHECK.search(code):
                break
            if GIT_CALL.search(code):
                found.append(number)
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
