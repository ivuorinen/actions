#!/usr/bin/env python3
"""
GitHub Actions Validation Module

This module provides advanced validation capabilities for GitHub Actions testing,
specifically handling PCRE regex patterns with lookahead/lookbehind assertions
that are not supported in bash's basic regex engine.

Features:
- PCRE-compatible regex validation using Python's re module
- GitHub token format validation with proper lookahead support
- Input sanitization and security validation
- Complex pattern detection and validation
"""

from __future__ import annotations

from pathlib import Path
import re
import sys

import yaml


class ActionValidator:
    """Handles validation of GitHub Action inputs using Python regex engine."""

    # Common regex patterns that require PCRE features
    COMPLEX_PATTERNS = {
        "lookahead": r"\(\?\=",
        "lookbehind": r"\(\?\<=",
        "negative_lookahead": r"\(\?\!",
        "named_groups": r"\(\?P<\w+>",
        "conditional": r"\(\?\(",
    }

    # Standardized token patterns (resolved GitHub documentation discrepancies)
    # Fine-grained PATs are 50-255 characters with underscores (github_pat_[A-Za-z0-9_]{50,255})
    TOKEN_PATTERNS = {
        "classic": r"^gh[efpousr]_[a-zA-Z0-9]{36}$",
        "fine_grained": r"^github_pat_[A-Za-z0-9_]{50,255}$",  # 50-255 chars with underscores
        "installation": r"^ghs_[a-zA-Z0-9]{36}$",
        "npm_classic": r"^npm_[a-zA-Z0-9]{40,}$",  # NPM classic tokens
    }

    def __init__(self):
        """Initialize the validator."""

    def is_complex_pattern(self, pattern: str) -> bool:
        """
        Check if a regex pattern requires PCRE features not supported in bash.

        Args:
            pattern: The regex pattern to check

        Returns:
            True if pattern requires PCRE features, False otherwise
        """
        for feature, regex in self.COMPLEX_PATTERNS.items():
            if re.search(regex, pattern):
                return True
        return False

    def validate_github_token(self, token: str, action_dir: str = "") -> tuple[bool, str]:
        """
        Validate GitHub token format using proper PCRE patterns.

        Args:
            token: The token to validate
            action_dir: The action directory (for context-specific validation)

        Returns:
            Tuple of (is_valid, error_message)
        """
        # Actions that require tokens shouldn't accept empty values
        action_name = Path(action_dir).name
        if action_name in ["csharp-publish", "eslint-fix", "pr-lint", "pre-commit"]:
            if not token or token.strip() == "":
                return False, "Token cannot be empty"
        # Other actions may accept empty tokens (they'll use defaults)
        elif not token or token.strip() == "":
            return True, ""

        # Check for GitHub Actions expression (should be allowed)
        if token == "${{ github.token }}" or (token.startswith("${{") and token.endswith("}}")):
            return True, ""

        # Check against all known token patterns
        for token_type, pattern in self.TOKEN_PATTERNS.items():
            if re.match(pattern, token):
                return True, ""

        return (
            False,
            "Invalid token format. Expected: gh[efpousr]_* (36 chars), "
            "github_pat_[A-Za-z0-9_]* (50-255 chars), ghs_* (36 chars), or npm_* (40+ chars)",
        )

    def validate_namespace_with_lookahead(self, namespace: str) -> tuple[bool, str]:
        """
        Validate namespace using the original lookahead pattern from csharp-publish.

        Args:
            namespace: The namespace to validate

        Returns:
            Tuple of (is_valid, error_message)
        """
        if not namespace or namespace.strip() == "":
            return False, "Namespace cannot be empty"

        # Original pattern: ^[a-zA-Z0-9]([a-zA-Z0-9]|-(?=[a-zA-Z0-9])){0,38}$
        # This ensures hyphens are only allowed when followed by alphanumeric characters
        pattern = r"^[a-zA-Z0-9]([a-zA-Z0-9]|-(?=[a-zA-Z0-9])){0,38}$"

        if re.match(pattern, namespace):
            return True, ""
        return (
            False,
            "Invalid namespace format. Must be 1-39 characters, "
            "alphanumeric and hyphens, no trailing hyphens",
        )

    def validate_input_pattern(self, input_value: str, pattern: str) -> tuple[bool, str]:
        """
        Validate an input value against a regex pattern using Python's re module.

        Args:
            input_value: The value to validate
            pattern: The regex pattern to match against

        Returns:
            Tuple of (is_valid, error_message)
        """
        try:
            if re.match(pattern, input_value):
                return True, ""
            return False, f"Value '{input_value}' does not match required pattern: {pattern}"
        except re.error as e:
            return False, f"Invalid regex pattern: {pattern} - {e!s}"

    def validate_security_patterns(self, input_value: str) -> tuple[bool, str]:
        """
        Check for common security injection patterns.

        Args:
            input_value: The value to validate

        Returns:
            Tuple of (is_valid, error_message)
        """
        # Allow empty values for most inputs (they're often optional)
        if not input_value or input_value.strip() == "":
            return True, ""

        # Common injection patterns
        injection_patterns = [
            r";\s*(rm|del|format|shutdown|reboot)",
            r"&&\s*(rm|del|format|shutdown|reboot)",
            r"\|\s*(rm|del|format|shutdown|reboot)",
            r"`[^`]*`",  # Command substitution
            r"\$\([^)]*\)",  # Command substitution
            # Path traversal only dangerous when combined with commands
            r"\.\./.*;\s*(rm|del|format|shutdown|reboot)",
            r"\\\.\\\.\\.*;\s*(rm|del|format|shutdown|reboot)",
        ]

        for pattern in injection_patterns:
            if re.search(pattern, input_value, re.IGNORECASE):
                return False, f"Potential security injection pattern detected: {pattern}"

        return True, ""


