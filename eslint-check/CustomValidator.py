#!/usr/bin/env python3
"""Custom validator for eslint-check action."""

from __future__ import annotations

from pathlib import Path
import sys

# Add validate-inputs directory to path to import validators
validate_inputs_path = Path(__file__).parent.parent / "validate-inputs"
sys.path.insert(0, str(validate_inputs_path))

from validators.base import BaseValidator  # noqa: E402
from validators.file import FileValidator  # noqa: E402


class CustomValidator(BaseValidator):
    """Custom validator for eslint-check action."""

    def __init__(self, action_type: str = "eslint-check") -> None:
        """Initialize eslint-check validator."""
        super().__init__(action_type)
        self.file_validator = FileValidator()

    def validate_inputs(self, inputs: dict[str, str]) -> bool:
        """Validate eslint-check action inputs."""
        valid = True

        # Validate directory if provided
        if inputs.get("directory"):
            result = self.file_validator.validate_file_path(inputs["directory"], "directory")
            for error in self.file_validator.errors:
                if error not in self.errors:
                    self.add_error(error)
            self.file_validator.clear_errors()
            if not result:
                valid = False

        # Validate config-file if provided
        if inputs.get("config-file"):
            result = self.file_validator.validate_file_path(inputs["config-file"], "config-file")
            for error in self.file_validator.errors:
                if error not in self.errors:
                    self.add_error(error)
            self.file_validator.clear_errors()
            if not result:
                valid = False

        return valid

    def get_required_inputs(self) -> list[str]:
        """Get list of required inputs."""
        return []

    def get_validation_rules(self) -> dict:
        """Get validation rules."""
        return {
            "directory": {
                "type": "directory",
                "required": False,
                "description": "Directory to check",
            },
            "config-file": {
                "type": "file",
                "required": False,
                "description": "ESLint config file",
            },
        }
