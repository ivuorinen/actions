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
    assert "SECRETS" in source


def _env_name(input_name: str) -> str:
    return "INPUT_" + input_name.upper().replace("-", "_")


def _valid_value(check: str) -> str:
    # A token's documented example is a `${{ }}` reference, which is not a value.
    tokens = {"github_token": "ghp_" + "a" * 36, "opaque_token": NPM_TOKEN}
    return tokens.get(check, kit.EXAMPLES[check])


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


# Fabricated, shaped like the real thing. The generated validators are what callers run, so
# these go through them rather than through kit.CHECKS.
NPM_TOKEN = "npm_" + "aB3dE6gH9j" * 3 + "k1M2n3"
DOCKERHUB_PAT = "dckr_pat_" + "aB3-dE6_gH9" * 2 + "k1M2n"


@pytest.mark.parametrize(
    ("action", "env"),
    [
        ("npm-publish", {"INPUT_NPM_TOKEN": NPM_TOKEN}),
        ("npm-semantic-release", {"INPUT_NPM_TOKEN": NPM_TOKEN}),
        ("docker-publish", {"INPUT_DOCKERHUB_TOKEN": DOCKERHUB_PAT}),
        ("docker-publish", {"INPUT_TAGS": "latest,v1.0.0"}),
        ("docker-publish", {"INPUT_TAGS": "v2025.04.05-rc.1,latest"}),
        ("npm-publish", {"INPUT_NPM_TOKEN": NPM_TOKEN, "INPUT_PACKAGE_VERSION": "v1.0.0"}),
        ("npm-publish", {"INPUT_NPM_TOKEN": NPM_TOKEN, "INPUT_PACKAGE_VERSION": "v1.0.0-rc.1"}),
        ("npm-publish", {"INPUT_NPM_TOKEN": NPM_TOKEN, "INPUT_PACKAGE_VERSION": "v1.0.0+build"}),
    ],
)
def test_real_world_values_pass_the_generated_validator(action, env):
    result = _run(action, env)
    assert result.returncode == 0, result.stdout


@pytest.mark.parametrize(
    ("action", "env", "input_name"),
    [
        ("npm-publish", {"INPUT_NPM_TOKEN": NPM_TOKEN + "\nsecond-line"}, "npm_token"),
        ("npm-publish", {"INPUT_NPM_TOKEN": NPM_TOKEN + " x"}, "npm_token"),
        ("npm-semantic-release", {"INPUT_NPM_TOKEN": NPM_TOKEN + "\n"}, "npm_token"),
        ("docker-publish", {"INPUT_DOCKERHUB_TOKEN": DOCKERHUB_PAT + "\n"}, "dockerhub-token"),
        ("docker-publish", {"INPUT_TAGS": "latest, v1.0.0"}, "tags"),
        ("docker-publish", {"INPUT_TAGS": "1.0.0+build"}, "tags"),
        (
            "npm-publish",
            {"INPUT_NPM_TOKEN": NPM_TOKEN, "INPUT_PACKAGE_VERSION": "v1.0"},
            "package-version",
        ),
    ],
)
def test_unsafe_values_fail_the_generated_validator(action, env, input_name):
    result = _run(action, env)
    assert result.returncode == 1
    assert f"::error::{action}: " in result.stdout
    assert input_name in result.stdout


@pytest.mark.parametrize("action", ["npm-publish", "npm-semantic-release"])
def test_blank_required_token_is_reported_as_missing(action):
    result = _run(action, {"INPUT_NPM_TOKEN": " \n"})
    assert result.returncode == 1
    assert "npm_token: required input is missing" in result.stdout


def test_invalid_input_is_rejected_with_annotation():
    result = _run("docker-build", {"INPUT_TAG": "bad tag", "INPUT_MAX_RETRIES": "999"})
    assert result.returncode == 1
    assert "::error::docker-build:" in result.stdout
    assert "max-retries" in result.stdout


def _secret_inputs(action: str) -> list[str]:
    checks = SPECS[action]["checks"]
    return sorted(name for name, check in checks.items() if check in kit.SECRET_CHECKS)


def _masks(stdout: str) -> list[str]:
    return [
        line.removeprefix(MASK_COMMAND)
        for line in stdout.splitlines()
        if line.startswith(MASK_COMMAND)
    ]


@pytest.mark.parametrize("action", ACTIONS)
def test_secret_inputs_are_masked_before_any_check_reports(action):
    # "bad value" fails every secret check, so each run also prints ::error:: lines
    values = {name: f"bad value {name}" for name in _secret_inputs(action)}
    result = _run(action, {_env_name(name): value for name, value in values.items()})
    assert result.returncode == 1
    lines = result.stdout.splitlines()
    assert lines[: len(values)] == [MASK_COMMAND + value for value in values.values()]
    assert any(line.startswith("::error::") for line in lines[len(values) :])


@pytest.mark.parametrize("action", ACTIONS)
def test_non_secret_inputs_are_not_masked(action):
    secrets = _secret_inputs(action)
    env = {_env_name(name): "visible" for name in SPECS[action]["checks"] if name not in secrets}
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
