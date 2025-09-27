#!/usr/bin/env python3
"""Custom validator for pre-commit action."""

from __future__ import annotations

from pathlib import Path
import sys

# Add validate-inputs directory to path to import validators
validate_inputs_path = Path(__file__).parent.parent / "validate-inputs"
sys.path.insert(0, str(validate_inputs_path))

from validators.base import BaseValidator
from validators.file import FileValidator
from validators.network import NetworkValidator
from validators.security import SecurityValidator
from validators.token import TokenValidator


class CustomValidator(BaseValidator):
    """Custom validator for pre-commit action."""

    def __init__(self, action_type: str = "pre-commit") -> None:
        """Initialize pre-commit validator."""
        super().__init__(action_type)
        self.file_validator = FileValidator()
        self.token_validator = TokenValidator()
        self.network_validator = NetworkValidator()
        self.security_validator = SecurityValidator()

    def validate_inputs(self, inputs: dict[str, str]) -> bool:
        """Validate pre-commit action inputs."""
        valid = True

        # Validate pre-commit-config if provided
        if "pre-commit-config" in inputs:
            result = self.file_validator.validate_file_path(
                inputs["pre-commit-config"], "pre-commit-config"
            )
            for error in self.file_validator.errors:
                if error not in self.errors:
                    self.add_error(error)
            self.file_validator.clear_errors()
            if not result:
                valid = False

        # Validate base-branch if provided (just check for injection)
        if inputs.get("base-branch"):
            # Check for dangerous characters that could cause shell injection
            result = self.security_validator.validate_no_injection(
                inputs["base-branch"], "base-branch"
            )
            for error in self.security_validator.errors:
                if error not in self.errors:
                    self.add_error(error)
            self.security_validator.clear_errors()
            if not result:
                valid = False

        # Validate token if provided
        if inputs.get("token"):
            result = self.token_validator.validate_github_token(inputs["token"])
            for error in self.token_validator.errors:
                if error not in self.errors:
                    self.add_error(error)
            self.token_validator.clear_errors()
            if not result:
                valid = False

        # Validate commit_user if provided (allow spaces for Git usernames)
        # Check both underscore and hyphen versions since inputs can have either
        commit_user_key = (
            "commit_user"
            if "commit_user" in inputs
            else "commit-user"
            if "commit-user" in inputs
            else None
        )
        if commit_user_key and inputs[commit_user_key]:
            # Check for dangerous injection patterns
            value = inputs[commit_user_key]
            if any(char in value for char in [";", "&", "|", "`", "$", "(", ")", "\n", "\r"]):
                self.add_error(f"{commit_user_key}: Contains potentially dangerous characters")
                valid = False

        # Validate commit_email if provided
        # Check both underscore and hyphen versions
        commit_email_key = (
            "commit_email"
            if "commit_email" in inputs
            else "commit-email"
            if "commit-email" in inputs
            else None
        )
        if commit_email_key and inputs[commit_email_key]:
            result = self.network_validator.validate_email(
                inputs[commit_email_key], commit_email_key
            )
            for error in self.network_validator.errors:
                if error not in self.errors:
                    self.add_error(error)
            self.network_validator.clear_errors()
            if not result:
                valid = False

        return valid

    def get_required_inputs(self) -> list[str]:
        """Get list of required inputs."""
        return []

    def get_validation_rules(self) -> dict:
        """Get validation rules."""
        rules_path = Path(__file__).parent / "rules.yml"
        return self.load_rules(rules_path)
