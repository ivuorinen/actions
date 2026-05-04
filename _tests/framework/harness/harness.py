#!/usr/bin/env python3
"""Composite-action step harness.

See docs/superpowers/specs/2026-04-20-batch-a-test-harness-design.md.
"""

from __future__ import annotations

import argparse
from dataclasses import dataclass, field
import json
import os
from pathlib import Path
import re
import stat
import subprocess
import sys

import yaml


@dataclass
class Step:
    id: str
    shell: str | None
    run: str | None
    env: dict[str, str] = field(default_factory=dict)
    if_expr: str | None = None
    uses: str | None = None


class ActionParser:
    @staticmethod
    def _load(action_dir: Path) -> dict:
        with (Path(action_dir) / "action.yml").open(encoding="utf-8") as f:
            return yaml.safe_load(f)

    @staticmethod
    def _steps(action_dir: Path) -> list[dict]:
        data = ActionParser._load(action_dir)
        runs = data.get("runs") or {}
        return list(runs.get("steps") or [])

    @staticmethod
    def list_run_steps(action_dir: Path) -> list[str]:
        return [
            raw["id"] for raw in ActionParser._steps(action_dir) if "run" in raw and raw.get("id")
        ]

    @staticmethod
    def get_step(action_dir: Path, step_id: str) -> Step:
        for raw in ActionParser._steps(action_dir):
            if raw.get("id") == step_id:
                return Step(
                    id=raw["id"],
                    shell=raw.get("shell"),
                    run=raw.get("run"),
                    env=dict(raw.get("env") or {}),
                    if_expr=raw.get("if"),
                    uses=raw.get("uses"),
                )
        raise KeyError(f"step '{step_id}' not found in {action_dir}/action.yml")


class UnsupportedExpressionError(ValueError):
    """Raised when an expression uses a construct the harness does not implement."""


class ExpressionResolver:
    """Resolves the subset of ${{ }} expressions used in this repo.

    Supported: inputs.X, steps.X.outputs.Y, github.X, env.X, string literals,
    the || (default) operator, == and != equality. Unsupported constructs
    raise UnsupportedExpressionError — no silent fallback.
    """

    _TOKEN_RE = re.compile(
        r"""
        \s+                              # whitespace (skipped)
        | '([^']*)'                      # string literal  (group 1)
        | (==|!=|\|\|)                   # operator        (group 2)
        | ([A-Za-z_][A-Za-z0-9_.-]*)     # identifier/path (group 3)
        """,
        re.VERBOSE,
    )

    def __init__(self, context: dict) -> None:
        self.context = context

    # ---------- public ----------

    def resolve(self, text: str) -> str:
        out: list[str] = []
        i = 0
        while i < len(text):
            if text.startswith("${{", i):
                end = text.find("}}", i + 3)
                if end == -1:
                    raise UnsupportedExpressionError(f"unterminated expression: {text!r}")
                expr = text[i + 3 : end]
                out.append(self._reduce_expression(expr))
                i = end + 2
            else:
                out.append(text[i])
                i += 1
        return "".join(out)

    def is_truthy(self, text: str) -> bool:
        resolved = self.resolve(text).strip()
        return resolved == "true"

    # ---------- parser ----------

    def _tokenize(self, expr: str) -> list[tuple[str, str]]:
        tokens: list[tuple[str, str]] = []
        for match in self._TOKEN_RE.finditer(expr):
            s_lit, op, ident = match.group(1), match.group(2), match.group(3)
            if s_lit is not None:
                tokens.append(("str", s_lit))
            elif op:
                tokens.append(("op", op))
            elif ident:
                tokens.append(("id", ident))
        return tokens

    def _reduce_expression(self, expr: str) -> str:
        tokens = self._tokenize(expr)
        if not tokens:
            raise UnsupportedExpressionError(f"empty expression: {expr!r}")
        if len(tokens) % 2 == 0:
            raise UnsupportedExpressionError(f"malformed expression (even token count): {expr!r}")
        result = self._reduce_value(tokens[0])
        i = 1
        while i < len(tokens):
            if i + 1 >= len(tokens):
                raise UnsupportedExpressionError(
                    f"malformed expression (trailing operator): {expr!r}"
                )
            op_kind, op = tokens[i]
            if op_kind != "op":
                raise UnsupportedExpressionError(f"expected operator, got {tokens[i]}")
            rhs = self._reduce_value(tokens[i + 1])
            if op == "||":
                result = result or rhs
            elif op == "==":
                result = "true" if result == rhs else "false"
            elif op == "!=":
                result = "true" if result != rhs else "false"
            else:
                raise UnsupportedExpressionError(f"unknown operator: {op}")
            i += 2
        return result

    def _reduce_value(self, token: tuple[str, str]) -> str:
        kind, text = token
        if kind == "str":
            return text
        if kind == "id":
            return self._resolve_identifier(text)
        raise UnsupportedExpressionError(f"expected value, got {token}")

    def _resolve_identifier(self, path: str) -> str:
        parts = path.split(".")
        head = parts[0]
        allowed = {"inputs", "steps", "github", "env"}
        if head not in allowed:
            raise UnsupportedExpressionError(
                f"unsupported context '{head}' (allowed: {sorted(allowed)})"
            )
        node: object = self.context.get(head, {})
        for part in parts[1:]:
            if not isinstance(node, dict):
                return ""
            node = node.get(part, "")
        if node is None:
            return ""
        return str(node)


