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

    # GitHub token patterns (using the same pattern as in the actions)
    GITHUB_TOKEN_PATTERNS = {
        "classic": r"^gh[efpousr]_[a-zA-Z0-9]{36}$",
        "fine_grained": r"^github_pat_[a-zA-Z0-9_]{50,255}$",
        "installation_token": r"^ghs_[a-zA-Z0-9]{36}$",
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

        # Check against all known GitHub token patterns
        for token_type, pattern in self.GITHUB_TOKEN_PATTERNS.items():
            if re.match(pattern, token):
                return True, ""

        return (
            False,
            "Invalid GitHub token format. Expected: gh[efpousr]_* (36 chars), github_pat_* (50-255 chars), or ghs_* (36 chars)",
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
            "Invalid namespace format. Must be 1-39 characters, alphanumeric and hyphens, no trailing hyphens",
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
            r"\.\./",  # Path traversal
            r"\\\.\\\.\\",  # Windows path traversal
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
        with open(action_file) as f:
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


def _parse_command_line_args():
    """Parse and validate command line arguments."""
    if len(sys.argv) < 4:
        print(
            "Usage: python3 validation.py <action_dir> <input_name> <input_value> [expected_result]",
        )
        print("Expected result: 'success' or 'failure' (default: auto-detect)")
        sys.exit(1)

    return {
        "action_dir": sys.argv[1],
        "input_name": sys.argv[2],
        "input_value": sys.argv[3],
        "expected_result": sys.argv[4] if len(sys.argv) > 4 else None,
    }


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


def _validate_special_inputs(
    input_name: str, input_value: str, action_dir: str, validator: ActionValidator
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
    input_name: str, input_value: str, patterns: dict, validator: ActionValidator
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


def _handle_test_mode(expected_result: str, is_valid: bool) -> None:
    """Handle test mode output and exit."""
    if (expected_result == "success" and is_valid) or (
        expected_result == "failure" and not is_valid
    ):
        sys.exit(0)  # Test expectation met
    sys.exit(1)  # Test expectation not met


def _handle_validation_mode(is_valid: bool, error_message: str) -> None:
    """Handle validation mode output and exit."""
    if is_valid:
        print("VALID")
        sys.exit(0)
    print(f"INVALID: {error_message}")
    sys.exit(1)


def main():
    """Command-line interface for the validation module."""
    # Parse command line arguments
    args = _parse_command_line_args()

    # Resolve action file path
    action_file = _resolve_action_file_path(args["action_dir"])

    # Initialize validator and extract patterns
    validator = ActionValidator()
    patterns = extract_validation_patterns(action_file)

    # Perform security validation (always performed)
    security_valid, security_error = validator.validate_security_patterns(args["input_value"])
    if not security_valid:
        if args["expected_result"]:
            _handle_test_mode(expected_result=args["expected_result"], is_valid=False)
        _handle_validation_mode(is_valid=False, error_message=security_error)

    # Perform input-specific validation
    # Check special input cases first
    is_valid, error_message, has_validation = _validate_special_inputs(
        args["input_name"], args["input_value"], args["action_dir"], validator
    )

    # If no special validation, try pattern-based validation
    if not has_validation:
        is_valid, error_message, has_validation = _validate_with_patterns(
            args["input_name"], args["input_value"], patterns, validator
        )

    # Handle output based on mode
    if args["expected_result"]:
        _handle_test_mode(args["expected_result"], is_valid)
    _handle_validation_mode(is_valid, error_message)


if __name__ == "__main__":
    main()