def extract_validation_patterns(action_file: str) -> dict[str, list[str]]:
    """
    Extract validation patterns from an action.yml file.

    Args:
        action_file: Path to the action.yml file

    Returns:
        Dictionary mapping input names to their validation patterns
    """
    patterns = {}

    try:
        with Path(action_file).open() as f:
            content = f.read()

        # Look for validation patterns in the shell scripts
        validation_block_match = re.search(
            r"- name:\s*Validate\s+Inputs.*?run:\s*\|(.+?)(?=- name:|$)",
            content,
            re.DOTALL | re.IGNORECASE,
        )

        if validation_block_match:
            validation_script = validation_block_match.group(1)

            # Extract regex patterns from the validation script
            regex_matches = re.findall(
                r'\[\[\s*["\']?\$\{\{\s*inputs\.(\w+(?:-\w+)*)\s*\}\}["\']?\s*=~\s*(.+?)\]\]',
                validation_script,
                re.DOTALL | re.IGNORECASE,
            )

            for input_name, pattern in regex_matches:
                # Clean up the pattern
                pattern = pattern.strip().strip("\"'")
                if input_name not in patterns:
                    patterns[input_name] = []
                patterns[input_name].append(pattern)

    except Exception as e:
        print(f"Error extracting patterns from {action_file}: {e}", file=sys.stderr)

    return patterns


def get_input_property(action_file: str, input_name: str, property_check: str) -> str:
    """
    Get a property of an input from an action.yml file.

    This function replaces the functionality of check_input.py.

    Args:
        action_file: Path to the action.yml file
        input_name: Name of the input to check
        property_check: Property to check (required, optional, default, description, all_optional)

    Returns:
        - For 'required': 'required' or 'optional'
        - For 'optional': 'optional' or 'required'
        - For 'default': the default value or 'no-default'
        - For 'description': the description or 'no-description'
        - For 'all_optional': 'none' if no required inputs, else comma-separated list of
          required inputs
    """
    try:
        with Path(action_file).open(encoding="utf-8") as f:
            data = yaml.safe_load(f)

        inputs = data.get("inputs", {})
        input_data = inputs.get(input_name, {})

        if property_check in ["required", "optional"]:
            is_required = input_data.get("required") in [True, "true"]
            if property_check == "required":
                return "required" if is_required else "optional"
            # optional
            return "optional" if not is_required else "required"

        if property_check == "default":
            default_value = input_data.get("default", "")
            return str(default_value) if default_value else "no-default"

        if property_check == "description":
            description = input_data.get("description", "")
            return description if description else "no-description"

        if property_check == "all_optional":
            # Check if all inputs are optional (none are required)
            required_inputs = [k for k, v in inputs.items() if v.get("required") in [True, "true"]]
            return "none" if not required_inputs else ",".join(required_inputs)

        return f"unknown-property-{property_check}"

    except Exception as e:
        return f"error: {e}"


