#!/usr/bin/env python3
"""Custom validator for php-composer action."""

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
from validators.numeric import NumericValidator
from validators.security import SecurityValidator
from validators.token import TokenValidator
from validators.version import VersionValidator


class CustomValidator(BaseValidator):
    """Custom validator for php-composer action."""

    def __init__(self, action_type: str = "php-composer") -> None:
        """Initialize php-composer validator."""
        super().__init__(action_type)
        self.boolean_validator = BooleanValidator()
        self.file_validator = FileValidator()
        self.numeric_validator = NumericValidator()
        self.security_validator = SecurityValidator()
        self.token_validator = TokenValidator()
        self.version_validator = VersionValidator()

    def validate_inputs(self, inputs: dict[str, str]) -> bool:
        """Validate php-composer action inputs."""
        valid = True

        # Validate required input: php
        if "php" not in inputs or not inputs["php"]:
            self.add_error("Input 'php' is required")
            valid = False
        elif inputs["php"]:
            php_version = inputs["php"]
            if not self.is_github_expression(php_version):
                # PHP version validation with minimum version check
                result = self.version_validator.validate_php_version(php_version, "php")
                for error in self.version_validator.errors:
                    if error not in self.errors:
                        self.add_error(error)
                self.version_validator.clear_errors()
                if not result:
                    valid = False
                elif php_version and not php_version.startswith("$"):
                    # Additional check for minimum PHP version (7.0)
                    try:
                        parts = php_version.split(".")
                        major = int(parts[0])
                        minor = int(parts[1]) if len(parts) > 1 else 0
                        if major < 7 or (major == 7 and minor < 0):
                            self.add_error("PHP version must be 7.0 or higher")
                            valid = False
                    except (ValueError, IndexError):
                        pass  # Already handled by validate_php_version

        # Validate extensions (empty string is invalid)
        if "extensions" in inputs:
            extensions = inputs["extensions"]
            if extensions == "":
                self.add_error("Extensions cannot be empty string")
                valid = False
            elif extensions:
                if not self.is_github_expression(extensions):
                    # Extensions should be comma-separated list (spaces allowed after commas)
                    if not re.match(r"^[a-zA-Z0-9_-]+(\s*,\s*[a-zA-Z0-9_-]+)*$", extensions):
                        self.add_error("Invalid extensions format: must be comma-separated list")
                        valid = False

                    # Check for injection
                    result = self.security_validator.validate_no_injection(extensions, "extensions")
                    for error in self.security_validator.errors:
                        if error not in self.errors:
                            self.add_error(error)
                    self.security_validator.clear_errors()
                    if not result:
                        valid = False

        # Validate tools (empty string is invalid)
        if "tools" in inputs:
            tools = inputs["tools"]
            if tools == "":
                self.add_error("Tools cannot be empty string")
                valid = False
            elif tools:
                if not self.is_github_expression(tools):
                    # Tools should be comma-separated list with optional version constraints
                    # Allow: letters, numbers, dash, underscore, colon, dot, caret, tilde,
                    # spaces after commas
                    if not re.match(r"^[a-zA-Z0-9_:.\-^~]+(\s*,\s*[a-zA-Z0-9_:.\-^~]+)*$", tools):
                        self.add_error("Invalid tools format: must be comma-separated list")
                        valid = False

                    # Check for injection
                    result = self.security_validator.validate_no_injection(tools, "tools")
                    for error in self.security_validator.errors:
                        if error not in self.errors:
                            self.add_error(error)
                    self.security_validator.clear_errors()
                    if not result:
                        valid = False

        # Validate composer-version (empty string is invalid, only 1 or 2 accepted)
        if "composer-version" in inputs:
            composer_version = inputs["composer-version"]
            if composer_version == "":
                self.add_error("Composer version cannot be empty string")
                valid = False
            elif composer_version:
                if not self.is_github_expression(composer_version) and composer_version not in [
                    "1",
                    "2",
                ]:
                    self.add_error("Composer version must be 1 or 2")
                    valid = False

        # Validate stability
        if inputs.get("stability"):
            stability = inputs["stability"]
            if not self.is_github_expression(stability):
                valid_stabilities = ["stable", "RC", "beta", "alpha", "dev", "snapshot"]
                if stability not in valid_stabilities:
                    self.add_error(
                        f"Invalid stability: {stability}. "
                        f"Must be one of: {', '.join(valid_stabilities)}"
                    )
                    valid = False

                # Check for injection
                result = self.security_validator.validate_no_injection(stability, "stability")
                for error in self.security_validator.errors:
                    if error not in self.errors:
                        self.add_error(error)
                self.security_validator.clear_errors()
                if not result:
                    valid = False

        # Validate cache-directories (empty string is invalid, accepts directory paths)
        if "cache-directories" in inputs:
            cache_dirs = inputs["cache-directories"]
            if cache_dirs == "":
                self.add_error("Cache directories cannot be empty string")
                valid = False
            elif cache_dirs:
                if not self.is_github_expression(cache_dirs):
                    # Should be comma-separated list of directories
                    dirs = cache_dirs.split(",")
                    for dir_path in dirs:
                        dir_path = dir_path.strip()
                        if dir_path:
                            result = self.file_validator.validate_file_path(
                                dir_path, "cache-directories"
                            )
                            for error in self.file_validator.errors:
                                if error not in self.errors:
                                    self.add_error(error)
                            self.file_validator.clear_errors()
                            if not result:
                                valid = False

        # Validate token (empty string is invalid)
        if "token" in inputs:
            token = inputs["token"]
            if token == "":
                self.add_error("Token cannot be empty string")
                valid = False
            elif token:
                result = self.token_validator.validate_github_token(token, required=False)
                for error in self.token_validator.errors:
                    if error not in self.errors:
                        self.add_error(error)
                self.token_validator.clear_errors()
                if not result:
                    valid = False

        # Validate max-retries
        if inputs.get("max-retries"):
            result = self.numeric_validator.validate_numeric_range(
                inputs["max-retries"], min_val=1, max_val=10, name="max-retries"
            )
            for error in self.numeric_validator.errors:
                if error not in self.errors:
                    self.add_error(error)
            self.numeric_validator.clear_errors()
            if not result:
                valid = False

        # Validate args (empty string is invalid, checks for injection if provided)
        if "args" in inputs:
            args = inputs["args"]
            if args == "":
                self.add_error("Args cannot be empty string")
                valid = False
            elif args:
                if not self.is_github_expression(args):
                    # Check for command injection patterns
                    result = self.security_validator.validate_no_injection(args, "args")
                    for error in self.security_validator.errors:
                        if error not in self.errors:
                            self.add_error(error)
                    self.security_validator.clear_errors()
                    if not result:
                        valid = False

        return valid

    def get_required_inputs(self) -> list[str]:
        """Get list of required inputs."""
        return ["php"]

    def get_validation_rules(self) -> dict:
        """Get validation rules."""
        rules_path = Path(__file__).parent / "rules.yml"
        return self.load_rules(rules_path)
