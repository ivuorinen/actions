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
import yaml

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
def test_github_token_check_is_only_used_for_github_tokens(action):
    """The check knows GitHub's token prefixes, so any other issuer's real token fails it."""
    inputs = yaml.safe_load((REPO_ROOT / action / "action.yml").read_text(encoding="utf-8"))[
        "inputs"
    ]
    wrong = [
        name
        for name, check_type in SPECS[action]["checks"].items()
        if check_type == "github_token" and "GitHub token" not in inputs[name]["description"]
    ]
    assert not wrong, f"{action}: not described as GitHub tokens, use opaque_token: {wrong}"


@pytest.mark.parametrize("action", ACTIONS)
def test_spec_covers_exactly_the_declared_inputs(action):
    assert set(SPECS[action]["checks"]) == declared_inputs(action)


@pytest.mark.parametrize("action", ACTIONS)
def test_required_matches_action_yml(action):
    assert set(SPECS[action]["required"]) == required_inputs(action)


def test_masked_checks_exist_in_kit():
    assert set(kit.CHECKS) >= kit.MASKED_CHECKS


_CREDENTIAL_NAME = re.compile(
    r"token|secret|password|passphrase|credential|license|api.?key", re.IGNORECASE
)
# docker-build's `secrets` holds `id=path` pairs pointing at secret files, never a secret value.
_NOT_A_CREDENTIAL = {("docker-build", "secrets")}


@pytest.mark.parametrize("action", ACTIONS)
def test_credential_named_inputs_use_a_masked_check(action):
    unmasked = [
        name
        for name, check in SPECS[action]["checks"].items()
        if _CREDENTIAL_NAME.search(name)
        and check not in kit.MASKED_CHECKS
        and (action, name) not in _NOT_A_CREDENTIAL
    ]
    assert not unmasked, f"{action}: give these a check in kit.MASKED_CHECKS: {unmasked}"


@pytest.mark.parametrize("action", ACTIONS)
def test_masking_lives_only_in_the_generated_validator(action):
    assert "add-mask" not in (REPO_ROOT / action / "action.yml").read_text(encoding="utf-8")


@pytest.mark.parametrize("action", ACTIONS)
def test_env_forwarding_matches_spec(action):
    expected = {"INPUT_" + n.upper().replace("-", "_") for n in SPECS[action]["checks"]}
    assert env_keys(action) == expected


@pytest.mark.parametrize("action", ACTIONS)
def test_input_whose_check_refuses_blank_declares_a_default(action):
    # Without a default, a caller leaving the input out reaches the validator as blank and fails.
    inputs = yaml.safe_load((REPO_ROOT / action / "action.yml").read_text(encoding="utf-8"))[
        "inputs"
    ]
    refusing = [n for n, check in SPECS[action]["checks"].items() if kit.CHECKS[check]("")]
    assert [n for n in refusing if not inputs[n].get("default")] == []


def _local_action_steps():
    """Yield (workflow name, step, action.yml path) for each step running an in-repo action."""
    for pattern in ("_tests/integration/workflows/*.yml", ".github/workflows/*.yml"):
        for workflow in sorted(REPO_ROOT.glob(pattern)):
            jobs = yaml.safe_load(workflow.read_text(encoding="utf-8"))["jobs"]
            for job in jobs.values():
                for step in job.get("steps", []):
                    action_yml = REPO_ROOT / step.get("uses", "") / "action.yml"
                    if step.get("uses", "").startswith("./") and action_yml.is_file():
                        yield workflow.name, step, action_yml


def test_workflows_pass_only_declared_inputs_to_local_actions():
    # The runner only warns about an undeclared input and drops its value, so a misnamed one
    # leaves the step testing something other than what it says.
    undeclared = []
    for workflow, step, action_yml in _local_action_steps():
        metadata = yaml.safe_load(action_yml.read_text(encoding="utf-8"))
        extra = set(step.get("with", {})) - set(metadata.get("inputs") or {})
        undeclared += [f"{workflow}: {step['uses']} {name}" for name in sorted(extra)]
    assert undeclared == []


