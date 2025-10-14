"""Tests for the BooleanValidator module."""

from pathlib import Path
import sys

import pytest  # pylint: disable=import-error

# Add the parent directory to the path
sys.path.insert(0, str(Path(__file__).parent.parent))

from validators.boolean import BooleanValidator

from tests.fixtures.version_test_data import BOOLEAN_INVALID, BOOLEAN_VALID


class TestBooleanValidator:
    """Test cases for BooleanValidator."""

    def setup_method(self):
        """Set up test environment."""
        self.validator = BooleanValidator()

    def test_initialization(self):
        """Test validator initialization."""
        assert self.validator.errors == []
        rules = self.validator.get_validation_rules()
        assert "boolean" in rules

    @pytest.mark.parametrize("value,description", BOOLEAN_VALID)
    def test_validate_boolean_valid(self, value, description):
        """Test boolean validation with valid values."""
        self.validator.errors = []
        result = self.validator.validate_boolean(value)
        assert result is True, f"Failed for {description}: {value}"
        assert len(self.validator.errors) == 0

    @pytest.mark.parametrize("value,description", BOOLEAN_INVALID)
    def test_validate_boolean_invalid(self, value, description):
        """Test boolean validation with invalid values."""
        self.validator.errors = []
        result = self.validator.validate_boolean(value)
        if value == "":  # Empty value is allowed
            assert result is True
        else:
            assert result is False, f"Should fail for {description}: {value}"
            assert len(self.validator.errors) > 0

    def test_case_insensitive_validation(self):
        """Test that boolean validation is case-insensitive."""
        valid_cases = [
            "true",
            "True",
            "TRUE",
            "false",
            "False",
            "FALSE",
        ]

        for value in valid_cases:
            self.validator.errors = []
            result = self.validator.validate_boolean(value)
            assert result is True, f"Should accept: {value}"

    def test_invalid_boolean_strings(self):
        """Test that non-boolean strings are rejected."""
        invalid_values = [
            "yes",
            "no",  # Yes/no not allowed
            "1",
            "0",  # Numbers not allowed
            "on",
            "off",  # On/off not allowed
            "enabled",
            "disabled",  # Words not allowed
        ]

        for value in invalid_values:
            self.validator.errors = []
            result = self.validator.validate_boolean(value)
            assert result is False, f"Should reject: {value}"
            assert len(self.validator.errors) > 0

    def test_validate_inputs_with_boolean_keywords(self):
        """Test that inputs with boolean keywords are validated."""
        inputs = {
            "dry-run": "true",
            "verbose": "false",
            "debug": "TRUE",
            "skip-tests": "False",
            "enable-cache": "true",
            "disable-warnings": "false",
        }

        result = self.validator.validate_inputs(inputs)
        assert result is True
        assert len(self.validator.errors) == 0

    def test_validate_inputs_with_invalid_booleans(self):
        """Test that invalid boolean values are caught."""
        inputs = {
            "dry-run": "yes",  # Invalid
            "verbose": "1",  # Invalid
        }

        result = self.validator.validate_inputs(inputs)
        assert result is False
        assert len(self.validator.errors) > 0

    def test_boolean_patterns(self):
        """Test that boolean patterns are detected correctly."""
        # Test inputs that should be treated as boolean
        boolean_inputs = [
            "dry-run",
            "dry_run",
            "is-enabled",
            "is_enabled",
            "has-feature",
            "has_feature",
            "enable-something",
            "disable-something",
            "use-cache",
            "with-logging",
            "without-logging",
            "feature-enabled",
            "feature_disabled",
        ]

        for input_name in boolean_inputs:
            inputs = {input_name: "invalid"}
            self.validator.errors = []
            result = self.validator.validate_inputs(inputs)
            assert result is False, f"Should validate as boolean: {input_name}"

    def test_non_boolean_inputs_ignored(self):
        """Test that non-boolean inputs are not validated."""
        inputs = {
            "version": "1.2.3",  # Not a boolean input
            "name": "test",  # Not a boolean input
            "count": "5",  # Not a boolean input
        }

        result = self.validator.validate_inputs(inputs)
        assert result is True  # Should not validate non-boolean inputs
        assert len(self.validator.errors) == 0

    def test_empty_value_allowed(self):
        """Test that empty boolean values are allowed."""
        result = self.validator.validate_boolean("")
        assert result is True
        assert len(self.validator.errors) == 0

    def test_whitespace_only_value(self):
        """Test that whitespace-only values are treated as empty."""
        values = [" ", "  ", "\t", "\n"]

        for value in values:
            self.validator.errors = []
            result = self.validator.validate_boolean(value)
            assert result is True  # Empty/whitespace should be allowed