def get_action_inputs(action_file: str) -> list[str]:
    """
    Get all input names from an action.yml file.

    This function replaces the bash version in utils.sh.

    Args:
        action_file: Path to the action.yml file

    Returns:
        List of input names
    """
    try:
        with Path(action_file).open(encoding="utf-8") as f:
            data = yaml.safe_load(f)

        inputs = data.get("inputs", {})
        return list(inputs.keys())

    except Exception:
        return []


def get_action_outputs(action_file: str) -> list[str]:
    """
    Get all output names from an action.yml file.

    This function replaces the bash version in utils.sh.

    Args:
        action_file: Path to the action.yml file

    Returns:
        List of output names
    """
    try:
        with Path(action_file).open(encoding="utf-8") as f:
            data = yaml.safe_load(f)

        outputs = data.get("outputs", {})
        return list(outputs.keys())

    except Exception:
        return []


def get_action_name(action_file: str) -> str:
    """
    Get the action name from an action.yml file.

    This function replaces the bash version in utils.sh.

    Args:
        action_file: Path to the action.yml file

    Returns:
        Action name or "Unknown" if not found
    """
    try:
        with Path(action_file).open(encoding="utf-8") as f:
            data = yaml.safe_load(f)

        return data.get("name", "Unknown")

    except Exception:
        return "Unknown"


def _show_usage():
    """Show usage information and exit."""
    print("Usage:")
    print(
        "  Validation mode: python3 validation.py <action_dir> <input_name> <input_value> "
        "[expected_result]",
    )
    print(
        "  Property mode:   python3 validation.py --property <action_file> <input_name> <property>",
    )
    print("  List inputs:     python3 validation.py --inputs <action_file>")
    print("  List outputs:    python3 validation.py --outputs <action_file>")
    print("  Get name:        python3 validation.py --name <action_file>")
    sys.exit(1)


def _parse_property_mode():
    """Parse property mode arguments."""
    if len(sys.argv) != 5:
        print(
            "Property mode usage: python3 validation.py --property <action_file> "
            "<input_name> <property>",
        )
        print("Properties: required, optional, default, description, all_optional")
        sys.exit(1)
    return {
        "mode": "property",
        "action_file": sys.argv[2],
        "input_name": sys.argv[3],
        "property": sys.argv[4],
    }


def _parse_single_file_mode(mode_name):
    """Parse modes that take a single action file argument."""
    if len(sys.argv) != 3:
        print(f"{mode_name.title()} mode usage: python3 validation.py --{mode_name} <action_file>")
        sys.exit(1)
    return {
        "mode": mode_name,
        "action_file": sys.argv[2],
    }


def _parse_validation_mode():
    """Parse validation mode arguments."""
    if len(sys.argv) < 4:
        print(
            "Validation mode usage: python3 validation.py <action_dir> <input_name> "
            "<input_value> [expected_result]",
        )
        print("Expected result: 'success' or 'failure' (default: auto-detect)")
        sys.exit(1)
    return {
        "mode": "validation",
        "action_dir": sys.argv[1],
        "input_name": sys.argv[2],
        "input_value": sys.argv[3],
        "expected_result": sys.argv[4] if len(sys.argv) > 4 else None,
    }


def _parse_command_line_args():
    """Parse and validate command line arguments."""
    if len(sys.argv) < 2:
        _show_usage()

    mode_arg = sys.argv[1]

    if mode_arg == "--property":
        return _parse_property_mode()
    if mode_arg in ["--inputs", "--outputs", "--name"]:
        return _parse_single_file_mode(mode_arg[2:])  # Remove '--' prefix
    return _parse_validation_mode()


