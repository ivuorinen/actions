#!/usr/bin/env python3
"""Shared validation core for the ShellSpec test harness.

The actual input checks live in ``_validation/kit.py`` (the single source of truth); this
module delegates to ``kit.CHECKS`` via ``_validation/spec.py`` and adds:

1. action.yml parsing utilities (name, inputs, outputs, runs-using, input properties)
2. a command-line interface for ShellSpec test integration (``--validate``, ``--property``,
   ``--inputs``, ``--outputs``, ``--name``, ``--runs-using``, ``--validate-yaml``)

It holds no validation patterns of its own — to change what an input accepts, edit
``_validation/kit.py`` and run ``make update-validators``.
"""

from __future__ import annotations

import argparse
from pathlib import Path
import sys
from typing import Any

import yaml  # pylint: disable=import-error

# Delegate input validation to the canonical per-action validation kit
# (_validation/kit.py + _validation/spec.py) — the single source of truth that
# also generates each action's self-contained validate.py. Adding the directory
# to sys.path lets this CLI import the same checks the actions run.
sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "_validation"))
# The harness runs many of these CLI processes in parallel; skipping .pyc writes for
# kit/spec avoids a cold-cache bytecode-compile race on the first run.
sys.dont_write_bytecode = True
import kit  # pylint: disable=import-error,wrong-import-position
from spec import SPECS  # pylint: disable=import-error,wrong-import-position

# Default value for unknown items (used by ActionFileParser)
DEFAULT_UNKNOWN = "Unknown"


class ActionFileParser:
    """Parser for GitHub Action YAML files."""

    @staticmethod
    def load_action_file(action_file: str) -> dict[str, Any]:
        """Load and parse an action.yml file."""
        try:
            with Path(action_file).open(encoding="utf-8") as f:
                return yaml.safe_load(f)
        except (OSError, yaml.YAMLError) as e:
            msg = f"Failed to load action file {action_file}: {e}"
            raise ValueError(msg) from e

    @staticmethod
    def get_action_name(action_file: str) -> str:
        """Get the action name from an action.yml file."""
        try:
            data = ActionFileParser.load_action_file(action_file)
            return data.get("name", DEFAULT_UNKNOWN)
        except (OSError, ValueError, yaml.YAMLError, AttributeError):
            return DEFAULT_UNKNOWN

    @staticmethod
    def get_action_inputs(action_file: str) -> list[str]:
        """Get all input names from an action.yml file."""
        try:
            data = ActionFileParser.load_action_file(action_file)
            inputs = data.get("inputs", {})
            return list(inputs.keys())
        except (OSError, ValueError, yaml.YAMLError, AttributeError):
            return []

    @staticmethod
    def get_action_outputs(action_file: str) -> list[str]:
        """Get all output names from an action.yml file."""
        try:
            data = ActionFileParser.load_action_file(action_file)
            outputs = data.get("outputs", {})
            return list(outputs.keys())
        except (OSError, ValueError, yaml.YAMLError, AttributeError):
            return []

    @staticmethod
    def get_action_runs_using(action_file: str) -> str:
        """Get the runs.using value from an action.yml file."""
        try:
            data = ActionFileParser.load_action_file(action_file)
            runs = data.get("runs", {})
            return runs.get("using", "unknown")
        except (OSError, ValueError, yaml.YAMLError, AttributeError):
            return "unknown"

    @staticmethod
    def _get_required_property(input_data: dict, property_name: str) -> str:
        """Get the required/optional property."""
        is_required = input_data.get("required") in [True, "true"]
        if property_name == "required":
            return "required" if is_required else "optional"
        return "optional" if not is_required else "required"

    @staticmethod
    def _get_default_property(input_data: dict) -> str:
        """Get the default property."""
        default_value = input_data.get("default", "")
        return str(default_value) if default_value else "no-default"

    @staticmethod
    def _get_description_property(input_data: dict) -> str:
        """Get the description property."""
        description = input_data.get("description", "")
        return description or "no-description"

    @staticmethod
    def _get_all_optional_property(inputs: dict) -> str:
        """Get the all_optional property (list of required inputs)."""
        required_inputs = [k for k, v in inputs.items() if v.get("required") in [True, "true"]]
        return "none" if not required_inputs else ",".join(required_inputs)

    @staticmethod
    def get_input_property(action_file: str, input_name: str, property_name: str) -> str:
        """
        Get a property of an input from an action.yml file.

        Args:
            action_file: Path to the action.yml file
            input_name: Name of the input to check
            property_name: Property to check (required, optional, default, description,
                all_optional)

        Returns:
            - For 'required': 'required' or 'optional'
            - For 'optional': 'optional' or 'required'
            - For 'default': the default value or 'no-default'
            - For 'description': the description or 'no-description'
            - For 'all_optional': 'none' if no required inputs, else comma-separated list
        """
        try:
            data = ActionFileParser.load_action_file(action_file)
            inputs = data.get("inputs", {})
            input_data = inputs.get(input_name, {})

            property_handlers = {
                "required": lambda: ActionFileParser._get_required_property(
                    input_data, property_name
                ),
                "optional": lambda: ActionFileParser._get_required_property(
                    input_data, property_name
                ),
                "default": lambda: ActionFileParser._get_default_property(input_data),
                "description": lambda: ActionFileParser._get_description_property(input_data),
                "all_optional": lambda: ActionFileParser._get_all_optional_property(inputs),
            }

            if property_name in property_handlers:
                return property_handlers[property_name]()

            return f"unknown-property-{property_name}"

        except (OSError, ValueError, yaml.YAMLError, AttributeError, KeyError) as e:
            return f"error: {e}"


