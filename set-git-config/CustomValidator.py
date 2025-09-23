#!/usr/bin/env python3
"""Custom validator for set-git-config action."""

from __future__ import annotations

from pathlib import Path
import sys

# Add validate-inputs directory to path to import validators
validate_inputs_path = Path(__file__).parent.parent / "validate-inputs"
sys.path.insert(0, str(validate_inputs_path))

from validators.base import BaseValidator  # noqa: E402
from validators.network import NetworkValidator  # noqa: E402
from validators.token import TokenValidator  # noqa: E402


class CustomValidator(BaseValidator):
    """Custom validator for set-git-config action."""

    def __init__(self, action_type: str = "set-git-config") -> None:
        """Initialize set-git-config validator."""
        super().__init__(action_type)
        self.network_validator = NetworkValidator()
        self.token_validator = TokenValidator()

    def validate_inputs(self, inputs: dict[str, str]) -> bool:
        """Validate set-git-config action inputs."""
        valid = True
        # No required inputs
        # Validate optional input: email
        if inputs.get("email"):
            result = self.network_validator.validate_email(inputs["email"], "email")
            for error in self.network_validator.errors:
                if error not in self.errors:
                    self.add_error(error)
            self.network_validator.clear_errors()
            if not result:
                valid = False
        # Validate optional input: token
        if inputs.get("token"):
            result = self.token_validator.validate_github_token(inputs["token"], required=False)
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
        return self.load_rules("set-git-config")
