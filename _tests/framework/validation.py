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

from pathlib import Path
import re
import sys
from typing import Dict, List, Tuple


class ActionValidator:
    """Handles validation of GitHub Action inputs using Python regex engine."""

    # Common regex patterns that require PCRE features
    COMPLEX_PATTERNS = {
        "lookahead": r"\(\?\=",
        "lookbehind": r"\(\?\<[\=\!]",
        "negative_lookahead": r"\(\?\!",
        "named_groups": r"\(\?\P\<\w+\>",
        "conditional": r"\(\?\(",
    }

    # GitHub token patterns (using the same pattern as in the actions)
    GITHUB_TOKEN_PATTERNS = {
        "classic": r"^gh[efpousr]_[a-zA-Z0-9]{36}$",
        "fine_grained": r"^github_pat_[a-zA-Z0-9_]{82}$",
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

    def validate_github_token(self, token: str, action_dir: str = "") -> Tuple[bool, str]:
        """
        Validate GitHub token format using proper PCRE patterns.

        Args:
            token: The token to validate
            action_dir: The action directory (for context-specific validation)

        Returns:
            Tuple of (is_valid, error_message)
        """
        # Actions that require tokens shouldn't accept empty values
        if action_dir in ["csharp-publish", "eslint-fix", "pr-lint", "pre-commit"]:
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
            "Invalid GitHub token format. Expected: gh[efpousr]_* (36 chars), github_pat_* (82 chars), or ghs_* (36 chars)",
        )

    def validate_namespace_with_lookahead(self, namespace: str) -> Tuple[bool, str]:
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

    def validate_input_pattern(self, input_value: str, pattern: str) -> Tuple[bool, str]:
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

    def validate_security_patterns(self, input_value: str) -> Tuple[bool, str]:
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


def extract_validation_patterns(action_file: str) -> Dict[str, List[str]]:
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
                r'\[\[\s*["\']?\$\{\{\s*inputs\.(\w+(?:-\w+)*)\s*\}\}["\']?\s*=~\s*([^\]]+)\]\]',
                validation_script,
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


def main():
    """Command-line interface for the validation module."""
    if len(sys.argv) < 4:
        print(
            "Usage: python3 validation.py <action_dir> <input_name> <input_value> [expected_result]",
        )
        print("Expected result: 'success' or 'failure' (default: auto-detect)")
        sys.exit(1)

    action_dir = sys.argv[1]
    input_name = sys.argv[2]
    input_value = sys.argv[3]
    expected_result = sys.argv[4] if len(sys.argv) > 4 else None

    # Handle both absolute and relative paths
    action_dir_path = Path(action_dir)
    if not action_dir_path.is_absolute():
        # If relative, assume we're in _tests/framework and actions are at ../../
        script_dir = Path(__file__).resolve().parent
        project_root = script_dir.parent.parent
        action_file = str(project_root / action_dir / "action.yml")
    else:
        action_file = f"{action_dir}/action.yml"
    validator = ActionValidator()

    # Extract validation patterns from the action file
    patterns = extract_validation_patterns(action_file)

    # Perform validation
    is_valid = True
    error_message = ""

    # 1. Security validation (always performed)
    security_valid, security_error = validator.validate_security_patterns(input_value)
    if not security_valid:
        is_valid = False
        error_message = security_error

    # 2. Input-specific validation
    if is_valid:
        # Check if there are specific validation patterns for this input
        has_specific_validation = False

        # For docker-build, use the centralized validation system
        # Extract just the action name from the path
        action_name = Path(action_dir).name
        if action_name == "docker-build":
            # Docker-build uses validate-inputs action - simulate its behavior
            # Empty build-args should be valid (it's an optional input)
            if input_name == "build-args" and input_value == "":
                is_valid = True
                has_specific_validation = True
            # All other docker-build inputs pass through centralized validation
            # which already handled security checks above
            else:
                has_specific_validation = True

        elif input_name == "token":
            # Special handling for GitHub tokens (only for actions that actually validate tokens)
            if action_dir in ["csharp-publish", "eslint-fix", "pr-lint", "pre-commit"]:
                token_valid, token_error = validator.validate_github_token(input_value, action_dir)
                if not token_valid:
                    is_valid = False
                    error_message = token_error
                has_specific_validation = True
        elif input_name == "namespace" and action_dir == "csharp-publish":
            # Special handling for namespace with lookahead
            ns_valid, ns_error = validator.validate_namespace_with_lookahead(input_value)
            if not ns_valid:
                is_valid = False
                error_message = ns_error
            has_specific_validation = True
        elif input_name in patterns:
            # Use extracted patterns
            for pattern in patterns[input_name]:
                if validator.is_complex_pattern(pattern):
                    pattern_valid, pattern_error = validator.validate_input_pattern(
                        input_value,
                        pattern,
                    )
                    if not pattern_valid:
                        is_valid = False
                        error_message = pattern_error
                        break
            has_specific_validation = True

        # For actions without specific validation, only apply basic security checks
        # which have already been performed above

    # Output result
    if expected_result:
        # Test mode: return success if expectation matches result
        if (expected_result == "success" and is_valid) or (
            expected_result == "failure" and not is_valid
        ):
            sys.exit(0)  # Test expectation met
        else:
            sys.exit(1)  # Test expectation not met
    # Validation mode: return based on validation result
    elif is_valid:
        print("VALID")
        sys.exit(0)
    else:
        print(f"INVALID: {error_message}")
        sys.exit(1)


if __name__ == "__main__":
    main()
