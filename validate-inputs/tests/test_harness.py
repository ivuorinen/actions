"""Unit tests for the composite-step harness."""

from __future__ import annotations

import sys
from pathlib import Path

import pytest

PROJECT_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(PROJECT_ROOT / "_tests" / "framework"))

from harness.harness import ActionParser, Step  # noqa: E402


class TestActionParser:
    def test_returns_empty_for_action_with_only_uses_steps(self, tmp_path: Path) -> None:
        action = tmp_path / "action.yml"
        action.write_text(
            "name: x\nruns:\n  using: composite\n  steps:\n    - uses: actions/checkout@v4\n"
        )
        steps = ActionParser.list_run_steps(tmp_path)
        assert steps == []

    def test_returns_run_step_ids(self, tmp_path: Path) -> None:
        action = tmp_path / "action.yml"
        action.write_text(
            "name: x\n"
            "runs:\n"
            "  using: composite\n"
            "  steps:\n"
            "    - id: first\n"
            "      shell: sh\n"
            "      run: echo one\n"
            "    - uses: actions/checkout@v4\n"
            "    - id: second\n"
            "      shell: sh\n"
            "      run: echo two\n"
        )
        steps = ActionParser.list_run_steps(tmp_path)
        assert steps == ["first", "second"]

    def test_get_step_returns_step_dataclass(self, tmp_path: Path) -> None:
        action = tmp_path / "action.yml"
        action.write_text(
            "name: x\n"
            "runs:\n"
            "  using: composite\n"
            "  steps:\n"
            "    - id: only\n"
            "      shell: sh\n"
            "      run: |\n"
            "        echo hello\n"
            "      env:\n"
            "        FOO: bar\n"
        )
        step = ActionParser.get_step(tmp_path, "only")
        assert isinstance(step, Step)
        assert step.id == "only"
        assert step.shell == "sh"
        assert step.run is not None
        assert step.run.strip() == "echo hello"
        assert step.env == {"FOO": "bar"}
        assert step.if_expr is None
        assert step.uses is None

    def test_get_step_preserves_if_expression_text(self, tmp_path: Path) -> None:
        action = tmp_path / "action.yml"
        action.write_text(
            "name: x\n"
            "runs:\n"
            "  using: composite\n"
            "  steps:\n"
            "    - id: gated\n"
            "      if: ${{ inputs.enabled == 'true' }}\n"
            "      shell: sh\n"
            "      run: echo ok\n"
        )
        step = ActionParser.get_step(tmp_path, "gated")
        assert step.if_expr == "${{ inputs.enabled == 'true' }}"

    def test_get_step_raises_for_unknown_id(self, tmp_path: Path) -> None:
        action = tmp_path / "action.yml"
        action.write_text(
            "name: x\n"
            "runs:\n"
            "  using: composite\n"
            "  steps:\n"
            "    - id: real\n"
            "      shell: sh\n"
            "      run: echo ok\n"
        )
        with pytest.raises(KeyError):
            ActionParser.get_step(tmp_path, "bogus")


from harness.harness import ExpressionResolver, UnsupportedExpressionError  # noqa: E402


