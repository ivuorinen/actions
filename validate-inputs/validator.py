#!/usr/bin/env python3
"""GitHub Actions Input Validator.

This module validates inputs for GitHub Actions based on predefined rules.
"""

from __future__ import annotations

import logging
import os
from pathlib import Path
import sys

# Add current directory to path
sys.path.insert(0, str(Path(__file__).parent))

from validators.registry import get_validator

# Configure logging for GitHub Actions
logging.basicConfig(
    format="%(message)s",
    level=logging.INFO,
)
logger = logging.getLogger(__name__)


def collect_inputs() -> dict[str, str]:
    """Collect all inputs from environment variables.

    Returns:
        Dictionary of input names to values
    """
    inputs = {}
    for key, value in os.environ.items():
        if key.startswith("INPUT_") and key != "INPUT_ACTION_TYPE":
            input_name = key[6:].lower()
            inputs[input_name] = value

            # Also add dash version for compatibility
            if "_" in input_name:
                inputs[input_name.replace("_", "-")] = value
    return inputs


def write_output(status: str, action_type: str, **kwargs) -> None:
    """Write validation output to GitHub Actions output file.

    Args:
        status: Status to write (success or failure)
        action_type: The action type being validated
        **kwargs: Additional key-value pairs to write
    """
    output_file = os.environ.get("GITHUB_OUTPUT")
    if not output_file:
        return  # No output file configured

    try:
        output_path = Path(output_file)
        # Try to create parent directory if it doesn't exist
        output_path.parent.mkdir(parents=True, exist_ok=True)

        with output_path.open("a") as f:
            lines = [
                f"status={status}\n",
                f"action={action_type}\n",
            ]
            lines.extend(f"{key}={value}\n" for key, value in kwargs.items())
            f.writelines(lines)
    except OSError:
        logger.exception("::error::Validation script error: Could not write to output file")
        sys.exit(1)


def main() -> None:
    """Main validation entry point."""
    # Get the action type from environment
    action_type = os.environ.get("INPUT_ACTION_TYPE", "").strip()
    if not action_type:
        logger.error("::error::No action type provided")
        sys.exit(1)

    # Convert to standard format (replace dashes with underscores)
    action_type = action_type.replace("-", "_")

    # Get validator from registry
    # This will either load custom validator or fall back to convention-based
    validator = get_validator(action_type)

    # Collect all inputs
    inputs = collect_inputs()

    # Validate inputs
    logger.debug("::debug::Validating %d inputs for %s", len(inputs), action_type)

    if validator.validate_inputs(inputs):
        # Only show success message if not in quiet mode (for tests)
        if not os.environ.get("VALIDATOR_QUIET"):
            logger.info("✓ All input validation checks passed for %s", action_type)
        write_output("success", action_type, inputs_validated=len(inputs))
    else:
        # Report errors (suppress if in quiet mode for tests)
        if not os.environ.get("VALIDATOR_QUIET"):
            for error in validator.errors:
                logger.error("::error::%s", error)
            logger.error("✗ Input validation failed for %s", action_type)

        write_output(
            "failure",
            action_type,
            error="; ".join(validator.errors),
            errors=len(validator.errors),
        )
        sys.exit(1)


if __name__ == "__main__":
    main()
