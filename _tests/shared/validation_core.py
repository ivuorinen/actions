#!/usr/bin/env python3
"""
Shared validation core module for GitHub Actions.

This module consolidates all validation logic to eliminate duplication between
the framework validation and the centralized validator. It provides:

1. Standardized token patterns (resolved GitHub documentation discrepancies)
2. Common validation functions
3. Unified security validation
4. Centralized YAML parsing utilities
5. Command-line interface for ShellSpec test integration

This replaces inline Python code in ShellSpec tests and duplicate functions
across multiple files.
"""

from __future__ import annotations

import argparse
from pathlib import Path
import re
import sys
from typing import Any

import yaml


class ValidationCore:
    """Core validation functionality with standardized patterns and functions."""

    # Standardized token patterns - resolved based on GitHub documentation
    # Fine-grained tokens are 82 characters according to GitHub docs
    TOKEN_PATTERNS = {
        "classic": r"^gh[efpousr]_[a-zA-Z0-9]{36}$",
        "fine_grained": r"^github_pat_[a-zA-Z0-9_]{82}$",  # GitHub docs: exactly 82 chars
        "installation": r"^ghs_[a-zA-Z0-9]{36}$",
        "npm_classic": r"^npm_[a-zA-Z0-9]{40,}$",  # NPM classic tokens
    }

    # Security injection patterns
    SECURITY_PATTERNS = [
        r";\s*(rm|del|format|shutdown|reboot)",
        r"&&\s*(rm|del|format|shutdown|reboot)",
        r"\|\s*(rm|del|format|shutdown|reboot)",
        r"`[^`]*`",  # Command substitution
        r"\$\([^)]*\)",  # Command substitution
        # Path traversal only dangerous when combined with commands
        r"\.\./.*;\s*(rm|del|format|shutdown|reboot)",
        r"\\\.\\\.\\\.*;\s*(rm|del|format|shutdown|reboot)",
    ]

    def __init__(self):
        """Initialize the validation core."""

    def validate_github_token(self, token: str, *, required: bool = False) -> tuple[bool, str]:
        """
        Validate GitHub token format using standardized PCRE patterns.

        Args:
            token: The token to validate
            required: Whether the token is required

        Returns:
            Tuple of (is_valid, error_message)
        """
        if not token or token.strip() == "":
            if required:
                return False, "Token is required but not provided"
            return True, ""

        # Allow GitHub Actions expressions
        if token == "${{ github.token }}" or (token.startswith("${{") and token.endswith("}}")):
            return True, ""

        # Check against standardized token patterns
        for _token_type, pattern in self.TOKEN_PATTERNS.items():
            if re.match(pattern, token):
                return True, ""

        return (
            False,
            "Invalid token format. Expected: gh[efpousr]_* (36 chars), "
            "github_pat_* (82 chars), ghs_* (36 chars), or npm_* (40+ chars)",
        )

    def validate_namespace_with_lookahead(self, namespace: str) -> tuple[bool, str]:
        """
        Validate namespace using lookahead pattern for .NET namespaces.

        Args:
            namespace: The namespace to validate

        Returns:
            Tuple of (is_valid, error_message)
        """
        if not namespace or namespace.strip() == "":
            return False, "Namespace cannot be empty"

        # Pattern with lookahead ensures hyphens are only allowed when followed by alphanumeric
        pattern = r"^[a-zA-Z0-9]([a-zA-Z0-9]|-(?=[a-zA-Z0-9])){0,38}$"

        if re.match(pattern, namespace):
            return True, ""
        return (
            False,
            "Invalid namespace format. Must be 1-39 characters, "
            "alphanumeric and hyphens, no trailing hyphens",
        )

    def validate_security_patterns(
        self,
        input_value: str,
        input_name: str = "",
    ) -> tuple[bool, str]:
        """
        Check for common security injection patterns.

        Args:
            input_value: The value to validate
            input_name: Name of the input (for context)

        Returns:
            Tuple of (is_valid, error_message)
        """
        # Allow empty values for most inputs (they're often optional)
        if not input_value or input_value.strip() == "":
            return True, ""

        for pattern in self.SECURITY_PATTERNS:
            if re.search(pattern, input_value, re.IGNORECASE):
                return (
                    False,
                    f"Potential security injection pattern detected in {input_name or 'input'}",
                )

        return True, ""

    def validate_boolean(self, value: str, input_name: str) -> tuple[bool, str]:
        """Validate boolean input with intelligent fallback for misclassified inputs."""
        # Handle empty values
        if not value:
            return True, ""

        # Standard boolean values
        if value.lower() in ["true", "false"]:
            return True, ""

        # Intelligent fallback for misclassified inputs
        # If input name suggests it should accept paths/directories, validate as such
        if any(
            keyword in input_name.lower()
            for keyword in ["directories", "directory", "path", "file"]
        ):
            return self.validate_cache_directories(value)

        return False, f"Input '{input_name}' must be 'true' or 'false'"

    def validate_version_format(
        self,
        value: str,
        *,
        allow_v_prefix: bool = False,
    ) -> tuple[bool, str]:
        """Validate semantic version format."""
        if value.lower() == "latest":
            return True, ""
        if not allow_v_prefix and value.startswith("v"):
            return False, f"Version should not start with 'v': {value}"
        if value.startswith("v"):
            value = value[1:]  # Remove v prefix for validation
        # More flexible version pattern that also accepts simple numbers
        # (for composer-version, etc.)
        if re.match(r"^[0-9]+(\.[0-9]+(\.[0-9]+)?)?$", value):
            return True, ""
        return True, ""

    def validate_file_path(self, value: str, *, allow_traversal: bool = False) -> tuple[bool, str]:
        """Validate file path format."""
        if not value:
            return True, ""

        # Check for injection patterns
        if re.search(r"[;&|`$()]", value):
            return False, f"Potential injection detected in file path: {value}"

        # Check for path traversal (unless explicitly allowed)
        if not allow_traversal and ("../" in value or "..\\" in value):
            return False, f"Path traversal not allowed: {value}"

        # Check for absolute paths (often not allowed)
        if value.startswith("/") or (len(value) > 1 and value[1] == ":"):
            return False, f"Absolute paths not allowed: {value}"

        return True, ""

    def validate_docker_image_name(self, value: str) -> tuple[bool, str]:
        """Validate docker image name format."""
        if not value:
            return True, ""
        if not re.match(
            r"^[a-z0-9]+((\\.|_|__|-+)[a-z0-9]+)*(/[a-z0-9]+((\\.|_|__|-+)[a-z0-9]+)*)*$",
            value,
        ):
            return False, f"Invalid docker image name format: {value}"
        return True, ""

    def validate_docker_tag(self, value: str) -> tuple[bool, str]:
        """Validate docker tag format (handles comma-separated lists)."""
        if not value:
            return True, ""
        tags = [tag.strip() for tag in value.split(",")]
        for tag in tags:
            if not re.match(r"^[a-zA-Z0-9]([a-zA-Z0-9._-]*[a-zA-Z0-9])?$", tag):
                return False, f"Invalid docker tag format: {tag}"
        return True, ""

    def validate_php_extensions(self, value: str) -> tuple[bool, str]:
        """Validate PHP extensions format."""
        if not value:
            return True, ""
        if re.search(r"[;&|`$()@#]", value):
            return False, f"Potential injection detected in PHP extensions: {value}"
        if not re.match(r"^[a-zA-Z0-9_,\\s]+$", value):
            return False, f"Invalid PHP extensions format: {value}"
        return True, ""

    def validate_coverage_driver(self, value: str) -> tuple[bool, str]:
        """Validate coverage driver."""
        if value not in ["none", "xdebug", "pcov", "xdebug3"]:
            return False, "Invalid coverage driver. Must be 'none', 'xdebug', 'pcov', or 'xdebug3'"
        return True, ""

    def validate_numeric_range(self, value: str, min_val: int, max_val: int) -> tuple[bool, str]:
        """Validate numeric value within range."""
        try:
            num = int(value)
            if min_val <= num <= max_val:
                return True, ""
            return False, f"Value must be between {min_val} and {max_val}, got {num}"
        except ValueError:
            return False, f"Invalid numeric value: {value}"

    def validate_php_version(self, value: str) -> tuple[bool, str]:
        """Validate PHP version format (allows X.Y and X.Y.Z)."""
        if not value:
            return True, ""
        # PHP versions can be X.Y or X.Y.Z format
        if re.match(r"^[0-9]+\.[0-9]+(\.[0-9]+)?$", value):
            return True, ""
        return False, f"Invalid PHP version format: {value}"

    def validate_composer_version(self, value: str) -> tuple[bool, str]:
        """Validate Composer version (1 or 2)."""
        if value in ["1", "2"]:
            return True, ""
        return False, f"Invalid Composer version. Must be '1' or '2', got '{value}'"

    def validate_stability(self, value: str) -> tuple[bool, str]:
        """Validate Composer stability."""
        valid_stabilities = ["stable", "RC", "beta", "alpha", "dev"]
        if value in valid_stabilities:
            return True, ""
        return False, f"Invalid stability. Must be one of: {', '.join(valid_stabilities)}"

    def validate_cache_directories(self, value: str) -> tuple[bool, str]:
        """Validate cache directories (comma-separated paths)."""
        if not value:
            return True, ""

        # Split by comma and validate each directory
        directories = [d.strip() for d in value.split(",")]
        for directory in directories:
            if not directory:
                continue

            # Basic path validation
            if re.search(r"[;&|`$()]", directory):
                return False, f"Potential injection detected in directory path: {directory}"

            # Check for path traversal
            if "../" in directory or "..\\\\" in directory:
                return False, f"Path traversal not allowed in directory: {directory}"

            # Check for absolute paths
            if directory.startswith("/") or (len(directory) > 1 and directory[1] == ":"):
                return False, f"Absolute paths not allowed in directory: {directory}"

        return True, ""

    def validate_tools(self, value: str) -> tuple[bool, str]:
        """Validate Composer tools format."""
        if not value:
            return True, ""

        # Check for injection patterns
        if re.search(r"[;&|`$()@]", value):
            return False, f"Potential injection detected in tools: {value}"

        return True, ""

    def validate_numeric_range_1_10(self, value: str) -> tuple[bool, str]:
        """Validate numeric value between 1 and 10."""
        return self.validate_numeric_range(value, 1, 10)

    def validate_enhanced_business_logic(
        self,
        action_name: str,
        input_name: str,
        value: str,
    ) -> tuple[bool | None, str]:
        """
        Enhanced business logic validation for specific action/input combinations.
        Returns (None, "") if no enhanced validation applies, otherwise returns validation result.
        """
        if not value:  # Empty values are generally allowed, except for specific cases
            # Some inputs should not be empty even if they're optional
            if action_name == "php-composer" and input_name in ["composer-version"]:
                return False, f"Empty {input_name} is not allowed"
            return None, ""

        # PHP Composer specific validations
        if action_name == "php-composer":
            return self._validate_php_composer_business_logic(input_name, value)

        # Prettier-check specific validations
        if action_name == "prettier-check":
            return self._validate_prettier_check_business_logic(input_name, value)

        # Add more action-specific validations here as needed

        return None, ""  # No enhanced validation applies

    def _validate_composer_version(self, value: str) -> tuple[bool, str]:
        """Validate composer version input."""
        if value not in ["1", "2"]:
            return False, f"Composer version must be '1' or '2', got '{value}'"
        return True, ""

    def _validate_stability(self, value: str) -> tuple[bool, str]:
        """Validate stability input."""
        valid_stabilities = ["stable", "RC", "beta", "alpha", "dev"]
        if value not in valid_stabilities:
            return (
                False,
                f"Invalid stability '{value}'. Must be one of: {', '.join(valid_stabilities)}",
            )
        return True, ""

    def _validate_php_version(self, value: str) -> tuple[bool, str]:
        """Validate PHP version input."""
        if not re.match(r"^[0-9]+\.[0-9]+(\.[0-9]+)?$", value):
            return False, f"Invalid PHP version format: {value}"

        try:
            major, minor = value.split(".")[:2]
            major_num, minor_num = int(major), int(minor)

            if major_num < 7:
                return False, f"PHP version {value} is too old (minimum 7.0)"

            if major_num > 20:
                return False, f"Invalid PHP version: {value}"

            if minor_num < 0 or minor_num > 99:
                return False, f"Invalid PHP version: {value}"

        except (ValueError, IndexError):
            return False, f"Invalid PHP version format: {value}"
        return True, ""

    def _validate_extensions(self, value: str) -> tuple[bool, str]:
        """Validate PHP extensions input."""
        if re.search(r"[@#$&*(){}[\]|\\]", value):
            return False, f"Invalid characters in PHP extensions: {value}"
        return True, ""

    def _validate_tools(self, value: str) -> tuple[bool, str]:
        """Validate tools input."""
        if re.search(r"[@#$&*(){}[\]|\\]", value):
            return False, f"Invalid characters in tools specification: {value}"
        return True, ""

    def _validate_args(self, value: str) -> tuple[bool, str]:
        """Validate args input."""
        if re.search(r"[;&|`$()]", value):
            return False, f"Potentially dangerous characters in args: {value}"
        return True, ""

    def _validate_php_composer_business_logic(
        self,
        input_name: str,
        value: str,
    ) -> tuple[bool | None, str]:
        """Business logic validation specific to php-composer action."""
        validators = {
            "composer-version": self._validate_composer_version,
            "stability": self._validate_stability,
            "php": self._validate_php_version,
            "extensions": self._validate_extensions,
            "tools": self._validate_tools,
            "args": self._validate_args,
        }

        if input_name in validators:
            is_valid, error_msg = validators[input_name](value)
            return is_valid, error_msg

        return None, ""  # No specific validation for this input

    def _validate_file_pattern_security(self, value: str) -> tuple[bool, str]:
        """Validate file-pattern for security issues."""
        if ".." in value:
            return False, "Path traversal detected in file-pattern"
        if value.startswith("/"):
            return False, "Absolute path not allowed in file-pattern"
        if "$" in value:
            return False, "Shell expansion not allowed in file-pattern"
        return True, ""

    def _validate_plugins_security(self, value: str) -> tuple[bool, str]:
        """Validate plugins for security issues."""
        if re.search(r"[;&|`$()]", value):
            return False, "Potentially dangerous characters in plugins"
        if re.search(r"\$\{.*\}", value):
            return False, "Variable expansion not allowed in plugins"
        if re.search(r"\$\(.*\)", value):
            return False, "Command substitution not allowed in plugins"
        return True, ""

    def _validate_prettier_check_business_logic(
        self,
        input_name: str,
        value: str,
    ) -> tuple[bool | None, str]:
        """Business logic validation specific to prettier-check action."""
        # Handle prettier-version specially (accepts "latest" or semantic version)
        if input_name == "prettier-version":
            if value == "latest":
                return True, ""
            # Otherwise validate as semantic version
            return None, ""  # Let standard semantic version validation handle it

        # Validate file-pattern for security issues
        if input_name == "file-pattern":
            return self._validate_file_pattern_security(value)

        # Validate report-format enum
        if input_name == "report-format":
            if value == "":
                return False, "report-format cannot be empty"
            if value not in ["json", "sarif"]:
                return False, f"Invalid report-format: {value}"
            return True, ""

        # Validate plugins for security issues
        if input_name == "plugins":
            return self._validate_plugins_security(value)

        return None, ""  # No specific validation for this input


