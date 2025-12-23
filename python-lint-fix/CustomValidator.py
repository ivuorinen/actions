#!/usr/bin/env python3
"""Custom validator for python-lint-fix action."""

from __future__ import annotations

from pathlib import Path
import sys

# Add validate-inputs directory to path to import validators
validate_inputs_path = Path(__file__).parent.parent / "validate-inputs"
sys.path.insert(0, str(validate_inputs_path))

from validators.base import BaseValidator
from validators.network import NetworkValidator
from validators.token import TokenValidator
from validators.version import VersionValidator


class CustomValidator(BaseValidator):
    """Custom validator for python-lint-fix action."""

    def __init__(self, action_type: str = "python-lint-fix") -> None:
        """Initialize python-lint-fix validator."""
        super().__init__(action_type)
        self.version_validator = VersionValidator()
        self.network_validator = NetworkValidator()
        self.token_validator = TokenValidator()

    def validate_inputs(self, inputs: dict[str, str]) -> bool:
        """Validate python-lint-fix action inputs."""
        valid = True

        # Validate python-version if provided
        version_key = self.get_key_variant(inputs, "python-version", "python_version")
        if version_key:
            value = inputs[version_key]
            if not value:
                self.add_error("Python version cannot be empty")
                valid = False
            else:
                valid &= self.validate_with(
                    self.version_validator, "validate_python_version", value, version_key
                )

        # Validate username
        if inputs.get("username"):
            username = inputs["username"]
            if len(username) > 39:
                self.add_error("Username is too long (max 39 characters)")
                valid = False
            if ";" in username or "`" in username or "$" in username:
                self.add_error("Username contains potentially dangerous characters")
                valid = False

        # Validate email
        if inputs.get("email"):
            valid &= self.validate_with(
                self.network_validator, "validate_email", inputs["email"], "email"
            )

        # Validate token
        if inputs.get("token"):
            token = inputs["token"]
            # Check for variable expansion (but allow GitHub Actions expressions)
            if "${" in token and not token.startswith("${{ ") and not token.endswith(" }}"):
                self.add_error("Token contains potentially dangerous variable expansion")
                valid = False
            else:
                valid &= self.validate_with(self.token_validator, "validate_github_token", token)

        return valid

    def get_required_inputs(self) -> list[str]:
        """Get list of required inputs."""
        return []

    def get_validation_rules(self) -> dict:
        """Get validation rules."""
        return {
            "python-version": {
                "type": "python_version",
                "required": False,
                "description": "Python version to use",
            },
            "working-directory": {
                "type": "directory",
                "required": False,
                "description": "Working directory",
            },
        }