class TestExpressionResolver:
    def _run(self, expr: str, ctx: dict | None = None) -> str:
        return ExpressionResolver(ctx or {}).resolve(expr)

    def test_literal_text_returns_unchanged(self) -> None:
        assert self._run("plain text") == "plain text"

    def test_inputs_reference(self) -> None:
        assert self._run("${{ inputs.foo }}", {"inputs": {"foo": "bar"}}) == "bar"

    def test_missing_inputs_resolves_to_empty_string(self) -> None:
        assert self._run("${{ inputs.missing }}", {"inputs": {}}) == ""

    def test_string_literal(self) -> None:
        assert self._run("${{ 'hello' }}") == "hello"

    def test_logical_or_falls_back_on_empty(self) -> None:
        ctx = {"inputs": {"token": ""}, "github": {"token": "gh_tok"}}
        assert self._run("${{ inputs.token || github.token }}", ctx) == "gh_tok"

    def test_logical_or_returns_first_truthy(self) -> None:
        ctx = {"inputs": {"token": "user_tok"}, "github": {"token": "gh_tok"}}
        assert self._run("${{ inputs.token || github.token }}", ctx) == "user_tok"

    def test_equality_returns_true_string(self) -> None:
        ctx = {"inputs": {"mode": "check"}}
        assert self._run("${{ inputs.mode == 'check' }}", ctx) == "true"

    def test_inequality(self) -> None:
        ctx = {"inputs": {"mode": "check"}}
        assert self._run("${{ inputs.mode != 'fix' }}", ctx) == "true"

    def test_steps_output_reference(self) -> None:
        ctx = {"steps": {"detect": {"outputs": {"found": "true"}}}}
        assert self._run("${{ steps.detect.outputs.found }}", ctx) == "true"

    def test_env_reference(self) -> None:
        ctx = {"env": {"CI": "1"}}
        assert self._run("${{ env.CI }}", ctx) == "1"

    def test_mixed_text_and_expression(self) -> None:
        ctx = {"inputs": {"name": "app"}}
        assert self._run("image: ${{ inputs.name }}:latest", ctx) == "image: app:latest"

    def test_unsupported_function_raises(self) -> None:
        with pytest.raises(UnsupportedExpressionError):
            self._run("${{ hashFiles('**/*.py') }}")

    def test_unknown_top_level_context_raises(self) -> None:
        with pytest.raises(UnsupportedExpressionError):
            self._run("${{ matrix.os }}")

    def test_is_truthy_when_condition_matches(self) -> None:
        ctx = {"inputs": {"enabled": "true"}}
        resolver = ExpressionResolver(ctx)
        assert resolver.is_truthy("${{ inputs.enabled == 'true' }}") is True

    def test_is_truthy_when_condition_does_not_match(self) -> None:
        ctx = {"inputs": {"enabled": "false"}}
        resolver = ExpressionResolver(ctx)
        assert resolver.is_truthy("${{ inputs.enabled == 'true' }}") is False


import json
import os
import subprocess

from harness.harness import MockRegistry  # noqa: E402


class TestMockRegistry:
    def _write_mocks(self, session: Path, mocks: list[dict]) -> None:
        (session / "mocks.json").write_text(json.dumps(mocks))

    def test_materialize_creates_stub_for_each_command(self, tmp_path: Path) -> None:
        self._write_mocks(
            tmp_path,
            [
                {"command": "gh", "argv_glob": "release list*", "stdout": "v1.0.0", "exit": 0},
                {"command": "git", "argv_glob": "status*", "stdout": "clean", "exit": 0},
            ],
        )
        bin_dir = MockRegistry.materialize(tmp_path)
        assert (bin_dir / "gh").exists()
        assert (bin_dir / "git").exists()
        assert os.access(bin_dir / "gh", os.X_OK)

    def test_stub_matches_glob_and_prints_stdout(self, tmp_path: Path) -> None:
        self._write_mocks(
            tmp_path,
            [{"command": "gh", "argv_glob": "release list *", "stdout": "v1.0.0", "exit": 0}],
        )
        bin_dir = MockRegistry.materialize(tmp_path)
        result = subprocess.run(
            [str(bin_dir / "gh"), "release", "list", "--limit", "1"],
            capture_output=True,
            text=True,
            check=False,
        )
        assert result.returncode == 0
        assert result.stdout.strip() == "v1.0.0"

    def test_stub_fails_loud_on_unregistered_argv(self, tmp_path: Path) -> None:
        self._write_mocks(
            tmp_path,
            [{"command": "gh", "argv_glob": "release list *", "stdout": "x", "exit": 0}],
        )
        bin_dir = MockRegistry.materialize(tmp_path)
        result = subprocess.run(
            [str(bin_dir / "gh"), "pr", "create"],
            capture_output=True,
            text=True,
            check=False,
        )
        assert result.returncode == 127
        assert "unregistered call to gh" in result.stderr

    def test_stub_honors_nonzero_exit_code(self, tmp_path: Path) -> None:
        self._write_mocks(
            tmp_path,
            [{"command": "gh", "argv_glob": "release view*", "stdout": "", "exit": 1}],
        )
        bin_dir = MockRegistry.materialize(tmp_path)
        result = subprocess.run(
            [str(bin_dir / "gh"), "release", "view", "v0.0.0"],
            capture_output=True,
            text=True,
            check=False,
        )
        assert result.returncode == 1

    def test_first_matching_glob_wins(self, tmp_path: Path) -> None:
        self._write_mocks(
            tmp_path,
            [
                {
                    "command": "gh",
                    "argv_glob": "release list --limit 1*",
                    "stdout": "first",
                    "exit": 0,
                },
                {"command": "gh", "argv_glob": "release list*", "stdout": "second", "exit": 0},
            ],
        )
        bin_dir = MockRegistry.materialize(tmp_path)
        result = subprocess.run(
            [str(bin_dir / "gh"), "release", "list", "--limit", "1"],
            capture_output=True,
            text=True,
            check=False,
        )
        assert result.stdout.strip() == "first"