class ActionFileParser:
    """Parser for GitHub Action YAML files."""

    @staticmethod
    def load_action_file(action_file: str) -> dict[str, Any]:
        """Load and parse an action.yml file."""
        try:
            with Path(action_file).open(encoding="utf-8") as f:
                return yaml.safe_load(f)
        except Exception as e:
            msg = f"Failed to load action file {action_file}: {e}"
            raise ValueError(msg) from e

    @staticmethod
    def get_action_name(action_file: str) -> str:
        """Get the action name from an action.yml file."""
        try:
            data = ActionFileParser.load_action_file(action_file)
            return data.get("name", "Unknown")
        except Exception:
            return "Unknown"

    @staticmethod
    def get_action_inputs(action_file: str) -> list[str]:
        """Get all input names from an action.yml file."""
        try:
            data = ActionFileParser.load_action_file(action_file)
            inputs = data.get("inputs", {})
            return list(inputs.keys())
        except Exception:
            return []

    @staticmethod
    def get_action_outputs(action_file: str) -> list[str]:
        """Get all output names from an action.yml file."""
        try:
            data = ActionFileParser.load_action_file(action_file)
            outputs = data.get("outputs", {})
            return list(outputs.keys())
        except Exception:
            return []

    @staticmethod
    def get_input_property(action_file: str, input_name: str, property_name: str) -> str:
        """
        Get a property of an input from an action.yml file.

        Args:
            action_file: Path to the action.yml file
            input_name: Name of the input to check
            property_name: Property to check (required, optional, default, description,
                all_optional)

        Returns:
            - For 'required': 'required' or 'optional'
            - For 'optional': 'optional' or 'required'
            - For 'default': the default value or 'no-default'
            - For 'description': the description or 'no-description'
            - For 'all_optional': 'none' if no required inputs, else comma-separated list
        """
        try:
            data = ActionFileParser.load_action_file(action_file)
            inputs = data.get("inputs", {})
            input_data = inputs.get(input_name, {})

            if property_name in ["required", "optional"]:
                is_required = input_data.get("required") in [True, "true"]
                if property_name == "required":
                    return "required" if is_required else "optional"
                return "optional" if not is_required else "required"

            if property_name == "default":
                default_value = input_data.get("default", "")
                return str(default_value) if default_value else "no-default"

            if property_name == "description":
                description = input_data.get("description", "")
                return description if description else "no-description"

            if property_name == "all_optional":
                required_inputs = [
                    k for k, v in inputs.items() if v.get("required") in [True, "true"]
                ]
                return "none" if not required_inputs else ",".join(required_inputs)

            return f"unknown-property-{property_name}"

        except Exception as e:
            return f"error: {e}"


