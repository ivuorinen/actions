#!/usr/bin/env python3
"""Debug utility for testing validators.

This tool helps debug validation issues by:
- Testing validators directly with sample inputs
- Showing which validator would be used for inputs
- Tracing validation flow
- Reporting detailed error information
"""

from __future__ import annotations

import argparse
import json
import logging
import sys
from pathlib import Path
from typing import TYPE_CHECKING

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent))

from validators.conventions import ConventionBasedValidator

if TYPE_CHECKING:
    from validators.base import BaseValidator
from validators.registry import ValidatorRegistry

# Set up logging
logging.basicConfig(
    level=logging.INFO,
    format="%(levelname)-8s %(name)s: %(message)s",
)
logger = logging.getLogger("debug-validator")


class ValidatorDebugger:
    """Debugging utility for validators."""

    def __init__(self, *, verbose: bool = False) -> None:
        """Initialize the debugger.

        Args:
            verbose: Enable verbose output
        """
        self.verbose = verbose
        self.registry = ValidatorRegistry()

        if verbose:
            logging.getLogger().setLevel(logging.DEBUG)

    def debug_action(self, action_type: str, inputs: dict[str, str]) -> None:
        """Debug validation for an action.

        Args:
            action_type: The action type to validate
            inputs: Dictionary of inputs to validate
        """
        print(f"\n{'=' * 60}")
        print(f"Debugging: {action_type}")
        print(f"{'=' * 60}\n")

        # Get the validator
        print("1. Getting validator...")
        validator = self.registry.get_validator(action_type)
        print(f"   Validator: {validator.__class__.__name__}")
        print(f"   Module: {validator.__class__.__module__}\n")

        # Show required inputs
        if hasattr(validator, "get_required_inputs"):
            required = validator.get_required_inputs()
            if required:
                print("2. Required inputs:")
                for inp in required:
                    status = "✓" if inp in inputs else "✗"
                    print(f"   {status} {inp}")
                print()

        # Validate inputs
        print("3. Validating inputs...")
        result = validator.validate_inputs(inputs)
        print(f"   Result: {'PASS' if result else 'FAIL'}\n")

        # Show errors
        if validator.errors:
            print("4. Validation errors:")
            for i, error in enumerate(validator.errors, 1):
                print(f"   {i}. {error}")
            print()
        else:
            print("4. No validation errors\n")

        # Show validation details for each input
        if self.verbose:
            self.show_input_details(validator, inputs)

    def show_input_details(self, validator: BaseValidator, inputs: dict[str, str]) -> None:
        """Show detailed validation info for each input.

        Args:
            validator: The validator instance
            inputs: Dictionary of inputs
        """
        print("5. Input validation details:")

        # If it's a convention-based validator, show which validator would be used
        if isinstance(validator, ConventionBasedValidator):
            for input_name, value in inputs.items():
                mapper = getattr(validator, "_convention_mapper", None)
                validator_type = mapper.get_validator_type(input_name) if mapper else None
                print(f"\n   {input_name}:")
                print(f"     Value: {value[:50]}..." if len(value) > 50 else f"     Value: {value}")
                print(f"     Validator: {validator_type or 'BaseValidator (default)'}")

                # Try to validate individually to see specific errors
                if validator_type:
                    # Use registry to get validator instance
                    sub_validator = self.registry.get_validator_by_type(validator_type)
                    if sub_validator:
                        # Clear previous errors
                        sub_validator.clear_errors()

                        # Validate based on type
                        valid = self._validate_single_input(
                            sub_validator,
                            validator_type,
                            input_name,
                            value,
                        )

                        print(f"     Valid: {'✓' if valid else '✗'}")
                        if sub_validator.errors:
                            for error in sub_validator.errors:
                                print(f"     Error: {error}")
        print()

    def _validate_single_input(
        self,
        validator: BaseValidator,
        validator_type: str,
        input_name: str,
        value: str,
    ) -> bool:
        """Validate a single input with appropriate method.

        Args:
            validator: The validator instance
            validator_type: Type of validator
            input_name: Name of the input
            value: Value to validate

        Returns:
            True if valid, False otherwise
        """
        # Map validator types to validation methods
        method_map = {
            "boolean": "validate_boolean",
            "version": "validate_flexible_version",
            "token": "validate_github_token",
            "numeric": "validate_numeric_range",
            "file": "validate_file_path",
            "network": "validate_url",
            "docker": "validate_image_name",
            "security": "validate_no_injection",
            "codeql": "validate_languages",
        }

        method_name = method_map.get(validator_type)
        if method_name and hasattr(validator, method_name):
            method = getattr(validator, method_name)

            # Handle methods with different signatures
            if validator_type == "numeric":
                # Numeric validator needs min/max values
                # Try to detect from input name
                if "retries" in input_name:
                    return method(value, 1, 10, input_name)
                if "limit" in input_name or "max" in input_name:
                    return method(value, 0, 100, input_name)
                return method(value, 0, 999999, input_name)
            if validator_type == "codeql":
                # CodeQL expects a list
                return method([value], input_name)
            # Most validators take (value, field_name)
            return method(value, input_name)

        # Fallback to validate_inputs
        return validator.validate_inputs({input_name: value})

    def test_input_matching(self, input_names: list[str]) -> None:
        """Test which validators would be used for input names.

        Args:
            input_names: List of input names to test
        """
        print(f"\n{'=' * 60}")
        print("Input Name Matching Test")
        print(f"{'=' * 60}\n")

        conv_validator = ConventionBasedValidator("test")
        mapper = getattr(conv_validator, "_convention_mapper", None)
        if not mapper:
            print("Convention mapper not available")
            return

        print(f"{'Input Name':<30} {'Validator':<20} {'Pattern Type'}")
        print("-" * 70)

        for name in input_names:
            validator_type = mapper.get_validator_type(name)

            # Determine pattern type
            pattern_type = "none"
            if validator_type:
                if name in mapper.PATTERNS.get("exact", {}):
                    pattern_type = "exact"
                elif any(name.startswith(p) for p in mapper.PATTERNS.get("prefix", {})):
                    pattern_type = "prefix"
                elif any(name.endswith(p) for p in mapper.PATTERNS.get("suffix", {})):
                    pattern_type = "suffix"
                elif any(p in name for p in mapper.PATTERNS.get("contains", {})):
                    pattern_type = "contains"

            validator_display = validator_type or "BaseValidator"
            print(f"{name:<30} {validator_display:<20} {pattern_type}")

    def validate_file(self, filepath: Path) -> None:
        """Validate inputs from a JSON file.

        Args:
            filepath: Path to JSON file with inputs
        """
        try:
            with filepath.open() as f:
                data = json.load(f)

            action_type = data.get("action_type", "unknown")
            inputs = data.get("inputs", {})

            self.debug_action(action_type, inputs)

        except json.JSONDecodeError:
            logger.exception("Invalid JSON in %s", filepath)
            sys.exit(1)
        except FileNotFoundError:
            logger.exception("File not found: %s", filepath)
            sys.exit(1)

    def list_validators(self) -> None:
        """List all available validators."""
        print(f"\n{'=' * 60}")
        print("Available Validators")
        print(f"{'=' * 60}\n")

        # Core validators
        from validators.boolean import BooleanValidator
        from validators.codeql import CodeQLValidator
        from validators.docker import DockerValidator
        from validators.file import FileValidator
        from validators.network import NetworkValidator
        from validators.numeric import NumericValidator
        from validators.security import SecurityValidator
        from validators.token import TokenValidator
        from validators.version import VersionValidator

        validators = [
            ("BooleanValidator", BooleanValidator, "Boolean values (true/false)"),
            ("VersionValidator", VersionValidator, "Version strings (SemVer/CalVer)"),
            ("TokenValidator", TokenValidator, "Authentication tokens"),
            ("NumericValidator", NumericValidator, "Numeric ranges"),
            ("FileValidator", FileValidator, "File paths"),
            ("NetworkValidator", NetworkValidator, "URLs, emails, hostnames"),
            ("DockerValidator", DockerValidator, "Docker images, tags, platforms"),
            ("SecurityValidator", SecurityValidator, "Security patterns, injection"),
            ("CodeQLValidator", CodeQLValidator, "CodeQL languages and queries"),
        ]

        print("Core Validators:")
        for name, _cls, desc in validators:
            print(f"  {name:<20} - {desc}")

        # Check for custom validators
        print("\nCustom Validators:")
        custom_found = False
        for action_dir in Path().iterdir():
            if action_dir.is_dir() and not action_dir.name.startswith((".", "_")):
                custom_file = action_dir / "CustomValidator.py"
                if custom_file.exists():
                    print(f"  {action_dir.name:<20} - Custom validator")
                    custom_found = True

        if not custom_found:
            print("  None found")

        print()


