"""Report run: steps in the given files that call an external tool before checking for it.

.claude/rules/posix-shell.md lists the external tools the repository's scripts use that are
not POSIX utilities, and requires `command -v <tool>` before any of them is used. Without
the check a missing tool does not always stop the step: `count=$(git diff --name-only | wc -l)`
takes its status from wc, so the count is 0, and `if git rev-parse ...` takes the else branch.
The tools are read from that rule, so the list exists once.

Files are parsed as YAML, so each run: value is the script GitHub runs, with YAML quoting,
escapes and line folding already decoded. Steps whose shell: is not sh or bash are skipped.
shfmt parses each script into its syntax tree (`shfmt --to-json`), so quoting, comments,
here-documents, redirections, arithmetic and command substitutions are read the way the shell
reads them, not matched as text.

A call is the command a simple command runs: its first word, past assignments and
redirections; the command a wrapper such as sudo, env, timeout, xargs, exec or eval runs,
past the wrapper's options; the command after find's -exec; or the word after `set --`, which
builds a command that "$@" runs later. The script given to `sh -c`, and a here-document fed to
sh or bash, are read as scripts; any other here-document is data. A word with an expansion,
such as "$@", names no command. A call through a function the script defines is not followed.

A check is `command -v <tool>` in a form that stops the step when the tool is missing:
`command -v <tool> ... || { ...; exit 1; }`, or `if ! command -v <tool> ...; then ... exit; fi`.
It covers what runs after it in the same block. `if command -v <tool> ...; then` and
`command -v <tool> ... && ...` cover only the code they guard. A check in one branch of an if
or case covers code after the if or case only when every branch that goes on checks too; a
check in a subshell, a pipeline, a loop, a function body or a command substitution covers
nothing outside it.
"""

from functools import reduce
import json
from pathlib import Path
import re
import shutil
import subprocess
import sys

import yaml

RULE = Path(__file__).resolve().parents[3] / ".claude" / "rules" / "posix-shell.md"
# The paragraph of the rule that lists the tools needing the check, up to its closing period.
# The rule wraps its lines anywhere, so any whitespace separates the words.
TOOL_LIST = re.compile(
    r"each\s+needing\s+that\s+check\s+before\s+its\s+first\s+use\s+in\s+a\s+script:\s*\n(.*?)\.\n",
    re.DOTALL,
)
# shfmt's language for each shell a step can name.
SHELLS = {"sh": "posix", "bash": "bash"}
# For each wrapper that runs the command after its options: the options that take an argument.
WRAPPERS = {
    "command": set(),
    "eval": set(),
    "exec": {"-a"},
    "env": {"-u", "-C", "-S"},
    "nice": {"-n"},
    "nohup": set(),
    "sudo": {"-u", "-g", "-C", "-D", "-h", "-p", "-r", "-t", "-U", "-T"},
    "timeout": {"-s", "-k"},
    "xargs": {"-n", "-L", "-P", "-s", "-I", "-E", "-d", "-a"},
}
# timeout's first operand is the duration, not the command.
OPERANDS_BEFORE_COMMAND = {"timeout": 1}
FIND_EXEC = {"-exec", "-execdir", "-ok", "-okdir"}
ASSIGNMENT = re.compile(r"[A-Za-z_][A-Za-z0-9_]*=")
TERMINATORS = {"exit", "return"}


def rule_tools(rule_text):
    """Return the tools the rule says need a `command -v` check, in the rule's order."""
    match = TOOL_LIST.search(rule_text)
    if not match:
        sys.exit(f"{RULE}: the list of tools that need a command -v check was not found")
    return re.findall(r"`([^`]+)`", match.group(1))


TOOLS = set(rule_tools(RULE.read_text(encoding="utf-8")))
SHFMT = shutil.which("shfmt")