def resolve_action_file_path(action_dir: str) -> str:
    """Resolve the path to the action.yml file."""
    action_dir_path = Path(action_dir)
    if not action_dir_path.is_absolute():
        # If relative, assume we're in _tests/shared and actions are at ../../
        script_dir = Path(__file__).resolve().parent
        project_root = script_dir.parent.parent
        return str(project_root / action_dir / "action.yml")
    return f"{action_dir}/action.yml"


def _apply_validation_by_type(
    validator: ValidationCore,
    validation_type: str,
    input_value: str,
    input_name: str,
    required_inputs: list,
) -> tuple[bool, str]:
    """Apply validation based on the validation type."""
    validation_map = {
        "github_token": lambda: validator.validate_github_token(
            input_value, required=input_name in required_inputs
        ),
        "namespace_with_lookahead": lambda: validator.validate_namespace_with_lookahead(
            input_value,
        ),
        "boolean": lambda: validator.validate_boolean(input_value, input_name),
        "file_path": lambda: validator.validate_file_path(input_value),
        "docker_image_name": lambda: validator.validate_docker_image_name(input_value),
        "docker_tag": lambda: validator.validate_docker_tag(input_value),
        "php_extensions": lambda: validator.validate_php_extensions(input_value),
        "coverage_driver": lambda: validator.validate_coverage_driver(input_value),
        "php_version": lambda: validator.validate_php_version(input_value),
        "composer_version": lambda: validator.validate_composer_version(input_value),
        "stability": lambda: validator.validate_stability(input_value),
        "cache_directories": lambda: validator.validate_cache_directories(input_value),
        "tools": lambda: validator.validate_tools(input_value),
        "numeric_range_1_10": lambda: validator.validate_numeric_range_1_10(input_value),
    }

    # Handle version formats
    if validation_type in ["semantic_version", "calver_version", "flexible_version"]:
        return validator.validate_version_format(input_value)

    if validation_type == "terraform_version":
        return validator.validate_version_format(input_value, allow_v_prefix=True)

    # Use validation map for other types
    if validation_type in validation_map:
        return validation_map[validation_type]()

    return True, ""  # Unknown validation type, assume valid


