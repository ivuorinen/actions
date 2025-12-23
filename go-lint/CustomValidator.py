#!/usr/bin/env python3
"""Custom validator for go-lint action."""

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
from validators.security import SecurityValidator
from validators.version import VersionValidator


class CustomValidator(BaseValidator):
    """Custom validator for go-lint action."""

    def __init__(self, action_type: str = "go-lint") -> None:
        """Initialize go-lint validator."""
        super().__init__(action_type)
        self.file_validator = FileValidator()
        self.version_validator = VersionValidator()
        self.boolean_validator = BooleanValidator()
        self.numeric_validator = NumericValidator()
        self.security_validator = SecurityValidator()

    def validate_inputs(self, inputs: dict[str, str]) -> bool:
        """Validate go-lint action inputs."""
        valid = True

        # Validate working-directory if provided
        if inputs.get("working-directory"):
            valid &= self.validate_with(
                self.file_validator,
                "validate_file_path",
                inputs["working-directory"],
                "working-directory",
            )

        # Validate golangci-lint-version if provided
        if inputs.get("golangci-lint-version"):
            value = inputs["golangci-lint-version"]
            if value != "latest" and not self.is_github_expression(value):
                valid &= self.validate_with(
                    self.version_validator,
                    "validate_semantic_version",
                    value,
                    "golangci-lint-version",
                )

        # Validate go-version if provided
        if inputs.get("go-version"):
            value = inputs["go-version"]
            if value not in ["stable", "oldstable"] and not self.is_github_expression(value):
                valid &= self.validate_with(
                    self.version_validator, "validate_go_version", value, "go-version"
                )

        # Validate config-file if provided
        if inputs.get("config-file"):
            valid &= self.validate_with(
                self.file_validator, "validate_file_path", inputs["config-file"], "config-file"
            )

        # Validate timeout if provided
        if inputs.get("timeout"):
            value = inputs["timeout"]
            if not self.is_github_expression(value) and not re.match(r"^\d+[smh]$", value):
                self.add_error(
                    f"Invalid timeout format: {value}. Expected format like '5m', '1h', '30s'"
                )
                valid = False

        # Validate boolean inputs
        for field in ["cache", "fail-on-error", "only-new-issues", "disable-all"]:
            if inputs.get(field):
                valid &= self.validate_with(
                    self.boolean_validator, "validate_boolean", inputs[field], field
                )

        # Validate report-format
        if inputs.get("report-format"):
            valid &= self.validate_enum(
                inputs["report-format"],
                "report-format",
                ["json", "sarif", "github-actions", "colored-line-number", "tab"],
                case_sensitive=True,
            )

        # Validate max-retries
        if inputs.get("max-retries"):
            valid &= self.validate_with(
                self.numeric_validator,
                "validate_numeric_range",
                inputs["max-retries"],
                min_val=1,
                max_val=10,
                name="max-retries",
            )

        # Validate enable-linters and disable-linters
        for field in ["enable-linters", "disable-linters"]:
            if inputs.get(field):
                value = inputs[field]
                if not self.is_github_expression(value):
                    if " " in value:
                        self.add_error(f"Invalid {field} format: spaces not allowed in linter list")
                        valid = False
                    elif not re.match(r"^[a-z0-9_-]+(,[a-z0-9_-]+)*$", value, re.IGNORECASE):
                        self.add_error(
                            f"Invalid {field} format: must be comma-separated list of linters"
                        )
                        valid = False
                valid &= self.validate_with(
                    self.security_validator, "validate_no_injection", value, field
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
                "description": "Working directory",
            },
            "golangci-lint-version": {
                "type": "string",
                "required": False,
                "description": "golangci-lint version",
            },
            "go-version": {
                "type": "string",
                "required": False,
                "description": "Go version",
            },
            "config-file": {
                "type": "file",
                "required": False,
                "description": "Config file path",
            },
            "timeout": {
                "type": "string",
                "required": False,
                "description": "Timeout duration",
            },
            "cache": {
                "type": "boolean",
                "required": False,
                "description": "Enable caching",
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
                "description": "Maximum retries",
            },
            "only-new-issues": {
                "type": "boolean",
                "required": False,
                "description": "Report only new issues",
            },
            "enable-linters": {
                "type": "string",
                "required": False,
                "description": "Linters to enable",
            },
            "disable-linters": {
                "type": "string",
                "required": False,
                "description": "Linters to disable",
            },
        }
