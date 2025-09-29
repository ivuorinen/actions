#!/usr/bin/env python3
"""Custom validator for docker-build action.

This validator handles complex Docker build validation including:
- Dockerfile path validation
- Build context validation
- Platform validation (linux/amd64, linux/arm64, etc.)
- Build argument format validation
- Tag format validation
"""

from __future__ import annotations

from pathlib import Path
import sys

# Add validate-inputs directory to path to import validators
validate_inputs_path = Path(__file__).parent.parent / "validate-inputs"
sys.path.insert(0, str(validate_inputs_path))

from validators.base import BaseValidator
from validators.boolean import BooleanValidator
from validators.docker import DockerValidator
from validators.file import FileValidator
from validators.numeric import NumericValidator
from validators.version import VersionValidator


class CustomValidator(BaseValidator):
    """Custom validator for docker-build action.

    Validates Docker build-specific inputs with complex rules.
    """

    def __init__(self, action_type: str = "docker-build") -> None:
        """Initialize the docker-build validator."""
        super().__init__(action_type)
        self.docker_validator = DockerValidator(action_type)
        self.file_validator = FileValidator(action_type)
        self.boolean_validator = BooleanValidator(action_type)
        self.numeric_validator = NumericValidator(action_type)
        self.version_validator = VersionValidator(action_type)

    def validate_inputs(self, inputs: dict[str, str]) -> bool:
        """Validate docker-build specific inputs.

        Args:
            inputs: Dictionary of input names to values

        Returns:
            True if all validations pass, False otherwise
        """
        valid = True

        # Validate required inputs
        valid &= self.validate_required_inputs(inputs)

        # Validate dockerfile path
        if inputs.get("dockerfile"):
            valid &= self.validate_dockerfile(inputs["dockerfile"])

        # Validate context path
        if inputs.get("context"):
            valid &= self.validate_context(inputs["context"])

        # Validate image name
        if inputs.get("image-name"):
            result = self.docker_validator.validate_image_name(inputs["image-name"], "image-name")
            # Propagate errors from docker validator
            for error in self.docker_validator.errors:
                if error not in self.errors:
                    self.add_error(error)
            self.docker_validator.clear_errors()
            valid &= result

        # Validate tag (singular - as per action.yml)
        if inputs.get("tag"):
            result = self.docker_validator.validate_docker_tag(inputs["tag"], "tag")
            # Propagate errors
            for error in self.docker_validator.errors:
                if error not in self.errors:
                    self.add_error(error)
            self.docker_validator.clear_errors()
            valid &= result

        # Validate architectures/platforms
        if inputs.get("architectures"):
            result = self.docker_validator.validate_architectures(
                inputs["architectures"], "architectures"
            )
            # Propagate errors
            for error in self.docker_validator.errors:
                if error not in self.errors:
                    self.add_error(error)
            self.docker_validator.clear_errors()
            valid &= result

        # Validate build arguments
        if inputs.get("build-args"):
            valid &= self.validate_build_args(inputs["build-args"])

        # Validate push flag
        if inputs.get("push"):
            result = self.boolean_validator.validate_optional_boolean(inputs["push"], "push")
            for error in self.boolean_validator.errors:
                if error not in self.errors:
                    self.add_error(error)
            self.boolean_validator.clear_errors()
            valid &= result

        # Validate cache settings
        if inputs.get("cache-from"):
            valid &= self.validate_cache_from(inputs["cache-from"])

        if inputs.get("cache-to"):
            valid &= self.validate_cache_to(inputs["cache-to"])

        # Validate cache-mode
        if inputs.get("cache-mode"):
            valid &= self.validate_cache_mode(inputs["cache-mode"])

        # Validate buildx-version
        if inputs.get("buildx-version"):
            valid &= self.validate_buildx_version(inputs["buildx-version"])

        # Validate parallel-builds
        if inputs.get("parallel-builds"):
            result = self.numeric_validator.validate_numeric_range(
                inputs["parallel-builds"], min_val=0, max_val=16, name="parallel-builds"
            )
            for error in self.numeric_validator.errors:
                if error not in self.errors:
                    self.add_error(error)
            self.numeric_validator.clear_errors()
            valid &= result

        # Validate boolean flags
        for bool_input in [
            "dry-run",
            "verbose",
            "platform-fallback",
            "scan-image",
            "sign-image",
            "auto-detect-platforms",
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

        # Validate sbom-format
        if inputs.get("sbom-format"):
            valid &= self.validate_sbom_format(inputs["sbom-format"])

        # Validate max-retries
        if inputs.get("max-retries"):
            result = self.numeric_validator.validate_numeric_range(
                inputs["max-retries"], min_val=0, max_val=10, name="max-retries"
            )
            for error in self.numeric_validator.errors:
                if error not in self.errors:
                    self.add_error(error)
            self.numeric_validator.clear_errors()
            valid &= result

        return valid

    def get_required_inputs(self) -> list[str]:
        """Get list of required inputs for docker-build.

        Returns:
            List of required input names
        """
        # Tag is the only required input according to action.yml
        return ["tag"]

    def get_validation_rules(self) -> dict:
        """Get validation rules for docker-build.

        Returns:
            Dictionary of validation rules
        """
        return {
            "dockerfile": "Path to Dockerfile (default: ./Dockerfile)",
            "context": "Build context path (default: .)",
            "tag": "Docker image tag (required)",
            "architectures": "Comma-separated list of platforms",
            "build-args": "Build arguments in KEY=value format",
            "push": "Whether to push the image (true/false)",
            "cache-from": "Cache sources",
            "cache-to": "Cache destinations",
            "cache-mode": "Cache mode (min, max, or inline)",
            "buildx-version": "Docker Buildx version",
            "sbom-format": "SBOM format (spdx-json, cyclonedx-json, or syft-json)",
            "parallel-builds": "Number of parallel builds (0-16)",
        }

    def validate_dockerfile(self, dockerfile: str) -> bool:
        """Validate Dockerfile path.

        Args:
            dockerfile: Path to Dockerfile

        Returns:
            True if valid, False otherwise
        """
        # Allow GitHub Actions expressions
        if self.is_github_expression(dockerfile):
            return True

        # Use file validator for path validation
        result = self.file_validator.validate_file_path(dockerfile, "dockerfile")
        # Propagate errors
        for error in self.file_validator.errors:
            if error not in self.errors:
                self.add_error(error)
        self.file_validator.clear_errors()

        return result

    def validate_context(self, context: str) -> bool:
        """Validate build context path.

        Args:
            context: Build context path

        Returns:
            True if valid, False otherwise
        """
        # Allow GitHub Actions expressions
        if self.is_github_expression(context):
            return True

        # Allow current directory
        if context in [".", "./", ""]:
            return True

        # Note: The test says "accepts path traversal in context (no validation in action)"
        # This means we should NOT validate for path traversal in context
        # We allow path traversal for context as Docker needs to access parent directories
        # Only check for command injection patterns like ; | ` $()
        dangerous_chars = [";", "|", "`", "$(", "&&", "||"]
        for char in dangerous_chars:
            if char in context:
                self.add_error(f"Command injection detected in context: {context}")
                return False

        return True

    def validate_platforms(self, platforms: str) -> bool:
        """Validate platform list.

        Args:
            platforms: Comma-separated platform list

        Returns:
            True if valid, False otherwise
        """
        # Use docker validator for architectures
        result = self.docker_validator.validate_architectures(platforms, "platforms")
        # Propagate errors
        for error in self.docker_validator.errors:
            if error not in self.errors:
                self.add_error(error)
        self.docker_validator.clear_errors()

        return result

    def validate_build_args(self, build_args: str) -> bool:
        """Validate build arguments.

        Args:
            build_args: Build arguments in KEY=value format

        Returns:
            True if valid, False otherwise
        """
        # Allow GitHub Actions expressions
        if self.is_github_expression(build_args):
            return True

        # Build args can be comma-separated or newline-separated
        # Split by both
        args = build_args.replace(",", "\n").strip().split("\n")

        for arg in args:
            arg = arg.strip()
            if not arg:
                continue

            # Check for KEY=value format
            if "=" not in arg:
                self.add_error(f"Build argument must be in KEY=value format: {arg}")
                return False

            key, value = arg.split("=", 1)

            # Validate key format
            if not key:
                self.add_error("Build argument key cannot be empty")
                return False

            # Check for security issues in values
            if not self.validate_security_patterns(value, f"build-arg {key}"):
                return False

        return True

    def validate_cache_from(self, cache_from: str) -> bool:
        """Validate cache-from sources.

        Args:
            cache_from: Cache sources

        Returns:
            True if valid, False otherwise
        """
        # Allow GitHub Actions expressions
        if self.is_github_expression(cache_from):
            return True

        # Basic format validation for cache sources
        # Format: type=registry,ref=user/app:cache
        if "type=" not in cache_from:
            self.add_error("cache-from must specify type (e.g., type=registry,ref=...)")
            return False

        # Check for security issues
        return self.validate_security_patterns(cache_from, "cache-from")

    def validate_cache_to(self, cache_to: str) -> bool:
        """Validate cache-to destinations.

        Args:
            cache_to: Cache destinations

        Returns:
            True if valid, False otherwise
        """
        # Allow GitHub Actions expressions
        if self.is_github_expression(cache_to):
            return True

        # Basic format validation for cache destinations
        if "type=" not in cache_to:
            self.add_error("cache-to must specify type (e.g., type=registry,ref=...)")
            return False

        # Check for security issues
        return self.validate_security_patterns(cache_to, "cache-to")

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

        # Check for security issues (semicolon injection etc)
        if not self.validate_security_patterns(version, "buildx-version"):
            return False

        # Basic version format validation (e.g., 0.12.0, v0.12.0)
        import re

        if not re.match(r"^v?\d+\.\d+(\.\d+)?$", version):
            self.add_error(f"Invalid buildx-version format: {version}")
            return False

        return True

    def validate_sbom_format(self, sbom_format: str) -> bool:
        """Validate SBOM format.

        Args:
            sbom_format: SBOM format value

        Returns:
            True if valid, False otherwise
        """
        # Allow GitHub Actions expressions
        if self.is_github_expression(sbom_format):
            return True

        # Valid SBOM formats
        valid_formats = ["spdx-json", "cyclonedx-json", "syft-json"]
        if sbom_format.lower() not in valid_formats:
            self.add_error(
                f"Invalid sbom-format: {sbom_format}. "
                "Must be one of: spdx-json, cyclonedx-json, syft-json"
            )
            return False

        return True
