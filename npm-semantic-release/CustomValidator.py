#!/usr/bin/env python3
"""Custom validator for npm-semantic-release action."""

from __future__ import annotations

from pathlib import Path
import re
import sys

# Add validate-inputs directory to path to import validators
validate_inputs_path = Path(__file__).parent.parent / "validate-inputs"
sys.path.insert(0, str(validate_inputs_path))

from validators.base import BaseValidator
from validators.network import NetworkValidator
from validators.security import SecurityValidator
from validators.token import TokenValidator


class CustomValidator(BaseValidator):
    """Custom validator for npm-semantic-release action."""

    def __init__(self, action_type: str = "npm-semantic-release") -> None:
        """Initialize npm-semantic-release validator."""
        super().__init__(action_type)
        self.network_validator = NetworkValidator()
        self.security_validator = SecurityValidator()
        self.token_validator = TokenValidator()

    def validate_inputs(self, inputs: dict[str, str]) -> bool:
        """Validate npm-semantic-release action inputs."""
        valid = True

        # Validate required input: npm_token
        if "npm_token" not in inputs or not inputs["npm_token"]:
            self.add_error("Input 'npm_token' is required")
            valid = False
        elif inputs["npm_token"]:
            valid &= self._validate_npm_token(inputs["npm_token"])

        # Validate registry-url
        if inputs.get("registry-url"):
            valid &= self._validate_registry_url(inputs["registry-url"])

        # Validate scope
        if inputs.get("scope"):
            valid &= self._validate_scope(inputs["scope"])

        # Validate extra_plugins
        if inputs.get("extra_plugins"):
            valid &= self._validate_extra_plugins(inputs["extra_plugins"])

        return valid

    def _validate_npm_token(self, token: str) -> bool:
        """Validate NPM token format.

        Accepts either:
        - NPM classic tokens (npm_ prefix with 36+ alphanumeric chars)
        - GitHub tokens (for GitHub Packages publishing)
        """
        # Check for NPM classic token format first
        if token.startswith("npm_"):
            # NPM classic token format: npm_ followed by 36+ alphanumeric characters
            if not re.match(r"^npm_[a-zA-Z0-9]{36,}$", token):
                self.add_error("Invalid NPM token format")
                return False
            # Also check for injection
            return self.validate_with(
                self.security_validator, "validate_no_injection", token, "npm_token"
            )
        # Otherwise validate as GitHub token
        return self.validate_with(
            self.token_validator, "validate_github_token", token, required=True
        )

    def _validate_registry_url(self, url: str) -> bool:
        """Validate registry URL format."""
        if self.is_github_expression(url):
            return True
        # Must be http or https URL
        if not url.startswith(("http://", "https://")):
            self.add_error("Registry URL must use http or https protocol")
            return False
        # Validate URL format
        return self.validate_with(self.network_validator, "validate_url", url, "registry-url")

    def _validate_scope(self, scope: str) -> bool:
        """Validate NPM scope format."""
        if self.is_github_expression(scope):
            return True
        # Scope must start with @ and contain only valid characters
        if not scope.startswith("@"):
            self.add_error("Scope must start with @ symbol")
            return False
        if not re.match(r"^@[a-z0-9][a-z0-9\-_.]*$", scope):
            self.add_error(
                "Invalid scope format: must be @org-name with lowercase "
                "letters, numbers, hyphens, dots, and underscores"
            )
            return False
        # Check for injection
        return self.validate_with(self.security_validator, "validate_no_injection", scope, "scope")

    def _validate_extra_plugins(self, plugins: str) -> bool:
        """Validate extra_plugins format."""
        if self.is_github_expression(plugins):
            return True
        # Check for injection patterns
        return self.validate_with(
            self.security_validator, "validate_no_injection", plugins, "extra_plugins"
        )

    def get_required_inputs(self) -> list[str]:
        """Get list of required inputs."""
        return ["npm_token"]

    def get_validation_rules(self) -> dict:
        """Get validation rules."""
        return self.load_rules(Path(__file__).parent / "rules.yml")
