"""Tests that the spec, the actions, and the generated validators stay in lockstep.

If someone adds an input to an action.yml but forgets the spec (or vice versa), or forgets
to forward an INPUT_* env var, these fail loudly — there is no silent "unvalidated input".
Parsing is regex-based on purpose: the system is stdlib-only, so the tests are too.
"""

from __future__ import annotations

from pathlib import Path
import re

import kit
import pytest
from spec import SPECS

REPO_ROOT = Path(__file__).resolve().parents[2]
ACTIONS = sorted(SPECS)


def _inputs_body(action: str) -> str:
    text = (REPO_ROOT / action / "action.yml").read_text(encoding="utf-8")
    block = re.search(r"^inputs:\s*$(.*?)^(?:[A-Za-z])", text, re.DOTALL | re.MULTILINE)
    return block.group(1) if block else ""


def declared_inputs(action: str) -> set[str]:
    return set(re.findall(r"^  ([a-zA-Z0-9][\w.-]*):\s*$", _inputs_body(action), re.MULTILINE))


def required_inputs(action: str) -> set[str]:
    required, current = set(), None
    for line in _inputs_body(action).splitlines():
        name = re.match(r"^  ([a-zA-Z0-9][\w.-]*):\s*$", line)
        if name:
            current = name.group(1)
        elif current and re.match(r"^    required:\s*['\"]?true['\"]?\s*$", line):
            required.add(current)
    return required


def env_keys(action: str) -> set[str]:
    text = (REPO_ROOT / action / "action.yml").read_text(encoding="utf-8")
    step = re.search(r"- name: Validate Inputs.*?\n      run:", text, re.DOTALL)
    if not step:
        return set()
    return set(re.findall(r"^        (INPUT_[A-Z0-9_]+):", step.group(0), re.MULTILINE))


def test_every_input_action_has_a_spec():
    discovered = {
        p.parent.name
        for p in REPO_ROOT.glob("*/action.yml")
        if p.parent.name != "validate-inputs" and "inputs:" in p.read_text(encoding="utf-8")
    }
    assert discovered == set(SPECS)


@pytest.mark.parametrize("action", ACTIONS)
def test_validator_file_exists(action):
    assert (REPO_ROOT / action / "validate.py").is_file()


@pytest.mark.parametrize("action", ACTIONS)
def test_all_check_types_exist_in_kit(action):
    for input_name, check_type in SPECS[action]["checks"].items():
        assert check_type in kit.CHECKS, f"{action}.{input_name} -> unknown check {check_type!r}"


@pytest.mark.parametrize("action", ACTIONS)
def test_spec_covers_exactly_the_declared_inputs(action):
    assert set(SPECS[action]["checks"]) == declared_inputs(action)


@pytest.mark.parametrize("action", ACTIONS)
def test_required_matches_action_yml(action):
    assert set(SPECS[action]["required"]) == required_inputs(action)


@pytest.mark.parametrize("action", ACTIONS)
def test_env_forwarding_matches_spec(action):
    expected = {"INPUT_" + n.upper().replace("-", "_") for n in SPECS[action]["checks"]}
    assert env_keys(action) == expected


def test_no_action_uses_the_old_validate_inputs_action():
    offenders = [
        p.parent.name
        for p in REPO_ROOT.glob("*/action.yml")
        if "uses: ivuorinen/actions/validate-inputs@" in p.read_text(encoding="utf-8")
    ]
    assert offenders == []
