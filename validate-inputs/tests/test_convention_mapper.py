"""Tests for the ConventionMapper class."""

import sys
from pathlib import Path

# Add the parent directory to the path
sys.path.insert(0, str(Path(__file__).parent.parent))

from validators.convention_mapper import ConventionMapper


class TestConventionMapper:
    """Test cases for ConventionMapper."""

    def setup_method(self):
        """Set up test environment."""
        self.mapper = ConventionMapper()

    def test_initialization(self):
        """Test mapper initialization."""
        assert self.mapper._cache == {}
        assert len(self.mapper.CONVENTION_PATTERNS) > 0
        # Patterns should be sorted by priority
        priorities = [p["priority"] for p in self.mapper.CONVENTION_PATTERNS]
        assert priorities == sorted(priorities, reverse=True)

    def test_exact_match_conventions(self):
        """Test exact match conventions."""
        test_cases = {
            "email": "email",
            "url": "url",
            "username": "username",
            "token": "github_token",
            "github-token": "github_token",
            "npm-token": "npm_token",
            "dry-run": "boolean",
            "debug": "boolean",
            "verbose": "boolean",
            "dockerfile": "dockerfile",
            "retries": "numeric_1_10",
            "timeout": "timeout",
            "port": "port",
            "image": "docker_image",
            "tag": "docker_tag",
            "hostname": "hostname",
        }

        for input_name, expected_validator in test_cases.items():
            result = self.mapper.get_validator_type(input_name)
            assert result == expected_validator, f"Failed for {input_name}, got {result}"

    def test_prefix_conventions(self):
        """Test prefix-based conventions."""
        test_cases = {
            "is-enabled": "boolean",
            "is_enabled": "boolean",
            "has-feature": "boolean",
            "has_feature": "boolean",
            "enable-cache": "boolean",
            "disable-warnings": "boolean",
            "use-cache": "boolean",
            "with-logging": "boolean",
            "without-auth": "boolean",
        }

        for input_name, expected_validator in test_cases.items():
            result = self.mapper.get_validator_type(input_name)
            assert result == expected_validator, f"Failed for {input_name}, got {result}"

    def test_suffix_conventions(self):
        """Test suffix-based conventions."""
        test_cases = {
            "config-file": "file_path",
            "env_file": "file_path",
            "output-path": "file_path",
            "cache-dir": "directory",
            "working_directory": "directory",
            "api-url": "url",
            "webhook_url": "url",
            "service-endpoint": "url",
            "feature-enabled": "boolean",
            "warnings_disabled": "boolean",
            "some-version": "version",  # Generic version suffix
            "app_version": "version",  # Generic version suffix
        }

        for input_name, expected_validator in test_cases.items():
            result = self.mapper.get_validator_type(input_name)
            assert result == expected_validator, f"Failed for {input_name}, got {result}"

    def test_contains_conventions(self):
        """Test contains-based conventions."""
        test_cases = {
            "python-version": "python_version",
            "node-version": "node_version",
            "go-version": "go_version",
            "php-version": "php_version",
            "dotnet-version": "dotnet_version",
        }

        for input_name, expected_validator in test_cases.items():
            result = self.mapper.get_validator_type(input_name)
            assert result == expected_validator, f"Failed for {input_name}, got {result}"

    def test_priority_ordering(self):
        """Test that higher priority patterns take precedence."""
        # "token" should match exact pattern before suffix patterns
        assert self.mapper.get_validator_type("token") == "github_token"

        # "email-file" could match both email and file patterns
        # File suffix should win due to priority
        result = self.mapper.get_validator_type("email-file")
        assert result == "file_path"

    def test_case_insensitivity(self):
        """Test that matching is case-insensitive."""
        test_cases = {
            "EMAIL": "email",
            "Email": "email",
            "GitHub-Token": "github_token",
            "DRY_RUN": "boolean",
            "Is_Enabled": "boolean",
        }

        for input_name, expected_validator in test_cases.items():
            result = self.mapper.get_validator_type(input_name)
            assert result == expected_validator, f"Failed for {input_name}, got {result}"

    def test_underscore_dash_normalization(self):
        """Test that underscores and dashes are normalized."""
        # Both should map to the same validator
        assert self.mapper.get_validator_type("dry-run") == self.mapper.get_validator_type(
            "dry_run",
        )
        assert self.mapper.get_validator_type("github-token") == self.mapper.get_validator_type(
            "github_token",
        )
        assert self.mapper.get_validator_type("is-enabled") == self.mapper.get_validator_type(
            "is_enabled",
        )

    def test_explicit_validator_in_config(self):
        """Test that explicit validator in config takes precedence."""
        config_with_validator = {"validator": "custom_validator"}
        result = self.mapper.get_validator_type("any-name", config_with_validator)
        assert result == "custom_validator"

        config_with_type = {"type": "special_type"}
        result = self.mapper.get_validator_type("any-name", config_with_type)
        assert result == "special_type"

    def test_no_match_returns_none(self):
        """Test that inputs with no matching convention return None."""
        unmatched_inputs = [
            "random-input",
            "something-else",
            "xyz123",
            "data",
            "value",
        ]

        for input_name in unmatched_inputs:
            result = self.mapper.get_validator_type(input_name)
            assert result is None, f"Expected None for {input_name}, got {result}"

    def test_caching(self):
        """Test that results are cached."""
        # Clear cache first
        self.mapper.clear_cache()
        assert len(self.mapper._cache) == 0

        # First call should populate cache
        result1 = self.mapper.get_validator_type("email")
        assert len(self.mapper._cache) == 1

        # Second call should use cache
        result2 = self.mapper.get_validator_type("email")
        assert result1 == result2
        assert len(self.mapper._cache) == 1

        # Different input should add to cache
        result3 = self.mapper.get_validator_type("username")
        assert len(self.mapper._cache) == 2
        assert result1 != result3

    def test_get_validator_for_inputs(self):
        """Test batch validation type detection."""
        inputs = {
            "email": "test@example.com",
            "username": "testuser",
            "dry-run": "true",
            "version": "1.2.3",
            "random-field": "value",
        }

        validators = self.mapper.get_validator_for_inputs(inputs)

        assert validators["email"] == "email"
        assert validators["username"] == "username"
        assert validators["dry-run"] == "boolean"
        assert "random-field" not in validators  # No convention match

    def test_add_custom_pattern(self):
        """Test adding custom patterns."""
        # Add a custom pattern
        custom_pattern = {
            "priority": 200,  # High priority
            "type": "exact",
            "patterns": {"my-custom-input": "my_custom_validator"},
        }

        self.mapper.add_custom_pattern(custom_pattern)

        # Should now match the custom pattern
        result = self.mapper.get_validator_type("my-custom-input")
        assert result == "my_custom_validator"

        # Should be sorted by priority
        assert self.mapper.CONVENTION_PATTERNS[0]["priority"] == 200

    def test_remove_pattern(self):
        """Test removing patterns."""
        initial_count = len(self.mapper.CONVENTION_PATTERNS)

        # Remove all boolean patterns
        self.mapper.remove_pattern(
            lambda p: any("boolean" in str(v) for v in p.get("patterns", {}).values()),
        )

        # Should have fewer patterns
        assert len(self.mapper.CONVENTION_PATTERNS) < initial_count

        # Boolean inputs should no longer match
        result = self.mapper.get_validator_type("dry-run")
        assert result is None

    def test_docker_specific_conventions(self):
        """Test Docker-specific conventions."""
        docker_inputs = {
            "image": "docker_image",
            "image-name": "docker_image",
            "tag": "docker_tag",
            "tags": "docker_tags",
            "platforms": "docker_architectures",
            "architectures": "docker_architectures",
            "registry": "docker_registry",
            "namespace": "docker_namespace",
            "cache-from": "cache_mode",
            "cache-to": "cache_mode",
            "build-args": "build_args",
            "labels": "labels",
        }

        for input_name, expected_validator in docker_inputs.items():
            result = self.mapper.get_validator_type(input_name)
            assert result == expected_validator, f"Failed for {input_name}, got {result}"

    def test_numeric_range_conventions(self):
        """Test numeric range conventions."""
        numeric_inputs = {
            "retries": "numeric_1_10",
            "max-retries": "numeric_1_10",
            "threads": "numeric_1_128",
            "workers": "numeric_1_128",
            "compression-quality": "numeric_0_100",
            "jpeg-quality": "numeric_0_100",
            "max-warnings": "numeric_0_10000",
            "ram": "numeric_256_32768",
        }

        for input_name, expected_validator in numeric_inputs.items():
            result = self.mapper.get_validator_type(input_name)
            assert result == expected_validator, f"Failed for {input_name}, got {result}"