def resolve_action_file_path(action_dir: str) -> str:
    """Resolve the path to the action.yml file."""
    action_dir_path = Path(action_dir)
    if not action_dir_path.is_absolute():
        # If relative, assume we're in _tests/shared and actions are at ../../
        script_dir = Path(__file__).resolve().parent
        project_root = script_dir.parent.parent
        return str(project_root / action_dir / "action.yml")
    return f"{action_dir}/action.yml"


def validate_input(action_dir: str, input_name: str, input_value: str) -> tuple[bool, str]:
    """Validate one input value by delegating to the canonical validation kit.

    Looks up the action's spec (``_validation/spec.py``) to find the check type for
    ``input_name``, then runs the matching ``kit.CHECKS`` function. Returns
    ``(is_valid, error_message)``; ``error_message`` is empty on success. Inputs with
    no spec entry, or no check for the given name, are treated as valid — the kit only
    governs inputs it knows about.
    """
    action = Path(action_dir).name
    spec = SPECS.get(action)
    if spec is None:
        return True, ""

    checks = spec["checks"]
    # action.yml input names use hyphens; spec keys mirror them, but be tolerant of
    # the hyphen/underscore swap that env-var derivation introduces.
    check_type = (
        checks.get(input_name)
        or checks.get(input_name.replace("-", "_"))
        or checks.get(input_name.replace("_", "-"))
    )
    if check_type is None:
        return True, ""

    if input_name in spec["required"] and input_value.strip() == "":
        return False, f"Required input '{input_name}' cannot be empty"

    err = kit.CHECKS[check_type](input_value)
    return err is None, err or ""


def _handle_legacy_interface() -> bool:
    """Handle legacy 4-positional-arg CLI: (action_dir input_name value expected).

    Detects the legacy form by argument count only, so values beginning with
    '-' (valid semver prereleases, negative numbers) are not mistaken for
    argparse flags. Returns False (and lets argparse take over) for any
    other form, including --help explicitly.
    """
    if len(sys.argv) != 5:
        return False
    # Only sys.argv[1] (the action_dir) must not look like a flag. Later
    # positionals — especially input_value at sys.argv[3] — MAY start with
    # `-` (valid semver prereleases, negative numbers).
    if sys.argv[1].startswith("-"):
        return False
    action_dir, input_name, input_value, expected_result = sys.argv[1:5]
    is_valid, error_msg = validate_input(action_dir, input_name, input_value)
    actual_result = "success" if is_valid else "failure"
    if actual_result == expected_result:
        raise SystemExit(0)
    print(f"Expected {expected_result}, got {actual_result}: {error_msg}", file=sys.stderr)
    raise SystemExit(1)