def _load_and_validate_rules(
    rules_file: Path,
    input_name: str,
    input_value: str,
) -> tuple[str | None, dict, list]:
    """Load validation rules and perform basic validation."""
    try:
        with Path(rules_file).open(encoding="utf-8") as f:
            rules_data = yaml.safe_load(f)

        conventions = rules_data.get("conventions", {})
        overrides = rules_data.get("overrides", {})
        required_inputs = rules_data.get("required_inputs", [])

        # Check if input is required and empty
        if input_name in required_inputs and (not input_value or input_value.strip() == ""):
            return None, {}, []  # Will cause error in caller

        # Get validation type
        validation_type = overrides.get(input_name, conventions.get(input_name))
        return validation_type, rules_data, required_inputs

    except Exception:
        return None, {}, []


def validate_input(action_dir: str, input_name: str, input_value: str) -> tuple[bool | None, str]:
    """
    Validate an input value for a specific action.

    This is the main validation entry point that replaces the complex
    validation logic in the original framework.
    """
    validator = ValidationCore()

    # Always perform security validation first
    security_valid, security_error = validator.validate_security_patterns(input_value, input_name)
    if not security_valid:
        return False, security_error

    # Get action name for business logic and rules
    action_name = Path(action_dir).name

    # Check enhanced business logic first (takes precedence over general rules)
    enhanced_validation = validator.validate_enhanced_business_logic(
        action_name,
        input_name,
        input_value,
    )
    if enhanced_validation[0] is not None:  # If enhanced validation has an opinion
        return enhanced_validation

    # Load validation rules from action folder
    script_dir = Path(__file__).resolve().parent
    project_root = script_dir.parent.parent
    rules_file = project_root / action_name / "rules.yml"

    if rules_file.exists():
        validation_type, _rules_data, required_inputs = _load_and_validate_rules(
            rules_file,
            input_name,
            input_value,
        )

        # Check for required input error
        if input_name in required_inputs and (not input_value or input_value.strip() == ""):
            return False, f"Required input '{input_name}' cannot be empty"

        if validation_type:
            try:
                return _apply_validation_by_type(
                    validator,
                    validation_type,
                    input_value,
                    input_name,
                    required_inputs,
                )
            except Exception as e:
                print(
                    f"Warning: Could not apply validation for {action_name}: {e}",
                    file=sys.stderr,
                )

    # If no specific validation found, the security check is sufficient
    return True, ""