def _resolve_action_file_path(action_dir: str) -> str:
    """Resolve the path to the action.yml file."""
    action_dir_path = Path(action_dir)
    if not action_dir_path.is_absolute():
        # If relative, assume we're in _tests/framework and actions are at ../../
        script_dir = Path(__file__).resolve().parent
        project_root = script_dir.parent.parent
        return str(project_root / action_dir / "action.yml")
    return f"{action_dir}/action.yml"


def _validate_docker_build_input(input_name: str, input_value: str) -> tuple[bool, str]:
    """Handle special validation for docker-build inputs."""
    if input_name == "build-args" and input_value == "":
        return True, ""
    # All other docker-build inputs pass through centralized validation
    return True, ""


# Validation function registry
def _validate_boolean(input_value: str, input_name: str) -> tuple[bool, str]:
    """Validate boolean input."""
    if input_value.lower() not in ["true", "false"]:
        return False, f"Input '{input_name}' must be 'true' or 'false'"
    return True, ""


def _validate_docker_architectures(input_value: str) -> tuple[bool, str]:
    """Validate docker architectures format."""
    if input_value and not re.match(r"^[a-zA-Z0-9/_,.-]+$", input_value):
        return False, f"Invalid docker architectures format: {input_value}"
    return True, ""


def _validate_registry(input_value: str, action_name: str) -> tuple[bool, str]:
    """Validate registry format."""
    if action_name == "docker-publish":
        if input_value not in ["dockerhub", "github", "both"]:
            return False, "Invalid registry value. Must be 'dockerhub', 'github', or 'both'"
    elif input_value and not re.match(r"^[a-zA-Z0-9.-]+(\:[0-9]+)?$", input_value):
        return False, f"Invalid registry format: {input_value}"
    return True, ""


def _validate_file_path(input_value: str) -> tuple[bool, str]:
    """Validate file path format."""
    if input_value and re.search(r"[;&|`$()]", input_value):
        return False, f"Potential injection detected in file path: {input_value}"
    if input_value and not re.match(r"^[a-zA-Z0-9._/,~-]+$", input_value):
        return False, f"Invalid file path format: {input_value}"
    return True, ""


def _validate_backoff_strategy(input_value: str) -> tuple[bool, str]:
    """Validate backoff strategy."""
    if input_value not in ["linear", "exponential", "fixed"]:
        return False, "Invalid backoff strategy. Must be 'linear', 'exponential', or 'fixed'"
    return True, ""


def _validate_shell_type(input_value: str) -> tuple[bool, str]:
    """Validate shell type."""
    if input_value not in ["bash", "sh"]:
        return False, "Invalid shell type. Must be 'bash' or 'sh'"
    return True, ""


def _validate_docker_image_name(input_value: str) -> tuple[bool, str]:
    """Validate docker image name format."""
    if input_value and not re.match(
        r"^[a-z0-9]+((\.|_|__|-+)[a-z0-9]+)*(/[a-z0-9]+((\.|_|__|-+)[a-z0-9]+)*)*$",
        input_value,
    ):
        return False, f"Invalid docker image name format: {input_value}"
    return True, ""


def _validate_docker_tag(input_value: str) -> tuple[bool, str]:
    """Validate docker tag format."""
    if input_value:
        tags = [tag.strip() for tag in input_value.split(",")]
        for tag in tags:
            if not re.match(r"^[a-zA-Z0-9]([a-zA-Z0-9._-]*[a-zA-Z0-9])?$", tag):
                return False, f"Invalid docker tag format: {tag}"
    return True, ""


def _validate_docker_password(input_value: str) -> tuple[bool, str]:
    """Validate docker password."""
    if input_value and len(input_value) < 8:
        return False, "Docker password must be at least 8 characters long"
    return True, ""


def _validate_go_version(input_value: str) -> tuple[bool, str]:
    """Validate Go version format."""
    if input_value in ["stable", "latest"]:
        return True, ""
    if input_value and not re.match(r"^v?[0-9]+\.[0-9]+(\.[0-9]+)?", input_value):
        return False, f"Invalid Go version format: {input_value}"
    return True, ""


