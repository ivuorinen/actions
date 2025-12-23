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
            valid &= self.validate_with(
                self.file_validator,
                "validate_file_path",
                inputs["pre-commit-config"],
                "pre-commit-config",
            )

        # Validate base-branch if provided (just check for injection)
        if inputs.get("base-branch"):
            valid &= self.validate_with(
                self.security_validator,
                "validate_no_injection",
                inputs["base-branch"],
                "base-branch",
            )

        # Validate token if provided
        if inputs.get("token"):
            valid &= self.validate_with(
                self.token_validator, "validate_github_token", inputs["token"]
            )

        # Validate commit_user if provided (allow spaces for Git usernames)
        commit_user_key = self.get_key_variant(inputs, "commit_user", "commit-user")
        if commit_user_key and inputs[commit_user_key]:
            value = inputs[commit_user_key]
            if any(c in value for c in [";", "&", "|", "`", "$", "(", ")", "\n", "\r"]):
                self.add_error(f"{commit_user_key}: Contains potentially dangerous characters")
                valid = False

        # Validate commit_email if provided
        commit_email_key = self.get_key_variant(inputs, "commit_email", "commit-email")
        if commit_email_key and inputs[commit_email_key]:
            valid &= self.validate_with(
                self.network_validator,
                "validate_email",
                inputs[commit_email_key],
                commit_email_key,
            )

        return valid

    def get_required_inputs(self) -> list[str]:
        """Get list of required inputs."""
        return []

    def get_validation_rules(self) -> dict:
        """Get validation rules."""
        rules_path = Path(__file__).parent / "rules.yml"
        return self.load_rules(rules_path)
