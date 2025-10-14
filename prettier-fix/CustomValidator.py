#!/usr/bin/env python3
"""Custom validator for prettier-fix action."""

from __future__ import annotations

from pathlib import Path
import sys

# Add validate-inputs directory to path to import validators
validate_inputs_path = Path(__file__).parent.parent / "validate-inputs"
sys.path.insert(0, str(validate_inputs_path))

from validators.base import BaseValidator
from validators.network import NetworkValidator
from validators.numeric import NumericValidator
from validators.token import TokenValidator


class CustomValidator(BaseValidator):
    """Custom validator for prettier-fix action."""

    def __init__(self, action_type: str = "prettier-fix") -> None:
        """Initialize prettier-fix validator."""
        super().__init__(action_type)
        self.network_validator = NetworkValidator()
        self.numeric_validator = NumericValidator()
        self.token_validator = TokenValidator()

    def validate_inputs(self, inputs: dict[str, str]) -> bool:
        """Validate prettier-fix action inputs."""
        valid = True
        # No required inputs

        # Validate optional input: username
        if "username" in inputs:
            username = inputs["username"]
            if username:
                # Check username length (GitHub usernames are max 39 characters)
                if len(username) > 39:
                    self.add_error("Username is too long (max 39 characters)")
                    valid = False
                # Check for command injection patterns
                if ";" in username:
                    self.add_error("Username contains potentially dangerous character ';'")
                    valid = False
                if "&&" in username or "&" in username:
                    self.add_error("Username contains potentially dangerous character '&'")
                    valid = False
                if "|" in username:
                    self.add_error("Username contains potentially dangerous character '|'")
                    valid = False
                if "`" in username:
                    self.add_error("Username contains potentially dangerous character '`'")
                    valid = False
                if "$" in username:
                    self.add_error("Username contains potentially dangerous character '$'")
                    valid = False

        # Validate optional input: email
        if "email" in inputs:
            email = inputs["email"]
            if not email or email.strip() == "":
                # Empty email should fail validation
                self.add_error("Email cannot be empty")
                valid = False
            else:
                result = self.network_validator.validate_email(email, "email")
                for error in self.network_validator.errors:
                    if error not in self.errors:
                        self.add_error(error)
                self.network_validator.clear_errors()
                if not result:
                    valid = False
                # Additional security checks
                if "`" in email:
                    self.add_error("Email contains potentially dangerous character '`'")
                    valid = False
        # Validate optional input: max-retries (check both hyphenated and underscored)
        max_retries_key = None
        if "max-retries" in inputs:
            max_retries_key = "max-retries"
        elif "max_retries" in inputs:
            max_retries_key = "max_retries"

        if max_retries_key:
            result = self.numeric_validator.validate_numeric_range(
                inputs[max_retries_key], min_val=1, max_val=10
            )
            for error in self.numeric_validator.errors:
                if error not in self.errors:
                    self.add_error(error)
            self.numeric_validator.clear_errors()
            if not result:
                valid = False
        # Validate optional input: token
        if inputs.get("token"):
            token = inputs["token"]
            # Check for variable expansion (but allow GitHub Actions expressions)
            if "${" in token and not token.startswith("${{ ") and not token.endswith(" }}"):
                self.add_error("Token contains potentially dangerous variable expansion '${}'")
                valid = False
            else:
                result = self.token_validator.validate_github_token(token, required=False)
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
        """Get validation rules for this action."""
        rules_path = Path(__file__).parent / "rules.yml"
        return self.load_rules(rules_path)