class TestActionCorpus:
    """Load every action.yml in the repo; catch drift early."""

    # Actions composed entirely of `uses:` steps with no shell blocks.
    USES_ONLY: set[str] = {"stale"}

    def _all_action_dirs(self) -> list[Path]:
        return sorted(p.parent for p in PROJECT_ROOT.glob("*/action.yml"))

    def test_every_action_yml_parses(self) -> None:
        for action_dir in self._all_action_dirs():
            ActionParser.list_run_steps(action_dir)

    def test_every_run_step_has_shell(self) -> None:
        for action_dir in self._all_action_dirs():
            for step_id in ActionParser.list_run_steps(action_dir):
                step = ActionParser.get_step(action_dir, step_id)
                assert step.shell, f"{action_dir.name}/{step_id} has `run:` but no `shell:`"

    def test_non_uses_only_actions_have_run_steps(self) -> None:
        import yaml

        for action_dir in self._all_action_dirs():
            if action_dir.name in self.USES_ONLY:
                continue
            with (action_dir / "action.yml").open(encoding="utf-8") as f:
                data = yaml.safe_load(f)
            steps = (data.get("runs") or {}).get("steps") or []
            has_run = any("run" in s for s in steps)
            assert has_run or action_dir.name in self.USES_ONLY, (
                f"{action_dir.name} has no run: step and is not in USES_ONLY"
            )


HARNESS_PY = PROJECT_ROOT / "_tests" / "framework" / "harness" / "harness.py"