def _resolve_python_exe() -> str:
    """T-C1: Return the Python executable that harness stubs should invoke.

    Uses sys.executable — the absolute path to the currently-running interpreter.
    This is always correct whether invoked via ``uv run``, a plain venv, or a
    system Python, and avoids PATH lookups that fail under the harness's
    restricted child-process PATH.
    """
    return sys.executable


class MockRegistry:
    """Materializes mocked external commands as executable stubs on $PATH."""

    # T-C1: shebang uses harness-resolved Python so uv-managed envs work on CI
    STUB_TEMPLATE = """#!/bin/sh
# generated by harness MockRegistry
{python_exe} '{dispatcher}' '{cmd}' '{mocks_json}' "$@"
"""

    DISPATCHER_TEMPLATE = '''#!/usr/bin/env python3
"""Runtime stub dispatcher. Reads mocks.json, matches argv glob, emits output."""
import fnmatch, json, sys
cmd = sys.argv[1]
mocks_path = sys.argv[2]
argv_joined = " ".join(sys.argv[3:])
with open(mocks_path, encoding="utf-8") as f:
    mocks = json.load(f)
for m in mocks:
    if m["command"] != cmd:
        continue
    if fnmatch.fnmatchcase(argv_joined, m["argv_glob"]):
        sys.stdout.write(m.get("stdout", ""))
        if m.get("stdout") and not m["stdout"].endswith("\\n"):
            sys.stdout.write("\\n")
        sys.exit(int(m.get("exit", 0)))
sys.stderr.write(f"::error::unregistered call to {cmd} {argv_joined}\\n")
sys.exit(127)
'''

    @staticmethod
    def materialize(session_dir: Path) -> Path:
        session_dir = Path(session_dir)
        mocks_path = session_dir / "mocks.json"
        if not mocks_path.exists():
            mocks_path.write_text("[]", encoding="utf-8")
        # T-M5: use explicit utf-8 encoding for mocks.json reads
        mocks = json.loads(mocks_path.read_text(encoding="utf-8"))

        bin_dir = session_dir / "bin"
        bin_dir.mkdir(exist_ok=True)

        dispatcher = session_dir / "_dispatcher.py"
        dispatcher.write_text(MockRegistry.DISPATCHER_TEMPLATE, encoding="utf-8")
        dispatcher.chmod(dispatcher.stat().st_mode | stat.S_IXUSR)

        # T-C1: resolve the same Python executable that _harness_python() would use
        python_exe = _resolve_python_exe()

        commands = {m["command"] for m in mocks}
        for cmd in commands:
            stub = bin_dir / cmd
            stub.write_text(
                MockRegistry.STUB_TEMPLATE.format(
                    python_exe=python_exe,
                    dispatcher=dispatcher,
                    cmd=cmd,
                    mocks_json=mocks_path,
                ),
                encoding="utf-8",
            )
            stub.chmod(stub.stat().st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)

        return bin_dir


