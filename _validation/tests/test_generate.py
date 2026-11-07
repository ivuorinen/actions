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
    env = {
        f"INPUT_{n.upper().replace('-', '_')}": "${{ inputs.x }}" for n in SPECS[action]["required"]
    }
    assert _run(action, env).returncode == 0


def test_invalid_input_is_rejected_with_annotation():
    result = _run("docker-build", {"INPUT_TAG": "bad tag", "INPUT_MAX_RETRIES": "999"})
    assert result.returncode == 1
    assert "::error::docker-build:" in result.stdout
    assert "max-retries" in result.stdout


DETECTING = [a for a in ACTIONS if "detected_version" in SPECS[a]]


def _run_detected_version(action: str, value: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [sys.executable, "validate.py", "--detected-version", value],
        cwd=REPO_ROOT / action,
        env={k: v for k, v in os.environ.items() if not k.startswith("INPUT_")},
        capture_output=True,
        text=True,
        check=False,
    )


@pytest.mark.parametrize("value", ["8.0", "1.22.3", "1.0.0-rc.1", "1.0.0+build"])
@pytest.mark.parametrize("action", DETECTING)
def test_detected_version_mode_accepts(action, value):
    # Required inputs are unset here: csharp-publish and language-version-detect would fail
    # main(), so a zero exit also proves this mode answers without validating inputs.
    result = _run_detected_version(action, value)
    assert (result.returncode, result.stdout, result.stderr) == (0, "", "")


@pytest.mark.parametrize("value", ["", "latest", "8.4;evil", "8.4$(evil)", "8.0\ninjected=1"])
@pytest.mark.parametrize("action", DETECTING)
def test_detected_version_mode_rejects_quietly(action, value):
    # A rejected file value is not an error: the step moves on to its next source.
    result = _run_detected_version(action, value)
    assert (result.returncode, result.stdout, result.stderr) == (1, "", "")


@pytest.mark.parametrize("action", [a for a in ACTIONS if a not in DETECTING])
def test_detected_version_mode_is_only_generated_where_used(action):
    assert "--detected-version" not in (REPO_ROOT / action / "validate.py").read_text("utf-8")
