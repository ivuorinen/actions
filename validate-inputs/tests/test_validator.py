"""Comprehensive tests for the ActionValidator class."""

import os
from pathlib import Path
import sys
import tempfile
from unittest.mock import patch

import pytest

# Add the parent directory to the path to import validator
sys.path.insert(0, str(Path(__file__).parent.parent))

from tests.fixtures.version_test_data import (
    BOOLEAN_INVALID,
    BOOLEAN_VALID,
    CALVER_INVALID,
    CALVER_VALID,
    EMAIL_INVALID,
    EMAIL_VALID,
    FILE_PATH_INVALID,
    FILE_PATH_VALID,
    FLEXIBLE_INVALID,
    FLEXIBLE_VALID,
    GITHUB_TOKEN_INVALID,
    GITHUB_TOKEN_VALID,
    NUMERIC_RANGE_INVALID,
    NUMERIC_RANGE_VALID,
    SEMVER_INVALID,
    SEMVER_VALID,
    USERNAME_INVALID,
    USERNAME_VALID,
)
from validator import ActionValidator


class TestActionValidator:
    """Test cases for ActionValidator class."""

    def setup_method(self):
        """Set up test environment before each test."""
        # Clear environment variables
        for key in list(os.environ.keys()):
            if key.startswith("INPUT_"):
                del os.environ[key]

        # Set up basic test environment
        os.environ["INPUT_ACTION_TYPE"] = "test-action"

        # Create temporary output file
        self.temp_output = tempfile.NamedTemporaryFile(mode="w", delete=False)
        os.environ["GITHUB_OUTPUT"] = self.temp_output.name
        self.temp_output.close()

    def teardown_method(self):
        """Clean up after each test."""
        # Clean up temp file
        if os.path.exists(self.temp_output.name):
            os.unlink(self.temp_output.name)

    def test_init(self):
        """Test ActionValidator initialization."""
        validator = ActionValidator()
        assert validator.action_type == "test_action"
        assert validator.errors == []
        assert isinstance(validator.rules, dict)

    def test_github_token_patterns(self):
        """Test GitHub token pattern constants."""
        validator = ActionValidator()
        patterns = validator.GITHUB_TOKEN_PATTERNS

        assert "classic" in patterns
        assert "fine_grained" in patterns
        assert "installation" in patterns

        # Test pattern format
        assert patterns["classic"].startswith("^gh[efpousr]_")
        assert patterns["fine_grained"].startswith("^github_pat_")

    @pytest.mark.parametrize("token,description", GITHUB_TOKEN_VALID)
    def test_validate_github_token_valid(self, token, description):
        """Test GitHub token validation with valid tokens."""
        validator = ActionValidator()
        result = validator.validate_github_token(token, required=True)
        assert result is True, f"Failed for {description}: {token}"
        assert len(validator.errors) == 0

    @pytest.mark.parametrize("token,description", GITHUB_TOKEN_INVALID)
    def test_validate_github_token_invalid(self, token, description):
        """Test GitHub token validation with invalid tokens."""
        validator = ActionValidator()
        result = validator.validate_github_token(token, required=True)
        if token == "":  # Empty token with required=True should fail
            assert result is False
        else:
            assert result is False, f"Should fail for {description}: {token}"

    def test_validate_github_token_optional_empty(self):
        """Test GitHub token validation with empty optional token."""
        validator = ActionValidator()
        result = validator.validate_github_token("", required=False)
        assert result is True

    @pytest.mark.parametrize("version,description", CALVER_VALID)
    def test_validate_calver_valid(self, version, description):
        """Test CalVer validation with valid versions."""
        validator = ActionValidator()
        result = validator.validate_calver(version)
        assert result is True, f"Failed for {description}: {version}"
        assert len(validator.errors) == 0

    @pytest.mark.parametrize("version,description", CALVER_INVALID)
    def test_validate_calver_invalid(self, version, description):
        """Test CalVer validation with invalid versions."""
        validator = ActionValidator()
        result = validator.validate_calver(version)
        assert result is False, f"Should fail for {description}: {version}"
        assert len(validator.errors) > 0

    @pytest.mark.parametrize("version,description", SEMVER_VALID)
    def test_validate_semver_valid(self, version, description):
        """Test SemVer validation with valid versions."""
        validator = ActionValidator()
        result = validator.validate_version(version, "semantic")
        assert result is True, f"Failed for {description}: {version}"
        assert len(validator.errors) == 0

    @pytest.mark.parametrize("version,description", SEMVER_INVALID)
    def test_validate_semver_invalid(self, version, description):
        """Test SemVer validation with invalid versions."""
        validator = ActionValidator()
        result = validator.validate_version(version, "semantic")
        assert result is False, f"Should fail for {description}: {version}"

    @pytest.mark.parametrize("version,description", FLEXIBLE_VALID)
    def test_validate_flexible_version_valid(self, version, description):
        """Test flexible version validation with valid versions."""
        validator = ActionValidator()
        result = validator.validate_calver_or_semver(version)
        assert result is True, f"Failed for {description}: {version}"

    @pytest.mark.parametrize("version,description", FLEXIBLE_INVALID)
    def test_validate_flexible_version_invalid(self, version, description):
        """Test flexible version validation with invalid versions."""
        validator = ActionValidator()
        result = validator.validate_calver_or_semver(version)
        if version == "":  # Empty version is allowed in flexible validation
            assert result is True
        else:
            assert result is False, f"Should fail for {description}: {version}"

    def test_validate_calver_or_semver_prioritizes_calver(self):
        """Test that CalVer-looking versions are validated as CalVer."""
        validator = ActionValidator()

        # This looks like CalVer but has invalid month - should fail
        result = validator.validate_calver_or_semver("2024.13.1")
        assert result is False
        assert "CalVer" in str(validator.errors)

    @pytest.mark.parametrize("email,description", EMAIL_VALID)
    def test_validate_email_valid(self, email, description):
        """Test email validation with valid emails."""
        validator = ActionValidator()
        result = validator.validate_email(email)
        assert result is True, f"Failed for {description}: {email}"
        assert len(validator.errors) == 0

    @pytest.mark.parametrize("email,description", EMAIL_INVALID)
    def test_validate_email_invalid(self, email, description):
        """Test email validation with invalid emails."""
        validator = ActionValidator()
        result = validator.validate_email(email)
        assert result is False, f"Should fail for {description}: {email}"
        assert len(validator.errors) > 0

    @pytest.mark.parametrize("username,description", USERNAME_VALID)
    def test_validate_username_valid(self, username, description):
        """Test username validation with valid usernames."""
        validator = ActionValidator()
        result = validator.validate_username(username)
        assert result is True, f"Failed for {description}: {username}"
        assert len(validator.errors) == 0

    @pytest.mark.parametrize("username,description", USERNAME_INVALID)
    def test_validate_username_invalid(self, username, description):
        """Test username validation with invalid usernames."""
        validator = ActionValidator()
        result = validator.validate_username(username)
        if username == "":  # Empty username is allowed
            assert result is True
        else:
            assert result is False, f"Should fail for {description}: {username}"

    @pytest.mark.parametrize("path,description", FILE_PATH_VALID)
    def test_validate_file_path_valid(self, path, description):
        """Test file path validation with valid paths."""
        validator = ActionValidator()
        result = validator.validate_file_path(path)
        assert result is True, f"Failed for {description}: {path}"
        assert len(validator.errors) == 0

    @pytest.mark.parametrize("path,description", FILE_PATH_INVALID)
    def test_validate_file_path_invalid(self, path, description):
        """Test file path validation with invalid paths."""
        validator = ActionValidator()
        result = validator.validate_file_path(path)
        assert result is False, f"Should fail for {description}: {path}"
        assert len(validator.errors) > 0

    @pytest.mark.parametrize("value,description", NUMERIC_RANGE_VALID)
    def test_validate_numeric_range_valid(self, value, description):
        """Test numeric range validation with valid values."""
        validator = ActionValidator()
        result = validator.validate_numeric_range(value, 0, 100, "test")
        assert result is True, f"Failed for {description}: {value}"
        assert len(validator.errors) == 0

    @pytest.mark.parametrize("value,description", NUMERIC_RANGE_INVALID)
    def test_validate_numeric_range_invalid(self, value, description):
        """Test numeric range validation with invalid values."""
        validator = ActionValidator()
        result = validator.validate_numeric_range(value, 0, 100, "test")
        if value == "":  # Empty value is allowed
            assert result is True
        else:
            assert result is False, f"Should fail for {description}: {value}"

    @pytest.mark.parametrize("value,description", BOOLEAN_VALID)
    def test_validate_boolean_valid(self, value, description):
        """Test boolean validation with valid values."""
        validator = ActionValidator()
        result = validator.validate_boolean(value)
        assert result is True, f"Failed for {description}: {value}"
        assert len(validator.errors) == 0

    @pytest.mark.parametrize("value,description", BOOLEAN_INVALID)
    def test_validate_boolean_invalid(self, value, description):
        """Test boolean validation with invalid values."""
        validator = ActionValidator()
        result = validator.validate_boolean(value)
        if value == "":  # Empty value is allowed
            assert result is True
        else:
            assert result is False, f"Should fail for {description}: {value}"

    def test_validate_namespace_with_lookahead_valid(self):
        """Test namespace validation with valid namespaces."""
        validator = ActionValidator()

        valid_namespaces = [
            "user",
            "user-name",
            "user123",
            "a" * 39,  # Maximum length
            "test-org-123",
        ]

        for namespace in valid_namespaces:
            result = validator.validate_namespace_with_lookahead(namespace)
            assert result is True, f"Should pass for: {namespace}"

    def test_validate_namespace_with_lookahead_invalid(self):
        """Test namespace validation with invalid namespaces."""
        validator = ActionValidator()

        invalid_namespaces = [
            "",  # Empty
            "user-",  # Trailing dash
            "-user",  # Leading dash
            "a" * 40,  # Too long
            "user--name",  # Double dash
        ]

        for namespace in invalid_namespaces:
            validator.errors = []  # Reset errors
            result = validator.validate_namespace_with_lookahead(namespace)
            assert result is False, f"Should fail for: {namespace}"
            assert len(validator.errors) > 0

    def test_validate_docker_image_name_valid(self):
        """Test Docker image name validation with valid names."""
        validator = ActionValidator()

        valid_names = [
            "myapp",
            "my-app",
            "my_app",
            "app123",
            "a.b.c",
        ]

        for name in valid_names:
            validator.errors = []
            result = validator.validate_docker_image_name(name)
            assert result is True, f"Should pass for: {name}"

    def test_validate_docker_image_name_invalid(self):
        """Test Docker image name validation with invalid names."""
        validator = ActionValidator()

        invalid_names = [
            "MyApp",  # Uppercase
            "my/app",  # Slash not allowed
            "my app",  # Space not allowed
            "-myapp",  # Leading dash
            "myapp-",  # Trailing dash
        ]

        for name in invalid_names:
            validator.errors = []
            result = validator.validate_docker_image_name(name)
            assert result is False, f"Should fail for: {name}"

    def test_validate_docker_tag_valid(self):
        """Test Docker tag validation with valid tags."""
        validator = ActionValidator()

        valid_tags = [
            "v1.0.0",
            "latest",
            "main",
            "feature-branch",
            "1.2.3",
            "2024.3.1",
        ]

        for tag in valid_tags:
            validator.errors = []
            result = validator.validate_docker_tag(tag)
            assert result is True, f"Should pass for: {tag}"

    def test_validate_docker_tag_invalid(self):
        """Test Docker tag validation with invalid tags."""
        validator = ActionValidator()

        # Empty tag should fail
        result = validator.validate_docker_tag("")
        assert result is False

    def test_validate_architectures_valid(self):
        """Test Docker architectures validation with valid architectures."""
        validator = ActionValidator()

        valid_archs = [
            "linux/amd64",
            "linux/arm64",
            "linux/amd64,linux/arm64",
            "linux/arm/v7,linux/arm64",
        ]

        for arch in valid_archs:
            validator.errors = []
            result = validator.validate_architectures(arch)
            assert result is True, f"Should pass for: {arch}"

    def test_validate_architectures_invalid(self):
        """Test Docker architectures validation with invalid architectures."""
        validator = ActionValidator()

        invalid_archs = [
            "windows/amd64",  # Windows not supported
            "linux/invalid",  # Invalid arch
            "invalid/format",  # Invalid format
        ]

        for arch in invalid_archs:
            validator.errors = []
            result = validator.validate_architectures(arch)
            assert result is False, f"Should fail for: {arch}"

    def test_validate_prefix_valid(self):
        """Test prefix validation with valid prefixes."""
        validator = ActionValidator()

        valid_prefixes = [
            "",  # Empty prefix
            "v",
            "release-",
            "1.0.0",
            "pre_fix",
            "version.1",
        ]

        for prefix in valid_prefixes:
            validator.errors = []
            result = validator.validate_prefix(prefix)
            assert result is True, f"Should pass for: {prefix}"

    def test_validate_prefix_invalid(self):
        """Test prefix validation with invalid prefixes."""
        validator = ActionValidator()

        invalid_prefixes = [
            "pre@fix",  # Invalid character
            "pre#fix",  # Invalid character
            "pre fix",  # Space not allowed
        ]

        for prefix in invalid_prefixes:
            validator.errors = []
            result = validator.validate_prefix(prefix)
            assert result is False, f"Should fail for: {prefix}"

    def test_validate_security_patterns_valid(self):
        """Test security pattern validation with safe inputs."""
        validator = ActionValidator()

        safe_inputs = [
            "normal-input",
            "file.txt",
            "user@example.com",
            "valid-branch-name",
        ]

        for input_val in safe_inputs:
            validator.errors = []
            result = validator.validate_security_patterns(input_val)
            assert result is True, f"Should pass for: {input_val}"

    def test_validate_security_patterns_invalid(self):
        """Test security pattern validation with dangerous inputs."""
        validator = ActionValidator()

        dangerous_inputs = [
            "; rm -rf /",  # Command injection
            "&& rm file",  # Command chaining
            "| cat /etc/passwd",  # Pipe injection
            "`whoami`",  # Command substitution
            "$(whoami)",  # Command substitution
        ]

        for input_val in dangerous_inputs:
            validator.errors = []
            result = validator.validate_security_patterns(input_val)
            assert result is False, f"Should fail for: {input_val}"

    def test_validate_branch_name_valid(self):
        """Test branch name validation with valid names."""
        validator = ActionValidator()

        valid_branches = [
            "main",
            "feature/new-feature",
            "bugfix/issue-123",
            "release-1.0",
            "dev_branch",
        ]

        for branch in valid_branches:
            validator.errors = []
            result = validator.validate_branch_name(branch)
            assert result is True, f"Should pass for: {branch}"

    def test_validate_branch_name_invalid(self):
        """Test branch name validation with invalid names."""
        validator = ActionValidator()

        invalid_branches = [
            "",  # Empty
            ".hidden",  # Starts with dot
            "branch.",  # Ends with dot
            "-branch",  # Starts with dash
            "branch/",  # Ends with slash
            "/branch",  # Starts with slash
            "branch..name",  # Double dot
            "branch~name",  # Invalid character
            "branch^name",  # Invalid character
            "branch; rm -rf /",  # Command injection
        ]

        for branch in invalid_branches:
            validator.errors = []
            result = validator.validate_branch_name(branch)
            if branch == "":  # Empty branch is allowed
                assert result is True
            else:
                assert result is False, f"Should fail for: {branch}"