class TestRunStep:
    def _session(self, tmp_path: Path) -> dict:
        session = tmp_path / "session"
        session.mkdir()
        (session / "mocks.json").write_text("[]")
        output = session / "github-output"
        env_file = session / "github-env"
        output.touch()
        env_file.touch()
        return {"session": session, "output": output, "env": env_file}

    def _write_action(self, action_dir: Path, yml: str) -> None:
        action_dir.mkdir()
        (action_dir / "action.yml").write_text(yml)

    def test_run_step_executes_shell_and_writes_output(self, tmp_path: Path) -> None:
        self._write_action(
            tmp_path / "act",
            "name: t\n"
            "runs:\n"
            "  using: composite\n"
            "  steps:\n"
            "    - id: emit\n"
            "      shell: sh\n"
            "      run: printf 'hello=world\\n' >> \"$GITHUB_OUTPUT\"\n",
        )
        s = self._session(tmp_path)
        result = subprocess.run(
            [
                sys.executable,
                str(HARNESS_PY),
                "run-step",
                str(tmp_path / "act"),
                "emit",
                "--session",
                str(s["session"]),
                "--github-output",
                str(s["output"]),
                "--github-env",
                str(s["env"]),
            ],
            capture_output=True,
            text=True,
            check=False,
        )
        assert result.returncode == 0, result.stderr
        assert s["output"].read_text().strip() == "hello=world"

    def test_run_step_resolves_env_from_inputs(self, tmp_path: Path) -> None:
        self._write_action(
            tmp_path / "act",
            "name: t\n"
            "runs:\n"
            "  using: composite\n"
            "  steps:\n"
            "    - id: echo\n"
            "      shell: sh\n"
            "      env:\n"
            "        GREETING: ${{ inputs.who }}\n"
            '      run: printf \'out=%s\\n\' "$GREETING" >> "$GITHUB_OUTPUT"\n',
        )
        s = self._session(tmp_path)
        env = os.environ.copy()
        env["INPUT_WHO"] = "world"
        result = subprocess.run(
            [
                sys.executable,
                str(HARNESS_PY),
                "run-step",
                str(tmp_path / "act"),
                "echo",
                "--session",
                str(s["session"]),
                "--github-output",
                str(s["output"]),
                "--github-env",
                str(s["env"]),
            ],
            capture_output=True,
            text=True,
            check=False,
            env=env,
        )
        assert result.returncode == 0, result.stderr
        assert s["output"].read_text().strip() == "out=world"

    def test_run_step_propagates_nonzero_exit(self, tmp_path: Path) -> None:
        self._write_action(
            tmp_path / "act",
            "name: t\n"
            "runs:\n"
            "  using: composite\n"
            "  steps:\n"
            "    - id: fail\n"
            "      shell: sh\n"
            "      run: exit 3\n",
        )
        s = self._session(tmp_path)
        result = subprocess.run(
            [
                sys.executable,
                str(HARNESS_PY),
                "run-step",
                str(tmp_path / "act"),
                "fail",
                "--session",
                str(s["session"]),
                "--github-output",
                str(s["output"]),
                "--github-env",
                str(s["env"]),
            ],
            capture_output=True,
            text=True,
            check=False,
        )
        assert result.returncode == 3

    def test_run_step_uses_mocked_command(self, tmp_path: Path) -> None:
        self._write_action(
            tmp_path / "act",
            "name: t\n"
            "runs:\n"
            "  using: composite\n"
            "  steps:\n"
            "    - id: use-gh\n"
            "      shell: sh\n"
            "      run: |\n"
            "        tag=$(gh release list --limit 1)\n"
            '        printf \'tag=%s\\n\' "$tag" >> "$GITHUB_OUTPUT"\n',
        )
        s = self._session(tmp_path)
        (s["session"] / "mocks.json").write_text(
            json.dumps(
                [{"command": "gh", "argv_glob": "release list *", "stdout": "v9.9.9", "exit": 0}]
            )
        )
        result = subprocess.run(
            [
                sys.executable,
                str(HARNESS_PY),
                "run-step",
                str(tmp_path / "act"),
                "use-gh",
                "--session",
                str(s["session"]),
                "--github-output",
                str(s["output"]),
                "--github-env",
                str(s["env"]),
            ],
            capture_output=True,
            text=True,
            check=False,
        )
        assert result.returncode == 0, result.stderr
        assert s["output"].read_text().strip() == "tag=v9.9.9"


