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
        if "python-version" in inputs or "python_version" in inputs:
            key = "python-version" if "python-version" in inputs else "python_version"
            value = inputs[key]

            # Empty string should fail validation
            if value == "":
                self.add_error("Python version cannot be empty")
                valid = False
            elif value:
                result = self.version_validator.validate_python_version(value, key)

                # Propagate errors from the version validator
                for error in self.version_validator.errors:
                    if error not in self.errors:
                        self.add_error(error)

                self.version_validator.clear_errors()

                if not result:
                    valid = False

        # Validate username
        if "username" in inputs:
            username = inputs["username"]
            if username:
                # Check username length (GitHub usernames are max 39 characters)
                if len(username) > 39:
                    self.add_error("Username is too long (max 39 characters)")
                    valid = False
                # Check for command injection patterns
                if ";" in username or "`" in username or "$" in username:
                    self.add_error("Username contains potentially dangerous characters")
                    valid = False

        # Validate email
        if "email" in inputs:
            email = inputs["email"]
            if email:
                result = self.network_validator.validate_email(email, "email")
                for error in self.network_validator.errors:
                    if error not in self.errors:
                        self.add_error(error)
                self.network_validator.clear_errors()
                if not result:
                    valid = False

        # Validate token
        if "token" in inputs:
            token = inputs["token"]
            if token:
                # Check for variable expansion (but allow GitHub Actions expressions)
                if "${" in token and not token.startswith("${{ ") and not token.endswith(" }}"):
                    self.add_error("Token contains potentially dangerous variable expansion")
                    valid = False
                else:
                    result = self.token_validator.validate_github_token(token)
                    for error in self.token_validator.errors:
                        if error not in self.errors:
                            self.add_error(error)
                    self.token_validator.clear_errors()
                    if not result:
                        valid = False

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
