"""Version validators for various versioning schemes."""

from __future__ import annotations

import re

from .base import BaseValidator


class VersionValidator(BaseValidator):
    """Validator for version strings (SemVer, CalVer, language-specific)."""

    # Common version patterns
    VERSION_X_Y_Z_PATTERN = r"^\d+\.\d+(\.\d+)?$"

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
        pattern = r"^\d+\.\d+\.\d+(-[\dA-Za-z.-]+)?(\+[\dA-Za-z.-]+)?$"

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
            r"^\d{4}\.\d{1,2}\.\d{1,2}$",  # YYYY.MM.DD
            r"^\d{4}\.\d{1,2}\.\d{3,}$",  # YYYY.MM.PATCH
            r"^\d{4}\.0\d\.0\d$",  # YYYY.0M.0D
            r"^\d{2}\.\d{1,2}\.\d+$",  # YY.MM.MICRO
            r"^\d{4}\.\d{1,2}$",  # YYYY.MM
            r"^\d{4}-\d{2}-\d{2}$",  # YYYY-MM-DD
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

    def _parse_calver_year(self, year_part: str) -> int | None:
        """Parse year from CalVer version part.

        Returns:
            Year as integer, or None if not a valid year format
        """
        if len(year_part) == 4:
            return int(year_part)
        if len(year_part) == 2:
            # For YY format, assume 2000s
            return 2000 + int(year_part)
        return None  # Not a date-based CalVer

    def _is_valid_month(self, month: int) -> bool:
        """Check if month is in valid range (1-12)."""
        return 1 <= month <= 12

    def _is_leap_year(self, year: int) -> bool:
        """Check if year is a leap year."""
        return (year % 4 == 0 and year % 100 != 0) or (year % 400 == 0)

    def _get_max_day_for_month(self, month: int, year: int) -> int:
        """Get maximum valid day for given month and year.

        Args:
            month: Month (1-12)
            year: Year (for leap year calculation)

        Returns:
            Maximum valid day for the month
        """
        if month in [4, 6, 9, 11]:  # April, June, September, November
            return 30
        if month == 2:  # February
            return 29 if self._is_leap_year(year) else 28
        return 31  # All other months

    def _is_valid_day(self, day: int, month: int, year: int) -> bool:
        """Check if day is valid for the given month and year."""
        if not (1 <= day <= 31):
            return False
        max_day = self._get_max_day_for_month(month, year)
        return day <= max_day

    def _should_validate_day(self, pattern: str, third_part: str) -> bool:
        """Determine if third part should be validated as a day.

        Args:
            pattern: The CalVer pattern that matched
            third_part: The third part of the version string

        Returns:
            True if the third part represents a day and should be validated
        """
        # YYYY.MM.DD and YYYY-MM-DD formats have day as third part
        if r"\d{1,2}$" in pattern or r"\d{2}$" in pattern:
            # Check if it looks like a day (1-2 digits)
            return third_part.isdigit() and len(third_part) <= 2
        # YYYY.MM.PATCH format has patch number (3+ digits), not a day
        if r"\d{3,}" in pattern:
            return False
        # YYYY.0M.0D format is a date format
        return r"0\d" in pattern

    def _validate_calver_date_parts(self, version: str, pattern: str) -> bool:
        """Validate date components in CalVer version.

        Args:
            version: The version string to validate
            pattern: The regex pattern that matched (helps determine format type)

        Returns:
            True if date components are valid, False otherwise
        """
        # Handle different separators
        parts = version.split("-") if "-" in version else version.split(".")

        # Need at least year and month
        if len(parts) < 2:
            return True

        # Parse and validate year
        year = self._parse_calver_year(parts[0])
        if year is None:
            return True  # Not a date-based CalVer

        # Validate month
        month = int(parts[1])
        if not self._is_valid_month(month):
            return False

        # Validate day if present and pattern indicates it's a day (not patch number)
        if len(parts) >= 3 and self._should_validate_day(pattern, parts[2]):
            day = int(parts[2])
            if not self._is_valid_day(day, month, year):
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
            re.match(r"^\d{4}\.", clean_version)
            or re.match(r"^\d{4}-", clean_version)
            or (re.match(r"^\d{2}\.\d", clean_version) and int(clean_version.split(".")[0]) >= 20)
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
                "pattern": r"^\d+(\.\d+(\.\d+)?)?(-[\dA-Za-z-]+(\.\dA-Za-z-]+)*)?$",
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
        pattern = r"^\d+\.\d+\.\d+(-[\w.-]+)?$"

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

        pattern = r"^\d+(\.\d+(\.\d+)?)?$"

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
                "pattern": self.VERSION_X_Y_Z_PATTERN,
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
        if not re.match(self.VERSION_X_Y_Z_PATTERN, clean_value):
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
                "pattern": self.VERSION_X_Y_Z_PATTERN,
            },
        )

    def _check_version_prefix(
        self, value: str, clean_value: str, name: str, lang_name: str
    ) -> bool:
        """Check if version has invalid 'v' prefix."""
        if clean_value.startswith("v"):
            self.add_error(
                f'Invalid {lang_name} version format: "{value}" in {name}. '
                'Version prefix "v" is not allowed',
            )
            return False
        return True

    def _check_version_format(self, value: str, clean_value: str, name: str, config: dict) -> bool:
        """Check if version matches expected format pattern."""
        if not re.match(config["pattern"], clean_value):
            self.add_error(
                f'Invalid {config["name"]} version format: "{value}" in {name}. '
                "Must be X.Y or X.Y.Z format",
            )
            return False
        return True

    def _check_leading_zeros(self, value: str, parts: list[str], name: str, lang_name: str) -> bool:
        """Check for invalid leading zeros in version parts."""
        for part in parts:
            if part.startswith("0") and len(part) > 1:
                self.add_error(
                    f'Invalid {lang_name} version format: "{value}" in {name}. '
                    "Leading zeros are not allowed",
                )
                return False
        return True

    def _validate_major_version(
        self,
        major: int,
        value: str,
        name: str,
        major_range: int | tuple[int, int] | None,
        lang_name: str,
    ) -> bool:
        """Validate major version against allowed range."""
        if isinstance(major_range, int):
            if major != major_range:
                self.add_error(
                    f'{lang_name} version "{value}" in {name}. '
                    f"{lang_name} major version should be {major_range}",
                )
                return False
        elif major_range:
            min_major, max_major = major_range
            if major < min_major or major > max_major:
                self.add_error(
                    f'{lang_name} version "{value}" in {name}. '
                    f"Major version should be between {min_major} and {max_major}",
                )
                return False
        return True

    def _validate_minor_version(
        self,
        minor: int,
        value: str,
        name: str,
        minor_range: tuple[int, int] | None,
        lang_name: str,
    ) -> bool:
        """Validate minor version against allowed range."""
        if minor_range:
            min_minor, max_minor = minor_range
            if minor < min_minor or minor > max_minor:
                self.add_error(
                    f'{lang_name} version "{value}" in {name}. '
                    f"Minor version should be between {min_minor} and {max_minor}",
                )
                return False
        return True

    def _validate_language_version(self, value: str, name: str, config: dict) -> bool:
        """Consolidated language version validation."""
        if not value or value.strip() == "":
            if config.get("required", False):
                self.add_error(f'Input "{name}" is required and cannot be empty')
                return False
            return True

        clean_value = value.strip()
        lang_name = config["name"]

        # Check for invalid 'v' prefix
        if not self._check_version_prefix(value, clean_value, name, lang_name):
            return False

        # Check version format matches pattern
        if not self._check_version_format(value, clean_value, name, config):
            return False

        # Parse version components
        parts = clean_value.split(".")
        major = int(parts[0])
        minor = int(parts[1]) if len(parts) > 1 else 0

        # Check for leading zeros if required
        if config.get("check_leading_zeros") and not self._check_leading_zeros(
            value, parts, name, lang_name
        ):
            return False

        # Validate major version range
        major_valid = self._validate_major_version(
            major, value, name, config.get("major_range"), lang_name
        )
        if not major_valid:
            return False

        # Validate minor version range
        return self._validate_minor_version(
            minor, value, name, config.get("minor_range"), lang_name
        )