class TestRunOwned:
    def _session(self, tmp_path: Path) -> dict:
        session = tmp_path / "session"
        session.mkdir()
        (session / "mocks.json").write_text("[]")
        output = session / "github-output"
        env_file = session / "github-env"
        output.touch()
        env_file.touch()
        return {"session": session, "output": output, "env": env_file}

    def _run_owned(
        self,
        action_dir: Path,
        session: dict,
        extra_env: dict | None = None,
    ) -> subprocess.CompletedProcess:
        env = os.environ.copy()
        if extra_env:
            env.update(extra_env)
        return subprocess.run(
            [
                sys.executable,
                str(HARNESS_PY),
                "run-owned",
                str(action_dir),
                "--session",
                str(session["session"]),
                "--github-output",
                str(session["output"]),
                "--github-env",
                str(session["env"]),
            ],
            capture_output=True,
            text=True,
            check=False,
            env=env,
        )

    def test_executes_all_run_steps_in_order(self, tmp_path: Path) -> None:
        action = tmp_path / "act"
        action.mkdir()
        (action / "action.yml").write_text(
            "name: t\n"
            "runs:\n"
            "  using: composite\n"
            "  steps:\n"
            "    - id: first\n"
            "      shell: sh\n"
            "      run: printf 'a=1\\n' >> \"$GITHUB_OUTPUT\"\n"
            "    - id: second\n"
            "      shell: sh\n"
            "      run: printf 'b=2\\n' >> \"$GITHUB_OUTPUT\"\n",
        )
        s = self._session(tmp_path)
        result = self._run_owned(action, s)
        assert result.returncode == 0, result.stderr
        text = s["output"].read_text()
        assert "a=1" in text
        assert "b=2" in text

    def test_skips_uses_steps(self, tmp_path: Path) -> None:
        action = tmp_path / "act"
        action.mkdir()
        (action / "action.yml").write_text(
            "name: t\n"
            "runs:\n"
            "  using: composite\n"
            "  steps:\n"
            "    - uses: actions/checkout@v4\n"
            "    - id: only\n"
            "      shell: sh\n"
            "      run: printf 'c=3\\n' >> \"$GITHUB_OUTPUT\"\n",
        )
        s = self._session(tmp_path)
        result = self._run_owned(action, s)
        assert result.returncode == 0, result.stderr
        assert s["output"].read_text().strip() == "c=3"

    def test_if_condition_skips_step_when_false(self, tmp_path: Path) -> None:
        action = tmp_path / "act"
        action.mkdir()
        (action / "action.yml").write_text(
            "name: t\n"
            "runs:\n"
            "  using: composite\n"
            "  steps:\n"
            "    - id: first\n"
            "      shell: sh\n"
            "      run: printf 'ran=first\\n' >> \"$GITHUB_OUTPUT\"\n"
            "    - id: gated\n"
            "      if: ${{ inputs.enabled == 'true' }}\n"
            "      shell: sh\n"
            "      run: printf 'ran=gated\\n' >> \"$GITHUB_OUTPUT\"\n",
        )
        s = self._session(tmp_path)
        result = self._run_owned(action, s, {"INPUT_ENABLED": "false"})
        assert result.returncode == 0, result.stderr
        text = s["output"].read_text()
        assert "ran=first" in text
        assert "ran=gated" not in text

    def test_later_step_reads_prior_step_output(self, tmp_path: Path) -> None:
        action = tmp_path / "act"
        action.mkdir()
        (action / "action.yml").write_text(
            "name: t\n"
            "runs:\n"
            "  using: composite\n"
            "  steps:\n"
            "    - id: setter\n"
            "      shell: sh\n"
            "      run: printf 'flag=yes\\n' >> \"$GITHUB_OUTPUT\"\n"
            "    - id: reader\n"
            "      if: ${{ steps.setter.outputs.flag == 'yes' }}\n"
            "      shell: sh\n"
            "      run: printf 'conditional=ran\\n' >> \"$GITHUB_OUTPUT\"\n",
        )
        s = self._session(tmp_path)
        result = self._run_owned(action, s)
        assert result.returncode == 0, result.stderr
        assert "conditional=ran" in s["output"].read_text()

    def test_halts_on_first_failure(self, tmp_path: Path) -> None:
        action = tmp_path / "act"
        action.mkdir()
        (action / "action.yml").write_text(
            "name: t\n"
            "runs:\n"
            "  using: composite\n"
            "  steps:\n"
            "    - id: boom\n"
            "      shell: sh\n"
            "      run: exit 7\n"
            "    - id: never\n"
            "      shell: sh\n"
            "      run: printf 'should-not-run=1\\n' >> \"$GITHUB_OUTPUT\"\n",
        )
        s = self._session(tmp_path)
        result = self._run_owned(action, s)
        assert result.returncode == 7
        assert "should-not-run" not in s["output"].read_text()
