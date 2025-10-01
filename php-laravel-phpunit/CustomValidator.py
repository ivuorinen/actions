#!/usr/bin/env python3
"""Custom validator for php-laravel-phpunit action."""

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
    """Custom validator for php-laravel-phpunit action."""

    def __init__(self, action_type: str = "php-laravel-phpunit") -> None:
        """Initialize php-laravel-phpunit validator."""
        super().__init__(action_type)
        self.version_validator = VersionValidator()
        self.file_validator = FileValidator()
        self.token_validator = TokenValidator()

    def validate_inputs(self, inputs: dict[str, str]) -> bool:
        """Validate php-laravel-phpunit action inputs."""
        valid = True

        # Validate php-version if provided and not empty
        if inputs.get("php-version"):
            value = inputs["php-version"]
            # Special case: "latest" is allowed
            if value != "latest":
                result = self.version_validator.validate_php_version(value, "php-version")

                # Propagate errors from the version validator
                for error in self.version_validator.errors:
                    if error not in self.errors:
                        self.add_error(error)

                self.version_validator.clear_errors()

                if not result:
                    valid = False
        # Validate php-version-file if provided
        if inputs.get("php-version-file"):
            result = self.file_validator.validate_file_path(
                inputs["php-version-file"], "php-version-file"
            )
            for error in self.file_validator.errors:
                if error not in self.errors:
                    self.add_error(error)
            self.file_validator.clear_errors()
            if not result:
                valid = False

        # Validate extensions if provided
        if inputs.get("extensions"):
            value = inputs["extensions"]
            # Basic validation for PHP extensions list
            if ";" in value and not value.startswith("${{"):
                self.add_error(f"Invalid extensions format in extensions: {value}")
                valid = False
            # Check for dangerous characters and invalid format (@ is not valid in PHP extensions)
            if any(char in value for char in ["`", "$", "&", "|", ">", "<", "@", "\n", "\r"]):
                self.add_error(f"Invalid characters in extensions: {value}")
                valid = False

        # Validate coverage if provided
        if inputs.get("coverage"):
            value = inputs["coverage"]
            # Valid coverage drivers for PHPUnit
            valid_coverage = ["none", "xdebug", "xdebug3", "pcov"]
            if value not in valid_coverage:
                # Check for command injection attempts
                if any(char in value for char in [";", "`", "$", "&", "|", ">", "<", "\n", "\r"]):
                    self.add_error(f"Command injection attempt in coverage: {value}")
                    valid = False
                elif value and not value.startswith("${{"):
                    self.add_error(
                        f"Invalid coverage driver: {value}. "
                        f"Must be one of: {', '.join(valid_coverage)}"
                    )
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
            "php-version-file": {
                "type": "file",
                "required": False,
                "description": "PHP version file",
            },
            "extensions": {
                "type": "string",
                "required": False,
                "description": "PHP extensions to install",
            },
            "coverage": {
                "type": "string",
                "required": False,
                "description": "Coverage driver",
            },
            "token": {
                "type": "token",
                "required": False,
                "description": "GitHub token",
            },
        }
