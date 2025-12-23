#!/usr/bin/env python3
"""Custom validator for terraform-lint-fix action."""

from __future__ import annotations

from pathlib import Path
import sys

# Add validate-inputs directory to path to import validators
validate_inputs_path = Path(__file__).parent.parent / "validate-inputs"
sys.path.insert(0, str(validate_inputs_path))

from validators.base import BaseValidator
from validators.file import FileValidator
from validators.token import TokenValidator
from validators.version import VersionValidator


class CustomValidator(BaseValidator):
    """Custom validator for terraform-lint-fix action."""

    def __init__(self, action_type: str = "terraform-lint-fix") -> None:
        """Initialize terraform-lint-fix validator."""
        super().__init__(action_type)
        self.version_validator = VersionValidator()
        self.token_validator = TokenValidator()
        self.file_validator = FileValidator()

    def validate_inputs(self, inputs: dict[str, str]) -> bool:
        """Validate terraform-lint-fix action inputs."""
        valid = True

        # Validate terraform-version if provided (empty is OK - uses default)
        if inputs.get("terraform-version"):
            valid &= self.validate_with(
                self.version_validator,
                "validate_terraform_version",
                inputs["terraform-version"],
                "terraform-version",
            )

        # Validate token if provided (empty is OK - uses default)
        if inputs.get("token"):
            valid &= self.validate_with(
                self.token_validator,
                "validate_github_token",
                inputs["token"],
                required=False,
            )

        # Validate working-directory if provided
        if inputs.get("working-directory"):
            valid &= self.validate_with(
                self.file_validator,
                "validate_file_path",
                inputs["working-directory"],
                "working-directory",
            )

        return valid

    def get_required_inputs(self) -> list[str]:
        """Get list of required inputs."""
        return []

    def get_validation_rules(self) -> dict:
        """Get validation rules."""
        rules_path = Path(__file__).parent / "rules.yml"
        return self.load_rules(rules_path)
