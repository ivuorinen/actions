#!/usr/bin/env python3
"""Custom validator for php-tests action."""

from __future__ import annotations

from pathlib import Path
import sys

# Add validate-inputs directory to path to import validators
validate_inputs_path = Path(__file__).parent.parent / "validate-inputs"
sys.path.insert(0, str(validate_inputs_path))

from validators.base import BaseValidator
from validators.network import NetworkValidator
from validators.security import SecurityValidator
from validators.token import TokenValidator


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
            result = self.token_validator.validate_github_token(token)
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

        # Validate email (optional, empty means use default)
        if "email" in inputs and inputs["email"] and inputs["email"] != "":
            email = inputs["email"]
            result = self.network_validator.validate_email(email, "email")
            for error in self.network_validator.errors:
                if error not in self.errors:
                    self.add_error(error)
            self.network_validator.clear_errors()
            if not result:
                valid = False

            # Also check for shell metacharacters (but allow @ and .)
            if not self.is_github_expression(email):
                # Only check for dangerous shell metacharacters, not @ or .
                dangerous_chars = [";", "&", "|", "`", "$", "(", ")", "<", ">", "\n", "\r"]
                for char in dangerous_chars:
                    if char in email:
                        self.add_error(f"email: Contains dangerous character '{char}'")
                        valid = False
                        break

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

                # Check username length (GitHub usernames are max 39 characters)
                if len(username) > 39:
                    self.add_error("Username is too long (max 39 characters)")
                    valid = False

        return valid

    def get_required_inputs(self) -> list[str]:
        """Get list of required inputs."""
        return []

    def get_validation_rules(self) -> dict:
        """Get validation rules for this action."""
        rules_path = Path(__file__).parent / "rules.yml"
        return self.load_rules(rules_path)
