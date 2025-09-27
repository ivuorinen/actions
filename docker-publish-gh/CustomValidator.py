#!/usr/bin/env python3
"""Custom validator for docker-publish-gh action."""

from __future__ import annotations

from pathlib import Path
import sys

# Add validate-inputs directory to path to import validators
validate_inputs_path = Path(__file__).parent.parent / "validate-inputs"
sys.path.insert(0, str(validate_inputs_path))

from validators.base import BaseValidator
from validators.docker import DockerValidator
from validators.token import TokenValidator


class CustomValidator(BaseValidator):
    """Custom validator for docker-publish-gh action."""

    def __init__(self, action_type: str = "docker-publish-gh") -> None:
        """Initialize docker-publish-gh validator."""
        super().__init__(action_type)
        self.docker_validator = DockerValidator()
        self.token_validator = TokenValidator()

    def validate_inputs(self, inputs: dict[str, str]) -> bool:
        """Validate docker-publish-gh action inputs."""
        valid = True

        # Validate required input: image-name
        if "image-name" not in inputs or not inputs["image-name"]:
            self.add_error("Input 'image-name' is required")
            valid = False
        elif inputs["image-name"]:
            result = self.docker_validator.validate_image_name(inputs["image-name"], "image-name")
            for error in self.docker_validator.errors:
                if error not in self.errors:
                    self.add_error(error)
            self.docker_validator.clear_errors()
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

        return valid

    def get_required_inputs(self) -> list[str]:
        """Get list of required inputs."""
        return ["image-name"]

    def get_validation_rules(self) -> dict:
        """Get validation rules."""
        return {
            "image-name": {
                "type": "string",
                "required": True,
                "description": "Docker image name",
            },
            "registry": {
                "type": "string",
                "required": False,
                "description": "Docker registry",
            },
            "username": {
                "type": "string",
                "required": False,
                "description": "Registry username",
            },
            "password": {
                "type": "token",
                "required": False,
                "description": "Registry password",
            },
        }
