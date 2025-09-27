#!/usr/bin/env python3
"""Custom validator for version-file-parser action."""

from __future__ import annotations

from pathlib import Path
import sys

# Add validate-inputs directory to path to import validators
validate_inputs_path = Path(__file__).parent.parent / "validate-inputs"
sys.path.insert(0, str(validate_inputs_path))

from validators.base import BaseValidator


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
                    f"Invalid language: {inputs['language']}. "
                    f"Must be one of: {', '.join(valid_languages)}"
                )
                valid = False

        # Validate dockerfile-image for injection
        dockerfile_key = None
        if "dockerfile-image" in inputs:
            dockerfile_key = "dockerfile-image"
        elif "dockerfile_image" in inputs:
            dockerfile_key = "dockerfile_image"

        if dockerfile_key and inputs[dockerfile_key]:
            value = inputs[dockerfile_key]
            if ";" in value or "|" in value or "&" in value or "`" in value:
                self.add_error("dockerfile-image contains potentially dangerous characters")
                valid = False

        # Validate tool-versions-key for injection
        tool_key = None
        if "tool-versions-key" in inputs:
            tool_key = "tool-versions-key"
        elif "tool_versions_key" in inputs:
            tool_key = "tool_versions_key"

        if tool_key and inputs[tool_key]:
            value = inputs[tool_key]
            if "|" in value or ";" in value or "&" in value or "`" in value:
                self.add_error("tool-versions-key contains potentially dangerous characters")
                valid = False

        # Validate validation-regex for malicious patterns
        regex_key = None
        if "validation-regex" in inputs:
            regex_key = "validation-regex"
        elif "validation_regex" in inputs:
            regex_key = "validation_regex"

        if regex_key and inputs[regex_key]:
            value = inputs[regex_key]
            # Check for shell command injection in regex
            if ";" in value or "|" in value or "`" in value or "rm " in value:
                self.add_error("validation-regex contains potentially dangerous patterns")
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
