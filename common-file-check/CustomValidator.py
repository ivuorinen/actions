"""Custom validator for common-file-check action.

This validator handles file checking validation including:
- File patterns with glob support (*, ?, **, {}, [])
- Path security validation
- Injection detection
"""

from __future__ import annotations

from pathlib import Path
import sys

# Add validate-inputs directory to path to import validators
validate_inputs_path = Path(__file__).parent.parent / "validate-inputs"
sys.path.insert(0, str(validate_inputs_path))

from validators.base import BaseValidator  # noqa: E402
from validators.boolean import BooleanValidator  # noqa: E402
from validators.file import FileValidator  # noqa: E402


class CustomValidator(BaseValidator):
    """Custom validator for common-file-check action.

    Provides validation for file pattern checking.
    """

    def __init__(self, action_type: str = "common-file-check") -> None:
        """Initialize the common-file-check validator."""
        super().__init__(action_type)
        self.file_validator = FileValidator(action_type)
        self.boolean_validator = BooleanValidator(action_type)

    def validate_inputs(self, inputs: dict[str, str]) -> bool:
        """Validate common-file-check specific inputs.

        Args:
            inputs: Dictionary of input names to values

        Returns:
            True if all validations pass, False otherwise
        """
        valid = True

        # Validate file-pattern (required)
        if "file-pattern" in inputs:
            valid &= self.validate_file_pattern(inputs["file-pattern"])
        elif "file_pattern" in inputs:
            valid &= self.validate_file_pattern(inputs["file_pattern"])
        else:
            # File pattern is required
            self.add_error("File pattern is required")
            valid = False

        # Validate fail-on-missing (optional)
        if inputs.get("fail-on-missing") or inputs.get("fail_on_missing"):
            fail_on_missing = inputs.get("fail-on-missing", inputs.get("fail_on_missing"))
            # Use BooleanValidator for boolean validation
            result = self.boolean_validator.validate_optional_boolean(
                fail_on_missing, "fail-on-missing"
            )
            # Propagate errors
            for error in self.boolean_validator.errors:
                if error not in self.errors:
                    self.add_error(error)
            self.boolean_validator.clear_errors()
            valid &= result

        return valid

    def get_required_inputs(self) -> list[str]:
        """Get list of required inputs for common-file-check.

        Returns:
            List of required input names
        """
        return ["file-pattern"]

    def get_validation_rules(self) -> dict:
        """Get validation rules for common-file-check.

        Returns:
            Dictionary of validation rules
        """
        return {
            "file-pattern": "File glob pattern to check",
            "fail-on-missing": "Whether to fail if file is missing (true/false)",
        }

    def validate_file_pattern(self, pattern: str) -> bool:
        """Validate file pattern (glob pattern).

        Args:
            pattern: File pattern with glob support

        Returns:
            True if valid, False otherwise
        """
        # Check for empty
        if not pattern or not pattern.strip():
            self.add_error("File pattern cannot be empty")
            return False

        # Allow GitHub Actions expressions
        if self.is_github_expression(pattern):
            return True

        # Use base validator's path security check
        if not self.validate_path_security(pattern, "file-pattern"):
            return False

        # Also check for command injection patterns using base validator
        return self.validate_security_patterns(pattern, "file-pattern")
