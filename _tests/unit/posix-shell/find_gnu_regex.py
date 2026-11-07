"""Report GNU-only sed and grep syntax in the shell embedded in the given files.

POSIX leaves a backslash before an ordinary character undefined, so `\\s` or a basic `\\+`
means what GNU gives it only on GNU tools. BSD regex treats the same text as a literal,
which makes a pattern match nothing and raises no error. See .claude/rules/posix-shell.md.

Files are read as text, not parsed as YAML or shell, so this also sees `run:` blocks at any
depth and command substitutions nested inside double quotes.
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

# The regex of each s command, so a replacement is not read as a pattern.
SUBSTITUTION = re.compile(r"(?:^|[;{\s])s([^\w\s])((?:\\.|\[[^\]]*\]+|(?!\1).)*)\1")
ESCAPE_OR_BRACKET = re.compile(r"\\.|\[[^\]]*\]+")
ERE_OPERATOR = re.compile(r"[+?|()]")


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
        if has_short(opts, r"-\w*r\w*") or has_long(opts, "--regexp-extended"):
            problems.append("sed -r is not the portable spelling, use sed -E")
    return problems


def pattern_problems(tool: str, opts: list[str], args: list[str]) -> list[str]:
    """Return the GNU-only or misread regex syntax in the arguments."""
    if tool == "grep" and (has_short(opts, r"-\w*F\w*") or has_long(opts, "--fixed-strings")):
        return []
    long_extended = "--extended-regexp" if tool == "grep" else "--regexp-extended"
    extended = has_short(opts, r"-\w*[Er]\w*" if tool == "sed" else r"-\w*E\w*") or has_long(
        opts, long_extended
    )

    problems = []
    for arg in args:
        # A doubled backslash is a literal one, so it cannot start an escape.
        plain = arg.replace("\\\\", "")
        problems.extend(
            f"{escape} is GNU-only, use a bracket expression"
            for escape in GNU_ESCAPE.findall(plain)
        )
        if extended:
            continue
        problems.extend(
            f"{escape} is GNU-only in a basic pattern, use {tool} -E"
            for escape in GNU_BASIC_ESCAPE.findall(plain)
        )
        if tool == "sed" and any(
            ERE_OPERATOR.search(ESCAPE_OR_BRACKET.sub("", substitution.group(2)))
            for substitution in SUBSTITUTION.finditer(plain)
        ):
            problems.append("extended operators are literal without sed -E")
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
