#!/usr/bin/env python3
"""Custom validator for common-retry action."""

from __future__ import annotations

from pathlib import Path
import sys
from typing import Any

# Add validate-inputs directory to path to import validators
validate_inputs_path = Path(__file__).parent.parent / "validate-inputs"
sys.path.insert(0, str(validate_inputs_path))

from validators.base import BaseValidator  # noqa: E402
from validators.file import FileValidator  # noqa: E402
from validators.numeric import NumericValidator  # noqa: E402
from validators.security import SecurityValidator  # noqa: E402


class CustomValidator(BaseValidator):
    """Custom validator for common-retry action."""

    def __init__(self, action_type: str = "common-retry") -> None:
        """Initialize common-retry validator."""
        super().__init__(action_type)
        self.file_validator = FileValidator()
        self.numeric_validator = NumericValidator()
        self.security_validator = SecurityValidator()

    def validate_inputs(self, inputs: dict[str, str]) -> bool:
        """Validate common-retry action inputs."""
        valid = True
        # Validate required inputs
        if "command" not in inputs or not inputs["command"]:
            self.add_error("Input 'command' is required")
            valid = False
        elif inputs["command"]:
            # Validate command for security issues
            result = self.security_validator.validate_no_injection(inputs["command"])
            for error in self.security_validator.errors:
                if error not in self.errors:
                    self.add_error(error)
            self.security_validator.clear_errors()
            if not result:
                valid = False
        # Validate optional inputs
        return self._validate_optionals(inputs=inputs, prev_valid=valid)

    def _validate_optionals(self, inputs: dict[str, Any], *, prev_valid: bool) -> bool:  # noqa: PLR0912
        """Validate optional inputs for common-retry action.

        Args:
            inputs: Dictionary of input names and values
            prev_valid: Previous validity state
        Returns:
            True if all optional validations pass, False otherwise
        """
        valid = prev_valid
        # Backoff strategy - fixed is the correct value, not constant
        backoff_strategy = inputs.get("backoff-strategy")
        backoff_strategies = ["exponential", "linear", "fixed"]
        if backoff_strategy and backoff_strategy not in backoff_strategies:
            self.add_error(f"Invalid backoff strategy: {inputs['backoff-strategy']}")
            valid = False
        # Max retries
        max_retries = inputs.get("max-retries")
        if max_retries:
            result = self.numeric_validator.validate_numeric_range(
                max_retries, min_val=1, max_val=10
            )
            for error in self.numeric_validator.errors:
                if error not in self.errors:
                    self.add_error(error)
            self.numeric_validator.clear_errors()
            if not result:
                valid = False
        # Retry delay
        retry_delay = inputs.get("retry-delay")
        if retry_delay:
            result = self.numeric_validator.validate_numeric_range(
                retry_delay, min_val=1, max_val=300
            )
            for error in self.numeric_validator.errors:
                if error not in self.errors:
                    self.add_error(error)
            self.numeric_validator.clear_errors()
            if not result:
                valid = False
        # Shell type - only bash and sh are allowed
        shell = inputs.get("shell")
        valid_shells = ["bash", "sh"]
        if shell and shell not in valid_shells:
            self.add_error(f"Invalid shell type: {inputs['shell']}")
            valid = False
        # Timeout
        timeout = inputs.get("timeout")
        if timeout:
            result = self.numeric_validator.validate_numeric_range(timeout, min_val=1, max_val=3600)
            for error in self.numeric_validator.errors:
                if error not in self.errors:
                    self.add_error(error)
            self.numeric_validator.clear_errors()
            if not result:
                valid = False
        # Working directory
        working_directory = inputs.get("working-directory")
        if working_directory:
            result = self.file_validator.validate_file_path(working_directory)
            for error in self.file_validator.errors:
                if error not in self.errors:
                    self.add_error(error)
            self.file_validator.clear_errors()
            if not result:
                valid = False
        # Description
        description = inputs.get("description")
        if description:
            # Validate description for security patterns
            result = self.security_validator.validate_no_injection(description)
            for error in self.security_validator.errors:
                if error not in self.errors:
                    self.add_error(error)
            self.security_validator.clear_errors()
            if not result:
                valid = False
        # Success codes - validate for injection
        success_codes = inputs.get("success-codes")
        if success_codes:
            result = self.security_validator.validate_no_injection(success_codes)
            for error in self.security_validator.errors:
                if error not in self.errors:
                    self.add_error(error)
            self.security_validator.clear_errors()
            if not result:
                valid = False
        # Retry codes - validate for injection
        retry_codes = inputs.get("retry-codes")
        if retry_codes:
            result = self.security_validator.validate_no_injection(retry_codes)
            for error in self.security_validator.errors:
                if error not in self.errors:
                    self.add_error(error)
            self.security_validator.clear_errors()
            if not result:
                valid = False
        return valid

    def get_required_inputs(self) -> list[str]:
        """Get list of required inputs."""
        return ["command"]

    def get_validation_rules(self) -> dict:
        """Get validation rules."""
        return {
            "command": {
                "type": "string",
                "required": True,
                "description": "Command to retry",
            },
            "backoff-strategy": {
                "type": "string",
                "required": False,
                "description": "Backoff strategy",
            },
            "max-retries": {
                "type": "numeric",
                "required": False,
                "description": "Maximum number of retries",
            },
            "retry-delay": {
                "type": "numeric",
                "required": False,
                "description": "Delay between retries",
            },
            "shell": {
                "type": "string",
                "required": False,
                "description": "Shell to use",
            },
            "timeout": {
                "type": "numeric",
                "required": False,
                "description": "Command timeout",
            },
        }
