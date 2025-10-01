#!/usr/bin/env python3
"""Custom validator for version-validator action."""

from __future__ import annotations

from pathlib import Path
import sys

# Add validate-inputs directory to path to import validators
validate_inputs_path = Path(__file__).parent.parent / "validate-inputs"
sys.path.insert(0, str(validate_inputs_path))

from validators.base import BaseValidator
from validators.security import SecurityValidator
from validators.version import VersionValidator


class CustomValidator(BaseValidator):
    """Custom validator for version-validator action."""

    def __init__(self, action_type: str = "version-validator") -> None:
        """Initialize version-validator validator."""
        super().__init__(action_type)
        self.version_validator = VersionValidator()
        self.security_validator = SecurityValidator()

    def validate_inputs(self, inputs: dict[str, str]) -> bool:
        """Validate version-validator action inputs."""
        valid = True
        # Validate required input: version
        if "version" not in inputs or not inputs["version"]:
            self.add_error("Input 'version' is required")
            valid = False
        elif inputs["version"]:
            result = self.version_validator.validate_flexible_version(inputs["version"], "version")
            for error in self.version_validator.errors:
                if error not in self.errors:
                    self.add_error(error)
            self.version_validator.clear_errors()
            if not result:
                valid = False

        # Validate optional input: validation-regex
        # Check both underscore and dash versions
        regex_value = inputs.get("validation-regex") or inputs.get("validation_regex")
        if regex_value:
            result = self.security_validator.validate_regex_pattern(regex_value, "validation-regex")
            for error in self.security_validator.errors:
                if error not in self.errors:
                    self.add_error(error)
            self.security_validator.clear_errors()
            if not result:
                valid = False

        # Validate optional input: language (accept any value)
        if "language" in inputs and inputs.get("language"):
            # Basic check that it's not malicious
            lang_value = inputs["language"]
            if ";" in lang_value or "$(" in lang_value or "`" in lang_value:
                self.add_error("language contains potentially dangerous characters")
                valid = False

        return valid

    def get_required_inputs(self) -> list[str]:
        """Get list of required inputs."""
        return ["version"]

    def get_validation_rules(self) -> dict:
        """Get validation rules."""
        rules_path = Path(__file__).parent / "rules.yml"
        return self.load_rules(rules_path)
