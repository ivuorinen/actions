"""Numeric validators for ranges and numeric inputs."""

from __future__ import annotations

from .base import BaseValidator


class NumericValidator(BaseValidator):
    """Validator for numeric inputs and ranges."""

    def validate_inputs(self, inputs: dict[str, str]) -> bool:
        """Validate numeric inputs."""
        valid = True

        for input_name, value in inputs.items():
            # Check for specific numeric patterns
            if "retries" in input_name or "retry" in input_name:
                valid &= self.validate_range(value, 0, 10, input_name)
            elif "timeout" in input_name:
                valid &= self.validate_range(value, 1, 3600, input_name)
            elif "threads" in input_name or "workers" in input_name:
                valid &= self.validate_range(value, 1, 128, input_name)
            elif "ram" in input_name or "memory" in input_name:
                valid &= self.validate_range(value, 256, 32768, input_name)
            elif "quality" in input_name:
                valid &= self.validate_range(value, 0, 100, input_name)
            elif "parallel" in input_name and "builds" in input_name:
                valid &= self.validate_range(value, 0, 16, input_name)
            elif "max-warnings" in input_name or "max_warnings" in input_name:
                valid &= self.validate_range(value, 0, 10000, input_name)
            elif "delay" in input_name:
                valid &= self.validate_range(value, 1, 300, input_name)

        return valid

    def get_required_inputs(self) -> list[str]:
        """Numeric validators typically don't define required inputs."""
        return []

    def get_validation_rules(self) -> dict:
        """Return numeric validation rules."""
        return {
            "retries": "0-10",
            "timeout": "1-3600 seconds",
            "threads": "1-128",
            "ram": "256-32768 MB",
            "quality": "0-100",
            "parallel_builds": "0-16",
            "max_warnings": "0-10000",
            "delay": "1-300 seconds",
        }

    def validate_range(
        self,
        value: str,
        min_val: int | None,
        max_val: int | None,
        name: str = "value",
    ) -> bool:
        """Validate numeric input within a specific range.

        Args:
            value: The value to validate
            min_val: Minimum allowed value (None for no minimum)
            max_val: Maximum allowed value (None for no maximum)
            name: The input name for error messages

        Returns:
            True if valid, False otherwise
        """
        if not value or value.strip() == "":
            return True  # Numeric values are often optional

        # Allow GitHub Actions expressions
        if self.is_github_expression(value):
            return True

        try:
            num = int(value.strip())

            # Handle None values for min and max
            if min_val is not None and num < min_val:
                self.add_error(f"Invalid {name}: {num}. Must be at least {min_val}")
                return False

            if max_val is not None and num > max_val:
                self.add_error(f"Invalid {name}: {num}. Must be at most {max_val}")
                return False

            return True
        except ValueError:
            self.add_error(f'Invalid {name}: "{value}". Must be a number')
            return False

    def validate_numeric_range(
        self,
        value: str,
        min_val: int | None = None,
        max_val: int | None = None,
        name: str = "numeric",
    ) -> bool:
        """Generic numeric range validation.

        Args:
            value: The value to validate
            min_val: Minimum allowed value (inclusive), None for no minimum
            max_val: Maximum allowed value (inclusive), None for no maximum
            name: The input name for error messages

        Returns:
            True if valid, False otherwise
        """
        return self.validate_range(value, min_val, max_val, name)

    def validate_numeric_range_0_100(self, value: str, name: str = "value") -> bool:
        """Validate percentage or quality value (0-100).

        Args:
            value: The value to validate
            name: The input name for error messages

        Returns:
            True if valid, False otherwise
        """
        return self.validate_range(value, 0, 100, name)

    def validate_numeric_range_1_10(self, value: str, name: str = "retries") -> bool:
        """Validate retry count (1-10).

        Args:
            value: The value to validate
            name: The input name for error messages

        Returns:
            True if valid, False otherwise
        """
        return self.validate_range(value, 1, 10, name)

    def validate_numeric_range_1_128(self, value: str, name: str = "threads") -> bool:
        """Validate thread/worker count (1-128).

        Args:
            value: The value to validate
            name: The input name for error messages

        Returns:
            True if valid, False otherwise
        """
        return self.validate_range(value, 1, 128, name)

    def validate_numeric_range_256_32768(self, value: str, name: str = "ram") -> bool:
        """Validate RAM in MB (256-32768).

        Args:
            value: The value to validate
            name: The input name for error messages

        Returns:
            True if valid, False otherwise
        """
        return self.validate_range(value, 256, 32768, name)

    def validate_numeric_range_0_16(self, value: str, name: str = "parallel-builds") -> bool:
        """Validate parallel builds count (0-16).

        Args:
            value: The value to validate
            name: The input name for error messages

        Returns:
            True if valid, False otherwise
        """
        return self.validate_range(value, 0, 16, name)

    def validate_numeric_range_0_10000(self, value: str, name: str = "max-warnings") -> bool:
        """Validate max warnings count (0-10000).

        Args:
            value: The value to validate
            name: The input name for error messages

        Returns:
            True if valid, False otherwise
        """
        return self.validate_range(value, 0, 10000, name)

    def validate_numeric_range_1_300(self, value: str, name: str = "delay") -> bool:
        """Validate delay in seconds (1-300).

        Args:
            value: The value to validate
            name: The input name for error messages

        Returns:
            True if valid, False otherwise
        """
        return self.validate_range(value, 1, 300, name)

    def validate_numeric_range_1_3600(self, value: str, name: str = "timeout") -> bool:
        """Validate timeout in seconds (1-3600).

        Args:
            value: The value to validate
            name: The input name for error messages

        Returns:
            True if valid, False otherwise
        """
        return self.validate_range(value, 1, 3600, name)

    def validate_integer(self, value: str | int, name: str = "value") -> bool:
        """Validate integer (can be negative).

        Args:
            value: The value to validate
            name: The input name for error messages

        Returns:
            True if valid, False otherwise
        """
        if not value or str(value).strip() == "":
            return True  # Optional

        # Allow GitHub Actions expressions
        if self.is_github_expression(str(value)):
            return True

        try:
            int(str(value).strip())
            return True
        except ValueError:
            self.add_error(f'Invalid {name}: "{value}". Must be an integer')
            return False

    def validate_positive_integer(self, value: str, name: str = "value") -> bool:
        """Validate positive integer (> 0).

        Args:
            value: The value to validate
            name: The input name for error messages

        Returns:
            True if valid, False otherwise
        """
        if not value or value.strip() == "":
            return True  # Optional

        try:
            num = int(value.strip())
            if num > 0:
                return True
            self.add_error(f"Invalid {name}: {num}. Must be positive")
            return False
        except ValueError:
            self.add_error(f'Invalid {name}: "{value}". Must be a positive integer')
            return False

    def validate_non_negative_integer(self, value: str, name: str = "value") -> bool:
        """Validate non-negative integer (>= 0).

        Args:
            value: The value to validate
            name: The input name for error messages

        Returns:
            True if valid, False otherwise
        """
        if not value or value.strip() == "":
            return True  # Optional

        try:
            num = int(value.strip())
            if num >= 0:
                return True
            self.add_error(f"Invalid {name}: {num}. Cannot be negative")
            return False
        except ValueError:
            self.add_error(f'Invalid {name}: "{value}". Must be a non-negative integer')
            return False
