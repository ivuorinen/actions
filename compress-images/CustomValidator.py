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
            valid &= self.validate_with(
                self.numeric_validator,
                "validate_numeric_range",
                inputs["image-quality"],
                min_val=0,
                max_val=100,
            )

        if inputs.get("png-quality"):
            valid &= self.validate_with(
                self.numeric_validator,
                "validate_numeric_range",
                inputs["png-quality"],
                min_val=0,
                max_val=100,
            )

        # The action.yml input is named `working-directory`. Accept both forms
        # so the CV can be called consistently from tests using either name.
        working_dir_key = self.get_key_variant(inputs, "working-directory", "directory")
        if working_dir_key and inputs.get(working_dir_key):
            valid &= self.validate_with(
                self.file_validator,
                "validate_file_path",
                inputs[working_dir_key],
                working_dir_key,
            )

        if inputs.get("ignore-paths"):
            valid &= self.validate_with(
                self.security_validator,
                "validate_no_injection",
                inputs["ignore-paths"],
                "ignore-paths",
            )

        return valid

    def get_required_inputs(self) -> list[str]:
        """Get list of required inputs."""
        return []

    def get_validation_rules(self) -> dict:
        """Get validation rules."""
        return {
            "working-directory": {
                "type": "directory",
                "required": False,
                "description": "Directory containing images to compress",
            },
            "image-quality": {
                "type": "numeric",
                "required": False,
                "description": "JPEG compression quality (0-100)",
            },
            "png-quality": {
                "type": "numeric",
                "required": False,
                "description": "PNG compression quality (0-100)",
            },
            "ignore-paths": {
                "type": "string",
                "required": False,
                "description": "Paths to ignore (glob patterns)",
            },
        }