def _validate_timeout_with_unit(input_value: str) -> tuple[bool, str]:
    """Validate timeout with unit format."""
    if input_value and not re.match(r"^[0-9]+[smh]$", input_value):
        return False, "Invalid timeout format. Use format like '5m', '300s', or '1h'"
    return True, ""


def _validate_linter_list(input_value: str) -> tuple[bool, str]:
    """Validate linter list format."""
    if input_value and re.search(r",\s+", input_value):
        return False, "Invalid linter list format. Use comma-separated values without spaces"
    return True, ""


def _validate_version_types(input_value: str) -> tuple[bool, str]:
    """Validate semantic/calver/flexible version formats."""
    if input_value.lower() == "latest":
        return True, ""
    if input_value.startswith("v"):
        return False, f"Version should not start with 'v': {input_value}"
    if not re.match(r"^[0-9]+\.[0-9]+(\.[0-9]+)?", input_value):
        return False, f"Invalid version format: {input_value}"
    return True, ""


def _validate_file_pattern(input_value: str) -> tuple[bool, str]:
    """Validate file pattern format."""
    if input_value and ("../" in input_value or "\\..\\" in input_value):
        return False, f"Path traversal not allowed in file patterns: {input_value}"
    if input_value and input_value.startswith("/"):
        return False, f"Absolute paths not allowed in file patterns: {input_value}"
    if input_value and re.search(r"[;&|`$()]", input_value):
        return False, f"Potential injection detected in file pattern: {input_value}"
    return True, ""


def _validate_report_format(input_value: str) -> tuple[bool, str]:
    """Validate report format."""
    if input_value not in ["json", "sarif"]:
        return False, "Invalid report format. Must be 'json' or 'sarif'"
    return True, ""


def _validate_plugin_list(input_value: str) -> tuple[bool, str]:
    """Validate plugin list format."""
    if input_value and re.search(r"[;&|`$()]", input_value):
        return False, f"Potential injection detected in plugin list: {input_value}"
    return True, ""


def _validate_prefix(input_value: str) -> tuple[bool, str]:
    """Validate prefix format."""
    if input_value and re.search(r"[;&|`$()]", input_value):
        return False, f"Potential injection detected in prefix: {input_value}"
    return True, ""


def _validate_terraform_version(input_value: str) -> tuple[bool, str]:
    """Validate terraform version format."""
    if input_value and input_value.lower() == "latest":
        return True, ""
    if input_value and input_value.startswith("v"):
        return False, f"Terraform version should not start with 'v': {input_value}"
    if input_value and not re.match(r"^[0-9]+\.[0-9]+(\.[0-9]+)?", input_value):
        return False, f"Invalid terraform version format: {input_value}"
    return True, ""


def _validate_php_extensions(input_value: str) -> tuple[bool, str]:
    """Validate PHP extensions format."""
    if input_value and re.search(r"[;&|`$()@#]", input_value):
        return False, f"Potential injection detected in PHP extensions: {input_value}"
    if input_value and not re.match(r"^[a-zA-Z0-9_,\s]+$", input_value):
        return False, f"Invalid PHP extensions format: {input_value}"
    return True, ""


def _validate_coverage_driver(input_value: str) -> tuple[bool, str]:
    """Validate coverage driver."""
    if input_value not in ["none", "xdebug", "pcov", "xdebug3"]:
        return False, "Invalid coverage driver. Must be 'none', 'xdebug', 'pcov', or 'xdebug3'"
    return True, ""


