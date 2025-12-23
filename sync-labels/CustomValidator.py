#!/usr/bin/env python3
"""Custom validator for sync-labels action.

This demonstrates how actions can have their own custom validation logic
while still leveraging the modular validator system.
"""

from __future__ import annotations

from pathlib import Path
import sys

# Add validate-inputs directory to path to import validators
validate_inputs_path = Path(__file__).parent.parent / "validate-inputs"
sys.path.insert(0, str(validate_inputs_path))

from validators.base import BaseValidator
from validators.file import FileValidator
from validators.token import TokenValidator


class CustomValidator(BaseValidator):
    """Custom validator for sync-labels action.

    Validates:
    - labels: Must be a valid YAML file path
    - token: GitHub token for authentication
    """

    def __init__(self, action_type: str = "sync-labels") -> None:
        """Initialize the sync-labels validator.

        Args:
            action_type: The action type (default: sync-labels)
        """
        super().__init__(action_type)
        self.file_validator = FileValidator()
        self.token_validator = TokenValidator()

        # Don't share errors - let each validator manage its own

    def get_required_inputs(self) -> list[str]:
        """Get required inputs for sync-labels.

        Returns:
            List of required input names
        """
        return ["labels"]  # labels file is required

    def get_validation_rules(self) -> dict:
        """Get validation rules for sync-labels.

        Returns:
            Dictionary of validation rules
        """
        return {
            "labels": "Path to YAML file containing label definitions",
            "token": "GitHub token (optional, defaults to ${{ github.token }})",
        }

    def validate_inputs(self, inputs: dict[str, str]) -> bool:
        """Validate sync-labels inputs.

        Args:
            inputs: Dictionary of input names to values

        Returns:
            True if all inputs are valid, False otherwise
        """
        valid = True

        # First check required inputs
        valid &= self.validate_required_inputs(inputs)

        # Validate labels file if provided
        if "labels" in inputs:
            valid &= self.validate_labels_file(inputs["labels"])

        # Validate token if provided
        if "token" in inputs:
            valid &= self.validate_with(
                self.token_validator, "validate_github_token", inputs["token"], required=False
            )

        return valid

    def validate_labels_file(self, path: str) -> bool:
        """Validate the labels YAML file path.

        Args:
            path: Path to the labels file

        Returns:
            True if valid, False otherwise
        """
        if self.is_github_expression(path):
            return True

        result = self.validate_with(self.file_validator, "validate_file_path", path, "labels")
        if not result:
            return False

        if not (path.endswith(".yml") or path.endswith(".yaml")):
            self.add_error(f'Invalid labels file: "{path}". Must be a .yml or .yaml file')
            return False

        return True