def main() -> None:
    """Main entry point for the debug utility."""
    parser = argparse.ArgumentParser(
        description="Debug validator for GitHub Actions inputs",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Test specific inputs
  %(prog)s --action docker-build --input "image-name=myapp" --input "tag=v1.0.0"

  # Test from JSON file
  %(prog)s --file test-inputs.json

  # Test input name matching
  %(prog)s --test-matching github-token node-version dry-run

  # List available validators
  %(prog)s --list-validators
        """,
    )

    parser.add_argument(
        "--action",
        "-a",
        help="Action type to debug",
    )
    parser.add_argument(
        "--input",
        "-i",
        action="append",
        help="Input in format name=value (can be repeated)",
    )
    parser.add_argument(
        "--file",
        "-f",
        type=Path,
        help="JSON file with action_type and inputs",
    )
    parser.add_argument(
        "--test-matching",
        "-t",
        nargs="+",
        help="Test which validators match input names",
    )
    parser.add_argument(
        "--list-validators",
        "-l",
        action="store_true",
        help="List all available validators",
    )
    parser.add_argument(
        "--verbose",
        "-v",
        action="store_true",
        help="Enable verbose output",
    )

    args = parser.parse_args()

    # Create debugger
    debugger = ValidatorDebugger(verbose=args.verbose)

    # Handle different modes
    if args.list_validators:
        debugger.list_validators()

    elif args.test_matching:
        debugger.test_input_matching(args.test_matching)

    elif args.file:
        debugger.validate_file(args.file)

    elif args.action and args.input:
        # Parse inputs
        inputs = {}
        for input_str in args.input:
            if "=" not in input_str:
                logger.error("Invalid input format: %s (expected name=value)", input_str)
                sys.exit(1)

            name, value = input_str.split("=", 1)
            inputs[name] = value

        debugger.debug_action(args.action, inputs)

    else:
        parser.print_help()
        sys.exit(1)


if __name__ == "__main__":
    main()