def _handle_legacy_interface():
    """Handle legacy CLI interface for backward compatibility."""
    if len(sys.argv) == 5 and all(not arg.startswith("-") for arg in sys.argv[1:]):
        action_dir, input_name, input_value, expected_result = sys.argv[1:5]
        is_valid, error_msg = validate_input(action_dir, input_name, input_value)

        actual_result = "success" if is_valid else "failure"
        if actual_result == expected_result:
            sys.exit(0)
        else:
            print(f"Expected {expected_result}, got {actual_result}: {error_msg}", file=sys.stderr)
            sys.exit(1)
    return False  # Not legacy interface


def _create_argument_parser():
    """Create and configure the argument parser."""
    parser = argparse.ArgumentParser(
        description="Shared validation core for GitHub Actions",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Validate an input value
  python3 validation_core.py --validate action-dir input-name input-value

  # Get input property
  python3 validation_core.py --property action.yml input-name required

  # List inputs
  python3 validation_core.py --inputs action.yml

  # List outputs
  python3 validation_core.py --outputs action.yml

  # Get action name
  python3 validation_core.py --name action.yml
        """,
    )

    mode_group = parser.add_mutually_exclusive_group(required=True)
    mode_group.add_argument(
        "--validate",
        nargs=3,
        metavar=("ACTION_DIR", "INPUT_NAME", "INPUT_VALUE"),
        help="Validate an input value",
    )
    mode_group.add_argument(
        "--property",
        nargs=3,
        metavar=("ACTION_FILE", "INPUT_NAME", "PROPERTY"),
        help="Get input property",
    )
    mode_group.add_argument("--inputs", metavar="ACTION_FILE", help="List action inputs")
    mode_group.add_argument("--outputs", metavar="ACTION_FILE", help="List action outputs")
    mode_group.add_argument("--name", metavar="ACTION_FILE", help="Get action name")
    mode_group.add_argument(
        "--validate-yaml",
        metavar="YAML_FILE",
        help="Validate YAML file syntax",
    )

    return parser


def _handle_validate_command(args):
    """Handle the validate command."""
    action_dir, input_name, input_value = args.validate
    is_valid, error_msg = validate_input(action_dir, input_name, input_value)
    if is_valid:
        sys.exit(0)
    else:
        print(f"INVALID: {error_msg}", file=sys.stderr)
        sys.exit(1)


def _handle_property_command(args):
    """Handle the property command."""
    action_file, input_name, property_name = args.property
    result = ActionFileParser.get_input_property(action_file, input_name, property_name)
    print(result)


def _handle_inputs_command(args):
    """Handle the inputs command."""
    inputs = ActionFileParser.get_action_inputs(args.inputs)
    for input_name in inputs:
        print(input_name)


def _handle_outputs_command(args):
    """Handle the outputs command."""
    outputs = ActionFileParser.get_action_outputs(args.outputs)
    for output_name in outputs:
        print(output_name)


def _handle_name_command(args):
    """Handle the name command."""
    name = ActionFileParser.get_action_name(args.name)
    print(name)


def _handle_validate_yaml_command(args):
    """Handle the validate-yaml command."""
    try:
        with Path(args.validate_yaml).open(encoding="utf-8") as f:
            yaml.safe_load(f)
        sys.exit(0)
    except Exception as e:
        print(f"Invalid YAML: {e}", file=sys.stderr)
        sys.exit(1)


def _execute_command(args):
    """Execute the appropriate command based on arguments."""
    command_handlers = {
        "validate": _handle_validate_command,
        "property": _handle_property_command,
        "inputs": _handle_inputs_command,
        "outputs": _handle_outputs_command,
        "name": _handle_name_command,
        "validate_yaml": _handle_validate_yaml_command,
    }

    for command, handler in command_handlers.items():
        if getattr(args, command, None):
            handler(args)
            return


def main():
    """Command-line interface for validation core."""
    # Handle legacy interface first
    _handle_legacy_interface()

    # Parse arguments and execute command
    parser = _create_argument_parser()
    args = parser.parse_args()

    try:
        _execute_command(args)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
