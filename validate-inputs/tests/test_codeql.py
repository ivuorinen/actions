"""Tests for codeql validator."""

from validators.codeql import CodeQLValidator


class TestCodeqlValidator:
    """Test cases for CodeqlValidator."""

    def setup_method(self):
        """Set up test fixtures."""
        self.validator = CodeQLValidator("test-action")

    def teardown_method(self):
        """Clean up after tests."""
        self.validator.clear_errors()

    def test_initialization(self):
        """Test validator initialization."""
        assert self.validator.action_type == "test-action"
        assert len(self.validator.SUPPORTED_LANGUAGES) > 0
        assert len(self.validator.STANDARD_SUITES) > 0
        assert len(self.validator.BUILD_MODES) > 0

    def test_get_required_inputs(self):
        """Test getting required inputs."""
        required = self.validator.get_required_inputs()
        assert "language" in required

    def test_get_validation_rules(self):
        """Test getting validation rules."""
        rules = self.validator.get_validation_rules()
        assert "language" in rules
        assert "queries" in rules
        assert "build_modes" in rules

    def test_validate_inputs(self):
        """Test validate_inputs method."""
        inputs = {"language": "python"}
        result = self.validator.validate_inputs(inputs)
        assert result is True

    def test_error_handling(self):
        """Test error handling."""
        self.validator.add_error("Test error")
        assert self.validator.has_errors()
        assert len(self.validator.errors) == 1

        self.validator.clear_errors()
        assert not self.validator.has_errors()
        assert len(self.validator.errors) == 0

    def test_github_expressions(self):
        """Test GitHub expression handling."""
        result = self.validator.is_github_expression("${{ inputs.value }}")
        assert result is True

    # Language validation tests
    def test_validate_codeql_language_valid(self):
        """Test validation of valid CodeQL languages."""
        valid_languages = ["python", "javascript", "typescript", "java", "go", "cpp", "csharp"]
        for lang in valid_languages:
            assert self.validator.validate_codeql_language(lang) is True
            self.validator.clear_errors()

    def test_validate_codeql_language_case_insensitive(self):
        """Test language validation is case insensitive."""
        assert self.validator.validate_codeql_language("Python") is True
        assert self.validator.validate_codeql_language("JAVASCRIPT") is True

    def test_validate_codeql_language_empty(self):
        """Test validation rejects empty language."""
        assert self.validator.validate_codeql_language("") is False
        assert self.validator.has_errors()

    def test_validate_codeql_language_invalid(self):
        """Test validation rejects invalid language."""
        assert self.validator.validate_codeql_language("invalid-lang") is False
        assert self.validator.has_errors()

    # Queries validation tests
    def test_validate_codeql_queries_standard_suite(self):
        """Test validation of standard query suites."""
        standard_suites = ["security-extended", "security-and-quality", "code-scanning", "default"]
        for suite in standard_suites:
            assert self.validator.validate_codeql_queries(suite) is True
            self.validator.clear_errors()

    def test_validate_codeql_queries_multiple(self):
        """Test validation of multiple query suites."""
        assert self.validator.validate_codeql_queries("security-extended,code-scanning") is True

    def test_validate_codeql_queries_file_path(self):
        """Test validation of query file paths."""
        assert self.validator.validate_codeql_queries("queries/security.ql") is True
        assert self.validator.validate_codeql_queries("queries/suite.qls") is True

    def test_validate_codeql_queries_custom_path(self):
        """Test validation of custom query paths."""
        assert self.validator.validate_codeql_queries("./custom/queries") is True

    def test_validate_codeql_queries_github_expression(self):
        """Test queries accept GitHub expressions."""
        assert self.validator.validate_codeql_queries("${{ inputs.queries }}") is True

    def test_validate_codeql_queries_empty(self):
        """Test validation rejects empty queries."""
        assert self.validator.validate_codeql_queries("") is False
        assert self.validator.has_errors()

    def test_validate_codeql_queries_invalid(self):
        """Test validation rejects invalid queries."""
        assert self.validator.validate_codeql_queries("invalid-query") is False
        assert self.validator.has_errors()

    def test_validate_codeql_queries_path_traversal(self):
        """Test queries reject path traversal."""
        result = self.validator.validate_codeql_queries("../../../etc/passwd")
        assert result is False
        assert self.validator.has_errors()

    # Packs validation tests
    def test_validate_codeql_packs_valid(self):
        """Test validation of valid pack formats."""
        valid_packs = [
            "my-pack",
            "owner/repo",
            "owner/repo@1.0.0",
            "org/pack@latest",
        ]
        for pack in valid_packs:
            assert self.validator.validate_codeql_packs(pack) is True
            self.validator.clear_errors()

    def test_validate_codeql_packs_multiple(self):
        """Test validation of multiple packs."""
        assert self.validator.validate_codeql_packs("pack1,owner/pack2,org/pack3@1.0") is True

    def test_validate_codeql_packs_empty(self):
        """Test empty packs are allowed."""
        assert self.validator.validate_codeql_packs("") is True

    def test_validate_codeql_packs_invalid_format(self):
        """Test validation rejects invalid pack format."""
        assert self.validator.validate_codeql_packs("invalid pack!") is False
        assert self.validator.has_errors()

    # Build mode validation tests
    def test_validate_codeql_build_mode_valid(self):
        """Test validation of valid build modes."""
        valid_modes = ["none", "manual", "autobuild"]
        for mode in valid_modes:
            assert self.validator.validate_codeql_build_mode(mode) is True
            self.validator.clear_errors()

    def test_validate_codeql_build_mode_case_insensitive(self):
        """Test build mode validation is case insensitive."""
        assert self.validator.validate_codeql_build_mode("None") is True
        assert self.validator.validate_codeql_build_mode("AUTOBUILD") is True

    def test_validate_codeql_build_mode_empty(self):
        """Test empty build mode is allowed."""
        assert self.validator.validate_codeql_build_mode("") is True

    def test_validate_codeql_build_mode_invalid(self):
        """Test validation rejects invalid build mode."""
        assert self.validator.validate_codeql_build_mode("invalid-mode") is False
        assert self.validator.has_errors()

    # Config validation tests
    def test_validate_codeql_config_valid(self):
        """Test validation of valid config."""
        valid_config = "name: my-config\nqueries: security-extended"
        assert self.validator.validate_codeql_config(valid_config) is True

    def test_validate_codeql_config_empty(self):
        """Test empty config is allowed."""
        assert self.validator.validate_codeql_config("") is True

    def test_validate_codeql_config_dangerous_python(self):
        """Test config rejects dangerous Python patterns."""
        assert self.validator.validate_codeql_config("!!python/object/apply") is False
        assert self.validator.has_errors()

    def test_validate_codeql_config_dangerous_ruby(self):
        """Test config rejects dangerous Ruby patterns."""
        assert self.validator.validate_codeql_config("!!ruby/object:Gem::Installer") is False
        assert self.validator.has_errors()

    def test_validate_codeql_config_dangerous_patterns(self):
        """Test config rejects all dangerous patterns."""
        dangerous = ["!!python/", "!!ruby/", "!!perl/", "!!js/"]
        for pattern in dangerous:
            self.validator.clear_errors()
            assert self.validator.validate_codeql_config(f"test: {pattern}code") is False
            assert self.validator.has_errors()

    # Category validation tests
    def test_validate_category_format_valid(self):
        """Test validation of valid category formats."""
        valid_categories = [
            "/language:python",
            "/security",
            "/my-category",
            "/lang:javascript/security",
        ]
        for category in valid_categories:
            assert self.validator.validate_category_format(category) is True
            self.validator.clear_errors()

    def test_validate_category_format_github_expression(self):
        """Test category accepts GitHub expressions."""
        assert self.validator.validate_category_format("${{ inputs.category }}") is True

    def test_validate_category_format_empty(self):
        """Test empty category is allowed."""
        assert self.validator.validate_category_format("") is True

    def test_validate_category_format_no_leading_slash(self):
        """Test category must start with /."""
        assert self.validator.validate_category_format("category") is False
        assert self.validator.has_errors()

    def test_validate_category_format_invalid_chars(self):
        """Test category rejects invalid characters."""
        assert self.validator.validate_category_format("/invalid!@#") is False
        assert self.validator.has_errors()

    # Threads validation tests
    def test_validate_threads_valid(self):
        """Test validation of valid thread counts."""
        valid_threads = ["1", "4", "8", "16", "32", "64", "128"]
        for threads in valid_threads:
            assert self.validator.validate_threads(threads) is True
            self.validator.clear_errors()

    def test_validate_threads_empty(self):
        """Test empty threads is allowed."""
        assert self.validator.validate_threads("") is True

    def test_validate_threads_invalid_range(self):
        """Test threads rejects out of range values."""
        assert self.validator.validate_threads("0") is False
        assert self.validator.validate_threads("200") is False

    def test_validate_threads_non_numeric(self):
        """Test threads rejects non-numeric values."""
        assert self.validator.validate_threads("not-a-number") is False

    # RAM validation tests
    def test_validate_ram_valid(self):
        """Test validation of valid RAM values."""
        valid_ram = ["256", "512", "1024", "2048", "4096", "8192"]
        for ram in valid_ram:
            assert self.validator.validate_ram(ram) is True
            self.validator.clear_errors()

    def test_validate_ram_empty(self):
        """Test empty RAM is allowed."""
        assert self.validator.validate_ram("") is True

    def test_validate_ram_invalid_range(self):
        """Test RAM rejects out of range values."""
        assert self.validator.validate_ram("100") is False
        assert self.validator.validate_ram("50000") is False

    def test_validate_ram_non_numeric(self):
        """Test RAM rejects non-numeric values."""
        assert self.validator.validate_ram("not-a-number") is False

    # Numeric range validation tests
    def test_validate_numeric_range_1_128(self):
        """Test numeric range 1-128 validation."""
        assert self.validator.validate_numeric_range_1_128("1", "threads") is True
        assert self.validator.validate_numeric_range_1_128("128", "threads") is True
        assert self.validator.validate_numeric_range_1_128("0", "threads") is False
        assert self.validator.validate_numeric_range_1_128("129", "threads") is False

    def test_validate_numeric_range_256_32768(self):
        """Test numeric range 256-32768 validation."""
        assert self.validator.validate_numeric_range_256_32768("256", "ram") is True
        assert self.validator.validate_numeric_range_256_32768("32768", "ram") is True
        assert self.validator.validate_numeric_range_256_32768("255", "ram") is False
        assert self.validator.validate_numeric_range_256_32768("40000", "ram") is False

    # Integration tests
    def test_validate_inputs_multiple_fields(self):
        """Test validation with multiple input fields."""
        inputs = {
            "language": "python",
            "queries": "security-extended",
            "build-mode": "none",
            "category": "/security",
            "threads": "4",
        }
        result = self.validator.validate_inputs(inputs)
        assert result is True

    def test_validate_inputs_with_errors(self):
        """Test validation with invalid inputs."""
        inputs = {
            "language": "invalid-lang",
            "threads": "500",
        }
        result = self.validator.validate_inputs(inputs)
        assert result is False
        assert self.validator.has_errors()
        assert len(self.validator.errors) >= 2