def literal(word):
    """Return the text of a word that has no expansion, or None."""
    text = []
    for part in (word or {}).get("Parts") or []:
        kind = part.get("Type")
        # shfmt leaves an empty Value out of its JSON.
        if kind == "Lit":
            text.append(re.sub(r"\\(.)", r"\1", part.get("Value", "")))
        elif kind == "SglQuoted":
            text.append(part.get("Value", ""))
        elif kind == "DblQuoted":
            inner = literal(part)
            if inner is None:
                return None
            text.append(inner)
        else:
            return None
    return "".join(text)


def command_names(words):
    """Return the command names a simple command runs, from its words (None: not literal)."""
    names = []
    index = 2 if len(words) > 2 and words[0] == "set" and words[1] == "--" else 0
    while index < len(words) and words[index] is not None:
        name = words[index]
        names.append(name)
        if name == "find":
            names.extend(
                words[at + 1]
                for at in range(index, len(words) - 1)
                if words[at] in FIND_EXEC and words[at + 1] is not None
            )
            break
        if name not in WRAPPERS or (
            name == "command" and index + 1 < len(words) and words[index + 1] in ("-v", "-V")
        ):
            break
        index += 1
        while (
            index < len(words)
            and words[index] is not None
            and (words[index].startswith("-") or (name == "env" and ASSIGNMENT.match(words[index])))
        ):
            index += 2 if words[index] in WRAPPERS[name] else 1
        index += OPERANDS_BEFORE_COMMAND.get(name, 0)
        if name == "eval" and index < len(words) and words[index] is not None:
            # eval runs its operands as shell code; the first word of that code is the command.
            names.extend(words[index].split()[:1])
            break
    return names


def checked_tool(stmt):
    """Return the tool a statement looks up with `command -v <tool>`, or None."""
    cmd = stmt.get("Cmd") or {}
    if cmd.get("Type") != "CallExpr":
        return None
    words = [literal(word) for word in cmd.get("Args") or []]
    if len(words) >= 3 and words[0] == "command" and words[1] == "-v" and words[2] in TOOLS:
        return words[2]
    return None


def and_chain(stmt):
    """Return the statements of `a && b && c`, or the statement itself."""
    cmd = stmt.get("Cmd") or {}
    if cmd.get("Type") == "BinaryCmd" and cmd.get("Op") == "&&" and not stmt.get("Negated"):
        return and_chain(cmd["X"]) + and_chain(cmd["Y"])
    return [stmt]


def terminates(stmts):
    """Whether a statement list always ends with exit or return."""
    for stmt in stmts:
        cmd = stmt.get("Cmd") or {}
        kind = cmd.get("Type")
        if kind == "CallExpr" and cmd.get("Args") and literal(cmd["Args"][0]) in TERMINATORS:
            return True
        if kind == "Block" and terminates(cmd.get("Stmts") or []):
            return True
        if kind == "IfClause" and if_terminates(cmd):
            return True
    return False


def if_terminates(node):
    """Whether every branch of an if, an else included, ends with exit or return."""
    otherwise = node.get("Else")
    if not terminates(node.get("Then") or []) or not otherwise:
        return False
    if otherwise.get("Cond"):
        return if_terminates(otherwise)
    return terminates(otherwise.get("Then") or [])


class ParseError(Exception):
    """shfmt could not parse a script."""


def parse(text, language):
    """Return shfmt's syntax tree of a script, or raise ParseError with shfmt's message."""
    if SHFMT is None:
        message = "shfmt is required to parse run: scripts"
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


