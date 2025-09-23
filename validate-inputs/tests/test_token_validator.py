"""Tests for the TokenValidator module."""

from pathlib import Path
import sys

import pytest

# Add the parent directory to the path
sys.path.insert(0, str(Path(__file__).parent.parent))

from validators.token import TokenValidator

from tests.fixtures.version_test_data import GITHUB_TOKEN_INVALID, GITHUB_TOKEN_VALID


class TestTokenValidator:
    """Test cases for TokenValidator."""

    def setup_method(self):
        """Set up test environment."""
        self.validator = TokenValidator()

    def test_initialization(self):
        """Test validator initialization."""
        assert self.validator.errors == []
        assert "github_classic" in self.validator.TOKEN_PATTERNS
        assert "github_fine_grained" in self.validator.TOKEN_PATTERNS
        assert "npm_classic" in self.validator.TOKEN_PATTERNS

    @pytest.mark.parametrize("token,description", GITHUB_TOKEN_VALID)
    def test_github_token_valid(self, token, description):
        """Test GitHub token validation with valid tokens."""
        result = self.validator.validate_github_token(token, required=True)
        assert result is True, f"Failed for {description}: {token}"
        assert len(self.validator.errors) == 0

    @pytest.mark.parametrize("token,description", GITHUB_TOKEN_INVALID)
    def test_github_token_invalid(self, token, description):
        """Test GitHub token validation with invalid tokens."""
        self.validator.errors = []  # Clear errors
        result = self.validator.validate_github_token(token, required=True)
        if token == "":  # Empty token with required=True should fail
            assert result is False
            assert len(self.validator.errors) > 0
        else:
            assert result is False, f"Should fail for {description}: {token}"

    def test_github_token_optional_empty(self):
        """Test GitHub token validation with empty optional token."""
        result = self.validator.validate_github_token("", required=False)
        assert result is True
        assert len(self.validator.errors) == 0

    def test_github_token_environment_variable(self):
        """Test that environment variable references are accepted."""
        tokens = [
            "$GITHUB_TOKEN",
            "${GITHUB_TOKEN}",
            "$MY_TOKEN",
        ]
        for token in tokens:
            self.validator.errors = []
            result = self.validator.validate_github_token(token)
            assert result is True, f"Should accept environment variable: {token}"

    def test_npm_token_valid(self):
        """Test NPM token validation with valid tokens."""
        valid_tokens = [
            "npm_" + "a" * 40,  # Classic NPM token
            "00000000-0000-0000-0000-000000000000",  # UUID format
            "$NPM_TOKEN",  # Environment variable
            "",  # Empty (optional)
        ]

        for token in valid_tokens:
            self.validator.errors = []
            result = self.validator.validate_npm_token(token)
            assert result is True, f"Should accept: {token}"

    def test_npm_token_invalid(self):
        """Test NPM token validation with invalid tokens."""
        invalid_tokens = [
            "npm_short",  # Too short
            "not-a-uuid-or-npm-token",  # Invalid format
            "npm_" + "a" * 39,  # One character too short
        ]

        for token in invalid_tokens:
            self.validator.errors = []
            result = self.validator.validate_npm_token(token)
            assert result is False, f"Should reject: {token}"
            assert len(self.validator.errors) > 0

    def test_docker_token_valid(self):
        """Test Docker token validation with valid tokens."""
        valid_tokens = [
            "dckr_pat_" + "a" * 20,  # Docker personal access token
            "a" * 20,  # Generic token
            "$DOCKER_TOKEN",  # Environment variable
            "",  # Empty (optional)
        ]

        for token in valid_tokens:
            self.validator.errors = []
            result = self.validator.validate_docker_token(token)
            assert result is True, f"Should accept: {token}"

    def test_docker_token_invalid(self):
        """Test Docker token validation with invalid tokens."""
        invalid_tokens = [
            "short",  # Too short (< 10 chars)
            "has spaces",  # Contains whitespace
            "has\nnewline",  # Contains newline
            "has\ttab",  # Contains tab
        ]

        for token in invalid_tokens:
            self.validator.errors = []
            result = self.validator.validate_docker_token(token)
            assert result is False, f"Should reject: {token}"
            assert len(self.validator.errors) > 0

    def test_validate_inputs(self):
        """Test the main validate_inputs method."""
        # Test with various token inputs
        inputs = {
            "github-token": "${{ github.token }}",
            "npm-token": "npm_" + "a" * 40,
            "docker-token": "dckr_pat_" + "a" * 20,
        }

        result = self.validator.validate_inputs(inputs)
        assert result is True
        assert len(self.validator.errors) == 0

    def test_validate_inputs_with_invalid_tokens(self):
        """Test validate_inputs with invalid tokens."""
        inputs = {
            "github-token": "invalid-github-token",
            "npm-token": "invalid-npm",
            "docker-token": "short",
        }

        result = self.validator.validate_inputs(inputs)
        assert result is False
        assert len(self.validator.errors) > 0

    def test_get_validation_rules(self):
        """Test that validation rules are properly defined."""
        rules = self.validator.get_validation_rules()
        assert "github_token" in rules
        assert "npm_token" in rules
        assert "docker_token" in rules
        assert "patterns" in rules
        assert rules["patterns"] == self.validator.TOKEN_PATTERNS
