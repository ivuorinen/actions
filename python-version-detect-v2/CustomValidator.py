#!/usr/bin/env python3
"""Custom validator for python-version-detect-v2 action."""

from __future__ import annotations

from pathlib import Path
import sys

# Add validate-inputs directory to path to import validators
validate_inputs_path = Path(__file__).parent.parent / "validate-inputs"
sys.path.insert(0, str(validate_inputs_path))

from validators.base import BaseValidator
from validators.version import VersionValidator


class CustomValidator(BaseValidator):
    """Custom validator for python-version-detect-v2 action."""

    def __init__(self, action_type: str = "python-version-detect-v2") -> None:
        """Initialize python-version-detect-v2 validator."""
        super().__init__(action_type)
        self.version_validator = VersionValidator()

    def validate_inputs(self, inputs: dict[str, str]) -> bool:
        """Validate python-version-detect-v2 action inputs."""
        valid = True

        # Validate default-version if provided
        if "default-version" in inputs:
            value = inputs["default-version"]

            # Empty string should fail validation
            if value == "":
                self.add_error("Python version cannot be empty")
                valid = False
            elif value:
                # Use the Python version validator which handles version ranges
                result = self.version_validator.validate_python_version(value, "default-version")

                # Propagate errors from the version validator
                for error in self.version_validator.errors:
                    if error not in self.errors:
                        self.add_error(error)

                # Clear the version validator's errors after propagating
                self.version_validator.clear_errors()

                if not result:
                    valid = False

        return valid

    def get_required_inputs(self) -> list[str]:
        """Get list of required inputs."""
        return []

    def get_validation_rules(self) -> dict:
        """Get validation rules."""
        return {
            "default-version": {
                "type": "python_version",
                "required": False,
                "description": "Default Python version to use",
            }
        }
