#!/usr/bin/env python3
"""Custom validator for npm-publish action."""

from __future__ import annotations

from pathlib import Path
import re
import sys

# Add validate-inputs directory to path to import validators
validate_inputs_path = Path(__file__).parent.parent / "validate-inputs"
sys.path.insert(0, str(validate_inputs_path))

from validators.base import BaseValidator
from validators.boolean import BooleanValidator
from validators.file import FileValidator
from validators.network import NetworkValidator
from validators.security import SecurityValidator
from validators.token import TokenValidator
from validators.version import VersionValidator


class CustomValidator(BaseValidator):
    """Custom validator for npm-publish action."""

    def __init__(self, action_type: str = "npm-publish") -> None:
        """Initialize npm-publish validator."""
        super().__init__(action_type)
        self.network_validator = NetworkValidator()
        self.security_validator = SecurityValidator()
        self.token_validator = TokenValidator()
        self.version_validator = VersionValidator()
        self.boolean_validator = BooleanValidator()
        self.file_validator = FileValidator()

    def validate_inputs(self, inputs: dict[str, str]) -> bool:
        """Validate npm-publish action inputs."""
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

        # Validate access
        if inputs.get("access"):
            valid &= self.validate_enum(
                inputs["access"], "access", ["public", "restricted", "private"]
            )

        # Validate boolean inputs (only always-auth and include-merged-tags are strict)
        for field in ["always-auth", "include-merged-tags"]:
            if inputs.get(field):
                valid &= self.validate_with(
                    self.boolean_validator, "validate_boolean", inputs[field], field
                )

        # provenance and dry-run accept any value (npm handles them)
        # No validation needed for these

        # Validate package-version
        if inputs.get("package-version"):
            valid &= self.validate_with(
                self.version_validator,
                "validate_semantic_version",
                inputs["package-version"],
                "package-version",
            )

        # Validate tag
        if inputs.get("tag"):
            tag = inputs["tag"]
            if not self.is_github_expression(tag) and not re.match(
                r"^[a-z0-9][a-z0-9\-_.]*$", tag, re.IGNORECASE
            ):
                self.add_error(
                    "Invalid tag format: must contain only letters, numbers, "
                    "hyphens, dots, and underscores"
                )
                valid = False

        # Validate working-directory and ignore-scripts as file paths
        for field in ["working-directory", "ignore-scripts"]:
            if inputs.get(field):
                valid &= self.validate_with(
                    self.file_validator, "validate_path", inputs[field], field
                )

        return valid

    def _validate_npm_token(self, token: str) -> bool:
        """Validate NPM token format."""
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

    def get_required_inputs(self) -> list[str]:
        """Get list of required inputs."""
        return ["npm_token"]

    def get_validation_rules(self) -> dict:
        """Get validation rules."""
        return self.load_rules(validate_inputs_path / "rules" / "npm-publish.yml")
