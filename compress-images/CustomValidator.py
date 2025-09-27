#!/usr/bin/env python3
"""Custom validator for compress-images action."""

from __future__ import annotations

from pathlib import Path
import sys

# Add validate-inputs directory to path to import validators
validate_inputs_path = Path(__file__).parent.parent / "validate-inputs"
sys.path.insert(0, str(validate_inputs_path))

from validators.base import BaseValidator
from validators.file import FileValidator
from validators.network import NetworkValidator
from validators.numeric import NumericValidator
from validators.security import SecurityValidator
from validators.token import TokenValidator


class CustomValidator(BaseValidator):
    """Custom validator for compress-images action."""

    def __init__(self, action_type: str = "compress-images") -> None:
        """Initialize compress-images validator."""
        super().__init__(action_type)
        self.file_validator = FileValidator()
        self.network_validator = NetworkValidator()
        self.numeric_validator = NumericValidator()
        self.security_validator = SecurityValidator()
        self.token_validator = TokenValidator()

    def validate_inputs(self, inputs: dict[str, str]) -> bool:
        """Validate compress-images action inputs."""
        valid = True

        # Validate optional inputs
        if inputs.get("image-quality"):
            result = self.numeric_validator.validate_numeric_range(
                inputs["image-quality"], min_val=0, max_val=100
            )
            for error in self.numeric_validator.errors:
                if error not in self.errors:
                    self.add_error(error)
            self.numeric_validator.clear_errors()
            if not result:
                valid = False

        if inputs.get("png-quality"):
            result = self.numeric_validator.validate_numeric_range(
                inputs["png-quality"], min_val=0, max_val=100
            )
            for error in self.numeric_validator.errors:
                if error not in self.errors:
                    self.add_error(error)
            self.numeric_validator.clear_errors()
            if not result:
                valid = False

        if inputs.get("directory"):
            result = self.file_validator.validate_file_path(inputs["directory"], "directory")
            for error in self.file_validator.errors:
                if error not in self.errors:
                    self.add_error(error)
            self.file_validator.clear_errors()
            if not result:
                valid = False

        if inputs.get("ignore-paths"):
            # Validate for injection
            result = self.security_validator.validate_no_injection(
                inputs["ignore-paths"], "ignore-paths"
            )
            for error in self.security_validator.errors:
                if error not in self.errors:
                    self.add_error(error)
            self.security_validator.clear_errors()
            if not result:
                valid = False

        return valid

    def get_required_inputs(self) -> list[str]:
        """Get list of required inputs."""
        return []

    def get_validation_rules(self) -> dict:
        """Get validation rules."""
        return {
            "directory": {
                "type": "directory",
                "required": False,
                "description": "Directory containing images",
            },
            "image-quality": {
                "type": "numeric",
                "required": False,
                "description": "Image compression quality",
            },
            "png-quality": {
                "type": "numeric",
                "required": False,
                "description": "PNG compression quality",
            },
            "ignore-paths": {
                "type": "string",
                "required": False,
                "description": "Paths to ignore",
            },
        }
