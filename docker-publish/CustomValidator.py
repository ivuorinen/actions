#!/usr/bin/env python3
"""Custom validator for docker-publish action.

This validator handles Docker publish-specific validation including:
- Registry validation (dockerhub, github, or both)
- Authentication validation
- Platform validation
- Scanning and signing configuration
"""

from __future__ import annotations

from pathlib import Path
import re
import sys

# Add validate-inputs directory to path to import validators
validate_inputs_path = Path(__file__).parent.parent / "validate-inputs"
sys.path.insert(0, str(validate_inputs_path))

from validators.base import BaseValidator
from validators.boolean import BooleanValidator
from validators.docker import DockerValidator
from validators.token import TokenValidator
from validators.version import VersionValidator


class CustomValidator(BaseValidator):
    """Custom validator for docker-publish action.

    Validates Docker publishing configuration with registry-specific rules.
    """

    def __init__(self, action_type: str = "docker-publish") -> None:
        """Initialize the docker-publish validator."""
        super().__init__(action_type)
        self.docker_validator = DockerValidator(action_type)
        self.boolean_validator = BooleanValidator(action_type)
        self.token_validator = TokenValidator(action_type)
        self.version_validator = VersionValidator(action_type)

    def validate_inputs(self, inputs: dict[str, str]) -> bool:
        """Validate docker-publish specific inputs.

        Args:
            inputs: Dictionary of input names to values

        Returns:
            True if all validations pass, False otherwise
        """
        valid = True

        # Validate required inputs
        valid &= self.validate_required_inputs(inputs)

        # Validate registry (required)
        if inputs.get("registry"):
            valid &= self.validate_registry(inputs["registry"])

        # Validate platforms
        if inputs.get("platforms"):
            valid &= self.validate_with(
                self.docker_validator, "validate_architectures", inputs["platforms"], "platforms"
            )

        # Validate boolean flags
        for bool_input in [
            "nightly",
            "auto-detect-platforms",
            "scan-image",
            "sign-image",
            "verbose",
        ]:
            if inputs.get(bool_input):
                valid &= self.validate_with(
                    self.boolean_validator,
                    "validate_optional_boolean",
                    inputs[bool_input],
                    bool_input,
                )

        # Validate cache-mode
        if inputs.get("cache-mode"):
            valid &= self.validate_enum(
                inputs["cache-mode"], "cache-mode", ["min", "max", "inline"]
            )

        # Validate buildx-version
        if inputs.get("buildx-version"):
            valid &= self.validate_buildx_version(inputs["buildx-version"])

        # Validate dockerhub credentials
        if inputs.get("dockerhub-username"):
            valid &= self.validate_username(inputs["dockerhub-username"])

        if inputs.get("dockerhub-password"):
            valid &= self.validate_with(
                self.token_validator,
                "validate_docker_token",
                inputs["dockerhub-password"],
                "dockerhub-password",
            )

        # Validate github-token
        if inputs.get("github-token"):
            valid &= self.validate_with(
                self.token_validator, "validate_github_token", inputs["github-token"]
            )

        return valid

    def get_required_inputs(self) -> list[str]:
        """Get list of required inputs for docker-publish.

        Returns:
            List of required input names
        """
        # Registry is required according to action.yml
        return ["registry"]

    def get_validation_rules(self) -> dict:
        """Get validation rules for docker-publish.

        Returns:
            Dictionary of validation rules
        """
        return {
            "registry": "Registry to publish to (dockerhub, github, or both) - required",
            "nightly": "Is this a nightly build? (true/false)",
            "platforms": "Platforms to build for (comma-separated)",
            "auto-detect-platforms": "Auto-detect platforms (true/false)",
            "scan-image": "Scan images for vulnerabilities (true/false)",
            "sign-image": "Sign images with cosign (true/false)",
            "cache-mode": "Cache mode (min, max, or inline)",
            "buildx-version": "Docker Buildx version",
            "verbose": "Enable verbose logging (true/false)",
            "dockerhub-username": "Docker Hub username",
            "dockerhub-password": "Docker Hub password or token",
            "github-token": "GitHub token for ghcr.io",
        }

    def validate_registry(self, registry: str) -> bool:
        """Validate registry input.

        Args:
            registry: Registry value

        Returns:
            True if valid, False otherwise
        """
        return self.validate_enum(registry, "registry", ["dockerhub", "github", "both"])

    def validate_buildx_version(self, version: str) -> bool:
        """Validate buildx version.

        Args:
            version: Buildx version

        Returns:
            True if valid, False otherwise
        """
        # Allow GitHub Actions expressions
        if self.is_github_expression(version):
            return True

        # Allow 'latest'
        if version == "latest":
            return True

        # Check for security issues
        if not self.validate_security_patterns(version, "buildx-version"):
            return False

        # Basic version format validation
        if not re.match(r"^v?\d+\.\d+(\.\d+)?$", version):
            self.add_error(f"Invalid buildx-version format: {version}")
            return False

        return True

    def validate_username(self, username: str) -> bool:
        """Validate Docker Hub username.

        Args:
            username: Username

        Returns:
            True if valid, False otherwise
        """
        # Allow GitHub Actions expressions
        if self.is_github_expression(username):
            return True

        # Check for empty
        if not username or not username.strip():
            self.add_error("Docker Hub username cannot be empty")
            return False

        # Check for security issues
        if not self.validate_security_patterns(username, "dockerhub-username"):
            return False

        # Docker Hub username rules: lowercase letters, digits, periods, hyphens, underscores
        if not re.match(r"^[a-z0-9._-]+$", username.lower()):
            self.add_error(f"Invalid Docker Hub username format: {username}")
            return False

        return True