def _create_argument_parser():
    """Create and configure the argument parser."""
    parser = argparse.ArgumentParser(
        description="Shared validation core for GitHub Actions",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Validate an input value
  python3 validation_core.py --validate action-dir input-name input-value

  # Get input property
  python3 validation_core.py --property action.yml input-name required

  # List inputs
  python3 validation_core.py --inputs action.yml

  # List outputs
  python3 validation_core.py --outputs action.yml

  # Get action name
  python3 validation_core.py --name action.yml
        """,
    )

    mode_group = parser.add_mutually_exclusive_group(required=True)
    mode_group.add_argument(
        "--validate",
        nargs=3,
        metavar=("ACTION_DIR", "INPUT_NAME", "INPUT_VALUE"),
        help="Validate an input value",
    )
    mode_group.add_argument(
        "--property",
        nargs=3,
        metavar=("ACTION_FILE", "INPUT_NAME", "PROPERTY"),
        help="Get input property",
    )
    mode_group.add_argument("--inputs", metavar="ACTION_FILE", help="List action inputs")
    mode_group.add_argument("--outputs", metavar="ACTION_FILE", help="List action outputs")
    mode_group.add_argument("--name", metavar="ACTION_FILE", help="Get action name")
    mode_group.add_argument(
        "--runs-using",
        metavar="ACTION_FILE",
        help="Get action runs.using value",
    )
    mode_group.add_argument(
        "--validate-yaml",
        metavar="YAML_FILE",
        help="Validate YAML file syntax",
    )

    return parser


def _handle_validate_command(args):
    """Handle the validate command."""
    action_dir, input_name, input_value = args.validate
    is_valid, error_msg = validate_input(action_dir, input_name, input_value)
    if is_valid:
        sys.exit(0)
    else:
        print(f"INVALID: {error_msg}", file=sys.stderr)
        sys.exit(1)


def _handle_property_command(args):
    """Handle the property command."""
    action_file, input_name, property_name = args.property
    result = ActionFileParser.get_input_property(action_file, input_name, property_name)
    print(result)


def _handle_inputs_command(args):
    """Handle the inputs command."""
    inputs = ActionFileParser.get_action_inputs(args.inputs)
    for input_name in inputs:
        print(input_name)


def _handle_outputs_command(args):
    """Handle the outputs command."""
    outputs = ActionFileParser.get_action_outputs(args.outputs)
    for output_name in outputs:
        print(output_name)


def _handle_name_command(args):
    """Handle the name command."""
    name = ActionFileParser.get_action_name(args.name)
    print(name)


def _handle_runs_using_command(args):
    """Handle the runs-using command."""
    runs_using = ActionFileParser.get_action_runs_using(args.runs_using)
    print(runs_using)


def _handle_validate_yaml_command(args):
    """Handle the validate-yaml command."""
    try:
        with Path(args.validate_yaml).open(encoding="utf-8") as f:
            yaml.safe_load(f)
        sys.exit(0)
    except (OSError, yaml.YAMLError) as e:
        print(f"Invalid YAML: {e}", file=sys.stderr)
        sys.exit(1)


def _execute_command(args):
    """Execute the appropriate command based on arguments."""
    command_handlers = {
        "validate": _handle_validate_command,
        "property": _handle_property_command,
        "inputs": _handle_inputs_command,
        "outputs": _handle_outputs_command,
        "name": _handle_name_command,
        "runs_using": _handle_runs_using_command,
        "validate_yaml": _handle_validate_yaml_command,
    }

    for command, handler in command_handlers.items():
        if getattr(args, command, None):
            handler(args)
            return


def main():
    """Command-line interface for validation core."""
    # Handle legacy interface first
    _handle_legacy_interface()

    # Parse arguments and execute command
    parser = _create_argument_parser()
    args = parser.parse_args()

    try:
        _execute_command(args)
    except (ValueError, OSError, AttributeError) as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
