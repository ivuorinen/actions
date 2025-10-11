"""Boolean validator for true/false inputs."""

from __future__ import annotations

from .base import BaseValidator


class BooleanValidator(BaseValidator):
    """Validator for boolean inputs."""

    def validate_inputs(self, inputs: dict[str, str]) -> bool:
        """Validate boolean inputs."""
        valid = True

        # Common boolean input patterns
        boolean_keywords = [
            "dry-run",
            "dry_run",
            "verbose",
            "debug",
            "fail-on-error",
            "fail_on_error",
            "cache",
            "skip",
            "force",
            "auto",
            "enabled",
            "disabled",
            "check-only",
            "check_only",
            "sign",
            "scan",
            "push",
            "nightly",
            "stable",
            "provenance",
            "sbom",
        ]

        for input_name, value in inputs.items():
            # Check if input name suggests boolean
            is_boolean_input = any(keyword in input_name.lower() for keyword in boolean_keywords)

            # Also check for specific patterns
            if (
                is_boolean_input
                or input_name.startswith(
                    (
                        "is-",
                        "is_",
                        "has-",
                        "has_",
                        "enable-",
                        "enable_",
                        "disable-",
                        "disable_",
                        "use-",
                        "use_",
                        "with-",
                        "with_",
                        "without-",
                        "without_",
                    ),
                )
                or input_name.endswith(("-enabled", "_enabled", "-disabled", "_disabled"))
            ):
                valid &= self.validate_boolean(value, input_name)

        return valid

    def get_required_inputs(self) -> list[str]:
        """Boolean validators typically don't define required inputs."""
        return []

    def get_validation_rules(self) -> dict:
        """Return boolean validation rules."""
        return {
            "boolean": "Must be 'true' or 'false' (lowercase)",
        }

    def validate_boolean(self, value: str, name: str = "boolean") -> bool:
        """Validate boolean input.

        Args:
            value: The value to validate
            name: The input name for error messages

        Returns:
            True if valid, False otherwise
        """
        if not value or value.strip() == "":
            # Empty boolean often defaults to false
            return True

        # Allow GitHub Actions expressions
        if self.is_github_expression(value):
            return True

        # Accept any case variation of true/false
        if value.lower() in ["true", "false"]:
            return True

        # Check for yes/no (not valid for GitHub Actions)
        if value.lower() in ["yes", "no", "y", "n"]:
            self.add_error(
                f"Invalid {name}: \"{value}\". Must be 'true' or 'false'",
            )
            return False

        # Check for numeric boolean
        if value in ["0", "1"]:
            self.add_error(
                f"Invalid {name}: \"{value}\". Must be 'true' or 'false'",
            )
            return False

        # Generic error
        self.add_error(f"Invalid {name}: \"{value}\". Must be 'true' or 'false'")
        return False

    def validate_boolean_extended(self, value: str | None, name: str = "boolean") -> bool:
        """Validate boolean input with extended options (true/false/empty).

        Args:
            value: The value to validate
            name: The input name for error messages

        Returns:
            True if valid or empty, False otherwise
        """
        if value is None:
            return True

        if not value or value.strip() == "":
            return True

        if value.lower() in ["yes", "no", "y", "n", "0", "1", "on", "off"]:
            return True

        return self.validate_boolean(value, name)

    def validate_optional_boolean(self, value: str | None, name: str = "boolean") -> bool:
        """Validate optional boolean input (can be empty).

        Args:
            value: The value to validate
            name: The input name for error messages

        Returns:
            True if valid or empty, False otherwise
        """
        if value is None:
            return True

        if not value or value.strip() == "":
            return True

        return self.validate_boolean(value, name)

    def validate_required_boolean(self, value: str, name: str = "boolean") -> bool:
        """Validate required boolean input (cannot be empty).

        Args:
            value: The value to validate
            name: The input name for error messages

        Returns:
            True if valid, False otherwise
        """
        if not value or value.strip() == "":
            self.add_error(f"Boolean {name} cannot be empty")
            return False

        return self.validate_boolean(value, name)