class Scan:
    """Walk one script, recording the first unchecked call of each tool in `found`."""

    def __init__(self, text, line_of, found):
        self.source = text.encode("utf-8")
        self.line_of = line_of
        self.found = found

    def call(self, tool, pos, settled):
        if tool in TOOLS and tool not in settled and tool not in self.found:
            self.found[tool] = self.line_of(pos["Line"])

    def script(self, text, language, line, settled):
        """Walk a script that a command in this one runs: a child shell, so nothing it checks
        covers this script."""
        tree = parse(text, language)
        Scan(text, lambda _line: self.line_of(line), self.found).stmts(
            tree.get("Stmts") or [], settled
        )

    def substitutions(self, node, settled):
        """Walk the command substitutions anywhere inside a node."""
        if isinstance(node, dict):
            if node.get("Type") in ("CmdSubst", "ProcSubst"):
                self.stmts(node.get("Stmts") or [], settled)
                return
            for value in node.values():
                self.substitutions(value, settled)
        elif isinstance(node, list):
            for value in node:
                self.substitutions(value, settled)

    def stmts(self, stmts, settled):
        for stmt in stmts:
            settled = self.stmt(stmt, settled)
        return settled

    def stmt(self, stmt, settled):
        for redirect in stmt.get("Redirs") or []:
            self.substitutions(redirect.get("Word"), settled)
        cmd = stmt.get("Cmd")
        if not cmd:
            return settled
        if cmd["Type"] == "CallExpr":
            return self.call_expr(cmd, stmt, settled)
        handler = {
            "BinaryCmd": self.binary_cmd,
            "IfClause": self.if_clause,
            "CaseClause": self.case_clause,
            "Block": self.block,
            "Subshell": self.subshell,
            "WhileClause": self.while_clause,
            "ForClause": self.for_clause,
            "FuncDecl": self.func_decl,
            "TimeClause": self.time_clause,
        }.get(cmd["Type"])
        if handler is None:
            self.substitutions(cmd, settled)
            return settled
        return handler(cmd, settled)

    def call_expr(self, cmd, stmt, settled):
        self.substitutions(cmd.get("Assigns"), settled)
        self.substitutions(cmd.get("Args"), settled)
        words = [literal(word) for word in cmd.get("Args") or []]
        names = command_names(words)
        for name in names:
            self.call(name, cmd["Pos"], settled)
        line = cmd["Pos"]["Line"]
        for at, word in enumerate(words[:-2]):
            if word in SHELLS and words[at + 1] == "-c" and words[at + 2] is not None:
                self.script(words[at + 2], SHELLS[word], line, settled)
        if names and names[-1] in SHELLS and "-c" not in words:
            for redirect in stmt.get("Redirs") or []:
                hdoc = redirect.get("Hdoc")
                if hdoc:
                    body = self.source[hdoc["Pos"]["Offset"] : hdoc["End"]["Offset"]].decode(
                        "utf-8"
                    )
                    # The byte range ends with the closing delimiter's line.
                    body = body.rsplit("\n", 1)[0] if "\n" in body else ""
                    self.script(body, SHELLS[names[-1]], hdoc["Pos"]["Line"], settled)
        return settled

    def binary_cmd(self, cmd, settled):
        first, second, op = cmd["X"], cmd["Y"], cmd["Op"]
        tool = None if first.get("Negated") else checked_tool(first)
        if op in ("|", "|&"):
            self.stmt(first, settled)
            self.stmt(second, settled)
            return settled
        after_first = self.stmt(first, settled)
        if op == "||" and tool and terminates([second]):
            self.stmt(second, after_first)
            return after_first | {tool}
        self.stmt(second, after_first | ({tool} if tool and op == "&&" else set()))
        return after_first

    def if_clause(self, cmd, settled):
        cond = cmd.get("Cond") or []
        after_cond = self.stmts(cond, settled)
        chain = and_chain(cond[-1]) if cond else []
        guarded = {checked_tool(s) for s in chain if not s.get("Negated")} - {None}
        # `if ! command -v t` goes on to the else branch only when t is there.
        missing = (
            {checked_tool(chain[0])} - {None}
            if len(chain) == 1 and chain[0].get("Negated")
            else set()
        )
        ends = []
        then = cmd.get("Then") or []
        then_end = self.stmts(then, after_cond | guarded)
        if not terminates(then):
            ends.append(then_end)
        otherwise = cmd.get("Else")
        if not otherwise:
            ends.append(after_cond | missing)
        elif otherwise.get("Cond"):
            else_end = self.if_clause(otherwise, after_cond | missing)
            if not if_terminates(otherwise):
                ends.append(else_end)
        else:
            body = otherwise.get("Then") or []
            else_end = self.stmts(body, after_cond | missing)
            if not terminates(body):
                ends.append(else_end)
        return reduce(lambda left, right: left & right, ends) if ends else after_cond

    def case_clause(self, cmd, settled):
        self.substitutions(cmd.get("Word"), settled)
        ends = []
        default = False
        for item in cmd.get("Items") or []:
            self.substitutions(item.get("Patterns"), settled)
            default = default or "*" in [literal(word) for word in item.get("Patterns") or []]
            body = item.get("Stmts") or []
            end = self.stmts(body, settled)
            if not terminates(body):
                ends.append(end)
        if not default:
            ends.append(settled)
        return reduce(lambda left, right: left & right, ends) if ends else settled

    def block(self, cmd, settled):
        return self.stmts(cmd.get("Stmts") or [], settled)

    def subshell(self, cmd, settled):
        self.stmts(cmd.get("Stmts") or [], settled)
        return settled

    def while_clause(self, cmd, settled):
        self.stmts(cmd.get("Cond") or [], settled)
        self.stmts(cmd.get("Do") or [], settled)
        return settled

    def for_clause(self, cmd, settled):
        self.substitutions(cmd.get("Loop"), settled)
        self.stmts(cmd.get("Do") or [], settled)
        return settled

    def func_decl(self, cmd, settled):
        self.stmt(cmd.get("Body") or {}, settled)
        return settled

    def time_clause(self, cmd, settled):
        return self.stmt(cmd.get("Stmt") or {}, settled)


