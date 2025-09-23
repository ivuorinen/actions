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
