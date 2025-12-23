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
            valid &= self.validate_with(self.token_validator, "validate_github_token", token)
            # Also check for variable expansion
            if not self.is_github_expression(token):
                valid &= self.validate_with(
                    self.security_validator, "validate_no_injection", token, "token"
                )

        # Validate email (optional, empty means use default)
        if inputs.get("email"):
            email = inputs["email"]
            valid &= self.validate_with(self.network_validator, "validate_email", email, "email")
            # Also check for shell metacharacters (but allow @ and .)
            if not self.is_github_expression(email):
                dangerous_chars = [";", "&", "|", "`", "$", "(", ")", "<", ">", "\n", "\r"]
                if any(char in email for char in dangerous_chars):
                    self.add_error("email: Contains dangerous shell metacharacter")
                    valid = False

        # Validate username (optional)
        if inputs.get("username"):
            username = inputs["username"]
            if not self.is_github_expression(username):
                valid &= self.validate_with(
                    self.security_validator, "validate_no_injection", username, "username"
                )
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
