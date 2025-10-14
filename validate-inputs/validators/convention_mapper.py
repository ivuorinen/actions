"""Convention mapper for automatic validation detection.

Maps input names to appropriate validators based on naming conventions.
"""

from __future__ import annotations

from typing import TYPE_CHECKING, Any, ClassVar

if TYPE_CHECKING:
    from collections.abc import Callable


class ConventionMapper:
    """Maps input names to validators based on naming conventions."""

    # Priority-ordered convention patterns
    CONVENTION_PATTERNS: ClassVar[list[dict[str, Any]]] = [
        # High priority - exact matches
        {
            "priority": 100,
            "type": "exact",
            "patterns": {
                "email": "email",
                "url": "url",
                "username": "username",
                "password": "password",
                "token": "github_token",
                "github-token": "github_token",
                "npm-token": "npm_token",
                "docker-token": "docker_token",
                "dockerhub-token": "docker_token",
                "registry-token": "registry_token",
                "api-key": "api_key",
                "secret": "secret",
            },
        },
        # Version patterns - specific versions have higher priority
        {
            "priority": 96,  # Highest priority for exact version match
            "type": "exact",
            "patterns": {
                "version": "flexible_version",  # Support both SemVer and CalVer
            },
        },
        {
            "priority": 95,  # Higher priority for specific versions
            "type": "contains",
            "patterns": {
                "python-version": "python_version",
                "node-version": "node_version",
                "go-version": "go_version",
                "php-version": "php_version",
                "dotnet-version": "dotnet_version",
                "terraform-version": "terraform_version",
                "java-version": "java_version",
                "ruby-version": "ruby_version",
            },
        },
        {
            "priority": 90,  # Lower priority for generic version
            "type": "suffix",
            "patterns": {
                "-version": "version",
                "_version": "version",
            },
        },
        # Boolean patterns
        {
            "priority": 80,
            "type": "exact",
            "patterns": {
                "dry-run": "boolean",
                "draft": "boolean",
                "prerelease": "boolean",
                "push": "boolean",
                "force": "boolean",
                "skip": "boolean",
                "enabled": "boolean",
                "disabled": "boolean",
                "verbose": "boolean",
                "debug": "boolean",
                "nightly": "boolean",
                "stable": "boolean",
                "provenance": "boolean",
                "sbom": "boolean",
                "sign": "boolean",
                "scan": "boolean",
            },
        },
        {
            "priority": 80,
            "type": "prefix",
            "patterns": {
                "is-": "boolean",
                "is_": "boolean",
                "has-": "boolean",
                "has_": "boolean",
                "enable-": "boolean",
                "enable_": "boolean",
                "disable-": "boolean",
                "disable_": "boolean",
                "use-": "boolean",
                "use_": "boolean",
                "with-": "boolean",
                "with_": "boolean",
                "without-": "boolean",
                "without_": "boolean",
            },
        },
        {
            "priority": 80,
            "type": "suffix",
            "patterns": {
                "-enabled": "boolean",
                "_enabled": "boolean",
                "-disabled": "boolean",
                "_disabled": "boolean",
            },
        },
        # File patterns
        {
            "priority": 70,
            "type": "suffix",
            "patterns": {
                "-file": "file_path",
                "_file": "file_path",
                "-path": "file_path",
                "_path": "file_path",
                "-dir": "directory",
                "_dir": "directory",
                "-directory": "directory",
                "_directory": "directory",
            },
        },
        {
            "priority": 70,
            "type": "exact",
            "patterns": {
                "dockerfile": "dockerfile",
                "config": "file_path",
                "config-file": "file_path",
                "env-file": "env_file",
                "compose-file": "compose_file",
            },
        },
        # Numeric patterns
        {
            "priority": 60,
            "type": "exact",
            "patterns": {
                "retries": "numeric_1_10",
                "max-retries": "numeric_1_10",
                "attempts": "numeric_1_10",
                "timeout": "timeout",
                "timeout-ms": "timeout_ms",
                "timeout-seconds": "timeout",
                "threads": "numeric_1_128",
                "workers": "numeric_1_128",
                "concurrency": "numeric_1_128",
                "parallel-builds": "numeric_0_16",
                "max-parallel": "numeric_0_16",
                "compression-quality": "numeric_0_100",
                "jpeg-quality": "numeric_0_100",
                "quality": "numeric_0_100",
                "max-warnings": "numeric_0_10000",
                "days-before-stale": "positive_integer",
                "days-before-close": "positive_integer",
                "port": "port",
                "ram": "numeric_256_32768",
                "memory": "numeric_256_32768",
            },
        },
        # Docker patterns
        {
            "priority": 50,
            "type": "exact",
            "patterns": {
                "image": "docker_image",
                "image-name": "docker_image",
                "tag": "docker_tag",
                "tags": "docker_tags",
                "platforms": "docker_architectures",
                "architectures": "docker_architectures",
                "registry": "docker_registry",
                "namespace": "docker_namespace",
                "prefix": "prefix",
                "suffix": "suffix",
                "cache-from": "cache_mode",
                "cache-to": "cache_mode",
                "build-args": "build_args",
                "labels": "labels",
            },
        },
        # Network patterns
        {
            "priority": 40,
            "type": "suffix",
            "patterns": {
                "-url": "url",
                "_url": "url",
                "-endpoint": "url",
                "_endpoint": "url",
                "-webhook": "url",
                "_webhook": "url",
            },
        },
        {
            "priority": 40,
            "type": "exact",
            "patterns": {
                "hostname": "hostname",
                "host": "hostname",
                "server": "hostname",
                "domain": "hostname",
                "ip": "ip_address",
                "ip-address": "ip_address",
            },
        },
    ]

    def __init__(self) -> None:
        """Initialize the convention mapper."""
        self._cache = {}
        self._compile_patterns()

    def _compile_patterns(self) -> None:
        """Compile patterns for efficient matching."""
        # Sort patterns by priority
        self.CONVENTION_PATTERNS.sort(key=lambda x: x["priority"], reverse=True)

    def _normalize_pattern(
        self, normalized: str, pattern_type: str, patterns: dict[str, str]
    ) -> str | None:
        result = None  # Initialize to None for cases where no pattern matches

        if pattern_type == "exact" and normalized in patterns:
            result = patterns[normalized]
        elif pattern_type == "prefix":
            for prefix, validator in patterns.items():
                if normalized.startswith(prefix):
                    result = validator
                    break
        elif pattern_type == "suffix":
            for suffix, validator in patterns.items():
                if normalized.endswith(suffix):
                    result = validator
                    break
        elif pattern_type == "contains":
            for substring, validator in patterns.items():
                if substring in normalized:
                    result = validator
                    break
        return result

    def get_validator_type(
        self,
        input_name: str,
        input_config: dict[str, Any] | None = None,
    ) -> str | None:
        """Get the validator type for an input based on conventions.

        Args:
            input_name: The name of the input
            input_config: Optional configuration for the input

        Returns:
            The validator type or None if no convention matches
        """
        # Check cache
        cache_key = f"{input_name}:{input_config!s}"
        if cache_key in self._cache:
            return self._cache[cache_key]

        result = None

        # Check for explicit validator in config
        if input_config and isinstance(input_config, dict):
            if "validator" in input_config:
                result = input_config["validator"]
            elif "type" in input_config:
                result = input_config["type"]

        # If no explicit validator, try pattern matching
        if result is None:
            # Normalize input name for matching
            normalized = input_name.lower().replace("_", "-")

            # Try each pattern group in priority order
            for pattern_group in self.CONVENTION_PATTERNS:
                if result is not None:
                    break

                pattern_type = pattern_group["type"]
                patterns = pattern_group["patterns"]

                result = self._normalize_pattern(normalized, pattern_type, patterns)

        # Cache and return result
        self._cache[cache_key] = result
        return result

    def get_validator_for_inputs(self, inputs: dict[str, Any]) -> dict[str, str]:
        """Get validators for all inputs based on conventions.

        Args:
            inputs: Dictionary of input names and values

        Returns:
            Dictionary mapping input names to validator types
        """
        validators = {}
        for input_name in inputs:
            validator_type = self.get_validator_type(input_name)
            if validator_type:
                validators[input_name] = validator_type
        return validators

    def clear_cache(self) -> None:
        """Clear the validator cache."""
        self._cache = {}

    def add_custom_pattern(self, pattern: dict[str, Any]) -> None:
        """Add a custom pattern to the convention mapper.

        Args:
            pattern: Pattern dictionary with priority, type, and patterns
        """
        # Note: Modifying ClassVar directly is not ideal, but needed for dynamic configuration
        ConventionMapper.CONVENTION_PATTERNS.append(pattern)
        self._compile_patterns()
        self.clear_cache()

    def remove_pattern(self, pattern_filter: Callable[[dict], bool]) -> None:
        """Remove patterns matching a filter.

        Args:
            pattern_filter: Function that returns True for patterns to remove
        """
        # Note: Modifying ClassVar directly is not ideal, but needed for dynamic configuration
        ConventionMapper.CONVENTION_PATTERNS = [
            p for p in ConventionMapper.CONVENTION_PATTERNS if not pattern_filter(p)
        ]
        self._compile_patterns()
        self.clear_cache()
