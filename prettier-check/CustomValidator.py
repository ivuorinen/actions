#!/usr/bin/env python3
"""Custom validator for prettier-check action."""

from __future__ import annotations

from pathlib import Path
import re
import sys

# Add validate-inputs directory to path to import validators
validate_inputs_path = Path(__file__).parent.parent / "validate-inputs"
sys.path.insert(0, str(validate_inputs_path))

from validators.base import BaseValidator
from validators.conventions import ConventionBasedValidator
from validators.security import SecurityValidator
from validators.version import VersionValidator


class CustomValidator(BaseValidator):
    """Custom validator for prettier-check action."""

    def __init__(self, action_type: str = "prettier-check") -> None:
        """Initialize prettier-check validator."""
        super().__init__(action_type)
        self.convention_validator = ConventionBasedValidator(action_type)
        self.security_validator = SecurityValidator()
        self.version_validator = VersionValidator()

    def validate_inputs(self, inputs: dict[str, str]) -> bool:
        """Validate prettier-check action inputs."""
        valid = True

        # Use convention-based validation for most inputs
        rules_path = Path(__file__).parent / "rules.yml"
        self.convention_validator.rules = self.convention_validator.load_rules(rules_path)

        # Handle prettier-version specially (accepts "latest" or semantic version)
        # Check both hyphenated and underscored versions since inputs can come either way
        inputs_copy = inputs.copy()
        prettier_version_key = None
        if "prettier-version" in inputs:
            prettier_version_key = "prettier-version"
        elif "prettier_version" in inputs:
            prettier_version_key = "prettier_version"

        if prettier_version_key:
            value = inputs[prettier_version_key]
            if value and value != "latest":
                # Prettier versions should not have 'v' prefix (npm package versions)
                if value.startswith("v"):
                    self.add_error(
                        f"{prettier_version_key}: Prettier version should not have 'v' prefix"
                    )
                    valid = False
                else:
                    # Must be a semantic version
                    result = self.version_validator.validate_semantic_version(
                        value, prettier_version_key
                    )
                    for error in self.version_validator.errors:
                        if error not in self.errors:
                            self.add_error(error)
                    self.version_validator.clear_errors()
                    if not result:
                        valid = False
            # Remove both versions from inputs for convention validation
            if "prettier-version" in inputs_copy:
                del inputs_copy["prettier-version"]
            if "prettier_version" in inputs_copy:
                del inputs_copy["prettier_version"]

        # Validate plugins for security issues
        if inputs_copy.get("plugins"):
            # Check for command injection patterns
            dangerous_patterns = [
                r"[;&|`$()]",  # Shell operators
                r"\$\{.*\}",  # Variable expansion
                r"\$\(.*\)",  # Command substitution
            ]

            for pattern in dangerous_patterns:
                if re.search(pattern, inputs_copy["plugins"]):
                    self.add_error("plugins: Contains potentially dangerous characters or patterns")
                    valid = False
                    break

            # Remove plugins from inputs for convention validation
            if "plugins" in inputs_copy:
                del inputs_copy["plugins"]

        # Validate file-pattern for security issues
        if inputs_copy.get("file-pattern"):
            # Check for path traversal and shell expansion
            if ".." in inputs_copy["file-pattern"]:
                self.add_error("file-pattern: Path traversal detected")
                valid = False
            elif inputs_copy["file-pattern"].startswith("/"):
                self.add_error("file-pattern: Absolute path not allowed")
                valid = False
            elif "$" in inputs_copy["file-pattern"]:
                self.add_error("file-pattern: Shell expansion not allowed")
                valid = False

            # Remove file-pattern from inputs for convention validation
            if "file-pattern" in inputs_copy:
                del inputs_copy["file-pattern"]

        # Validate report-format enum
        if "report-format" in inputs_copy:
            value = inputs_copy["report-format"]
            if value == "":
                self.add_error("report-format: Cannot be empty. Must be 'json' or 'sarif'")
                valid = False
            elif value not in ["json", "sarif"]:
                self.add_error("report-format: Invalid format. Must be 'json' or 'sarif'")
                valid = False
            # Remove report-format from inputs for convention validation
            if "report-format" in inputs_copy:
                del inputs_copy["report-format"]

        # Use convention-based validation for remaining inputs
        if not self.convention_validator.validate_inputs(inputs_copy):
            for error in self.convention_validator.errors:
                if error not in self.errors:
                    self.add_error(error)
            valid = False

        return valid

    def get_required_inputs(self) -> list[str]:
        """Get list of required inputs."""
        return []

    def get_validation_rules(self) -> dict:
        """Get validation rules."""
        rules_path = Path(__file__).parent / "rules.yml"
        return self.load_rules(rules_path)
