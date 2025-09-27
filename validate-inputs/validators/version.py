"""Version validators for various versioning schemes."""

from __future__ import annotations

import re

from .base import BaseValidator


class VersionValidator(BaseValidator):
    """Validator for version strings (SemVer, CalVer, language-specific)."""

    def validate_inputs(self, inputs: dict[str, str]) -> bool:
        """Validate version-related inputs."""
        valid = True

        for input_name, value in inputs.items():
            if "version" in input_name.lower():
                # Determine version type from input name
                if "dotnet" in input_name:
                    valid &= self.validate_dotnet_version(value, input_name)
                elif "terraform" in input_name or "tflint" in input_name:
                    valid &= self.validate_terraform_version(value, input_name)
                elif "node" in input_name:
                    valid &= self.validate_node_version(value, input_name)
                elif "python" in input_name:
                    valid &= self.validate_python_version(value, input_name)
                elif "php" in input_name:
                    valid &= self.validate_php_version(value, input_name)
                elif "go" in input_name:
                    valid &= self.validate_go_version(value, input_name)
                else:
                    # Default to semantic version
                    valid &= self.validate_semantic_version(value, input_name)

        return valid

    def get_required_inputs(self) -> list[str]:
        """Version validators typically don't define required inputs."""
        return []

    def get_validation_rules(self) -> dict:
        """Return version validation rules."""
        return {
            "semantic": "X.Y.Z format with optional pre-release and build metadata",
            "calver": "Calendar-based versioning (YYYY.MM.DD, etc.)",
            "dotnet": ".NET version format",
            "terraform": "Terraform version format",
            "node": "Node.js version format",
            "python": "Python 3.x version",
            "php": "PHP 7.4-9.x version",
            "go": "Go 1.x version",
        }

    def validate_semantic_version(self, version: str, name: str = "version") -> bool:
        """Validate semantic version format.

        Args:
            version: The version string to validate
            name: The input name for error messages

        Returns:
            True if valid, False otherwise
        """
        if not version or version.strip() == "":
            return True  # Version is often optional

        # Remove 'v' or 'V' prefix if present (case-insensitive)
        clean_version = version
        if clean_version.lower().startswith("v"):
            clean_version = clean_version[1:]

        # Examples: 1.0.0, 2.1.3-beta, 3.0.0-rc.1, 1.2.3+20130313144700
        semver_pattern = (
            r"^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)"  # MAJOR.MINOR.PATCH
            r"(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)"  # Pre-release
            r"(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?"
            r"(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$"  # Build metadata
        )

        if re.match(semver_pattern, clean_version):
            return True

        # Also allow simple X.Y format for flexibility
        simple_pattern = r"^(0|[1-9]\d*)\.(0|[1-9]\d*)$"
        if re.match(simple_pattern, clean_version):
            return True

        # Also allow single digit version (e.g., "1", "2")
        single_digit_pattern = r"^(0|[1-9]\d*)$"
        if re.match(single_digit_pattern, clean_version):
            return True

        self.add_error(
            f'Invalid semantic version: "{version}" in {name}. '
            "Expected format: MAJOR.MINOR.PATCH (e.g., 1.2.3, 2.0.0-beta)",
        )
        return False

    # Compatibility aliases for tests and backward compatibility
    def validate_semver(self, version: str, name: str = "version") -> bool:
        """Alias for validate_semantic_version."""
        return self.validate_semantic_version(version, name)

    def validate_calver(self, version: str, name: str = "version") -> bool:
        """Alias for validate_calver_version."""
        return self.validate_calver_version(version, name)

    def validate_version(self, version: str, version_type: str, name: str = "version") -> bool:
        """Generic version validation based on type."""
        if version_type == "semantic":
            return self.validate_semantic_version(version, name)
        if version_type == "calver":
            return self.validate_calver_version(version, name)
        if version_type == "flexible":
            return self.validate_flexible_version(version, name)
        if version_type == "dotnet":
            return self.validate_dotnet_version(version, name)
        if version_type == "terraform":
            return self.validate_terraform_version(version, name)
        if version_type == "node":
            return self.validate_node_version(version, name)
        if version_type == "python":
            return self.validate_python_version(version, name)
        if version_type == "php":
            return self.validate_php_version(version, name)
        if version_type == "go":
            return self.validate_go_version(version, name)
        # Allow "latest" as special case
        if version.strip().lower() == "latest":
            return True
        # Default to semantic version
        return self.validate_semantic_version(version, name)  # Version is often optional

    def validate_strict_semantic_version(self, version: str, name: str = "version") -> bool:
        """Validate strict semantic version format (X.Y.Z required).

        Args:
            version: The version string to validate
            name: The input name for error messages

        Returns:
            True if valid, False otherwise
        """
        if not version or version.strip() == "":
            self.add_error(f"Version cannot be empty in {name}")
            return False

        # Allow "latest" as special case
        if version.strip().lower() == "latest":
            return True

        # Remove common prefixes for validation
        clean_version = version.lstrip("v")

        # Strict semantic version pattern
        pattern = r"^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?(\+[0-9A-Za-z.-]+)?$"

        if re.match(pattern, clean_version):
            return True

        self.add_error(
            f'Invalid strict semantic version format: "{version}" in {name}. Must be X.Y.Z',
        )
        return False

    def validate_calver_version(self, version: str, name: str = "version") -> bool:
        """Validate CalVer (Calendar Versioning) format.

        Args:
            version: The version string to validate
            name: The input name for error messages

        Returns:
            True if valid, False otherwise
        """
        if not version or version.strip() == "":
            return True  # Version is often optional

        # Remove common prefixes for validation
        clean_version = version.lstrip("v")

        # CalVer patterns
        calver_patterns = [
            r"^[0-9]{4}\.[0-9]{1,2}\.[0-9]{1,2}$",  # YYYY.MM.DD
            r"^[0-9]{4}\.[0-9]{1,2}\.[0-9]{3,}$",  # YYYY.MM.PATCH
            r"^[0-9]{4}\.0[0-9]\.0[0-9]$",  # YYYY.0M.0D
            r"^[0-9]{2}\.[0-9]{1,2}\.[0-9]+$",  # YY.MM.MICRO
            r"^[0-9]{4}\.[0-9]{1,2}$",  # YYYY.MM
            r"^[0-9]{4}-[0-9]{2}-[0-9]{2}$",  # YYYY-MM-DD
        ]

        for pattern in calver_patterns:
            match = re.match(pattern, clean_version)
            # Additional validation for date components
            if match and self._validate_calver_date_parts(clean_version, pattern):
                return True

        self.add_error(
            f'Invalid CalVer format: "{version}" in {name}. '
            "Expected formats like YYYY.MM.DD, YY.MM.MICRO, etc.",
        )
        return False

    def _validate_calver_date_parts(self, version: str, pattern: str) -> bool:  # noqa: ARG002
        """Validate date components in CalVer version."""
        # Handle different separators
        parts = version.split("-") if "-" in version else version.split(".")

        # Validate based on number of parts
        if len(parts) >= 2:
            # Check year (if 4 digits)
            if len(parts[0]) == 4:
                year = int(parts[0])
            elif len(parts[0]) == 2:
                # For YY format, assume 2000s
                year = 2000 + int(parts[0])
            else:
                return True  # Not a date-based CalVer

            # Check month
            month = int(parts[1])
            if not (1 <= month <= 12):
                return False

            # Check day if present
            if len(parts) >= 3 and parts[2].isdigit() and len(parts[2]) <= 2:
                day = int(parts[2])

                # Basic day validation
                if not (1 <= day <= 31):
                    return False

                # Check valid days for each month
                if month in [4, 6, 9, 11] and day > 30:
                    return False  # April, June, September, November have 30 days
                if month == 2:
                    # February validation
                    is_leap = (year % 4 == 0 and year % 100 != 0) or (year % 400 == 0)
                    if (is_leap and day > 29) or (not is_leap and day > 28):
                        return False

        return True

    def validate_flexible_version(self, version: str, name: str = "version") -> bool:
        """Validate either CalVer or SemVer format.

        Args:
            version: The version string to validate
            name: The input name for error messages

        Returns:
            True if valid, False otherwise
        """
        if not version or version.strip() == "":
            return True  # Version is often optional

        # Allow "latest" as special case
        if version.strip().lower() == "latest":
            return True

        # Save current errors
        original_errors = self.errors.copy()

        # Try CalVer first if it looks like CalVer
        clean_version = version.lstrip("v")
        looks_like_calver = (
            re.match(r"^[0-9]{4}\.", clean_version)
            or re.match(r"^[0-9]{4}-", clean_version)
            or (
                re.match(r"^[0-9]{2}\.[0-9]", clean_version)
                and int(clean_version.split(".")[0]) >= 20
            )
        )

        if looks_like_calver:
            self.errors = []
            if self.validate_calver_version(version, name):
                self.errors = original_errors
                return True
            # If it looks like CalVer but fails, don't try SemVer
            self.errors = original_errors
            self.add_error(f'Invalid CalVer format: "{version}" in {name}')
            return False

        # Try SemVer
        self.errors = []
        if self.validate_semantic_version(version, name):
            self.errors = original_errors
            return True

        # Failed both
        self.errors = original_errors
        self.add_error(
            f'Invalid version format: "{version}" in {name}. '
            "Expected either CalVer (e.g., 2024.3.1) or SemVer (e.g., 1.2.3)",
        )
        return False

    def validate_dotnet_version(self, value: str, name: str = "dotnet-version") -> bool:
        """Validate .NET version format."""
        return self._validate_language_version(
            value,
            name,
            {
                "name": ".NET",
                "major_range": (3, 20),
                "pattern": r"^[0-9]+(\.[0-9]+(\.[0-9]+)?)?(-[0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*)?$",
                "check_leading_zeros": True,
            },
        )

    def validate_terraform_version(self, value: str, name: str = "terraform-version") -> bool:
        """Validate Terraform version format."""
        if not value or value.strip() == "":
            return True

        if value.strip().lower() == "latest":
            return True

        clean_version = value.lstrip("v")
        pattern = r"^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.-]+)?$"

        if re.match(pattern, clean_version):
            return True

        self.add_error(f'Invalid Terraform version format: "{value}" in {name}')
        return False

    def validate_node_version(self, value: str, name: str = "node-version") -> bool:
        """Validate Node.js version format."""
        if not value or value.strip() == "":
            return True

        # Check for special Node.js keywords (case-insensitive)
        value_lower = value.strip().lower()
        node_keywords = ["latest", "lts", "current", "node"]
        if value_lower in node_keywords or value_lower.startswith("lts/"):
            return True

        # Remove v prefix (case-insensitive)
        clean_version = value
        if clean_version.lower().startswith("v"):
            clean_version = clean_version[1:]

        pattern = r"^[0-9]+(\.[0-9]+(\.[0-9]+)?)?$"

        if re.match(pattern, clean_version):
            return True

        self.add_error(f'Invalid Node.js version format: "{value}" in {name}')
        return False

    def validate_python_version(self, value: str, name: str = "python-version") -> bool:
        """Validate Python version format (3.8-3.15)."""
        return self._validate_language_version(
            value,
            name,
            {
                "name": "Python",
                "major_range": 3,
                "minor_range": (8, 15),
                "pattern": r"^[0-9]+\.[0-9]+(\.[0-9]+)?$",
            },
        )

    def validate_php_version(self, value: str, name: str = "php-version") -> bool:
        """Validate PHP version format (7.4-9.x)."""
        # First do basic validation
        if not value or value.strip() == "":
            self.add_error(f"{name} cannot be empty")
            return False

        clean_value = value.strip()

        # Reject v prefix
        if clean_value.startswith("v"):
            self.add_error(
                f'Invalid PHP version format: "{value}" in {name}. '
                'Version prefix "v" is not allowed',
            )
            return False

        # Check format
        if not re.match(r"^[0-9]+\.[0-9]+(\.[0-9]+)?$", clean_value):
            self.add_error(
                f'Invalid PHP version format: "{value}" in {name}. Must be X.Y or X.Y.Z format',
            )
            return False

        # Parse version
        parts = clean_value.split(".")
        major = int(parts[0])
        minor = int(parts[1])

        # Check major version range (7-9)
        if major < 7 or major > 9:
            self.add_error(
                f'PHP version "{value}" in {name}. Major version should be between 7 and 9',
            )
            return False

        # Check minor version ranges per major version
        # PHP 7: 7.0-7.4 are the only released versions, but allow higher for testing
        # PHP 8: Allow any minor version for future compatibility
        # PHP 9: Allow any minor for future compatibility
        # Only restrict if the minor version is unreasonably high (>99)
        if minor > 99:
            self.add_error(
                f'PHP version "{value}" in {name}. Minor version {minor} is unreasonably high',
            )
            return False

        return True

    def validate_go_version(self, value: str, name: str = "go-version") -> bool:
        """Validate Go version format (1.18-1.30)."""
        return self._validate_language_version(
            value,
            name,
            {
                "name": "Go",
                "major_range": 1,
                "minor_range": (18, 30),
                "pattern": r"^[0-9]+\.[0-9]+(\.[0-9]+)?$",
            },
        )

    def _validate_language_version(self, value: str, name: str, config: dict) -> bool:  # noqa: PLR0912
        """Consolidated language version validation."""
        if not value or value.strip() == "":
            if config.get("required", False):
                self.add_error(f'Input "{name}" is required and cannot be empty')
                return False
            return True

        clean_value = value.strip()

        # Reject v prefix
        if clean_value.startswith("v"):
            self.add_error(
                f'Invalid {config["name"]} version format: "{value}" in {name}. '
                'Version prefix "v" is not allowed',
            )
            return False

        # Match version format
        if not re.match(config["pattern"], clean_value):
            self.add_error(
                f'Invalid {config["name"]} version format: "{value}" in {name}. '
                "Must be X.Y or X.Y.Z format",
            )
            return False

        # Parse version components
        parts = clean_value.split(".")
        major = int(parts[0])
        minor = int(parts[1]) if len(parts) > 1 else 0

        # Check leading zeros
        if config.get("check_leading_zeros"):
            for part in parts:
                if part.startswith("0") and len(part) > 1:
                    self.add_error(
                        f'Invalid {config["name"]} version format: "{value}" in {name}. '
                        "Leading zeros are not allowed",
                    )
                    return False

        # Validate major version
        major_range = config.get("major_range")
        if isinstance(major_range, int):
            if major != major_range:
                self.add_error(
                    f'{config["name"]} version "{value}" in {name}. '
                    f"{config['name']} major version should be {major_range}",
                )
                return False
        elif major_range:
            min_major, max_major = major_range
            if major < min_major or major > max_major:
                self.add_error(
                    f'{config["name"]} version "{value}" in {name}. '
                    f"Major version should be between {min_major} and {max_major}",
                )
                return False

        # Validate minor version
        minor_range = config.get("minor_range")
        if minor_range:
            min_minor, max_minor = minor_range
            if minor < min_minor or minor > max_minor:
                self.add_error(
                    f'{config["name"]} version "{value}" in {name}. '
                    f"Minor version should be between {min_minor} and {max_minor}",
                )
                return False

        return True
