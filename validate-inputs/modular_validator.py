#!/usr/bin/env python
"""Modular GitHub Actions Input Validator.

This is the new entry point that uses the modular validation system.
It maintains backward compatibility while leveraging the new architecture.
"""

from __future__ import annotations

import logging
import os
from pathlib import Path
import sys

# Add validators module to path
sys.path.insert(0, str(Path(__file__).parent))

from validators.registry import get_validator

# Configure logging for GitHub Actions
logging.basicConfig(
    format="%(message)s",
    level=logging.INFO,
)
logger = logging.getLogger(__name__)


def main() -> None:
    """Main execution for GitHub Actions validation."""
    try:
        # Get action type from environment
        action_type = os.getenv("INPUT_ACTION_TYPE", "").strip()

        if not action_type:
            logger.error("::error::action-type is required but not provided")
            output_path = Path(os.environ["GITHUB_OUTPUT"])
            with output_path.open("a") as f:
                f.write("status=failure\n")
                f.write("error=action-type is required\n")
            sys.exit(1)

        # Convert to underscore format for consistency
        action_type = action_type.replace("-", "_")

        # Get validator for this action type
        # This will either load a custom validator or fall back to convention-based
        validator = get_validator(action_type)

        # Extract input environment variables
        inputs = {}
        for key, value in os.environ.items():
            if key.startswith("INPUT_") and key != "INPUT_ACTION_TYPE":
                # Create both underscore and dash versions
                underscore_name = key[6:].lower()
                inputs[underscore_name] = value

                # Also create dash version for compatibility
                if "_" in underscore_name:
                    dash_name = underscore_name.replace("_", "-")
                    inputs[dash_name] = value

        # Validate inputs
        output_path = Path(os.environ["GITHUB_OUTPUT"])
        if validator.validate_inputs(inputs):
            logger.info("::notice::All input validation checks passed")
            with output_path.open("a") as f:
                f.write("status=success\n")
        else:
            logger.error("::error::Input validation failed")
            for error in validator.errors:
                logger.error("::error::%s", error)
            with output_path.open("a") as f:
                f.write("status=failure\n")
                f.write(f"error={'; '.join(validator.errors)}\n")
            sys.exit(1)

    except (ValueError, RuntimeError, KeyError, OSError):
        logger.exception("::error::Validation script error")
        github_output = os.environ.get("GITHUB_OUTPUT", "")
        output_path = Path(github_output) if github_output else Path.home() / "github_output"
        with output_path.open("a") as f:
            f.write("status=failure\n")
            f.write("error=Validation script error\n")
        sys.exit(1)


if __name__ == "__main__":
    main()
