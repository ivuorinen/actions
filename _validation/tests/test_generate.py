"""Tests for the generator: no drift, determinism, self-containment, and standalone runs.

These lock the core guarantee of the design — that each committed ``validate.py`` is
exactly what the generator produces, depends on nothing outside the Python standard
library, and behaves correctly when executed on its own.
"""

from __future__ import annotations

import ast
import os
from pathlib import Path
import subprocess
import sys

import generate
import kit
import pytest
from spec import SPECS

REPO_ROOT = Path(__file__).resolve().parents[2]
ACTIONS = sorted(SPECS)
STDLIB_IMPORTS = {"__future__", "os", "re", "sys", "json", "urllib", "urllib.parse"}
MASK_COMMAND = "::add-mask::"
VALID_TOKEN = "ghp_" + "a" * 36


@pytest.mark.parametrize("action", ACTIONS)
def test_committed_validator_matches_generator(action):
    committed = (REPO_ROOT / action / "validate.py").read_text(encoding="utf-8")
    assert committed == generate.render(action), (
        f"{action}/validate.py is stale — run make update-validators"
    )


@pytest.mark.parametrize("action", ACTIONS)
def test_render_is_deterministic(action):
    assert generate.render(action) == generate.render(action)


@pytest.mark.parametrize("action", ACTIONS)
def test_validator_is_self_contained(action):
    source = (REPO_ROOT / action / "validate.py").read_text(encoding="utf-8")
    tree = ast.parse(source)
    imported: set[str] = set()
    for node in ast.walk(tree):
        if isinstance(node, ast.Import):
            imported.update(alias.name for alias in node.names)
        elif isinstance(node, ast.ImportFrom) and node.module:
            imported.add(node.module)
    extra = imported - STDLIB_IMPORTS
    assert not extra, f"{action}/validate.py imports non-stdlib modules: {extra}"
    assert "kit" not in imported
    assert "spec" not in imported

    functions = {n.name for n in ast.walk(tree) if isinstance(n, ast.FunctionDef)}
    assert "main" in functions
    assert "ACTION =" in source
    assert "CHECKS =" in source
    assert "REQUIRED" in source
    assert "MASKED_INPUTS" in source


def _env_name(input_name: str) -> str:
    return f"INPUT_{input_name.upper().replace('-', '_')}"


def _run(action: str, extra_env: dict[str, str]) -> subprocess.CompletedProcess[str]:
    env = {k: v for k, v in os.environ.items() if not k.startswith("INPUT_")}
    env.update(extra_env)
    return subprocess.run(
        [sys.executable, "validate.py"],
        cwd=REPO_ROOT / action,
        env=env,
        capture_output=True,
        text=True,
        check=False,
    )


@pytest.mark.parametrize("action", ACTIONS)
def test_runs_standalone_with_no_inputs(action):
    result = _run(action, {})
    if SPECS[action]["required"]:
        assert result.returncode == 1
        # with empty inputs, the ONLY failures may be the required-input ones
        for line in result.stdout.splitlines():
            assert "required input is missing" in line
    else:
        assert result.returncode == 0, result.stdout


@pytest.mark.parametrize("action", [a for a in ACTIONS if SPECS[a]["required"]])
def test_required_inputs_satisfied_by_expression(action):
    # a ${{ }} expression passes every check, so supplying required inputs clears the gate
    env = {_env_name(n): "${{ inputs.x }}" for n in SPECS[action]["required"]}
    assert _run(action, env).returncode == 0


def test_invalid_input_is_rejected_with_annotation():
    result = _run("docker-build", {"INPUT_TAG": "bad tag", "INPUT_MAX_RETRIES": "999"})
    assert result.returncode == 1
    assert "::error::docker-build:" in result.stdout
    assert "max-retries" in result.stdout


def _masked_inputs(action: str) -> list[str]:
    checks = SPECS[action]["checks"]
    return sorted(name for name, check in checks.items() if check in kit.MASKED_CHECKS)


def _masks(stdout: str) -> list[str]:
    return [
        line.removeprefix(MASK_COMMAND)
        for line in stdout.splitlines()
        if line.startswith(MASK_COMMAND)
    ]


@pytest.mark.parametrize("action", ACTIONS)
def test_secret_inputs_are_masked_before_any_check_reports(action):
    # "bad value" fails every secret check, so each run also prints ::error:: lines
    values = {name: f"bad value {name}" for name in _masked_inputs(action)}
    result = _run(action, {_env_name(name): value for name, value in values.items()})
    assert result.returncode == 1
    lines = result.stdout.splitlines()
    assert lines[: len(values)] == [MASK_COMMAND + value for value in values.values()]
    assert any(line.startswith("::error::") for line in lines[len(values) :])


@pytest.mark.parametrize("action", ACTIONS)
def test_non_secret_inputs_are_not_masked(action):
    masked = _masked_inputs(action)
    env = {_env_name(name): "visible" for name in SPECS[action]["checks"] if name not in masked}
    assert _masks(_run(action, env).stdout) == []


def test_valid_secret_is_masked_and_still_passes():
    result = _run("stale", {"INPUT_TOKEN": VALID_TOKEN})
    assert result.returncode == 0
    assert result.stdout.splitlines() == [MASK_COMMAND + VALID_TOKEN]


@pytest.mark.parametrize("value", ["", "   ", "\n", " \r\n\t\n"])
def test_blank_secret_emits_no_mask_command(value):
    # the runner answers an empty ::add-mask:: with a warning on every run
    assert MASK_COMMAND not in _run("stale", {"INPUT_TOKEN": value}).stdout


def test_multiline_secret_is_masked_one_line_at_a_time():
    result = _run("stale", {"INPUT_TOKEN": "  first \n\n second\r\nthird\n"})
    assert _masks(result.stdout) == ["first", "second", "third"]


def test_secret_line_cannot_start_a_workflow_command():
    result = _run("stale", {"INPUT_TOKEN": "first\n::notice::second"})
    assert _masks(result.stdout) == ["first", "::notice::second"]
    assert not any(line.startswith("::notice::") for line in result.stdout.splitlines())


def test_percent_in_secret_survives_the_runner_unescaping_command_data():
    # the runner decodes %25, %0A and %0D in command data, so the mask would otherwise
    # register a different string from the one the tools print
    result = _run("stale", {"INPUT_TOKEN": "a%25b%0Ac"})
    assert _masks(result.stdout) == ["a%2525b%250Ac"]
