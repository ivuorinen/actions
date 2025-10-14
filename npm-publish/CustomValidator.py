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
            token = inputs["npm_token"]
            # Check for NPM classic token format first
            if token.startswith("npm_"):
                # NPM classic token format: npm_ followed by 36+ alphanumeric characters
                if not re.match(r"^npm_[a-zA-Z0-9]{36,}$", token):
                    self.add_error("Invalid NPM token format")
                    valid = False
                # Also check for injection
                result = self.security_validator.validate_no_injection(token, "npm_token")
                for error in self.security_validator.errors:
                    if error not in self.errors:
                        self.add_error(error)
                self.security_validator.clear_errors()
                if not result:
                    valid = False
            else:
                # Otherwise validate as GitHub token
                result = self.token_validator.validate_github_token(token, required=True)
                for error in self.token_validator.errors:
                    if error not in self.errors:
                        self.add_error(error)
                self.token_validator.clear_errors()
                if not result:
                    valid = False

        # Validate registry-url
        if inputs.get("registry-url"):
            url = inputs["registry-url"]
            if not self.is_github_expression(url):
                # Must be http or https URL
                if not url.startswith(("http://", "https://")):
                    self.add_error("Registry URL must use http or https protocol")
                    valid = False
                else:
                    # Validate URL format
                    result = self.network_validator.validate_url(url, "registry-url")
                    for error in self.network_validator.errors:
                        if error not in self.errors:
                            self.add_error(error)
                    self.network_validator.clear_errors()
                    if not result:
                        valid = False

        # Validate scope
        if inputs.get("scope"):
            scope = inputs["scope"]
            if not self.is_github_expression(scope):
                # Scope must start with @ and contain only valid characters
                if not scope.startswith("@"):
                    self.add_error("Scope must start with @ symbol")
                    valid = False
                elif not re.match(r"^@[a-z0-9][a-z0-9\-_.]*$", scope):
                    self.add_error(
                        "Invalid scope format: must be @org-name with lowercase "
                        "letters, numbers, hyphens, dots, and underscores"
                    )
                    valid = False

                # Check for injection
                result = self.security_validator.validate_no_injection(scope, "scope")
                for error in self.security_validator.errors:
                    if error not in self.errors:
                        self.add_error(error)
                self.security_validator.clear_errors()
                if not result:
                    valid = False

        # Validate access
        if inputs.get("access"):
            access = inputs["access"]
            if not self.is_github_expression(access):
                valid_access = ["public", "restricted", "private"]
                if access and access not in valid_access:
                    self.add_error(
                        f"Invalid access level: {access}. Must be one of: {', '.join(valid_access)}"
                    )
                    valid = False

        # Validate boolean inputs (only always-auth and include-merged-tags are strict)
        for field in ["always-auth", "include-merged-tags"]:
            if inputs.get(field):
                result = self.boolean_validator.validate_boolean(inputs[field], field)
                for error in self.boolean_validator.errors:
                    if error not in self.errors:
                        self.add_error(error)
                self.boolean_validator.clear_errors()
                if not result:
                    valid = False

        # provenance and dry-run accept any value (npm handles them)
        # No validation needed for these

        # Validate package-version
        if inputs.get("package-version"):
            result = self.version_validator.validate_semantic_version(
                inputs["package-version"], "package-version"
            )
            for error in self.version_validator.errors:
                if error not in self.errors:
                    self.add_error(error)
            self.version_validator.clear_errors()
            if not result:
                valid = False

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
                result = self.file_validator.validate_path(inputs[field], field)
                for error in self.file_validator.errors:
                    if error not in self.errors:
                        self.add_error(error)
                self.file_validator.clear_errors()
                if not result:
                    valid = False

        return valid

    def get_required_inputs(self) -> list[str]:
        """Get list of required inputs."""
        return ["npm_token"]

    def get_validation_rules(self) -> dict:
        """Get validation rules."""
        return self.load_rules(validate_inputs_path / "rules" / "npm-publish.yml")