def _inputs_from_env() -> dict[str, str]:
    out: dict[str, str] = {}
    for key, value in os.environ.items():
        if not key.startswith("INPUT_"):
            continue
        name = key[len("INPUT_") :].lower()
        out[name] = value
        if "_" in name:
            out[name.replace("_", "-")] = value
    return out


def _build_context() -> dict:
    return {
        "inputs": _inputs_from_env(),
        "github": {
            "token": os.environ.get("GITHUB_TOKEN", "ghp_fixture_token_0000000000000000000000"),
            "actor": os.environ.get("GITHUB_ACTOR", "test-actor"),
            "repository": os.environ.get("GITHUB_REPOSITORY", "ivuorinen/actions"),
            "workspace": os.environ.get("GITHUB_WORKSPACE", str(Path.cwd())),
            "run_id": os.environ.get("GITHUB_RUN_ID", "1"),
        },
        "env": dict(os.environ),
        "steps": {},
    }


def _parse_kv_content(content: str) -> dict[str, str]:
    """Parse KEY=VALUE and heredoc KEY<<DELIMITER\\nvalue\\nDELIMITER entries.

    T-M1: shared parser used by both $GITHUB_OUTPUT and $GITHUB_ENV readers.
    Heredoc format is handled before the simple = split so multi-line values
    are captured correctly.
    """
    out: dict[str, str] = {}
    lines = content.splitlines()
    i = 0
    while i < len(lines):
        line = lines[i]
        if line.startswith("#") or not line.strip():
            i += 1
            continue
        # Multi-line value: line has "KEY<<DELIM" form with no = before the opener
        if "<<" in line and "=" not in line[: line.index("<<")]:
            key, _, delimiter = line.partition("<<")
            key = key.strip()
            delimiter = delimiter.strip()
            value_lines: list[str] = []
            i += 1
            while i < len(lines) and lines[i] != delimiter:
                value_lines.append(lines[i])
                i += 1
            out[key] = "\n".join(value_lines)
            i += 1  # skip closing delimiter line
            continue
        # Simple KEY=VALUE
        if "=" in line:
            k, _, v = line.partition("=")
            out[k.strip()] = v
        i += 1
    return out


def _parse_github_output(github_output: Path) -> dict[str, str]:
    """Parse $GITHUB_OUTPUT content for use in later if: expressions."""
    if not github_output.exists():
        return {}
    return _parse_kv_content(github_output.read_text(encoding="utf-8"))


def _read_appended_bytes(path: Path, offset: int) -> bytes:
    """Return bytes written to path since offset, guarding against TOCTOU races."""
    if not path.exists():
        return b""
    with path.open("rb") as handle:
        current_size = os.fstat(handle.fileno()).st_size
        handle.seek(0 if current_size < offset else offset)
        return handle.read()


def _raw_steps(action_dir: Path) -> list[dict]:
    return ActionParser._steps(action_dir)  # noqa: SLF001 — harness-internal view of parsed steps


