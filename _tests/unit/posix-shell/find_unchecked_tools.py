"""Report run: steps in the given files that call an external tool before checking for it.

.claude/rules/posix-shell.md lists the external tools the repository's scripts use that are
not POSIX utilities, and requires `command -v <tool>` before any of them is used. Without
the check a missing tool does not always stop the step: `count=$(git diff --name-only | wc -l)`
takes its status from wc, so the count is 0, and `if git rev-parse ...` takes the else branch.
The tools are read from that rule, so the list exists once.

Files are parsed as YAML, so each run: value is the script GitHub runs, with YAML quoting,
escapes and line folding already decoded. Steps whose shell: is not sh or bash are skipped.
In each script, the first call of each tool must come after a `command -v <tool>` check, in
the order the shell runs them, a call and a check on one line included. Each line is read
quote-aware: a comment starts at a `#` that begins a word outside quotes, quoted text is
neither a call nor a check, and a `$(...)` inside double quotes still runs.

A call is a tool name in command position: the first word of a command after the start of
a line, `;`, `&&`, `||`, `|`, `&`, `(`, `$(` or a backquote, past keywords such as `if`,
`then` or `!` and past `NAME=value` assignments; the word a wrapper such as `sudo` or `exec`
runs; or the word after `set --`, which builds a command that "$@" runs later. A quoted
command name such as `"git"` is the word git. A word anywhere else, such as a value in
`manager="npm"` or a `case` pattern before its `)`, is not a call. The body of a
here-document is data and is skipped. Shell quotes that span lines are not followed.
"""

from pathlib import Path
import re
import sys

import yaml

RULE = Path(__file__).resolve().parents[3] / ".claude" / "rules" / "posix-shell.md"
# The paragraph of the rule that lists the tools needing the check, up to its closing period.
# The rule wraps its lines anywhere, so any whitespace separates the words.
TOOL_LIST = re.compile(
    r"each\s+needing\s+that\s+check\s+before\s+its\s+first\s+use\s+in\s+a\s+script:\s*\n(.*?)\.\n",
    re.DOTALL,
)
SHELLS = {"sh", "bash"}
HEREDOC = re.compile(r"<<-?\s*(['\"]?)([A-Za-z_][A-Za-z0-9_]*)\1")


def rule_tools(rule_text):
    """Return the tools the rule says need a `command -v` check, in the rule's order."""
    match = TOOL_LIST.search(rule_text)
    if not match:
        sys.exit(f"{RULE}: the list of tools that need a command -v check was not found")
    return re.findall(r"`([^`]+)`", match.group(1))


TOOLS = rule_tools(RULE.read_text(encoding="utf-8"))
NAMES = "|".join(re.escape(tool) for tool in TOOLS)
# `command -v "git"` looks up git, so a quoted name is unquoted before checks are matched.
QUOTED_TOOL = re.compile(rf"""(["'])({NAMES})\1""")
CHECKS = {tool: re.compile(rf"\bcommand\s+-v\s+{re.escape(tool)}(?![\w./:$-])") for tool in TOOLS}
# Text that ends one command and starts the next.
SEPARATORS = re.compile(r"\$\(|;;|&&|\|\||[;|&()`]")
KEYWORDS = {
    "if",
    "then",
    "else",
    "elif",
    "fi",
    "do",
    "done",
    "while",
    "until",
    "!",
    "{",
    "}",
    "time",
}
# Words that run the word after them as a command.
WRAPPERS = {"sudo", "exec", "nohup", "xargs", "env", "command"}
ASSIGNMENT = re.compile(r"[A-Za-z_][A-Za-z0-9_]*=")


def without_case_pattern(code):
    """Blank a `case` pattern: the text before a `)` that closes no `(` on the line."""
    depth = 0
    for index, char in enumerate(code):
        if char == "(":
            depth += 1
        elif char == ")":
            if depth == 0:
                return " " * (index + 1) + code[index + 1 :]
            depth -= 1
    return code