class TestActionValidatorIntegration:
    """Integration tests for ActionValidator with rules."""

    def setup_method(self):
        """Set up test environment."""
        # Create temporary output file
        self.temp_output = tempfile.NamedTemporaryFile(mode="w", delete=False)
        os.environ["GITHUB_OUTPUT"] = self.temp_output.name
        self.temp_output.close()

    def teardown_method(self):
        """Clean up after each test."""
        if os.path.exists(self.temp_output.name):
            os.unlink(self.temp_output.name)

    def test_load_validation_rules_missing_file(self):
        """Test loading validation rules when file doesn't exist."""
        os.environ["INPUT_ACTION_TYPE"] = "nonexistent-action"
        validator = ActionValidator()
        assert validator.rules == {}

    @pytest.mark.skipif(
        condition=True, reason="Hangs with coverage instrumentation - test disabled"
    )
    @patch("os.path.exists")
    @patch("builtins.open")
    def test_load_validation_rules_with_file(self, mock_open, mock_exists):
        """Test loading validation rules when file exists."""
        mock_exists.return_value = True
        mock_file_content = """
        action: test-action
        required_inputs: ["version"]
        conventions:
          version: semantic_version
        """
        mock_open.return_value.__enter__.return_value.read.return_value = mock_file_content

        os.environ["INPUT_ACTION_TYPE"] = "test-action"
        validator = ActionValidator()

        # Should have loaded rules
        assert "action" in validator.rules

    def test_validate_with_rules_no_rules(self):
        """Test validation when no rules are loaded."""
        validator = ActionValidator()
        validator.rules = {}

        inputs = {"test": "value"}
        result = validator.validate_with_rules(inputs)
        assert result is True

    def test_validate_with_rules_required_inputs(self):
        """Test validation of required inputs."""
        validator = ActionValidator()
        validator.rules = {
            "required_inputs": ["version", "token"],
            "conventions": {},
            "overrides": {},
        }

        # Missing required inputs
        inputs = {"other": "value"}
        result = validator.validate_with_rules(inputs)
        assert result is False
        assert len(validator.errors) == 2  # Two missing required inputs

    def test_validate_with_rules_overrides_null(self):
        """Test validation when input is overridden to null."""
        validator = ActionValidator()
        validator.rules = {
            "required_inputs": [],
            "conventions": {"test": "semantic_version"},
            "overrides": {"test": None},  # Override to skip validation
        }

        inputs = {"test": "invalid-version"}
        result = validator.validate_with_rules(inputs)
        assert result is True  # Should skip validation due to override

    def test_error_accumulation(self):
        """Test that errors accumulate correctly."""
        validator = ActionValidator()

        # Add multiple validation errors
        validator.validate_email("invalid-email")
        validator.validate_github_token("invalid-token", required=True)
        validator.validate_calver("invalid-date")

        # Should have multiple errors
        assert len(validator.errors) >= 3
