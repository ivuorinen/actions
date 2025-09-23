#!/usr/bin/env python3
"""Custom validator for php-laravel-phpunit action."""

from __future__ import annotations

from pathlib import Path
import sys

# Add validate-inputs directory to path to import validators
validate_inputs_path = Path(__file__).parent.parent / "validate-inputs"
sys.path.insert(0, str(validate_inputs_path))

from validators.base import BaseValidator  # noqa: E402
from validators.version import VersionValidator  # noqa: E402


class CustomValidator(BaseValidator):
    """Custom validator for php-laravel-phpunit action."""

    def __init__(self, action_type: str = "php-laravel-phpunit") -> None:
        """Initialize php-laravel-phpunit validator."""
        super().__init__(action_type)
        self.version_validator = VersionValidator()

    def validate_inputs(self, inputs: dict[str, str]) -> bool:
        """Validate php-laravel-phpunit action inputs."""
        valid = True

        # Validate php-version if provided
        if "php-version" in inputs:
            value = inputs["php-version"]

            # Empty string should fail validation
            if value == "":
                self.add_error("PHP version cannot be empty")
                valid = False
            elif value:
                result = self.version_validator.validate_php_version(value, "php-version")

                # Propagate errors from the version validator
                for error in self.version_validator.errors:
                    if error not in self.errors:
                        self.add_error(error)

                self.version_validator.clear_errors()

                if not result:
                    valid = False

        return valid

    def get_required_inputs(self) -> list[str]:
        """Get list of required inputs."""
        return []

    def get_validation_rules(self) -> dict:
        """Get validation rules."""
        return {
            "php-version": {
                "type": "php_version",
                "required": False,
                "description": "PHP version to use",
            },
            "working-directory": {
                "type": "directory",
                "required": False,
                "description": "Working directory",
            },
        }
