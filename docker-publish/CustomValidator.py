"""Custom validator for docker-publish action.

This validator handles Docker publish-specific validation including:
- Registry validation (dockerhub, github, or both)
- Authentication validation
- Platform validation
- Scanning and signing configuration
"""

from __future__ import annotations

from pathlib import Path
import sys

# Add validate-inputs directory to path to import validators
validate_inputs_path = Path(__file__).parent.parent / "validate-inputs"
sys.path.insert(0, str(validate_inputs_path))

from validators.base import BaseValidator  # noqa: E402
from validators.boolean import BooleanValidator  # noqa: E402
from validators.docker import DockerValidator  # noqa: E402
from validators.token import TokenValidator  # noqa: E402
from validators.version import VersionValidator  # noqa: E402


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
            result = self.docker_validator.validate_architectures(inputs["platforms"], "platforms")
            for error in self.docker_validator.errors:
                if error not in self.errors:
                    self.add_error(error)
            self.docker_validator.clear_errors()
            valid &= result

        # Validate boolean flags
        for bool_input in [
            "nightly",
            "auto-detect-platforms",
            "scan-image",
            "sign-image",
            "verbose",
        ]:
            if inputs.get(bool_input):
                result = self.boolean_validator.validate_optional_boolean(
                    inputs[bool_input], bool_input
                )
                for error in self.boolean_validator.errors:
                    if error not in self.errors:
                        self.add_error(error)
                self.boolean_validator.clear_errors()
                valid &= result

        # Validate cache-mode
        if inputs.get("cache-mode"):
            valid &= self.validate_cache_mode(inputs["cache-mode"])

        # Validate buildx-version
        if inputs.get("buildx-version"):
            valid &= self.validate_buildx_version(inputs["buildx-version"])

        # Validate dockerhub credentials
        if inputs.get("dockerhub-username"):
            valid &= self.validate_username(inputs["dockerhub-username"])

        if inputs.get("dockerhub-password"):
            # Use token validator for password/token
            result = self.token_validator.validate_docker_token(
                inputs["dockerhub-password"], "dockerhub-password"
            )
            for error in self.token_validator.errors:
                if error not in self.errors:
                    self.add_error(error)
            self.token_validator.clear_errors()
            valid &= result

        # Validate github-token
        if inputs.get("github-token"):
            result = self.token_validator.validate_github_token(inputs["github-token"])
            for error in self.token_validator.errors:
                if error not in self.errors:
                    self.add_error(error)
            self.token_validator.clear_errors()
            valid &= result

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
        # Allow GitHub Actions expressions
        if self.is_github_expression(registry):
            return True

        # Valid registry values according to action description
        valid_registries = ["dockerhub", "github", "both"]
        if registry.lower() not in valid_registries:
            self.add_error(
                f"Invalid registry: {registry}. Must be one of: dockerhub, github, or both"
            )
            return False

        return True

    def validate_cache_mode(self, cache_mode: str) -> bool:
        """Validate cache mode.

        Args:
            cache_mode: Cache mode value

        Returns:
            True if valid, False otherwise
        """
        # Allow GitHub Actions expressions
        if self.is_github_expression(cache_mode):
            return True

        # Valid cache modes
        valid_modes = ["min", "max", "inline"]
        if cache_mode.lower() not in valid_modes:
            self.add_error(f"Invalid cache-mode: {cache_mode}. Must be one of: min, max, inline")
            return False

        return True

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
        import re

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
        import re

        if not re.match(r"^[a-z0-9._-]+$", username.lower()):
            self.add_error(f"Invalid Docker Hub username format: {username}")
            return False

        return True
