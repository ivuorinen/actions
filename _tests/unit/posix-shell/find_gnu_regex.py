"""Report GNU-only sed and grep syntax in the shell embedded in the given files.

POSIX leaves a backslash before an ordinary character undefined, so `\\s` or a basic `\\+`
means what GNU gives it only on GNU tools. BSD regex treats the same text as a literal,
which makes a pattern match nothing and raises no error. .claude/rules/posix-shell.md also
requires `sed -E` everywhere, so a sed without it is reported even when its syntax is portable.

Files are read as text, not parsed as YAML or shell, so this also sees `run:` blocks at any
depth and command substitutions nested inside double quotes. It also means the word sed in
prose on a non-comment line is reported: reword the prose.
"""

from pathlib import Path
import re
import shlex
import sys

INVOCATION = re.compile(r"(?<![\w./-])(sed|grep)(?=\s)")
SHELL_OPERATORS = set("();<>|&")

# Undefined by POSIX in basic and extended patterns alike.
GNU_ESCAPE = re.compile(r"\\[sSwWdDbB<>]")
# GNU extensions in a basic pattern. In an extended pattern these are portable literals.
GNU_BASIC_ESCAPE = re.compile(r"\\[+?|]")

# A short option bundle holding -E, including one that ends in an attached -i extension.
EXTENDED = r"-\w*E.*"

# POSIX leaves a { that does not start an interval undefined. ${VAR} is the shell's, not sed's.
BARE_BRACE = re.compile(r"\{(?![0-9])")
VARIABLE = re.compile(r"\$\{\w+\}")


def logical_lines(text: str):
    """Yield (first line number, line), joining backslash continuations."""
    start, parts = 1, []
    for number, line in enumerate(text.splitlines(), 1):
        if not parts:
            start = number
        if line.endswith("\\"):
            parts.append(line[:-1])
            continue
        parts.append(line)
        yield start, "".join(parts)
        parts = []
    if parts:
        yield start, "".join(parts)


def invocation_args(text: str) -> list[str]:
    """Return the arguments up to the next shell operator, honouring quotes."""
    lexer = shlex.shlex(text, posix=True, punctuation_chars=True)
    lexer.whitespace_split = True
    lexer.commenters = ""
    args = []
    try:
        for token in lexer:
            if set(token) <= SHELL_OPERATORS:
                break
            args.append(token)
    except ValueError:
        # Unbalanced quote: prose inside an echo, or a pattern that spans lines.
        return [text]
    return args


def options(args: list[str]) -> list[str]:
    """Return the arguments before `--` that start with a dash."""
    found = []
    for arg in args:
        if arg == "--":
            break
        if arg.startswith("-"):
            found.append(arg)
    return found


def has_short(opts: list[str], pattern: str) -> bool:
    """Tell whether a bundle of short options fully matches the pattern."""
    return any(not o.startswith("--") and re.fullmatch(pattern, o) for o in opts)


def has_long(opts: list[str], name: str) -> bool:
    """Tell whether a long option is present, with or without a value."""
    return any(o == name or o.startswith(f"{name}=") for o in opts)


def option_problems(tool: str, opts: list[str]) -> list[str]:
    """Return the GNU-only options in use."""
    problems = []
    if tool == "grep" and (has_short(opts, r"-\w*P\w*") or has_long(opts, "--perl-regexp")):
        problems.append("grep -P is GNU-only, use grep -E")
    if tool == "sed":
        if has_short(opts, r"-\w*i") or has_long(opts, "--in-place"):
            problems.append("sed -i needs an attached extension, use sed -i.bak")
        if not has_short(opts, EXTENDED):
            problems.append("sed without -E, see .claude/rules/posix-shell.md")
    return problems


def bracket_end(script: str, start: int) -> int:
    """Return the position after the bracket expression opening at start."""
    index = start + 1
    if script.startswith("^", index):
        index += 1
    if script.startswith("]", index):
        index += 1
    while index < len(script):
        char = script[index]
        if char == "]":
            return index + 1
        if char == "[" and script[index + 1 : index + 2] in (":", ".", "="):
            closing = script.find(script[index + 1] + "]", index + 2)
            index = len(script) if closing == -1 else closing + 2
        else:
            index += 1
    return len(script)


def regex_text(script: str, start: int, delimiter: str) -> tuple[str | None, int]:
    """Read a regex up to its delimiter, minus escapes, bracket expressions and ${VAR}.

    Returns the text and the position after the delimiter. The text is None if it never closes.
    """
    text = []
    index = start
    while index < len(script):
        char = script[index]
        if char == delimiter:
            return "".join(text), index + 1
        if char == "\\":
            index += 2
        elif char == "[":
            index = bracket_end(script, index)
        elif variable := VARIABLE.match(script, index):
            index = variable.end()
        else:
            text.append(char)
            index += 1
    return None, index


def substitution_regexes(script: str) -> list[str]:
    """Return the regex of each s command, so a replacement is not read as a pattern.

    This walks the characters because a regex for the same job backtracks exponentially on
    input such as `s![][][]`.
    """
    regexes = []
    index = 0
    while index < len(script) - 1:
        before = script[index - 1] if index else " "
        delimiter = script[index + 1]
        if (
            script[index] == "s"
            and (before in ";{" or before.isspace())
            and not (delimiter.isalnum() or delimiter.isspace() or delimiter == "_")
        ):
            regex, index = regex_text(script, index + 2, delimiter)
            if regex is not None:
                regexes.append(regex)
        else:
            index += 1
    return regexes


def pattern_problems(tool: str, opts: list[str], args: list[str]) -> list[str]:
    """Return the GNU-only or misread regex syntax in the arguments."""
    if tool == "grep" and (has_short(opts, r"-\w*F\w*") or has_long(opts, "--fixed-strings")):
        return []
    extended = has_short(opts, EXTENDED) or has_long(opts, "--extended-regexp")

    problems = []
    for arg in args:
        # A doubled backslash is a literal one, so it cannot start an escape.
        plain = arg.replace("\\\\", "")
        problems.extend(
            f"{escape} is GNU-only, use a bracket expression"
            for escape in GNU_ESCAPE.findall(plain)
        )
        if not extended:
            problems.extend(
                f"{escape} is GNU-only in a basic pattern, use {tool} -E"
                for escape in GNU_BASIC_ESCAPE.findall(plain)
            )
        if tool == "sed" and any(BARE_BRACE.search(regex) for regex in substitution_regexes(plain)):
            problems.append(r"a literal { must be \{ in an extended pattern")
    return problems


def scan(path: str) -> list[str]:
    """Return one `path:line: problem` entry per problem found."""
    findings = []
    for number, line in logical_lines(Path(path).read_text(encoding="utf-8")):
        if line.lstrip().startswith("#"):
            continue
        for match in INVOCATION.finditer(line):
            tool = match.group(1)
            args = invocation_args(line[match.end() :])
            opts = options(args)
            problems = option_problems(tool, opts) + pattern_problems(tool, opts, args)
            findings.extend(f"{path}:{number}: {problem}" for problem in problems)
    return findings


def main(paths: list[str]) -> int:
    """Print every finding across the given files; fail if there are any."""
    if not paths:
        print("usage: find_gnu_regex.py FILE...")
        return 2
    # One line can repeat a problem, as with several \+ in one pattern.
    findings = dict.fromkeys(finding for path in paths for finding in scan(path))
    for finding in findings:
        print(finding)
    return 1 if findings else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
