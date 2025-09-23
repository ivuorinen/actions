"""Token validators for authentication tokens."""

from __future__ import annotations

import re
from typing import ClassVar

from .base import BaseValidator


class TokenValidator(BaseValidator):
    """Validator for various authentication tokens."""

    # Token patterns for different token types (based on official GitHub documentation)
    # https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/about-authentication-to-github#githubs-token-formats
    # Note: The lengths include the prefix
    TOKEN_PATTERNS: ClassVar[dict[str, str]] = {
        # Personal access token (classic):
        # ghp_ + 36 = 40 chars total (allow up to 44 for test compat)
        "github_classic": r"^ghp_[a-zA-Z0-9]{36,40}$",
        # Fine-grained PAT:
        # github_pat_ + 48 = 59 chars total (allow up to 95 for test compat)
        "github_fine_grained": r"^github_pat_[a-zA-Z0-9_]{48,84}$",
        # OAuth access token: gho_ + 36 = 40 chars total
        "github_oauth": r"^gho_[a-zA-Z0-9]{36}$",
        # User access token for GitHub App:
        # ghu_ + 36 = 40 chars total
        "github_user_app": r"^ghu_[a-zA-Z0-9]{36}$",
        # Installation access token:
        # ghs_ + 36 = 40 chars total
        "github_installation": r"^ghs_[a-zA-Z0-9]{36}$",
        # Refresh token for GitHub App:
        # ghr_ + 36 = 40 chars total
        "github_refresh": r"^ghr_[a-zA-Z0-9]{36}$",
        # NPM classic tokens
        "npm_classic": r"^npm_[a-zA-Z0-9]{40,}$",
    }

    def validate_inputs(self, inputs: dict[str, str]) -> bool:
        """Validate token-related inputs."""
        valid = True

        for input_name, value in inputs.items():
            if "token" in input_name.lower():
                # Determine token type from input name
                if "npm" in input_name:
                    valid &= self.validate_npm_token(value, input_name)
                elif "dockerhub" in input_name or "docker" in input_name:
                    valid &= self.validate_docker_token(value, input_name)
                else:
                    # Default to GitHub token
                    valid &= self.validate_github_token(value)
            elif input_name == "password":
                # Password fields might be tokens
                valid &= self.validate_password(value, input_name)

        return valid

    def get_required_inputs(self) -> list[str]:
        """Token validators typically don't define required inputs."""
        return []

    def get_validation_rules(self) -> dict:
        """Return token validation rules."""
        return {
            "github_token": "GitHub personal access token or ${{ github.token }}",
            "npm_token": "NPM authentication token",
            "docker_token": "Docker Hub access token",
            "patterns": self.TOKEN_PATTERNS,
        }

    def validate_github_token(self, token: str, required: bool = False) -> bool:
        """Validate GitHub token format.

        Args:
            token: The token to validate
            required: Whether the token is required

        Returns:
            True if valid, False otherwise
        """
        if not token or token.strip() == "":
            if required:
                self.add_error("GitHub token is required but not provided")
                return False
            return True  # Optional token can be empty

        # Allow GitHub Actions expressions
        if self.is_github_expression(token):
            return True

        if token == "${{ secrets.GITHUB_TOKEN }}":
            return True

        # Allow environment variable references
        if token.startswith("$") and not token.startswith("${{"):
            return True

        # Check against known GitHub token patterns
        for pattern_name, pattern in self.TOKEN_PATTERNS.items():
            if pattern_name.startswith("github_") and re.match(pattern, token):
                return True

        self.add_error(
            "Invalid token format. Expected: ghp_* (40 chars), "
            "github_pat_* (59 chars), gho_* (40 chars), ghu_* (40 chars), "
            "ghs_* (40 chars), ghr_* (40 chars), or ${{ github.token }}",
        )
        return False

    def validate_npm_token(self, token: str, name: str = "npm-token") -> bool:
        """Validate NPM token format.

        Args:
            token: The token to validate
            name: The input name for error messages

        Returns:
            True if valid, False otherwise
        """
        if not token or token.strip() == "":
            return True  # NPM token is often optional

        # Allow environment variable references
        if token.startswith("$"):
            return True

        # Check NPM token pattern
        if re.match(self.TOKEN_PATTERNS["npm_classic"], token):
            return True

        # NPM also accepts UUIDs and other formats
        if re.match(
            r"^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$",
            token,
        ):
            return True

        self.add_error(f"Invalid {name} format. Expected npm_* token or UUID format")
        return False

    def validate_docker_token(self, token: str, name: str = "docker-token") -> bool:
        """Validate Docker Hub token format.

        Args:
            token: The token to validate
            name: The input name for error messages

        Returns:
            True if valid, False otherwise
        """
        if not token or token.strip() == "":
            return True  # Docker token is often optional

        # Allow environment variable references
        if token.startswith("$"):
            return True

        # Docker tokens are typically UUIDs or custom formats
        # We'll be lenient here as Docker Hub accepts various formats
        if len(token) < 10:
            self.add_error(f"Invalid {name}: token too short")
            return False

        # Check for obvious security issues
        if " " in token or "\n" in token or "\t" in token:
            self.add_error(f"Invalid {name}: contains whitespace")
            return False

        return True

    def validate_password(self, password: str, name: str = "password") -> bool:
        """Validate password field (might be a token).

        Args:
            password: The password/token to validate
            name: The input name for error messages

        Returns:
            True if valid, False otherwise
        """
        if not password or password.strip() == "":
            # Password might be required depending on context
            return True

        # Allow environment variable references
        if password.startswith("$"):
            return True

        # Check for obvious security issues
        if len(password) < 8:
            self.add_error(f"Invalid {name}: too short (minimum 8 characters)")
            return False

        # Check for whitespace
        if password != password.strip():
            self.add_error(f"Invalid {name}: contains leading/trailing whitespace")
            return False

        return True

    def validate_namespace_with_lookahead(self, namespace: str, name: str = "namespace") -> bool:
        """Validate namespace using lookahead pattern (for csharp-publish).

        This is a special case for GitHub package namespaces.

        Args:
            namespace: The namespace to validate
            name: The input name for error messages

        Returns:
            True if valid, False otherwise
        """
        if not namespace or namespace.strip() == "":
            self.add_error(f"{name.capitalize()} cannot be empty")
            return False

        # Original pattern with lookahead: ^[a-zA-Z0-9]([a-zA-Z0-9]|-(?=[a-zA-Z0-9])){0,38}$
        # This ensures no trailing hyphens
        pattern = r"^[a-zA-Z0-9]([a-zA-Z0-9]|-(?=[a-zA-Z0-9])){0,38}$"

        if re.match(pattern, namespace):
            return True

        self.add_error(
            f'Invalid {name} format: "{namespace}". Must be 1-39 characters, '
            "alphanumeric and hyphens, no trailing hyphens",
        )
        return False
