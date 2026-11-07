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


def _env_name(input_name: str) -> str:
    return "INPUT_" + input_name.upper().replace("-", "_")


def _valid_value(check: str) -> str:
    # A token's documented example is a `${{ }}` reference, which is not a value.
    return "ghp_" + "a" * 36 if check == "github_token" else kit.EXAMPLES[check]


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
def test_required_inputs_satisfied_by_a_valid_value(action):
    checks = SPECS[action]["checks"]
    env = {_env_name(n): _valid_value(checks[n]) for n in SPECS[action]["required"]}
    assert _run(action, env).returncode == 0


@pytest.mark.parametrize("action", ACTIONS)
def test_literal_expression_is_rejected_for_every_input(action):
    # The runner expands an input before validate.py reads it, so a `${{` still present is
    # data. codeql_config is free-form YAML, where such text is ordinary content.
    checks = [n for n, t in SPECS[action]["checks"].items() if t != "codeql_config"]
    result = _run(action, {_env_name(n): "${{ inputs.x }}\nkey=value" for n in checks})
    assert result.returncode == 1
    for name in checks:
        assert f"::error::{action}: {name}: " in result.stdout


@pytest.mark.parametrize("separator", ["\n", "\r", "\r\n"])
def test_rejected_value_cannot_start_a_workflow_command(separator):
    value = f"a{separator}::notice::injected"
    result = _run("go-lint", {"INPUT_ENABLE_LINTERS": value})
    assert result.returncode == 1
    assert all(line.startswith("::error::") for line in result.stdout.splitlines())


def test_invalid_input_is_rejected_with_annotation():
    result = _run("docker-build", {"INPUT_TAG": "bad tag", "INPUT_MAX_RETRIES": "999"})
    assert result.returncode == 1
    assert "::error::docker-build:" in result.stdout
    assert "max-retries" in result.stdout
