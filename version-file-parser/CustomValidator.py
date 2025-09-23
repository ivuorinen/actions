#!/usr/bin/env python3
"""Custom validator for version-file-parser action."""

from __future__ import annotations

from pathlib import Path
import sys

# Add validate-inputs directory to path to import validators
validate_inputs_path = Path(__file__).parent.parent / "validate-inputs"
sys.path.insert(0, str(validate_inputs_path))

from validators.base import BaseValidator  # noqa: E402


class CustomValidator(BaseValidator):
    """Custom validator for version-file-parser action."""

    def __init__(self, action_type: str = "version-file-parser") -> None:
        """Initialize version-file-parser validator."""
        super().__init__(action_type)

    def validate_inputs(self, inputs: dict[str, str]) -> bool:
        """Validate version-file-parser action inputs."""
        valid = True

        # Validate required input: language
        if "language" not in inputs or not inputs["language"]:
            self.add_error("Input 'language' is required")
            valid = False
        elif inputs["language"]:
            # Validate language is one of the supported values
            valid_languages = [
                "node",
                "python",
                "go",
                "rust",
                "ruby",
                "php",
                "java",
                "dotnet",
                "elixir",
            ]
            if inputs["language"] not in valid_languages:
                self.add_error(
                    f"Invalid language: {inputs['language']}. Must be one of: {', '.join(valid_languages)}"
                )
                valid = False

        return valid

    def get_required_inputs(self) -> list[str]:
        """Get list of required inputs."""
        return ["language"]

    def get_validation_rules(self) -> dict:
        """Get validation rules."""
        return {
            "language": {
                "type": "string",
                "required": True,
                "description": "Language identifier",
            },
            "tool-versions-key": {
                "type": "string",
                "required": False,
                "description": "Key in .tool-versions",
            },
            "dockerfile-image": {
                "type": "string",
                "required": False,
                "description": "Dockerfile image name",
            },
        }