# Validation registry mapping types to functions and their argument requirements
VALIDATION_REGISTRY = {
    "boolean": (_validate_boolean, "input_name"),
    "docker_architectures": (_validate_docker_architectures, "value_only"),
    "registry": (_validate_registry, "action_name"),
    "file_path": (_validate_file_path, "value_only"),
    "backoff_strategy": (_validate_backoff_strategy, "value_only"),
    "shell_type": (_validate_shell_type, "value_only"),
    "docker_image_name": (_validate_docker_image_name, "value_only"),
    "docker_tag": (_validate_docker_tag, "value_only"),
    "docker_password": (_validate_docker_password, "value_only"),
    "go_version": (_validate_go_version, "value_only"),
    "timeout_with_unit": (_validate_timeout_with_unit, "value_only"),
    "linter_list": (_validate_linter_list, "value_only"),
    "semantic_version": (_validate_version_types, "value_only"),
    "calver_version": (_validate_version_types, "value_only"),
    "flexible_version": (_validate_version_types, "value_only"),
    "file_pattern": (_validate_file_pattern, "value_only"),
    "report_format": (_validate_report_format, "value_only"),
    "plugin_list": (_validate_plugin_list, "value_only"),
    "prefix": (_validate_prefix, "value_only"),
    "terraform_version": (_validate_terraform_version, "value_only"),
    "php_extensions": (_validate_php_extensions, "value_only"),
    "coverage_driver": (_validate_coverage_driver, "value_only"),
}


def _load_validation_rules(action_dir: str) -> tuple[dict, bool]:
    """Load validation rules for an action."""
    action_name = Path(action_dir).name
    script_dir = Path(__file__).resolve().parent
    project_root = script_dir.parent.parent
    rules_file = project_root / "validate-inputs" / "rules" / f"{action_name}.yml"

    if not rules_file.exists():
        return {}, False

    try:
        with Path(rules_file).open(encoding="utf-8") as f:
            return yaml.safe_load(f), True
    except Exception as e:
        print(f"Warning: Could not load centralized rules for {action_name}: {e}", file=sys.stderr)
        return {}, False


def _get_validation_type(input_name: str, rules_data: dict) -> str | None:
    """Get validation type for an input from rules."""
    conventions = rules_data.get("conventions", {})
    overrides = rules_data.get("overrides", {})

    # Check overrides first, then conventions
    if input_name in overrides:
        return overrides[input_name]
    if input_name in conventions:
        return conventions[input_name]
    return None


def _validate_with_centralized_rules(
    input_name: str,
    input_value: str,
    action_dir: str,
    validator: ActionValidator,
) -> tuple[bool, str, bool]:
    """Validate input using centralized validation rules."""
    rules_data, rules_loaded = _load_validation_rules(action_dir)
    if not rules_loaded:
        return True, "", False

    action_name = Path(action_dir).name
    required_inputs = rules_data.get("required_inputs", [])

    # Check if input is required and empty
    if input_name in required_inputs and (not input_value or input_value.strip() == ""):
        return False, f"Required input '{input_name}' cannot be empty", True

    validation_type = _get_validation_type(input_name, rules_data)
    if validation_type is None:
        return True, "", False

    # Handle special validator-based types
    if validation_type == "github_token":
        token_valid, token_error = validator.validate_github_token(input_value, action_dir)
        return token_valid, token_error, True
    if validation_type == "namespace_with_lookahead":
        ns_valid, ns_error = validator.validate_namespace_with_lookahead(input_value)
        return ns_valid, ns_error, True

    # Use registry for other validation types
    if validation_type in VALIDATION_REGISTRY:
        validate_func, arg_type = VALIDATION_REGISTRY[validation_type]

        if arg_type == "value_only":
            is_valid, error_msg = validate_func(input_value)
        elif arg_type == "input_name":
            is_valid, error_msg = validate_func(input_value, input_name)
        elif arg_type == "action_name":
            is_valid, error_msg = validate_func(input_value, action_name)
        else:
            return False, f"Unknown validation argument type: {arg_type}", True

        return is_valid, error_msg, True

    return True, "", True


def _validate_special_inputs(
    input_name: str,
    input_value: str,
    action_dir: str,
    validator: ActionValidator,
) -> tuple[bool, str, bool]:
    """Handle special input validation cases."""
    action_name = Path(action_dir).name

    if action_name == "docker-build":
        is_valid, error_message = _validate_docker_build_input(input_name, input_value)
        return is_valid, error_message, True

    if input_name == "token" and action_name in [
        "csharp-publish",
        "eslint-fix",
        "pr-lint",
        "pre-commit",
    ]:
        # Special handling for GitHub tokens
        token_valid, token_error = validator.validate_github_token(input_value, action_dir)
        return token_valid, token_error, True

    if input_name == "namespace" and action_name == "csharp-publish":
        # Special handling for namespace with lookahead
        ns_valid, ns_error = validator.validate_namespace_with_lookahead(input_value)
        return ns_valid, ns_error, True

    return True, "", False


