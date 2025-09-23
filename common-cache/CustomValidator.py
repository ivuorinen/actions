"""Custom validator for common-cache action.

This validator handles caching-specific validation including:
- Cache types (npm, composer, go, pip, maven, gradle)
- Cache paths (comma-separated list)
- Cache keys and restore keys
- Path validation with special handling for multiple paths
"""

from __future__ import annotations

from pathlib import Path
import sys

# Add validate-inputs directory to path to import validators
validate_inputs_path = Path(__file__).parent.parent / "validate-inputs"
sys.path.insert(0, str(validate_inputs_path))

from validators.base import BaseValidator  # noqa: E402
from validators.file import FileValidator  # noqa: E402


class CustomValidator(BaseValidator):
    """Custom validator for common-cache action.

    Provides validation for cache configuration.
    """

    def __init__(self, action_type: str = "common-cache") -> None:
        """Initialize the common-cache validator."""
        super().__init__(action_type)
        self.file_validator = FileValidator(action_type)

    def validate_inputs(self, inputs: dict[str, str]) -> bool:
        """Validate common-cache specific inputs.

        Args:
            inputs: Dictionary of input names to values

        Returns:
            True if all validations pass, False otherwise
        """
        valid = True

        # Validate type (required)
        if "type" in inputs:
            valid &= self.validate_cache_type(inputs["type"])
        else:
            # Type is required
            self.add_error("Cache type is required")
            valid = False

        # Validate paths (required)
        if "paths" in inputs:
            valid &= self.validate_cache_paths(inputs["paths"])
        else:
            # Paths is required
            self.add_error("Cache paths are required")
            valid = False

        # Validate key-prefix (optional)
        if inputs.get("key-prefix"):
            valid &= self.validate_key_prefix(inputs["key-prefix"])

        # Validate key-files (optional)
        if inputs.get("key-files"):
            valid &= self.validate_key_files(inputs["key-files"])

        # Validate restore-keys (optional)
        if inputs.get("restore-keys"):
            valid &= self.validate_restore_keys(inputs["restore-keys"])

        # Validate env-vars (optional)
        if inputs.get("env-vars"):
            valid &= self.validate_env_vars(inputs["env-vars"])

        return valid

    def get_required_inputs(self) -> list[str]:
        """Get list of required inputs for common-cache.

        Returns:
            List of required input names
        """
        return ["type", "paths"]

    def get_validation_rules(self) -> dict:
        """Get validation rules for common-cache.

        Returns:
            Dictionary of validation rules
        """
        return {
            "type": "Cache type (npm, composer, go, pip, maven, gradle)",
            "paths": "Comma-separated list of paths to cache",
            "key-prefix": "Optional prefix for cache key",
            "key-files": "Files to include in cache key hash",
            "restore-keys": "Fallback cache keys to try",
        }

    def validate_cache_type(self, cache_type: str) -> bool:
        """Validate cache type.

        Args:
            cache_type: Type of cache

        Returns:
            True if valid, False otherwise
        """
        # Check for empty
        if not cache_type or not cache_type.strip():
            self.add_error("Cache type cannot be empty")
            return False

        # Allow GitHub Actions expressions
        if self.is_github_expression(cache_type):
            return True

        # Note: The test says "accepts invalid cache type (no validation in action)"
        # This suggests we should accept any value, not just the supported ones
        # So we'll just validate for security issues, not restrict to specific types

        # Check for command injection using base validator
        return self.validate_security_patterns(cache_type, "cache type")

    def validate_cache_paths(self, paths: str) -> bool:
        """Validate cache paths (comma-separated).

        Args:
            paths: Comma-separated paths

        Returns:
            True if valid, False otherwise
        """
        # Check for empty
        if not paths or not paths.strip():
            self.add_error("Cache paths cannot be empty")
            return False

        # Allow GitHub Actions expressions
        if self.is_github_expression(paths):
            return True

        # Split paths and validate each
        path_list = [p.strip() for p in paths.split(",")]

        for path in path_list:
            if not path:
                continue

            # Use FileValidator for path validation
            result = self.file_validator.validate_file_path(path, "paths")
            # Propagate errors from file validator
            for error in self.file_validator.errors:
                if error not in self.errors:
                    self.add_error(error)
            self.file_validator.clear_errors()

            if not result:
                return False

        return True

    def validate_key_prefix(self, key_prefix: str) -> bool:
        """Validate cache key prefix.

        Args:
            key_prefix: Key prefix

        Returns:
            True if valid, False otherwise
        """
        # Allow GitHub Actions expressions
        if self.is_github_expression(key_prefix):
            return True

        # Check for command injection using base validator
        return self.validate_security_patterns(key_prefix, "key-prefix")

    def validate_key_files(self, key_files: str) -> bool:
        """Validate key files (comma-separated).

        Args:
            key_files: Comma-separated file paths

        Returns:
            True if valid, False otherwise
        """
        # Allow GitHub Actions expressions
        if self.is_github_expression(key_files):
            return True

        # Split files and validate each
        file_list = [f.strip() for f in key_files.split(",")]

        for file_path in file_list:
            if not file_path:
                continue

            # Use FileValidator for path validation
            result = self.file_validator.validate_file_path(file_path, "key-files")
            # Propagate errors from file validator
            for error in self.file_validator.errors:
                if error not in self.errors:
                    self.add_error(error)
            self.file_validator.clear_errors()

            if not result:
                return False

        return True

    def validate_restore_keys(self, restore_keys: str) -> bool:
        """Validate restore keys.

        Args:
            restore_keys: Restore keys specification

        Returns:
            True if valid, False otherwise
        """
        # Allow GitHub Actions expressions
        if self.is_github_expression(restore_keys):
            return True

        # Check for command injection using base validator
        return self.validate_security_patterns(restore_keys, "restore-keys")

    def validate_env_vars(self, env_vars: str) -> bool:
        """Validate environment variables.

        Args:
            env_vars: Environment variables specification

        Returns:
            True if valid, False otherwise
        """
        # Allow GitHub Actions expressions
        if self.is_github_expression(env_vars):
            return True

        # Check for command injection using base validator
        return self.validate_security_patterns(env_vars, "env-vars")