def fields(node):
    """Return a mapping node's scalar keys and their value nodes; any other node has none."""
    if not isinstance(node, yaml.MappingNode):
        return {}
    return {key.value: value for key, value in node.value if isinstance(key, yaml.ScalarNode)}


def shell_scripts(text):
    """Yield (script, language, line_of) for each sh or bash run: in the action's runs.steps.

    Only steps run scripts, so a key named run anywhere else, such as in env:, is not one.
    A literal block keeps its lines, so each maps to its own source line. Other styles fold
    or decode their lines, so those all map to the line where the value starts.
    """
    steps = fields(fields(yaml.compose(text)).get("runs")).get("steps")
    if not isinstance(steps, yaml.SequenceNode):
        return
    for step in steps.value:
        run, shell = fields(step).get("run"), fields(step).get("shell")
        shell_words = shell.value.split() if isinstance(shell, yaml.ScalarNode) else ["sh"]
        if not isinstance(run, yaml.ScalarNode) or shell_words[0] not in SHELLS:
            continue
        start = run.start_mark.line
        if run.style == "|":
            yield run.value, SHELLS[shell_words[0]], lambda line, first=start + 1: first + line
        else:
            yield run.value, SHELLS[shell_words[0]], lambda _line, first=start + 1: first


def unchecked_calls(text):
    """Return (line number, tool) for the first unchecked call of each tool in each script."""
    found = []
    for script, language, line_of in shell_scripts(text):
        first_calls = {}
        try:
            tree = parse(script, language)
        except ParseError as error:
            message = f"{line_of(1)}: shfmt cannot parse this run: script: {error}"
            raise ParseError(message) from error
        Scan(script, line_of, first_calls).stmts(tree.get("Stmts") or [], frozenset())
        found.extend((line, tool) for tool, line in first_calls.items())
    return sorted(found)


def main(paths):
    if SHFMT is None:
        sys.exit("shfmt is required to parse the run: scripts; install it (see _tests/README.md)")
    status = 0
    for path in paths:
        text = Path(path).read_text(encoding="utf-8")
        try:
            calls = unchecked_calls(text)
        except ParseError as error:
            print(f"{path}:{error}")
            status = 1
            continue
        for number, tool in calls:
            print(f"{path}:{number}: {tool} is called before `command -v {tool}` checks for it")
            status = 1
    return status


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
