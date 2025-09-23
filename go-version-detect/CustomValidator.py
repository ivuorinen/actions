#!/usr/bin/env python3
"""Custom validator for go-version-detect action."""

from __future__ import annotations

from pathlib import Path
import sys

# Add validate-inputs directory to path to import validators
validate_inputs_path = Path(__file__).parent.parent / "validate-inputs"
sys.path.insert(0, str(validate_inputs_path))

from validators.base import BaseValidator  # noqa: E402
from validators.version import VersionValidator  # noqa: E402


class CustomValidator(BaseValidator):
    """Custom validator for go-version-detect action."""

    def __init__(self, action_type: str = "go-version-detect") -> None:
        """Initialize the validator."""
        super().__init__(action_type)
        self.version_validator = VersionValidator()

    def validate_inputs(self, inputs: dict[str, str]) -> bool:
        """Validate go-version-detect specific inputs using existing validators."""
        valid = True

        # Validate default-version if provided
        if "default-version" in inputs:
            value = inputs["default-version"]

            # Empty string should fail validation for this action
            if value == "":
                self.add_error("Go version cannot be empty")
                valid = False
            elif value:
                # Use the existing Go version validator
                result = self.version_validator.validate_go_version(value, "default-version")

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
        """Return list of required inputs."""
        return []

    def get_validation_rules(self) -> dict:
        """Return validation rules for this action."""
        return {
            "default-version": {
                "type": "go_version",
                "required": False,
                "description": "Default Go version to use",
            }
        }
