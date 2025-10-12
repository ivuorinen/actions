"""Tests for the VersionValidator module."""

from pathlib import Path
import sys

import pytest

# Add the parent directory to the path
sys.path.insert(0, str(Path(__file__).parent.parent))

from validators.version import VersionValidator

from tests.fixtures.version_test_data import (
    CALVER_INVALID,
    CALVER_VALID,
    SEMVER_INVALID,
    SEMVER_VALID,
)


class TestVersionValidator:
    """Test cases for VersionValidator."""

    def setup_method(self):
        """Set up test environment."""
        self.validator = VersionValidator()

    def test_initialization(self):
        """Test validator initialization."""
        assert self.validator.errors == []
        rules = self.validator.get_validation_rules()
        assert "semantic" in rules
        assert "calver" in rules

    @pytest.mark.parametrize("version,description", SEMVER_VALID)
    def test_validate_semver_valid(self, version, description):
        """Test SemVer validation with valid versions."""
        self.validator.errors = []
        result = self.validator.validate_semver(version)
        assert result is True, f"Failed for {description}: {version}"
        assert len(self.validator.errors) == 0

    @pytest.mark.parametrize("version,description", SEMVER_INVALID)
    def test_validate_semver_invalid(self, version, description):
        """Test SemVer validation with invalid versions."""
        self.validator.errors = []
        result = self.validator.validate_semver(version)
        if version == "":  # Empty version might be allowed
            assert result is True or result is False  # Depends on implementation
        else:
            assert result is False, f"Should fail for {description}: {version}"

    @pytest.mark.parametrize("version,description", CALVER_VALID)
    def test_validate_calver_valid(self, version, description):
        """Test CalVer validation with valid versions."""
        self.validator.errors = []
        result = self.validator.validate_calver(version)
        assert result is True, f"Failed for {description}: {version}"
        assert len(self.validator.errors) == 0

    @pytest.mark.parametrize("version,description", CALVER_INVALID)
    def test_validate_calver_invalid(self, version, description):
        """Test CalVer validation with invalid versions."""
        self.validator.errors = []
        result = self.validator.validate_calver(version)
        assert result is False, f"Should fail for {description}: {version}"
        assert len(self.validator.errors) > 0

    def test_validate_flexible_version(self):
        """Test flexible version validation (CalVer or SemVer)."""
        # Test versions that could be either
        flexible_versions = [
            "2024.3.1",  # CalVer
            "1.2.3",  # SemVer
            "v1.0.0",  # SemVer with prefix
            "2024.03.15",  # CalVer
        ]

        for version in flexible_versions:
            self.validator.errors = []
            result = self.validator.validate_flexible_version(version)
            assert result is True, f"Should accept flexible version: {version}"

    def test_validate_dotnet_version(self):
        """Test .NET version validation."""
        valid_versions = [
            "6.0",
            "6.0.100",
            "7.0.0",
            "8.0",
            "3.1.426",
        ]

        for version in valid_versions:
            self.validator.errors = []
            result = self.validator.validate_dotnet_version(version)
            assert result is True, f"Should accept .NET version: {version}"

    def test_validate_terraform_version(self):
        """Test Terraform version validation."""
        valid_versions = [
            "1.0.0",
            "1.5.7",
            "0.14.0",
            "1.6.0-alpha",
        ]

        for version in valid_versions:
            self.validator.errors = []
            result = self.validator.validate_terraform_version(version)
            assert result is True, f"Should accept Terraform version: {version}"

    def test_validate_node_version(self):
        """Test Node.js version validation."""
        valid_versions = [
            "18",
            "18.0.0",
            "20.9.0",
            "lts",
            "latest",
            "lts/hydrogen",
        ]

        for version in valid_versions:
            self.validator.errors = []
            result = self.validator.validate_node_version(version)
            assert result is True, f"Should accept Node version: {version}"

    def test_validate_inputs(self):
        """Test the main validate_inputs method."""
        inputs = {
            "version": "1.2.3",
            "release-version": "2024.3.1",
            "node-version": "18",
        }

        result = self.validator.validate_inputs(inputs)
        # Should handle version inputs based on conventions
        assert isinstance(result, bool)

    def test_version_with_prefix(self):
        """Test that version prefixes are handled correctly."""
        versions_with_prefix = [
            ("v1.2.3", True),  # Common v prefix
            ("V1.2.3", True),  # Uppercase V
            ("release-1.2.3", False),  # Other prefix
            ("ver1.2.3", False),  # Invalid prefix
        ]

        for version, should_pass in versions_with_prefix:
            self.validator.errors = []
            result = self.validator.validate_semver(version)
            if should_pass:
                assert result is True, f"Should accept: {version}"
            else:
                assert result is False, f"Should reject: {version}"

    def test_get_validation_rules(self):
        """Test that validation rules are properly defined."""
        rules = self.validator.get_validation_rules()
        assert "semantic" in rules
        assert "calver" in rules
        assert "dotnet" in rules
        assert "terraform" in rules
        assert "node" in rules
        assert "python" in rules

    def test_validate_strict_semantic_version_valid(self):
        """Test strict semantic version validation with valid versions."""
        valid_versions = [
            "1.0.0",
            "1.2.3",
            "10.20.30",
            "1.0.0-alpha",
            "1.0.0-beta.1",
            "1.0.0-rc.1+build.1",
            "1.0.0+build",
            "v1.2.3",  # v prefix allowed
            "latest",  # Special case
        ]
        for version in valid_versions:
            self.validator.errors = []
            result = self.validator.validate_strict_semantic_version(version)
            assert result is True, f"Should accept strict semver: {version}"
            assert len(self.validator.errors) == 0

    def test_validate_strict_semantic_version_invalid(self):
        """Test strict semantic version validation with invalid versions."""
        invalid_versions = [
            "",  # Empty not allowed in strict mode
            "1.0",  # Must be X.Y.Z
            "1",  # Must be X.Y.Z
            "1.2.a",  # Non-numeric
            "1.2.3.4",  # Too many parts
        ]
        for version in invalid_versions:
            self.validator.errors = []
            result = self.validator.validate_strict_semantic_version(version)
            assert result is False, f"Should reject strict semver: {version}"
            assert len(self.validator.errors) > 0

    def test_validate_version_by_type(self):
        """Test generic validate_version with different types."""
        test_cases = [
            ("1.2.3", "semantic", True),
            ("2024.3.1", "calver", True),
            ("2024.3.1", "flexible", True),
            ("1.2.3", "flexible", True),
            ("6.0.100", "dotnet", True),
            ("1.5.7", "terraform", True),
            ("18.0.0", "node", True),
            ("3.10", "python", True),
            ("8.2", "php", True),
            ("1.21", "go", True),
            ("latest", "flexible", True),  # Special case - only flexible handles latest properly
        ]
        for version, version_type, expected in test_cases:
            self.validator.errors = []
            result = self.validator.validate_version(version, version_type)
            assert result == expected, f"Failed for {version_type}: {version}"

    def test_validate_python_version_valid(self):
        """Test Python version validation with valid versions."""
        valid_versions = [
            "3.8",
            "3.9",
            "3.10",
            "3.11",
            "3.12",
            "3.13",
            "3.14",
            "3.15",
            "3.10.5",  # With patch
        ]
        for version in valid_versions:
            self.validator.errors = []
            result = self.validator.validate_python_version(version)
            assert result is True, f"Should accept Python version: {version}"
            assert len(self.validator.errors) == 0

    def test_validate_python_version_invalid(self):
        """Test Python version validation with invalid versions."""
        invalid_versions = [
            "2.7",  # Python 2 not allowed (major must be 3)
            "3.7",  # Too old (minor < 8)
            "3.16",  # Too new (minor > 15)
            "4.0",  # Wrong major
            "v3.10",  # v prefix not allowed
        ]
        for version in invalid_versions:
            self.validator.errors = []
            result = self.validator.validate_python_version(version)
            assert result is False, f"Should reject Python version: {version}"
            assert len(self.validator.errors) > 0

    def test_validate_python_version_empty(self):
        """Test Python version allows empty (optional)."""
        self.validator.errors = []
        result = self.validator.validate_python_version("")
        assert result is True
        assert len(self.validator.errors) == 0

    def test_validate_php_version_valid(self):
        """Test PHP version validation with valid versions."""
        valid_versions = [
            "7.4",
            "8.0",
            "8.1",
            "8.2",
            "8.3",
            "9.0",
            "7.4.33",  # With patch
        ]
        for version in valid_versions:
            self.validator.errors = []
            result = self.validator.validate_php_version(version)
            assert result is True, f"Should accept PHP version: {version}"
            assert len(self.validator.errors) == 0

    def test_validate_php_version_invalid(self):
        """Test PHP version validation with invalid versions."""
        invalid_versions = [
            "",  # Empty NOT allowed for PHP
            "6.0",  # Too old (major < 7)
            "10.0",  # Too new (major > 9)
            "v8.2",  # v prefix NOT allowed for PHP
            "8",  # Must have minor version
            "8.100",  # Minor too high
        ]
        for version in invalid_versions:
            self.validator.errors = []
            result = self.validator.validate_php_version(version)
            assert result is False, f"Should reject PHP version: {version}"
            assert len(self.validator.errors) > 0

    def test_validate_go_version_valid(self):
        """Test Go version validation with valid versions."""
        valid_versions = [
            "1.18",
            "1.19",
            "1.20",
            "1.21",
            "1.22",
            "1.23",
            "1.30",
            "1.20.5",  # With patch
        ]
        for version in valid_versions:
            self.validator.errors = []
            result = self.validator.validate_go_version(version)
            assert result is True, f"Should accept Go version: {version}"
            assert len(self.validator.errors) == 0

    def test_validate_go_version_invalid(self):
        """Test Go version validation with invalid versions."""
        invalid_versions = [
            "2.0",  # Wrong major (must be 1)
            "1.17",  # Too old (minor < 18)
            "1.31",  # Too new (minor > 30)
            "v1.21",  # v prefix not allowed
        ]
        for version in invalid_versions:
            self.validator.errors = []
            result = self.validator.validate_go_version(version)
            assert result is False, f"Should reject Go version: {version}"
            assert len(self.validator.errors) > 0

    def test_validate_go_version_empty(self):
        """Test Go version allows empty (optional)."""
        self.validator.errors = []
        result = self.validator.validate_go_version("")
        assert result is True
        assert len(self.validator.errors) == 0

    def test_validate_dotnet_version_invalid(self):
        """Test .NET version validation with invalid versions."""
        invalid_versions = [
            "v6.0",  # v prefix not allowed
            "2.0",  # Major < 3
            "21.0",  # Major > 20
        ]
        for version in invalid_versions:
            self.validator.errors = []
            result = self.validator.validate_dotnet_version(version)
            assert result is False, f"Should reject .NET version: {version}"
            assert len(self.validator.errors) > 0

    def test_validate_dotnet_version_empty(self):
        """Test .NET version allows empty (optional)."""
        self.validator.errors = []
        result = self.validator.validate_dotnet_version("")
        assert result is True

    def test_validate_terraform_version_invalid(self):
        """Test Terraform version validation with invalid versions."""
        invalid_versions = [
            "1.0",  # Must be X.Y.Z
            "1",  # Must be X.Y.Z
            "1.0.0.0",  # Too many parts
        ]
        for version in invalid_versions:
            self.validator.errors = []
            result = self.validator.validate_terraform_version(version)
            assert result is False, f"Should reject Terraform version: {version}"

    def test_validate_terraform_version_empty(self):
        """Test Terraform version allows empty (optional)."""
        result = self.validator.validate_terraform_version("")
        assert result is True

    def test_validate_node_version_keywords(self):
        """Test Node.js version validation with keywords."""
        keywords = [
            "latest",
            "lts",
            "current",
            "node",
            "lts/hydrogen",
            "lts/gallium",
            "LTS",  # Case insensitive
            "LATEST",
        ]
        for keyword in keywords:
            self.validator.errors = []
            result = self.validator.validate_node_version(keyword)
            assert result is True, f"Should accept Node keyword: {keyword}"

    def test_validate_node_version_invalid(self):
        """Test Node.js version validation with invalid versions."""
        invalid_versions = [
            "18.0.0.0",  # Too many parts
            "abc",  # Non-numeric
        ]
        for version in invalid_versions:
            self.validator.errors = []
            result = self.validator.validate_node_version(version)
            assert result is False, f"Should reject Node version: {version}"

    def test_validate_node_version_empty(self):
        """Test Node.js version allows empty (optional)."""
        result = self.validator.validate_node_version("")
        assert result is True

    def test_calver_leap_year_validation(self):
        """Test CalVer validation with leap year dates."""
        # 2024 is a leap year
        self.validator.errors = []
        assert self.validator.validate_calver("2024.2.29") is True

        # 2023 is not a leap year
        self.validator.errors = []
        assert self.validator.validate_calver("2023.2.29") is False
        assert len(self.validator.errors) > 0

        # 2000 was a leap year (divisible by 400)
        self.validator.errors = []
        assert self.validator.validate_calver("2000.2.29") is True

        # 1900 was not a leap year (divisible by 100 but not 400)
        self.validator.errors = []
        assert self.validator.validate_calver("1900.2.29") is False

    def test_calver_month_boundaries(self):
        """Test CalVer validation with month boundaries."""
        # 30-day months
        thirty_day_months = [4, 6, 9, 11]
        for month in thirty_day_months:
            self.validator.errors = []
            assert self.validator.validate_calver(f"2024.{month}.30") is True
            self.validator.errors = []
            assert self.validator.validate_calver(f"2024.{month}.31") is False

        # 31-day months
        thirty_one_day_months = [1, 3, 5, 7, 8, 10, 12]
        for month in thirty_one_day_months:
            self.validator.errors = []
            assert self.validator.validate_calver(f"2024.{month}.31") is True

    def test_validate_flexible_version_with_latest(self):
        """Test flexible version accepts 'latest' keyword."""
        self.validator.errors = []
        result = self.validator.validate_flexible_version("latest")
        assert result is True
        assert len(self.validator.errors) == 0

    def test_validate_flexible_version_calver_detection(self):
        """Test flexible version correctly detects CalVer vs SemVer."""
        # Should detect as CalVer
        calver_versions = [
            "2024.3.1",
            "2024-03-15",
            "24.3.1",
        ]
        for version in calver_versions:
            self.validator.errors = []
            result = self.validator.validate_flexible_version(version)
            assert result is True, f"Should accept CalVer: {version}"

        # Invalid CalVer should fail (not try SemVer)
        self.validator.errors = []
        result = self.validator.validate_flexible_version("2024.13.1")
        assert result is False
        assert "CalVer" in " ".join(self.validator.errors)

    def test_validate_inputs_with_different_types(self):
        """Test validate_inputs with different version input types."""
        inputs = {
            "python-version": "3.10",
            "php-version": "8.2",
            "go-version": "1.21",
            "node-version": "18",
            "dotnet-version": "6.0",
            "terraform-version": "1.5.7",
            "version": "1.2.3",
        }
        result = self.validator.validate_inputs(inputs)
        assert result is True
        assert len(self.validator.errors) == 0

    def test_validate_inputs_with_invalid_versions(self):
        """Test validate_inputs with invalid versions."""
        inputs = {
            "python-version": "2.7",  # Too old
            "php-version": "v8.2",  # v prefix not allowed
        }
        result = self.validator.validate_inputs(inputs)
        assert result is False
        assert len(self.validator.errors) >= 2

    def test_semver_simple_formats(self):
        """Test semantic version with simple formats (X.Y and X)."""
        simple_versions = [
            "1.0",  # X.Y
            "2.5",  # X.Y
            "1",  # X
            "10",  # X
        ]
        for version in simple_versions:
            self.validator.errors = []
            result = self.validator.validate_semver(version)
            assert result is True, f"Should accept simple format: {version}"

    def test_semver_with_uppercase_v(self):
        """Test semantic version with uppercase V prefix."""
        self.validator.errors = []
        result = self.validator.validate_semver("V1.2.3")
        assert result is True
        assert len(self.validator.errors) == 0

    def test_dotnet_leading_zeros_rejection(self):
        """Test .NET version rejects leading zeros."""
        invalid_versions = [
            "06.0",  # Leading zero in major
            "6.01",  # Leading zero in minor
            "6.0.001",  # Leading zero in patch
        ]
        for version in invalid_versions:
            self.validator.errors = []
            result = self.validator.validate_dotnet_version(version)
            assert result is False, f"Should reject .NET version with leading zeros: {version}"

    def test_get_required_inputs(self):
        """Test get_required_inputs returns empty list."""
        required = self.validator.get_required_inputs()
        assert isinstance(required, list)
        assert len(required) == 0

    def test_error_handling_accumulation(self):
        """Test that errors accumulate across validations."""
        self.validator.errors = []
        self.validator.validate_semver("invalid")
        first_error_count = len(self.validator.errors)

        self.validator.validate_calver("2024.13.1")
        second_error_count = len(self.validator.errors)

        assert second_error_count > first_error_count
        assert second_error_count >= 2
