"""Report the scripts in the given action files that call an external tool before checking for it.

.claude/rules/posix-shell.md lists the external tools the repository's scripts use that are
not POSIX utilities, and requires `command -v <tool>` before any of them is used. Without
the check a missing tool does not always stop the step: `count=$(git diff --name-only | wc -l)`
takes its status from wc, so the count is 0, and `if git rev-parse ...` takes the else branch.
The tools are read from that rule, so the list exists once.

_tests/shared/shell_scripts.py finds the scripts (each run:, and nick-fields/retry's with:
command:), parses them with shfmt, and reads which commands each simple command runs. The script
given to `sh -c`, eval's operands, trap's action, and a here-document fed or piped to sh or bash
are read as scripts too; any other here-document is data, though a command substitution in it
still runs. A call through a function or alias the script defines is not followed.

A check is `command -v <tool>` in a form that stops the step when the tool is missing:
`command -v <tool> ... || { ...; exit 1; }`, or `if ! command -v <tool> ...; then ... exit; fi`.
It covers what runs after it in the same block. `if command -v <tool> ...; then` and
`command -v <tool> ... && ...` cover only the code they guard. A check in one branch of an if
or case covers code after the if or case only when every branch that goes on checks too; a
check in a subshell, a pipeline, a loop, a background command, a function body or a command
substitution covers nothing outside it.
"""

from functools import reduce
import importlib.util
from pathlib import Path
import re
import sys

RULE = Path(__file__).resolve().parents[3] / ".claude" / "rules" / "posix-shell.md"
SHARED = Path(__file__).resolve().parents[2] / "shared" / "shell_scripts.py"
# The paragraph of the rule that lists the tools needing the check, up to its closing period.
# The rule wraps its lines anywhere, so any whitespace separates the words.
TOOL_LIST = re.compile(
    r"each\s+needing\s+that\s+check\s+before\s+its\s+first\s+use\s+in\s+a\s+script:\s*\n(.*?)\.\n",
    re.DOTALL,
)
TERMINATORS = {"exit", "return"}


def load_shared():
    """Import _tests/shared/shell_scripts.py, which is not on sys.path."""
    spec = importlib.util.spec_from_file_location("shell_scripts", SHARED)
    if spec is None or spec.loader is None:
        sys.exit(f"{SHARED}: cannot be loaded")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


sh = load_shared()


def rule_tools(rule_text):
    """Return the tools the rule says need a `command -v` check, in the rule's order."""
    match = TOOL_LIST.search(rule_text)
    if not match:
        sys.exit(f"{RULE}: the list of tools that need a command -v check was not found")
    return re.findall(r"`([^`]+)`", match.group(1))


TOOLS = set(rule_tools(RULE.read_text(encoding="utf-8")))


def checked_tool(stmt):
    """Return the tool a statement looks up with `command -v <tool>`, or None."""
    cmd = stmt.get("Cmd") or {}
    if cmd.get("Type") != "CallExpr":
        return None
    words = [sh.shape(word) for word in cmd.get("Args") or []]
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
        if stmt.get("Background"):
            continue
        if kind == "CallExpr" and cmd.get("Args") and sh.shape(cmd["Args"][0]) in TERMINATORS:
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


def default_pattern(word):
    """Whether a case pattern is an unquoted *, which matches anything."""
    parts = (word or {}).get("Parts") or []
    return len(parts) == 1 and parts[0].get("Type") == "Lit" and parts[0].get("Value") == "*"


def stdin_shell(stmt):
    """Return the shfmt language of a shell that reads its script from stdin, or None."""
    cmd = stmt.get("Cmd") or {}
    if cmd.get("Type") != "CallExpr":
        return None
    words = [sh.shape(word) for word in cmd.get("Args") or []]
    calls, _ = sh.command_names(words)
    if not calls or calls[-1][1] not in sh.SHELLS:
        return None
    if sh.shell_c_script(words, calls[-1][0]) is not None or "-c" in words:
        return None
    return sh.SHELLS[calls[-1][1]]


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
        tree = sh.parse(text, language)
        Scan(text, lambda _line: self.line_of(line), self.found).stmts(
            tree.get("Stmts") or [], settled
        )

    def heredoc_scripts(self, stmt, language, settled):
        """Walk the here-documents of a statement as scripts a shell reads."""
        for redirect in stmt.get("Redirs") or []:
            hdoc = redirect.get("Hdoc")
            if hdoc:
                body = self.source[hdoc["Pos"]["Offset"] : hdoc["End"]["Offset"]].decode("utf-8")
                # The byte range ends with the closing delimiter's line.
                body = body.rsplit("\n", 1)[0] if "\n" in body else ""
                self.script(body, language, hdoc["Pos"]["Line"], settled)

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
        # A here-document's command substitutions run in this shell, whatever reads its body.
        for redirect in stmt.get("Redirs") or []:
            self.substitutions(redirect.get("Word"), settled)
            self.substitutions(redirect.get("Hdoc"), settled)
        cmd = stmt.get("Cmd")
        if not cmd:
            return settled
        after = self.command(cmd, stmt, settled)
        # A background command runs beside what follows, so its checks cover nothing after it.
        return settled if stmt.get("Background") else after

    def command(self, cmd, stmt, settled):
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
        words = [sh.shape(word) for word in cmd.get("Args") or []]
        calls, scripts = sh.command_names(words)
        for _, name in calls:
            self.call(name, cmd["Pos"], settled)
        for text, language in scripts:
            self.script(text, language, cmd["Pos"]["Line"], settled)
        language = stdin_shell(stmt)
        if language:
            self.heredoc_scripts(stmt, language, settled)
        return settled

    def binary_cmd(self, cmd, settled):
        first, second, op = cmd["X"], cmd["Y"], cmd["Op"]
        tool = None if first.get("Negated") else checked_tool(first)
        if op in ("|", "|&"):
            self.stmt(first, settled)
            self.stmt(second, settled)
            # `cat <<EOF | sh` runs the here-document as a script.
            language = stdin_shell(second)
            if language:
                self.heredoc_scripts(first, language, settled)
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
            default = default or any(default_pattern(word) for word in item.get("Patterns") or [])
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


def unchecked_calls(text):
    """Return (line number, tool) for the first unchecked call of each tool in each script."""
    found = []
    for script, language, line_of in sh.step_scripts(text):
        first_calls = {}
        try:
            tree = sh.parse(script, language)
        except sh.ParseError as error:
            message = f"{line_of(1)}: shfmt cannot parse this script: {error}"
            raise sh.ParseError(message) from error
        Scan(script, line_of, first_calls).stmts(tree.get("Stmts") or [], frozenset())
        found.extend((line, tool) for tool, line in first_calls.items())
    return sorted(found)


def main(paths):
    status = 0
    for path in paths:
        text = Path(path).read_text(encoding="utf-8")
        try:
            calls = unchecked_calls(text)
        except sh.ParseError as error:
            print(f"{path}:{error}")
            status = 1
            continue
        for number, tool in calls:
            print(f"{path}:{number}: {tool} is called before `command -v {tool}` checks for it")
            status = 1
    return status


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
