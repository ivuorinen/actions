"""Base validator class for GitHub Actions input validation.

Provides the foundation for all validators with common functionality.
"""

from __future__ import annotations

import re
import urllib.parse
from abc import ABC, abstractmethod
from pathlib import Path
from typing import Any


class BaseValidator(ABC):
    """Abstract base class for all validators.

    Provides common validation interface and error handling.
    """

    def __init__(self, action_type: str = "") -> None:
        """Initialize the base validator.

        Args:
            action_type: The type of GitHub Action being validated
        """
        self.action_type = action_type
        self.errors: list[str] = []
        self._rules: dict[str, Any] = {}

    def add_error(self, message: str) -> None:
        """Add a validation error message.

        Args:
            message: The error message to add
        """
        self.errors.append(message)

    def clear_errors(self) -> None:
        """Clear all validation errors."""
        self.errors = []

    def has_errors(self) -> bool:
        """Check if there are any validation errors.

        Returns:
            True if there are errors, False otherwise
        """
        return len(self.errors) > 0

    @abstractmethod
    def validate_inputs(self, inputs: dict[str, str]) -> bool:
        """Validate the provided inputs.

        Args:
            inputs: Dictionary of input names to values

        Returns:
            True if all inputs are valid, False otherwise
        """

    @abstractmethod
    def get_required_inputs(self) -> list[str]:
        """Get the list of required input names.

        Returns:
            List of required input names
        """

    @abstractmethod
    def get_validation_rules(self) -> dict[str, Any]:
        """Get the validation rules for this validator.

        Returns:
            Dictionary of validation rules
        """

    def validate_required_inputs(self, inputs: dict[str, str]) -> bool:
        """Validate that all required inputs are present and non-empty.

        Args:
            inputs: Dictionary of input names to values

        Returns:
            True if all required inputs are present, False otherwise
        """
        valid = True
        required = self.get_required_inputs()

        for req_input in required:
            if not inputs.get(req_input, "").strip():
                self.add_error(f"Required input '{req_input}' is missing or empty")
                valid = False

        return valid

    def validate_security_patterns(self, value: str, name: str = "input") -> bool:
        """Check for common security injection patterns.

        Args:
            value: The value to check
            name: The name of the input for error messages

        Returns:
            True if no injection patterns found, False otherwise
        """
        if not value or value.strip() == "":
            return True

        # GitHub Actions expressions (${{ ... }}) are safe — skip pattern checks
        if self.is_github_expression(value):
            return True

        # Common injection patterns to check
        dangerous_patterns = [
            (";", "command separator"),
            ("&&", "command chaining"),
            ("||", "command chaining"),
            ("|", "pipe operator"),
            ("`", "command substitution"),
            ("$(", "command substitution"),
            ("${", "variable expansion"),
            ("../", "path traversal"),
            ("..\\", "path traversal"),
        ]

        for pattern, description in dangerous_patterns:
            if pattern in value:
                self.add_error(
                    f"Potential security issue in {name}: contains {description} '{pattern}'",
                )
                return False

        return True

    def validate_path_security(self, path: str, name: str = "path") -> bool:
        """Validate file paths for security issues.

        Args:
            path: The file path to validate
            name: The name of the input for error messages

        Returns:
            True if path is secure, False otherwise
        """
        if not path or path.strip() == "":
            return True

        # Decode once; all security checks operate on the decoded form so that
        # URL-encoded bypass variants like %2Fetc/passwd are caught.
        decoded_path = urllib.parse.unquote(path)

        # Check for absolute paths
        if decoded_path.startswith("/") or (len(decoded_path) > 1 and decoded_path[1] == ":"):
            self.add_error(f"Invalid {name}: '{path}'. Absolute path not allowed")
            return False

        # Check for path traversal
        if ".." in decoded_path:
            self.add_error(f"Invalid {name}: '{path}'. Path traversal detected")
            return False

        # Check for home directory expansion
        if path.startswith("~"):
            self.add_error(f"Invalid {name}: '{path}'. Home directory expansion not allowed")
            return False

        return True

    def validate_empty_allowed(self, value: str, name: str) -> bool:
        """Validate that a value is provided (not empty).

        Args:
            value: The value to check
            name: The name of the input for error messages

        Returns:
            True if value is not empty, False otherwise
        """
        if not value or value.strip() == "":
            self.add_error(f"Input '{name}' cannot be empty")
            return False
        return True

    def load_rules(self, rules_path: Path | None = None) -> dict[str, Any]:
        """Load validation rules from YAML file.

        Args:
            rules_path: Path to the rules YAML file (must be a Path object)

        Returns:
            Dictionary containing validation rules
        """
        if not rules_path:
            # Default to action folder's rules.yml file
            action_dir = Path(__file__).parent.parent.parent / self.action_type.replace("_", "-")
            rules_path = action_dir / "rules.yml"

        if not rules_path.exists():
            return {}

        try:
            import yaml  # pylint: disable=import-error,import-outside-toplevel

            with rules_path.open(encoding="utf-8") as f:
                self._rules = yaml.safe_load(f) or {}
                return self._rules
        except Exception as e:  # pylint: disable=broad-exception-caught
            self.add_error(f"Failed to load rules from {rules_path}: {e}")
            return {}

    def get_github_actions_output(self) -> dict[str, str]:
        """Get output formatted for GitHub Actions.

        Returns:
            Dictionary with status and error keys for GitHub Actions
        """
        if self.has_errors():
            return {
                "status": "failure",
                "error": "; ".join(self.errors),
            }
        return {
            "status": "success",
            "error": "",
        }

    def is_github_expression(self, value: str) -> bool:
        """Check if the value is a GitHub expression or expression-prefixed path."""
        if not value.startswith("${{"):
            return False
        cleaned = re.sub(r"\$\{\{[^}]*\}\}", "", value)
        if ".." in cleaned:
            return False
        return bool(re.fullmatch(r"[\w/.-]*", cleaned))

    def propagate_errors(self, validator: BaseValidator, result: bool) -> bool:
        """Copy errors from another validator and return result.

        Args:
            validator: The validator to copy errors from
            result: The validation result to return

        Returns:
            The result parameter unchanged
        """
        for error in validator.errors:
            if error not in self.errors:
                self.add_error(error)
        validator.clear_errors()
        return result

    def validate_with(
        self, validator: BaseValidator, method: str, *args: Any, **kwargs: Any
    ) -> bool:
        """Call validator method and propagate errors.

        Args:
            validator: The validator instance to use
            method: The method name to call on the validator
            *args: Positional arguments to pass to the method
            **kwargs: Keyword arguments to pass to the method

        Returns:
            The validation result
        """
        result = getattr(validator, method)(*args, **kwargs)
        return self.propagate_errors(validator, result)

    def validate_enum(
        self,
        value: str,
        name: str,
        valid_values: list[str],
        *,
        case_sensitive: bool = False,
    ) -> bool:
        """Validate value is one of allowed options.

        Args:
            value: The value to validate
            name: The name of the input for error messages
            valid_values: List of allowed values
            case_sensitive: Whether comparison should be case sensitive

        Returns:
            True if value is valid or empty/GitHub expression, False otherwise
        """
        if not value or self.is_github_expression(value):
            return True
        check = value if case_sensitive else value.lower()
        allowed = valid_values if case_sensitive else [v.lower() for v in valid_values]
        if check not in allowed:
            self.add_error(f"Invalid {name}: {value}. Must be one of: {', '.join(valid_values)}")
            return False
        return True

    @staticmethod
    def get_key_variant(inputs: dict[str, str], *variants: str) -> str | None:
        """Get first matching key variant from inputs.

        Useful for inputs that may use underscore or hyphen variants.

        Args:
            inputs: Dictionary of inputs to check
            *variants: Key variants to search for in order

        Returns:
            The first matching key, or None if no match
        """
        for key in variants:
            if key in inputs:
                return key
        return None
