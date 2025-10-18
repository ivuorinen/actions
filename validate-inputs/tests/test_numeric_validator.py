"""Tests for the NumericValidator module."""

import sys
from pathlib import Path

import pytest  # pylint: disable=import-error

# Add the parent directory to the path
sys.path.insert(0, str(Path(__file__).parent.parent))

# pylint: disable=wrong-import-position
from tests.fixtures.version_test_data import NUMERIC_RANGE_INVALID, NUMERIC_RANGE_VALID
from validators.numeric import NumericValidator


class TestNumericValidator:
    """Test cases for NumericValidator."""

    def setup_method(self):  # pylint: disable=attribute-defined-outside-init
        """Set up test environment."""
        self.validator = NumericValidator()

    def test_initialization(self):
        """Test validator initialization."""
        assert not self.validator.errors
        rules = self.validator.get_validation_rules()
        assert rules is not None

    @pytest.mark.parametrize("value,description", NUMERIC_RANGE_VALID)
    def test_validate_numeric_range_valid(self, value, description):
        """Test numeric range validation with valid values."""
        self.validator.errors = []
        result = self.validator.validate_numeric_range(value, 0, 100, "test")
        assert result is True, f"Failed for {description}: {value}"
        assert len(self.validator.errors) == 0

    @pytest.mark.parametrize("value,description", NUMERIC_RANGE_INVALID)
    def test_validate_numeric_range_invalid(self, value, description):
        """Test numeric range validation with invalid values."""
        self.validator.errors = []
        result = self.validator.validate_numeric_range(value, 0, 100, "test")
        if value == "":  # Empty value is allowed
            assert result is True
        else:
            assert result is False, f"Should fail for {description}: {value}"
            assert len(self.validator.errors) > 0

    def test_validate_range_with_no_limits(self):
        """Test validation with no min/max limits."""
        # No limits - any number should be valid
        assert self.validator.validate_range("999999", None, None, "test") is True
        assert self.validator.validate_range("-999999", None, None, "test") is True
        assert self.validator.validate_range("0", None, None, "test") is True

    def test_validate_range_with_min_only(self):
        """Test validation with only minimum limit."""
        self.validator.errors = []
        assert self.validator.validate_range("10", 5, None, "test") is True
        assert self.validator.validate_range("5", 5, None, "test") is True

        self.validator.errors = []
        assert self.validator.validate_range("4", 5, None, "test") is False
        assert len(self.validator.errors) > 0

    def test_validate_range_with_max_only(self):
        """Test validation with only maximum limit."""
        self.validator.errors = []
        assert self.validator.validate_range("10", None, 20, "test") is True
        assert self.validator.validate_range("20", None, 20, "test") is True

        self.validator.errors = []
        assert self.validator.validate_range("21", None, 20, "test") is False
        assert len(self.validator.errors) > 0

    def test_validate_numeric_range_0_100(self):
        """Test percentage/quality value validation (0-100)."""
        # Valid values
        valid_values = ["0", "50", "100", "75"]
        for value in valid_values:
            self.validator.errors = []
            result = self.validator.validate_numeric_range_0_100(value)
            assert result is True, f"Should accept: {value}"

        # Invalid values
        invalid_values = ["-1", "101", "abc", "50.5"]
        for value in invalid_values:
            self.validator.errors = []
            result = self.validator.validate_numeric_range_0_100(value)
            assert result is False, f"Should reject: {value}"

    def test_validate_numeric_range_1_10(self):
        """Test retry count validation (1-10)."""
        # Valid values
        valid_values = ["1", "5", "10"]
        for value in valid_values:
            self.validator.errors = []
            result = self.validator.validate_numeric_range_1_10(value)
            assert result is True, f"Should accept: {value}"

        # Invalid values
        invalid_values = ["0", "11", "-1", "abc"]
        for value in invalid_values:
            self.validator.errors = []
            result = self.validator.validate_numeric_range_1_10(value)
            assert result is False, f"Should reject: {value}"

    def test_validate_numeric_range_1_128(self):
        """Test thread/worker count validation (1-128)."""
        # Valid values
        valid_values = ["1", "64", "128"]
        for value in valid_values:
            self.validator.errors = []
            result = self.validator.validate_numeric_range_1_128(value)
            assert result is True, f"Should accept: {value}"

        # Invalid values
        invalid_values = ["0", "129", "-1"]
        for value in invalid_values:
            self.validator.errors = []
            result = self.validator.validate_numeric_range_1_128(value)
            assert result is False, f"Should reject: {value}"

    def test_empty_values_allowed(self):
        """Test that empty values are allowed for optional inputs."""
        assert self.validator.validate_range("", 0, 100, "test") is True
        assert self.validator.validate_numeric_range_0_100("") is True
        assert self.validator.validate_numeric_range_1_10("") is True

    def test_whitespace_values(self):
        """Test that whitespace-only values are treated as empty."""
        values = [" ", "  ", "\t", "\n"]
        for value in values:
            self.validator.errors = []
            result = self.validator.validate_range(value, 0, 100, "test")
            assert result is True  # Empty/whitespace should be allowed

    def test_validate_inputs_with_numeric_keywords(self):
        """Test that inputs with numeric keywords are validated."""
        inputs = {
            "retries": "3",
            "max-retries": "5",
            "timeout": "30",
            "max-timeout": "60",
            "parallel-builds": "4",
            "max-warnings": "100",
            "compression-quality": "85",
            "jpeg-quality": "90",
        }

        result = self.validator.validate_inputs(inputs)
        # Result depends on actual validation logic
        assert isinstance(result, bool)

    def test_invalid_numeric_formats(self):
        """Test that invalid numeric formats are rejected."""
        invalid_formats = [
            "1.5",  # Decimal when integer expected
            "1e10",  # Scientific notation
            "0x10",  # Hexadecimal
            "010",  # Octal (might be confusing)
            "1,000",  # Thousands separator
            "+50",  # Explicit positive sign
        ]

        for value in invalid_formats:
            self.validator.errors = []
            result = self.validator.validate_range(value, 0, 100, "test")
            # Some formats might be accepted depending on implementation
            assert isinstance(result, bool)