def _validate_with_patterns(
    input_name: str,
    input_value: str,
    patterns: dict,
    validator: ActionValidator,
) -> tuple[bool, str, bool]:
    """Validate input using extracted patterns."""
    if input_name not in patterns:
        return True, "", False

    for pattern in patterns[input_name]:
        pattern_valid, pattern_error = validator.validate_input_pattern(
            input_value,
            pattern,
        )
        if not pattern_valid:
            return False, pattern_error, True

    return True, "", True


def _handle_test_mode(expected_result: str, *, is_valid: bool) -> None:
    """Handle test mode output and exit."""
    if (expected_result == "success" and is_valid) or (
        expected_result == "failure" and not is_valid
    ):
        sys.exit(0)  # Test expectation met
    sys.exit(1)  # Test expectation not met


def _handle_validation_mode(*, is_valid: bool, error_message: str) -> None:
    """Handle validation mode output and exit."""
    if is_valid:
        print("VALID")
        sys.exit(0)
    print(f"INVALID: {error_message}")
    sys.exit(1)


def _handle_property_mode(args: dict) -> None:
    """Handle property checking mode."""
    result = get_input_property(args["action_file"], args["input_name"], args["property"])
    print(result)


def _handle_inputs_mode(args: dict) -> None:
    """Handle inputs listing mode."""
    inputs = get_action_inputs(args["action_file"])
    for input_name in inputs:
        print(input_name)


def _handle_outputs_mode(args: dict) -> None:
    """Handle outputs listing mode."""
    outputs = get_action_outputs(args["action_file"])
    for output_name in outputs:
        print(output_name)


def _handle_name_mode(args: dict) -> None:
    """Handle name getting mode."""
    name = get_action_name(args["action_file"])
    print(name)


def _perform_validation_steps(args: dict) -> tuple[bool, str]:
    """Perform all validation steps and return result."""
    # Resolve action file path
    action_file = _resolve_action_file_path(args["action_dir"])

    # Initialize validator and extract patterns
    validator = ActionValidator()
    patterns = extract_validation_patterns(action_file)

    # Perform security validation (always performed)
    security_valid, security_error = validator.validate_security_patterns(args["input_value"])
    if not security_valid:
        return False, security_error

    # Perform input-specific validation
    # Check centralized rules first
    is_valid, error_message, has_validation = _validate_with_centralized_rules(
        args["input_name"],
        args["input_value"],
        args["action_dir"],
        validator,
    )

    # If no centralized validation, check special input cases
    if not has_validation:
        is_valid, error_message, has_validation = _validate_special_inputs(
            args["input_name"],
            args["input_value"],
            args["action_dir"],
            validator,
        )

    # If no special validation, try pattern-based validation
    if not has_validation:
        is_valid, error_message, has_validation = _validate_with_patterns(
            args["input_name"],
            args["input_value"],
            patterns,
            validator,
        )

    return is_valid, error_message


def _handle_validation_mode_main(args: dict) -> None:
    """Handle validation mode from main function."""
    is_valid, error_message = _perform_validation_steps(args)

    # Handle output based on mode
    if args["expected_result"]:
        _handle_test_mode(args["expected_result"], is_valid=is_valid)
    _handle_validation_mode(is_valid=is_valid, error_message=error_message)


def main():
    """Command-line interface for the validation module."""
    args = _parse_command_line_args()

    # Dispatch to appropriate mode handler
    mode_handlers = {
        "property": _handle_property_mode,
        "inputs": _handle_inputs_mode,
        "outputs": _handle_outputs_mode,
        "name": _handle_name_mode,
        "validation": _handle_validation_mode_main,
    }

    if args["mode"] in mode_handlers:
        mode_handlers[args["mode"]](args)
    else:
        print(f"Unknown mode: {args['mode']}")
        sys.exit(1)


if __name__ == "__main__":
    main()