def command_words(code, line):
    """Return (position, word) for each word in command position.

    `code` is the line's executable text and `line` the original, which share positions, so
    a quoted command name blanked in `code` is read from `line`.
    """
    code = without_case_pattern(code)
    found = []
    starts = [0] + [match.end() for match in SEPARATORS.finditer(code)]
    ends = [match.start() for match in SEPARATORS.finditer(code)] + [len(code)]
    for start, end in zip(starts, ends, strict=True):
        tokens = [
            (m.start() + start, line[m.start() + start : m.end() + start])
            for m in re.finditer(r"\S+", code[start:end])
        ]
        index = 0
        while index < len(tokens) and (
            tokens[index][1] in KEYWORDS or ASSIGNMENT.match(tokens[index][1])
        ):
            index += 1
        if index == len(tokens) or tokens[index][1] in ("for", "case"):
            continue
        position, word = tokens[index]
        if word == "set" and index + 2 < len(tokens) and tokens[index + 1][1] == "--":
            position, word = tokens[index + 2]
        while True:
            name = (
                word[1:-1] if len(word) > 1 and word[0] == word[-1] and word[0] in "'\"" else word
            )
            found.append((position, name))
            if name not in WRAPPERS or (
                name == "command" and index + 1 < len(tokens) and tokens[index + 1][1] == "-v"
            ):
                break
            index += 1
            while index < len(tokens) and (
                tokens[index][1].startswith("-") or ASSIGNMENT.match(tokens[index][1])
            ):
                index += 1
            if index == len(tokens):
                break
            position, word = tokens[index]
    return found


def executable_text(line):
    """Return the line without its comment and with quoted text blanked, keeping each
    character's position. A command substitution inside double quotes is kept.

    Quoted text becomes underscores, not spaces, so a quoted word stays one word and a
    quoted command name can be read back from the original line at the same position.
    """
    out = []
    quote = None
    depth = 0
    index = 0
    while index < len(line):
        char = line[index]
        if quote == "'":
            quote = None if char == "'" else quote
            out.append(char if char == "'" else "_")
        elif quote == '"':
            if char == "\\" and index + 1 < len(line):
                out.append("__")
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
                out.append("_")
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


def fields(node):
    """Return a mapping node's scalar keys and their value nodes; any other node has none."""
    if not isinstance(node, yaml.MappingNode):
        return {}
    return {key.value: value for key, value in node.value if isinstance(key, yaml.ScalarNode)}


def shell_scripts(text):
    """Yield the (line number, text) pairs of each sh or bash run: in the action's runs.steps.

    Only steps run scripts, so a key named run anywhere else, such as in env:, is not one.
    A literal block keeps its lines, so each maps to its own source line. Other styles fold
    or decode their lines, so those all carry the line where the value starts.
    """
    steps = fields(fields(yaml.compose(text)).get("runs")).get("steps")
    if not isinstance(steps, yaml.SequenceNode):
        return
    for step in steps.value:
        run, shell = fields(step).get("run"), fields(step).get("shell")
        shell_words = shell.value.split() if isinstance(shell, yaml.ScalarNode) else []
        if not isinstance(run, yaml.ScalarNode) or (shell_words and shell_words[0] not in SHELLS):
            continue
        lines = run.value.split("\n")
        if run.style == "|":
            first = run.start_mark.line + 2
            yield [(first + offset, line) for offset, line in enumerate(lines)]
        else:
            yield [(run.start_mark.line + 1, line) for line in lines]


def joined_lines(script):
    """Yield (line number, text) with each backslash-continued line joined to the next, so
    an argument on a continuation line is not read as a command. The number is the first's."""
    pending_number, parts = None, []
    for number, line in script:
        if pending_number is None:
            pending_number = number
        # A backslash inside a comment continues nothing, and executable_text drops comments.
        if executable_text(line).endswith("\\"):
            parts.append(line[:-1])
            continue
        parts.append(line)
        yield pending_number, " ".join(parts)
        pending_number, parts = None, []
    if parts:
        yield pending_number, " ".join(parts)


def unchecked_calls(text):
    """Return (line number, tool) for the first unchecked call of each tool in each script."""
    found = []
    for script in shell_scripts(text):
        settled = set()
        heredoc = None
        for number, line in joined_lines(script):
            if heredoc is not None:
                if line.strip() == heredoc:
                    heredoc = None
                continue
            code = executable_text(line)
            check_code = executable_text(QUOTED_TOOL.sub(r"\2", line))
            calls = command_words(code, line)
            for tool in TOOLS:
                if tool in settled:
                    continue
                check = CHECKS[tool].search(check_code)
                call = next((position for position, word in calls if word == tool), None)
                if call is not None and (check is None or call < check.start()):
                    found.append((number, tool))
                    settled.add(tool)
                elif check:
                    settled.add(tool)
            # The delimiter is read from the original line, where its quotes are not blanked;
            # the `<<` must be code there, not text inside quotes or a comment.
            opener = next(
                (m for m in HEREDOC.finditer(line) if code[m.start() : m.start() + 2] == "<<"), None
            )
            if opener:
                heredoc = opener.group(2)
    return sorted(found)


def main(paths):
    status = 0
    for path in paths:
        text = Path(path).read_text(encoding="utf-8")
        for number, tool in unchecked_calls(text):
            print(f"{path}:{number}: {tool} is called before `command -v {tool}` checks for it")
            status = 1
    return status


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
