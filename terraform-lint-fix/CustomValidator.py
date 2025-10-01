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

        # Validate terraform-version if provided
        if "terraform-version" in inputs:
            value = inputs["terraform-version"]

            # Empty string is OK - uses default
            if value == "":
                pass  # Allow empty, will use default
            elif value:
                result = self.version_validator.validate_terraform_version(
                    value, "terraform-version"
                )

                # Propagate errors from the version validator
                for error in self.version_validator.errors:
                    if error not in self.errors:
                        self.add_error(error)

                self.version_validator.clear_errors()

                if not result:
                    valid = False

        # Validate token if provided
        if "token" in inputs:
            value = inputs["token"]
            if value == "":
                # Empty token is OK - uses default
                pass
            elif value:
                result = self.token_validator.validate_github_token(value, required=False)
                for error in self.token_validator.errors:
                    if error not in self.errors:
                        self.add_error(error)
                self.token_validator.clear_errors()
                if not result:
                    valid = False

        # Validate working-directory if provided
        if "working-directory" in inputs:
            value = inputs["working-directory"]
            if value:
                result = self.file_validator.validate_file_path(value, "working-directory")
                for error in self.file_validator.errors:
                    if error not in self.errors:
                        self.add_error(error)
                self.file_validator.clear_errors()
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
