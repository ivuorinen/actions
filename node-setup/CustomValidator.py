#!/usr/bin/env python3
"""Custom validator for node-setup action."""

from __future__ import annotations

from pathlib import Path
import sys

# Add validate-inputs directory to path to import validators
validate_inputs_path = Path(__file__).parent.parent / "validate-inputs"
sys.path.insert(0, str(validate_inputs_path))

from validators.base import BaseValidator  # noqa: E402
from validators.version import VersionValidator  # noqa: E402


class CustomValidator(BaseValidator):
    """Custom validator for node-setup action."""

    def __init__(self, action_type: str = "node-setup") -> None:
        """Initialize node-setup validator."""
        super().__init__(action_type)
        self.version_validator = VersionValidator()

    def validate_inputs(self, inputs: dict[str, str]) -> bool:
        """Validate node-setup action inputs."""
        valid = True

        # Validate default-version if provided
        if "default-version" in inputs:
            value = inputs["default-version"]

            # Empty string should fail validation
            if value == "":
                self.add_error("Node version cannot be empty")
                valid = False
            elif value:
                # Use the Node version validator
                result = self.version_validator.validate_node_version(value, "default-version")

                # Propagate errors from the version validator
                for error in self.version_validator.errors:
                    if error not in self.errors:
                        self.add_error(error)

                # Clear the version validator's errors after propagating
                self.version_validator.clear_errors()

                if not result:
                    valid = False

        # Validate package-manager if provided
        if "package-manager" in inputs:
            value = inputs["package-manager"]
            if value and value not in ["npm", "yarn", "pnpm", "bun"]:
                self.add_error(
                    f"Invalid package manager: {value}. Must be one of: npm, yarn, pnpm, bun"
                )
                valid = False

        return valid

    def get_required_inputs(self) -> list[str]:
        """Get list of required inputs."""
        return []

    def get_validation_rules(self) -> dict:
        """Get validation rules."""
        return {
            "default-version": {
                "type": "node_version",
                "required": False,
                "description": "Default Node.js version to use",
            },
            "package-manager": {
                "type": "string",
                "required": False,
                "description": "Package manager to use",
            },
        }