def _run_owned(
    action_dir: Path,
    session: Path,
    github_output: Path,
    github_env: Path,
) -> int:
    context = _build_context()
    steps_ctx: dict = context["steps"]
    step_output_index = 0

    for raw in _raw_steps(action_dir):
        step_output_index += 1
        if "uses" in raw:
            continue
        step_id = raw.get("id") or f"_anon_{len(steps_ctx)}"
        step = Step(
            id=step_id,
            shell=raw.get("shell"),
            run=raw.get("run"),
            env=dict(raw.get("env") or {}),
            if_expr=raw.get("if"),
            uses=None,
        )
        if step.if_expr is not None:
            if_text = step.if_expr
            if not if_text.strip().startswith("${{"):
                if_text = "${{ " + if_text + " }}"
            if not ExpressionResolver(context).is_truthy(if_text):
                continue

        github_output_offset = github_output.stat().st_size if github_output.exists() else 0
        # Issue #559: track GITHUB_ENV writes so subsequent steps see exports
        github_env_offset = github_env.stat().st_size if github_env.exists() else 0

        rc = _execute_step(step, context, session, github_output, github_env)
        if rc != 0:
            return rc

        appended_output = _read_appended_bytes(github_output, github_output_offset)
        step_output_path = session / f".github_output_{step_output_index}"
        step_output_path.write_bytes(appended_output)
        outputs = _parse_github_output(step_output_path)
        steps_ctx[step_id] = {"outputs": outputs}

        appended_env = _read_appended_bytes(github_env, github_env_offset)
        if appended_env:
            env_entries = _parse_kv_content(appended_env.decode("utf-8", errors="replace"))
            context["env"].update(env_entries)

    return 0


def _execute_step(
    step: Step,
    context: dict,
    session: Path,
    github_output: Path,
    github_env: Path,
) -> int:
    if step.run is None:
        raise ValueError(f"step {step.id} has no run: block")
    shell = step.shell or "sh"
    if shell not in ("sh", "bash"):
        raise UnsupportedExpressionError(f"unsupported shell: {shell}")

    resolver = ExpressionResolver(context)
    resolved_env = {k: resolver.resolve(v) for k, v in step.env.items()}

    bin_dir = MockRegistry.materialize(session)

    child_env = os.environ.copy()
    # Issue #559: propagate env vars exported by previous steps via $GITHUB_ENV
    child_env.update(context.get("env", {}))
    child_env.update(resolved_env)
    # Restrict PATH so unmocked external commands fail rather than silently
    # picking up whatever is installed on the runner. Standard coreutils dirs
    # stay available so the shell can find sh/printf/echo/grep/awk etc.
    child_env["PATH"] = f"{bin_dir}:/usr/bin:/bin:/usr/sbin:/sbin"
    child_env["GITHUB_OUTPUT"] = str(github_output)
    child_env["GITHUB_ENV"] = str(github_env)

    proc = subprocess.run(
        [shell, "-c", step.run],
        env=child_env,
        check=False,
    )
    return proc.returncode


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="harness")
    sub = parser.add_subparsers(dest="command", required=True)

    p_run = sub.add_parser("run-step")
    p_run.add_argument("action_dir")
    p_run.add_argument("step_id")
    p_run.add_argument("--session", required=True)
    p_run.add_argument("--github-output", required=True)
    p_run.add_argument("--github-env", required=True)

    p_owned = sub.add_parser("run-owned")
    p_owned.add_argument("action_dir")
    p_owned.add_argument("--session", required=True)
    p_owned.add_argument("--github-output", required=True)
    p_owned.add_argument("--github-env", required=True)

    p_resolve = sub.add_parser("resolve-expr")
    p_resolve.add_argument("expr")
    p_resolve.add_argument("--session", required=True)

    p_list = sub.add_parser("list-run-steps")
    p_list.add_argument("action_dir")

    args = parser.parse_args(argv)

    if args.command == "list-run-steps":
        for step_id in ActionParser.list_run_steps(Path(args.action_dir)):
            print(step_id)
        return 0

    if args.command == "resolve-expr":
        ctx: dict = {}
        ctx_path = Path(args.session) / "context.json"
        if ctx_path.exists():
            with ctx_path.open(encoding="utf-8") as f:
                ctx = json.load(f)
        print(ExpressionResolver(ctx).resolve(args.expr))
        return 0

    if args.command == "run-step":
        context = _build_context()
        step = ActionParser.get_step(Path(args.action_dir), args.step_id)
        return _execute_step(
            step,
            context,
            Path(args.session),
            Path(args.github_output),
            Path(args.github_env),
        )

    if args.command == "run-owned":
        return _run_owned(
            Path(args.action_dir),
            Path(args.session),
            Path(args.github_output),
            Path(args.github_env),
        )

    print(f"unimplemented: {args.command}", file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main())
