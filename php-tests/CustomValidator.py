#!/usr/bin/env python3
"""Custom validator for php-tests action."""

from __future__ import annotations

from pathlib import Path
import sys

# Add validate-inputs directory to path to import validators
validate_inputs_path = Path(__file__).parent.parent / "validate-inputs"
sys.path.insert(0, str(validate_inputs_path))

from validators.base import BaseValidator  # noqa: E402
from validators.network import NetworkValidator  # noqa: E402
from validators.security import SecurityValidator  # noqa: E402
from validators.token import TokenValidator  # noqa: E402


class CustomValidator(BaseValidator):
    """Custom validator for php-tests action."""

    def __init__(self, action_type: str = "php-tests") -> None:
        """Initialize php-tests validator."""
        super().__init__(action_type)
        self.network_validator = NetworkValidator()
        self.security_validator = SecurityValidator()
        self.token_validator = TokenValidator()

    def validate_inputs(self, inputs: dict[str, str]) -> bool:
        """Validate php-tests action inputs."""
        valid = True

        # Validate token (optional)
        if inputs.get("token"):
            token = inputs["token"]
            if token == "":
                self.add_error("Token cannot be empty string")
                valid = False
            else:
                result = self.token_validator.validate_github_token(token, required=False)
                for error in self.token_validator.errors:
                    if error not in self.errors:
                        self.add_error(error)
                self.token_validator.clear_errors()
                if not result:
                    valid = False

                # Also check for variable expansion
                if not self.is_github_expression(token):
                    result = self.security_validator.validate_no_injection(token, "token")
                    for error in self.security_validator.errors:
                        if error not in self.errors:
                            self.add_error(error)
                    self.security_validator.clear_errors()
                    if not result:
                        valid = False

        # Validate email (optional)
        if inputs.get("email"):
            email = inputs["email"]
            if email == "":
                self.add_error("Email cannot be empty string")
                valid = False
            else:
                result = self.network_validator.validate_email(email, "email")
                for error in self.network_validator.errors:
                    if error not in self.errors:
                        self.add_error(error)
                self.network_validator.clear_errors()
                if not result:
                    valid = False

                # Also check for shell metacharacters
                if not self.is_github_expression(email):
                    result = self.security_validator.validate_no_injection(email, "email")
                    for error in self.security_validator.errors:
                        if error not in self.errors:
                            self.add_error(error)
                    self.security_validator.clear_errors()
                    if not result:
                        valid = False

        # Validate username (optional)
        if inputs.get("username"):
            username = inputs["username"]
            if not self.is_github_expression(username):
                # Check for injection
                result = self.security_validator.validate_no_injection(username, "username")
                for error in self.security_validator.errors:
                    if error not in self.errors:
                        self.add_error(error)
                self.security_validator.clear_errors()
                if not result:
                    valid = False

                # Check username length (Git username should be reasonable)
                if len(username) > 100:
                    self.add_error("Username is too long (max 100 characters)")
                    valid = False

        return valid

    def get_required_inputs(self) -> list[str]:
        """Get list of required inputs."""
        return []