_SINGLE = re.compile(r"^\s*([a-zA-Z0-9_.-]+): '((?:[^']|'')*)'\s*$")
_DOUBLE = re.compile(r'^\s*([a-zA-Z0-9_.-]+): "((?:[^"\\]|\\.)*)"\s*$')


def _scalar(line: str) -> tuple[str, str] | None:
    """Parse `key: <quoted scalar>` into (key, value), or None if the line is not one.

    Quoted values are unescaped rather than skipped. The first version of this test
    matched `['\"]([^'\"]*)['\"]`, which silently ignored any value containing a
    quote — exactly the values most likely to be mis-serialised. It skipped the JSON
    example for `platform-build-args` and so missed that it had been emitted as
    `"{"linux/amd64": ...}"`, producing three unparseable YAML blocks.
    """
    m = _SINGLE.match(line)
    if m:
        return m.group(1), m.group(2).replace("''", "'")
    m = _DOUBLE.match(line)
    if m:
        return m.group(1), m.group(2).replace('\\"', '"').replace("\\\\", "\\")
    return None


@pytest.mark.parametrize("action", ACTIONS)
def test_documented_input_values_pass_their_own_validator(action):
    """Every input value shown in a generated README must be one the action accepts.

    `make docs` substitutes kit.EXAMPLES into the generated examples so a reader can
    copy a quick start and have it run. This asserts the result: if a substitution
    silently fails, or a check is tightened without updating its example, the README
    ends up publishing a value the action's own validate.py rejects.
    """
    readme = REPO_ROOT / action / "README.md"
    if not readme.is_file():
        return
    checks = SPECS[action]["checks"]
    invalid = []
    for line in readme.read_text(encoding="utf-8").splitlines():
        parsed = _scalar(line)
        if parsed is None:
            continue
        name, value = parsed
        check = checks.get(name)
        # The runner expands a `${{ }}` value before validate.py reads it, so a README
        # showing one documents a reference: there is no literal value here to check.
        if not check or (value.startswith("${{") and value.endswith("}}")):
            continue
        error = kit.CHECKS[check](value)
        if error:
            invalid.append(f"{name}={value!r}: {error}")
    assert not invalid, f"{action}/README.md documents invalid input values: {invalid}"


_YAML_BLOCK = re.compile(r"```yaml\n(.*?)\n```", re.DOTALL)


def _yaml_error(block: str) -> str | None:
    """Return the parse error for one YAML block, or None if it parses.

    Kept out of the caller's loop so the try/except is not re-entered per block
    (ruff PERF203); it also keeps the failure message to a single line.
    """
    try:
        yaml.safe_load(block)
    except yaml.YAMLError as exc:
        return str(exc).replace("\n", " ")
    return None


@pytest.mark.parametrize("action", ACTIONS)
def test_documented_yaml_blocks_parse(action):
    """Every fenced YAML block in a generated README must actually parse.

    The value-level test above cannot catch this on its own: it asserts that each
    documented *value* is one the action accepts, so a line that fails to parse as
    YAML at all slips past it. That was the real defect behind 2d899a9 — reusing the
    generator's quote character emitted `platform-build-args: "{"linux/amd64": ...}"`
    and broke three blocks in docker-build/README.md while the value test reported
    clean. Emission is correct by construction now; this is the guard that keeps it
    that way, and it covers every block, not just the lines carrying a known input.
    """
    readme = REPO_ROOT / action / "README.md"
    if not readme.is_file():
        return
    blocks = _YAML_BLOCK.findall(readme.read_text(encoding="utf-8"))
    assert blocks, f"{action}/README.md has no YAML examples — the generator emits at least one"
    unparseable = [
        f"block {i}: {error}"
        for i, block in enumerate(blocks, 1)
        if (error := _yaml_error(block)) is not None
    ]
    assert not unparseable, f"{action}/README.md has unparseable YAML: {unparseable}"


def test_no_action_uses_the_old_validate_inputs_action():
    offenders = [
        p.parent.name
        for p in REPO_ROOT.glob("*/action.yml")
        if "uses: ivuorinen/actions/validate-inputs@" in p.read_text(encoding="utf-8")
    ]
    assert offenders == []
