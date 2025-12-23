#!/usr/bin/env python3
"""Custom validator for validate-inputs action."""
# pylint: disable=invalid-name  # Module name matches class name for clarity

from __future__ import annotations

import re
import sys
from pathlib import Path

# Add validate-inputs directory to path to import validators
validate_inputs_path = Path(__file__).parent
sys.path.insert(0, str(validate_inputs_path))

# pylint: disable=wrong-import-position
from validators.base import BaseValidator
from validators.boolean import BooleanValidator
from validators.file import FileValidator


class CustomValidator(BaseValidator):
    """Custom validator for validate-inputs action."""

    def __init__(self, action_type: str = "validate-inputs") -> None:
        """Initialize validate-inputs validator."""
        super().__init__(action_type)
        self.boolean_validator = BooleanValidator()
        self.file_validator = FileValidator()

    def validate_inputs(self, inputs: dict[str, str]) -> bool:
        """Validate validate-inputs action inputs."""
        valid = True

        # Validate action/action-type input
        action_key = self.get_key_variant(inputs, "action", "action-type")
        if action_key:
            action_input = inputs[action_key]
            if action_input == "":
                self.add_error("Action name cannot be empty")
                valid = False
            elif not self.is_github_expression(action_input):
                # Only validate non-GitHub expressions
                if any(
                    char in action_input
                    for char in [";", "`", "$", "&", "|", ">", "<", "\n", "\r", "/"]
                ):
                    self.add_error(f"Invalid characters in action name: {action_input}")
                    valid = False
                elif action_input and not re.match(r"^[a-z][a-z0-9_-]*[a-z0-9]$", action_input):
                    self.add_error(f"Invalid action name format: {action_input}")
                    valid = False

        # Validate rules-file if provided
        if inputs.get("rules-file"):
            valid &= self.validate_with(
                self.file_validator, "validate_file_path", inputs["rules-file"], "rules-file"
            )

        # Validate fail-on-error boolean
        if "fail-on-error" in inputs:
            value = inputs["fail-on-error"]
            if value == "":
                self.add_error("fail-on-error cannot be empty")
                valid = False
            elif value:
                valid &= self.validate_with(
                    self.boolean_validator, "validate_boolean", value, "fail-on-error"
                )

        return valid

    def get_required_inputs(self) -> list[str]:
        """Get list of required inputs."""
        # action/action-type is required
        return []

    def get_validation_rules(self) -> dict:
        """Get validation rules."""
        return {
            "action": {
                "type": "string",
                "required": False,
                "description": "Action name to validate",
            },
            "action-type": {
                "type": "string",
                "required": False,
                "description": "Action type to validate (alias for action)",
            },
            "rules-file": {
                "type": "file",
                "required": False,
                "description": "Rules file path",
            },
            "fail-on-error": {
                "type": "boolean",
                "required": False,
                "description": "Whether to fail on validation error",
            },
        }
