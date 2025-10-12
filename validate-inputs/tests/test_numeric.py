"""Tests for numeric validator."""

from validators.numeric import NumericValidator


class TestNumericValidator:
    """Test cases for NumericValidator."""

    def setup_method(self):
        """Set up test fixtures."""
        self.validator = NumericValidator("test-action")

    def teardown_method(self):
        """Clean up after tests."""
        self.validator.clear_errors()

    def test_initialization(self):
        """Test validator initialization."""
        assert self.validator.action_type == "test-action"
        assert len(self.validator.errors) == 0

    def test_get_required_inputs(self):
        """Test get_required_inputs returns empty list."""
        required = self.validator.get_required_inputs()
        assert isinstance(required, list)
        assert len(required) == 0

    def test_get_validation_rules(self):
        """Test get_validation_rules returns dict."""
        rules = self.validator.get_validation_rules()
        assert isinstance(rules, dict)
        assert "retries" in rules
        assert "timeout" in rules
        assert "threads" in rules
        assert "ram" in rules

    def test_valid_integers(self):
        """Test valid integer values."""
        assert self.validator.validate_integer("42") is True
        assert self.validator.validate_integer("-10") is True
        assert self.validator.validate_integer("0") is True
        assert self.validator.validate_integer(42) is True  # int type
        assert self.validator.validate_integer(-10) is True

    def test_invalid_integers(self):
        """Test invalid integer values."""
        self.validator.clear_errors()
        assert self.validator.validate_integer("3.14") is False
        assert self.validator.has_errors()

        self.validator.clear_errors()
        assert self.validator.validate_integer("abc") is False
        assert self.validator.has_errors()

        self.validator.clear_errors()
        assert self.validator.validate_integer("!") is False
        assert self.validator.has_errors()

    def test_integer_empty_optional(self):
        """Test integer allows empty (optional)."""
        assert self.validator.validate_integer("") is True
        assert self.validator.validate_integer("  ") is True

    def test_numeric_ranges(self):
        """Test numeric range validation."""
        assert self.validator.validate_range("5", min_val=1, max_val=10) is True
        assert self.validator.validate_range("1", min_val=1, max_val=10) is True  # Boundary
        assert self.validator.validate_range("10", min_val=1, max_val=10) is True  # Boundary

        self.validator.clear_errors()
        assert self.validator.validate_range("15", min_val=1, max_val=10) is False
        assert self.validator.has_errors()

        self.validator.clear_errors()
        assert self.validator.validate_range("-5", 0, None) is False
        assert self.validator.has_errors()

    def test_range_with_none_bounds(self):
        """Test range validation with None min/max."""
        # No minimum
        assert self.validator.validate_range("-100", None, 10) is True
        assert self.validator.validate_range("15", None, 10) is False

        # No maximum
        assert self.validator.validate_range("1000", 0, None) is True
        self.validator.clear_errors()
        assert self.validator.validate_range("-5", 0, None) is False

        # No bounds
        assert self.validator.validate_range("999999", None, None) is True
        assert self.validator.validate_range("-999999", None, None) is True

    def test_range_empty_optional(self):
        """Test range allows empty (optional)."""
        assert self.validator.validate_range("", 0, 100) is True
        assert self.validator.validate_range("  ", 0, 100) is True

    def test_github_expressions(self):
        """Test GitHub expression handling."""
        assert self.validator.validate_integer("${{ inputs.timeout }}") is True
        assert self.validator.validate_range("${{ env.RETRIES }}", 1, 2) is True
        # validate_positive_integer and validate_non_negative_integer methods
        # do not support GitHub expression syntax

    def test_validate_positive_integer_valid(self):
        """Test positive integer validation with valid values."""
        assert self.validator.validate_positive_integer("1") is True
        assert self.validator.validate_positive_integer("100") is True
        assert self.validator.validate_positive_integer("999999") is True

    def test_validate_positive_integer_invalid(self):
        """Test positive integer validation with invalid values."""
        self.validator.clear_errors()
        assert self.validator.validate_positive_integer("0") is False
        assert self.validator.has_errors()

        self.validator.clear_errors()
        assert self.validator.validate_positive_integer("-1") is False
        assert self.validator.has_errors()

        self.validator.clear_errors()
        assert self.validator.validate_positive_integer("abc") is False
        assert self.validator.has_errors()

    def test_validate_positive_integer_empty(self):
        """Test positive integer allows empty (optional)."""
        assert self.validator.validate_positive_integer("") is True

    def test_validate_non_negative_integer_valid(self):
        """Test non-negative integer validation with valid values."""
        assert self.validator.validate_non_negative_integer("0") is True
        assert self.validator.validate_non_negative_integer("1") is True
        assert self.validator.validate_non_negative_integer("100") is True

    def test_validate_non_negative_integer_invalid(self):
        """Test non-negative integer validation with invalid values."""
        self.validator.clear_errors()
        assert self.validator.validate_non_negative_integer("-1") is False
        assert self.validator.has_errors()

        self.validator.clear_errors()
        assert self.validator.validate_non_negative_integer("-100") is False
        assert self.validator.has_errors()

        self.validator.clear_errors()
        assert self.validator.validate_non_negative_integer("abc") is False
        assert self.validator.has_errors()

    def test_validate_non_negative_integer_empty(self):
        """Test non-negative integer allows empty (optional)."""
        assert self.validator.validate_non_negative_integer("") is True

    def test_validate_numeric_range_alias(self):
        """Test validate_numeric_range is alias for validate_range."""
        assert self.validator.validate_numeric_range("5", 1, 10) is True
        assert self.validator.validate_numeric_range("15", 1, 10) is False

    def test_validate_numeric_range_0_100(self):
        """Test percentage/quality range (0-100)."""
        assert self.validator.validate_numeric_range_0_100("0") is True
        assert self.validator.validate_numeric_range_0_100("50") is True
        assert self.validator.validate_numeric_range_0_100("100") is True

        self.validator.clear_errors()
        assert self.validator.validate_numeric_range_0_100("-1") is False
        assert self.validator.has_errors()

        self.validator.clear_errors()
        assert self.validator.validate_numeric_range_0_100("101") is False

    def test_validate_numeric_range_1_10(self):
        """Test retries range (1-10)."""
        assert self.validator.validate_numeric_range_1_10("1") is True
        assert self.validator.validate_numeric_range_1_10("5") is True
        assert self.validator.validate_numeric_range_1_10("10") is True

        self.validator.clear_errors()
        assert self.validator.validate_numeric_range_1_10("0") is False
        assert self.validator.has_errors()

        self.validator.clear_errors()
        assert self.validator.validate_numeric_range_1_10("11") is False

    def test_validate_numeric_range_1_128(self):
        """Test threads/workers range (1-128)."""
        assert self.validator.validate_numeric_range_1_128("1") is True
        assert self.validator.validate_numeric_range_1_128("64") is True
        assert self.validator.validate_numeric_range_1_128("128") is True

        self.validator.clear_errors()
        assert self.validator.validate_numeric_range_1_128("0") is False

        self.validator.clear_errors()
        assert self.validator.validate_numeric_range_1_128("129") is False

    def test_validate_numeric_range_256_32768(self):
        """Test RAM range (256-32768 MB)."""
        assert self.validator.validate_numeric_range_256_32768("256") is True
        assert self.validator.validate_numeric_range_256_32768("1024") is True
        assert self.validator.validate_numeric_range_256_32768("32768") is True

        self.validator.clear_errors()
        assert self.validator.validate_numeric_range_256_32768("255") is False

        self.validator.clear_errors()
        assert self.validator.validate_numeric_range_256_32768("32769") is False

    def test_validate_numeric_range_0_16(self):
        """Test parallel builds range (0-16)."""
        assert self.validator.validate_numeric_range_0_16("0") is True
        assert self.validator.validate_numeric_range_0_16("8") is True
        assert self.validator.validate_numeric_range_0_16("16") is True

        self.validator.clear_errors()
        assert self.validator.validate_numeric_range_0_16("-1") is False

        self.validator.clear_errors()
        assert self.validator.validate_numeric_range_0_16("17") is False

    def test_validate_numeric_range_0_10000(self):
        """Test max warnings range (0-10000)."""
        assert self.validator.validate_numeric_range_0_10000("0") is True
        assert self.validator.validate_numeric_range_0_10000("5000") is True
        assert self.validator.validate_numeric_range_0_10000("10000") is True

        self.validator.clear_errors()
        assert self.validator.validate_numeric_range_0_10000("-1") is False

        self.validator.clear_errors()
        assert self.validator.validate_numeric_range_0_10000("10001") is False

    def test_validate_numeric_range_1_300(self):
        """Test delay range (1-300 seconds)."""
        assert self.validator.validate_numeric_range_1_300("1") is True
        assert self.validator.validate_numeric_range_1_300("150") is True
        assert self.validator.validate_numeric_range_1_300("300") is True

        self.validator.clear_errors()
        assert self.validator.validate_numeric_range_1_300("0") is False

        self.validator.clear_errors()
        assert self.validator.validate_numeric_range_1_300("301") is False

    def test_validate_numeric_range_1_3600(self):
        """Test timeout range (1-3600 seconds)."""
        assert self.validator.validate_numeric_range_1_3600("1") is True
        assert self.validator.validate_numeric_range_1_3600("1800") is True
        assert self.validator.validate_numeric_range_1_3600("3600") is True

        self.validator.clear_errors()
        assert self.validator.validate_numeric_range_1_3600("0") is False

        self.validator.clear_errors()
        assert self.validator.validate_numeric_range_1_3600("3601") is False

    def test_validate_inputs_with_retries(self):
        """Test validate_inputs recognizes retry inputs."""
        inputs = {"retries": "5", "max-retry": "3"}
        result = self.validator.validate_inputs(inputs)
        assert result is True
        assert len(self.validator.errors) == 0

    def test_validate_inputs_with_timeout(self):
        """Test validate_inputs recognizes timeout inputs."""
        inputs = {"timeout": "60", "connection-timeout": "30"}
        result = self.validator.validate_inputs(inputs)
        assert result is True

    def test_validate_inputs_with_threads(self):
        """Test validate_inputs recognizes thread/worker inputs."""
        inputs = {"threads": "4", "workers": "8"}
        result = self.validator.validate_inputs(inputs)
        assert result is True

    def test_validate_inputs_with_ram(self):
        """Test validate_inputs recognizes RAM/memory inputs."""
        inputs = {"ram": "1024", "memory": "2048"}
        result = self.validator.validate_inputs(inputs)
        assert result is True

    def test_validate_inputs_with_quality(self):
        """Test validate_inputs recognizes quality inputs."""
        inputs = {"quality": "85", "image-quality": "90"}
        result = self.validator.validate_inputs(inputs)
        assert result is True

    def test_validate_inputs_with_parallel_builds(self):
        """Test validate_inputs recognizes parallel builds inputs."""
        inputs = {"parallel-builds": "4"}
        result = self.validator.validate_inputs(inputs)
        assert result is True

    def test_validate_inputs_with_max_warnings(self):
        """Test validate_inputs recognizes max warnings inputs."""
        inputs = {"max-warnings": "100", "max_warnings": "50"}
        result = self.validator.validate_inputs(inputs)
        assert result is True

    def test_validate_inputs_with_delay(self):
        """Test validate_inputs recognizes delay inputs."""
        inputs = {"delay": "10", "retry-delay": "5"}
        result = self.validator.validate_inputs(inputs)
        assert result is True

    def test_validate_inputs_with_invalid_values(self):
        """Test validate_inputs with invalid values."""
        inputs = {"retries": "20", "timeout": "0"}  # Both out of range
        result = self.validator.validate_inputs(inputs)
        assert result is False
        assert len(self.validator.errors) >= 2

    def test_validate_inputs_with_empty_values(self):
        """Test validate_inputs with empty values (should be optional)."""
        inputs = {"retries": "", "timeout": "  "}
        result = self.validator.validate_inputs(inputs)
        assert result is True

    def test_error_messages(self):
        """Test that error messages are meaningful."""
        self.validator.clear_errors()
        self.validator.validate_range("150", 1, 100, "test-value")
        assert len(self.validator.errors) == 1
        assert "test-value" in self.validator.errors[0]
        assert "100" in self.validator.errors[0]

        self.validator.clear_errors()
        self.validator.validate_range("-5", 0, 100, "count")
        assert len(self.validator.errors) == 1
        assert "count" in self.validator.errors[0]
        assert "0" in self.validator.errors[0]

        self.validator.clear_errors()
        self.validator.validate_integer("abc", "my-number")
        assert len(self.validator.errors) == 1
        assert "my-number" in self.validator.errors[0]
