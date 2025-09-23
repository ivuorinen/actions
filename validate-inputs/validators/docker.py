"""Docker-specific validators for container-related inputs."""

from __future__ import annotations

import re
from typing import ClassVar

from .base import BaseValidator


class DockerValidator(BaseValidator):
    """Validator for Docker-related inputs."""

    VALID_ARCHITECTURES: ClassVar[list[str]] = [
        "linux/amd64",
        "linux/arm64",
        "linux/arm/v7",
        "linux/arm/v6",
        "linux/386",
        "linux/ppc64le",
        "linux/s390x",
    ]

    CACHE_MODES: ClassVar[list[str]] = ["max", "min", "inline"]

    SBOM_FORMATS: ClassVar[list[str]] = ["spdx-json", "cyclonedx-json"]

    REGISTRY_TYPES: ClassVar[list[str]] = ["dockerhub", "github", "both"]

    def validate_inputs(self, inputs: dict[str, str]) -> bool:
        """Validate Docker-specific inputs."""
        valid = True

        for input_name, value in inputs.items():
            if "image" in input_name and "name" in input_name:
                valid &= self.validate_image_name(value, input_name)
            elif input_name == "tag" or input_name.endswith("-tag"):
                valid &= self.validate_tag(value, input_name)
            elif "architectures" in input_name or "platforms" in input_name:
                valid &= self.validate_architectures(value, input_name)
            elif "cache" in input_name and "mode" in input_name:
                valid &= self.validate_cache_mode(value, input_name)
            elif "sbom" in input_name and "format" in input_name:
                valid &= self.validate_sbom_format(value, input_name)
            elif input_name == "registry":
                valid &= self.validate_registry(value, input_name)

        return valid

    def get_required_inputs(self) -> list[str]:
        """Docker validators typically don't define required inputs."""
        return []

    def get_validation_rules(self) -> dict:
        """Return Docker validation rules."""
        return {
            "image_name": "lowercase, alphanumeric, periods, hyphens, underscores",
            "tag": "semantic version, 'latest', or valid Docker tag",
            "architectures": self.VALID_ARCHITECTURES,
            "cache_mode": self.CACHE_MODES,
            "sbom_format": self.SBOM_FORMATS,
            "registry": self.REGISTRY_TYPES,
        }

    def validate_image_name(self, image_name: str, name: str = "image-name") -> bool:
        """Validate Docker image name format.

        Args:
            image_name: The image name to validate
            name: The input name for error messages

        Returns:
            True if valid, False otherwise
        """
        if not image_name or image_name.strip() == "":
            return True  # Image name is often optional

        # Allow GitHub Actions expressions
        if self.is_github_expression(image_name):
            return True

        # Docker image name pattern (no slashes allowed per docker-build action)
        pattern = r"^[a-z0-9]+([._-][a-z0-9]+)*$"
        if re.match(pattern, image_name):
            return True

        self.add_error(
            f'Invalid {name}: "{image_name}". Must contain only '
            "lowercase letters, digits, periods, hyphens, and underscores",
        )
        return False

    def validate_tag(self, tag: str, name: str = "tag") -> bool:
        """Validate Docker tag format.

        Args:
            tag: The tag to validate
            name: The input name for error messages

        Returns:
            True if valid, False otherwise
        """
        if not tag or tag.strip() == "":
            self.add_error(f"Docker {name} cannot be empty")
            return False

        # Docker tags can be:
        # - image:tag format (e.g., myapp:latest, nginx:1.21)
        # - just a tag (e.g., latest, v1.2.3)
        # - registry/image:tag (e.g., docker.io/library/nginx:latest)

        # Allow GitHub Actions expressions
        if self.is_github_expression(tag):
            return True

        # Very permissive Docker tag pattern
        # Docker tags can contain letters, digits, periods, dashes, underscores, colons, and slashes
        pattern = r"^[a-zA-Z0-9][-a-zA-Z0-9._:/@]*[a-zA-Z0-9]$"
        if re.match(pattern, tag) or tag in ["latest"]:
            return True

        self.add_error(f'Invalid {name}: "{tag}". Must be a valid Docker tag')
        return False

    def validate_architectures(self, architectures: str, name: str = "architectures") -> bool:
        """Validate Docker architectures/platforms.

        Args:
            architectures: Comma-separated list of architectures
            name: The input name for error messages

        Returns:
            True if valid, False otherwise
        """
        if not architectures or architectures.strip() == "":
            return True  # Often optional

        archs = [arch.strip() for arch in architectures.split(",")]

        for arch in archs:
            if arch not in self.VALID_ARCHITECTURES:
                self.add_error(
                    f'Invalid {name}: "{arch}". Supported: {", ".join(self.VALID_ARCHITECTURES)}',
                )
                return False

        return True

    def validate_cache_mode(self, value: str, name: str = "cache-mode") -> bool:
        """Validate Docker cache mode values.

        Args:
            value: The cache mode value
            name: The input name for error messages

        Returns:
            True if valid, False otherwise
        """
        if not value or value.strip() == "":
            return True  # Cache mode is optional

        if value in self.CACHE_MODES:
            return True

        self.add_error(f'Invalid {name}: "{value}". Must be one of: {", ".join(self.CACHE_MODES)}')
        return False

    def validate_sbom_format(self, value: str, name: str = "sbom-format") -> bool:
        """Validate SBOM (Software Bill of Materials) format values.

        Args:
            value: The SBOM format value
            name: The input name for error messages

        Returns:
            True if valid, False otherwise
        """
        if not value or value.strip() == "":
            return True  # SBOM format is optional

        if value in self.SBOM_FORMATS:
            return True

        self.add_error(f'Invalid {name}: "{value}". Must be one of: {", ".join(self.SBOM_FORMATS)}')
        return False

    def validate_registry(self, value: str, name: str = "registry") -> bool:
        """Validate registry enum values for docker-publish.

        Args:
            value: The registry value
            name: The input name for error messages

        Returns:
            True if valid, False otherwise
        """
        if not value or value.strip() == "":
            self.add_error(f"Registry is required and cannot be empty in {name}")
            return False

        if value in self.REGISTRY_TYPES:
            return True

        self.add_error(
            f'Invalid {name}: "{value}". Must be one of: {", ".join(self.REGISTRY_TYPES)}',
        )
        return False

    def validate_namespace_with_lookahead(self, namespace: str, name: str = "namespace") -> bool:
        """Validate Docker namespace/organization name.

        Args:
            namespace: The namespace to validate
            name: The input name for error messages

        Returns:
            True if valid, False otherwise
        """
        if not namespace or namespace.strip() == "":
            return True  # Empty namespace is often valid

        # Namespace must be lowercase, can contain hyphens but not at start/end
        # No double hyphens allowed, max length 255
        if len(namespace) > 255:
            self.add_error(f'Invalid {name}: "{namespace}". Too long (max 255 characters)')
            return False

        # Check for invalid patterns
        if namespace.startswith("-") or namespace.endswith("-"):
            self.add_error(f'Invalid {name}: "{namespace}". Cannot start or end with hyphen')
            return False

        if "--" in namespace:
            self.add_error(f'Invalid {name}: "{namespace}". Cannot contain double hyphens')
            return False

        if " " in namespace:
            self.add_error(f'Invalid {name}: "{namespace}". Cannot contain spaces')
            return False

        # Must be lowercase alphanumeric with hyphens
        pattern = r"^[a-z0-9]+(?:-[a-z0-9]+)*$"
        if re.match(pattern, namespace):
            return True

        self.add_error(
            f'Invalid {name}: "{namespace}". Must contain only '
            "lowercase letters, digits, and hyphens (not at start/end)",
        )
        return False

    def validate_prefix(self, prefix: str, name: str = "prefix") -> bool:
        """Validate Docker tag prefix.

        Args:
            prefix: The prefix to validate
            name: The input name for error messages

        Returns:
            True if valid, False otherwise
        """
        # Empty prefix is valid
        if not prefix:
            return True

        # Prefix cannot contain spaces or special characters like @, #, :
        invalid_chars = [" ", "@", "#", ":"]
        for char in invalid_chars:
            if char in prefix:
                self.add_error(f'Invalid {name}: "{prefix}". Cannot contain "{char}" character')
                return False

        # Valid prefix contains alphanumeric, dots, dashes, underscores
        pattern = r"^[a-zA-Z0-9._-]+$"
        if re.match(pattern, prefix):
            return True

        self.add_error(
            f'Invalid {name}: "{prefix}". Must contain only '
            "letters, digits, periods, hyphens, and underscores",
        )
        return False

    # Convenience methods for direct access
    def validate_docker_image_name(self, value: str, name: str = "image-name") -> bool:
        """Alias for validate_image_name for convention compatibility."""
        return self.validate_image_name(value, name)

    def validate_docker_tag(self, value: str, name: str = "tag") -> bool:
        """Alias for validate_tag for convention compatibility."""
        return self.validate_tag(value, name)

    def validate_docker_architectures(self, value: str, name: str = "architectures") -> bool:
        """Alias for validate_architectures for convention compatibility."""
        return self.validate_architectures(value, name)
