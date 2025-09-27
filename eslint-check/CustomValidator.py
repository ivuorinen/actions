#!/usr/bin/env python3
"""Custom validator for eslint-check action."""

from __future__ import annotations

from pathlib import Path
import re
import sys

# Add validate-inputs directory to path to import validators
validate_inputs_path = Path(__file__).parent.parent / "validate-inputs"
sys.path.insert(0, str(validate_inputs_path))

from validators.base import BaseValidator
from validators.boolean import BooleanValidator
from validators.file import FileValidator
from validators.numeric import NumericValidator
from validators.version import VersionValidator


class CustomValidator(BaseValidator):
    """Custom validator for eslint-check action."""

    def __init__(self, action_type: str = "eslint-check") -> None:
        """Initialize eslint-check validator."""
        super().__init__(action_type)
        self.file_validator = FileValidator()
        self.version_validator = VersionValidator()
        self.boolean_validator = BooleanValidator()
        self.numeric_validator = NumericValidator()

    def validate_inputs(self, inputs: dict[str, str]) -> bool:
        """Validate eslint-check action inputs."""
        valid = True

        # Validate working-directory if provided
        if inputs.get("working-directory"):
            result = self.file_validator.validate_file_path(
                inputs["working-directory"], "working-directory"
            )
            for error in self.file_validator.errors:
                if error not in self.errors:
                    self.add_error(error)
            self.file_validator.clear_errors()
            if not result:
                valid = False

        # Validate eslint-version if provided
        if "eslint-version" in inputs:
            value = inputs["eslint-version"]
            # Check for empty version - reject it
            if value == "":
                self.add_error("ESLint version cannot be empty")
                valid = False
            # Allow "latest" as a special case
            elif value == "latest":
                pass  # Valid
            # Validate as semantic version (eslint uses strict semantic versioning)
            elif value and not value.startswith("${{"):
                # ESLint requires full semantic version (X.Y.Z), not partial versions
                if not re.match(r"^\d+\.\d+\.\d+", value):
                    self.add_error(
                        f"ESLint version must be a complete semantic version (X.Y.Z), got: {value}"
                    )
                    valid = False
                else:
                    result = self.version_validator.validate_semantic_version(
                        value, "eslint-version"
                    )
                    for error in self.version_validator.errors:
                        if error not in self.errors:
                            self.add_error(error)
                    self.version_validator.clear_errors()
                    if not result:
                        valid = False

        # Validate config-file if provided
        if inputs.get("config-file"):
            result = self.file_validator.validate_file_path(inputs["config-file"], "config-file")
            for error in self.file_validator.errors:
                if error not in self.errors:
                    self.add_error(error)
            self.file_validator.clear_errors()
            if not result:
                valid = False

        # Validate ignore-file if provided
        if inputs.get("ignore-file"):
            result = self.file_validator.validate_file_path(inputs["ignore-file"], "ignore-file")
            for error in self.file_validator.errors:
                if error not in self.errors:
                    self.add_error(error)
            self.file_validator.clear_errors()
            if not result:
                valid = False

        # Validate ignore-file if provided
        if inputs.get("ignore-file"):
            result = self.file_validator.validate_file_path(inputs["ignore-file"], "ignore-file")
            for error in self.file_validator.errors:
                if error not in self.errors:
                    self.add_error(error)
            self.file_validator.clear_errors()
            if not result:
                valid = False

        # Validate file-extensions if provided
        if inputs.get("file-extensions"):
            value = inputs["file-extensions"]
            # Check for valid extension format
            extensions = value.split(",") if "," in value else value.split()
            for ext in extensions:
                ext = ext.strip()
                if ext and not ext.startswith("${{"):
                    # Extensions should start with a dot
                    if not ext.startswith("."):
                        self.add_error(f"Extension '{ext}' should start with a dot")
                        valid = False
                    # Check for invalid characters
                    elif not re.match(r"^\.[a-zA-Z0-9]+$", ext):
                        self.add_error(f"Invalid extension format: {ext}")
                        valid = False

        # Validate cache boolean
        if inputs.get("cache"):
            result = self.boolean_validator.validate_boolean(inputs["cache"], "cache")
            for error in self.boolean_validator.errors:
                if error not in self.errors:
                    self.add_error(error)
            self.boolean_validator.clear_errors()
            if not result:
                valid = False

        # Validate max-warnings numeric
        if inputs.get("max-warnings"):
            value = inputs["max-warnings"]
            if value and not value.startswith("${{"):
                try:
                    num_value = int(value)
                    if num_value < 0:
                        self.add_error(f"max-warnings cannot be negative: {value}")
                        valid = False
                except ValueError:
                    self.add_error(f"max-warnings must be a number: {value}")
                    valid = False

        # Validate fail-on-error boolean
        if inputs.get("fail-on-error"):
            result = self.boolean_validator.validate_boolean(
                inputs["fail-on-error"], "fail-on-error"
            )
            for error in self.boolean_validator.errors:
                if error not in self.errors:
                    self.add_error(error)
            self.boolean_validator.clear_errors()
            if not result:
                valid = False

        # Validate report-format
        if "report-format" in inputs:
            value = inputs["report-format"]
            valid_formats = [
                "stylish",
                "compact",
                "json",
                "junit",
                "html",
                "table",
                "tap",
                "unix",
                "sarif",
                "checkstyle",
            ]
            if value == "":
                self.add_error("Report format cannot be empty")
                valid = False
            elif value and not value.startswith("${{"):
                if value not in valid_formats:
                    self.add_error(
                        f"Invalid report format: {value}. "
                        f"Must be one of: {', '.join(valid_formats)}"
                    )
                    valid = False

        # Validate max-retries
        if inputs.get("max-retries"):
            value = inputs["max-retries"]
            if value and not value.startswith("${{"):
                result = self.numeric_validator.validate_numeric_range_1_10(value, "max-retries")
                for error in self.numeric_validator.errors:
                    if error not in self.errors:
                        self.add_error(error)
                self.numeric_validator.clear_errors()
                if not result:
                    valid = False

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
                "description": "Working directory",
            },
            "eslint-version": {
                "type": "flexible_version",
                "required": False,
                "description": "ESLint version",
            },
            "config-file": {
                "type": "file",
                "required": False,
                "description": "ESLint config file",
            },
            "ignore-file": {
                "type": "file",
                "required": False,
                "description": "ESLint ignore file",
            },
            "file-extensions": {
                "type": "string",
                "required": False,
                "description": "File extensions to check",
            },
            "cache": {
                "type": "boolean",
                "required": False,
                "description": "Enable caching",
            },
            "max-warnings": {
                "type": "numeric",
                "required": False,
                "description": "Maximum warnings allowed",
            },
            "fail-on-error": {
                "type": "boolean",
                "required": False,
                "description": "Fail on error",
            },
            "report-format": {
                "type": "string",
                "required": False,
                "description": "Report format",
            },
            "max-retries": {
                "type": "numeric",
                "required": False,
                "description": "Maximum retry count",
            },
        }
