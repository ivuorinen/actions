"""Tests for the main validator entry point."""

import os
from pathlib import Path
import sys
import tempfile
from unittest.mock import MagicMock, patch

import pytest

# Add the parent directory to the path
sys.path.insert(0, str(Path(__file__).parent.parent))


class TestValidatorScript:
    """Test the main validator.py script functionality."""

    def setup_method(self):
        """Set up test environment before each test."""
        # Clear environment variables
        for key in list(os.environ.keys()):
            if key.startswith("INPUT_"):
                del os.environ[key]

        # Create temporary output file
        self.temp_output = tempfile.NamedTemporaryFile(mode="w", delete=False)
        os.environ["GITHUB_OUTPUT"] = self.temp_output.name
        self.temp_output.close()

    def teardown_method(self):
        """Clean up after each test."""
        # Clean up temp file
        if hasattr(self, "temp_output") and Path(self.temp_output.name).exists():
            os.unlink(self.temp_output.name)

        # Clear environment
        for key in list(os.environ.keys()):
            if key.startswith("INPUT_"):
                del os.environ[key]

    def test_main_no_action_type(self):
        """Test that validator fails when no action type is provided."""
        # Remove action type
        if "INPUT_ACTION_TYPE" in os.environ:
            del os.environ["INPUT_ACTION_TYPE"]

        from validator import main

        with pytest.raises(SystemExit) as exc_info:
            main()
        assert exc_info.value.code == 1

    def test_main_with_valid_inputs(self):
        """Test validator with valid inputs."""
        os.environ["INPUT_ACTION_TYPE"] = "docker-build"
        os.environ["INPUT_CONTEXT"] = "."  # Required by docker-build custom validator
        os.environ["INPUT_IMAGE"] = "myapp"
        os.environ["INPUT_TAG"] = "v1.0.0"

        from validator import main

        # Should not raise SystemExit
        main()

        # Check output file
        with Path(self.temp_output.name).open() as f:
            output = f.read()
        assert "status=success" in output
        assert "action=docker_build" in output

    def test_main_with_invalid_inputs(self):
        """Test validator with invalid inputs."""
        os.environ["INPUT_ACTION_TYPE"] = "docker-build"
        os.environ["INPUT_IMAGE"] = "INVALID-IMAGE"  # Uppercase not allowed

        from validator import main

        with pytest.raises(SystemExit) as exc_info:
            main()
        assert exc_info.value.code == 1

        # Check output file
        with Path(self.temp_output.name).open() as f:
            output = f.read()
        assert "status=failure" in output

    def test_main_collects_all_inputs(self):
        """Test that validator collects all INPUT_ environment variables."""
        os.environ["INPUT_ACTION_TYPE"] = "test-action"
        os.environ["INPUT_FIRST_INPUT"] = "value1"
        os.environ["INPUT_SECOND_INPUT"] = "value2"
        os.environ["INPUT_THIRD_INPUT"] = "value3"

        # Mock the validator to capture inputs
        mock_validator = MagicMock()
        mock_validator.validate_inputs.return_value = True
        mock_validator.errors = []

        # Patch get_validator at module level
        with patch("validator.get_validator") as mock_get_validator:
            mock_get_validator.return_value = mock_validator

            from validator import main

            main()

        # Check that validate_inputs was called with correct inputs
        mock_validator.validate_inputs.assert_called_once()
        inputs = mock_validator.validate_inputs.call_args[0][0]
        # Should have both underscore and dash versions
        assert inputs == {
            "first_input": "value1",
            "first-input": "value1",
            "second_input": "value2",
            "second-input": "value2",
            "third_input": "value3",
            "third-input": "value3",
        }

    def test_main_output_format(self):
        """Test that output is formatted correctly for GitHub Actions."""
        os.environ["INPUT_ACTION_TYPE"] = "test-action"

        from validators.base import BaseValidator
        from validators.registry import ValidatorRegistry

        class TestValidator(BaseValidator):
            def validate_inputs(self, inputs):  # noqa: ARG002
                return True

            def get_required_inputs(self):
                return []

            def get_validation_rules(self):
                return {}

        registry = ValidatorRegistry()
        registry.register_validator("test-action", TestValidator)

        from validator import main

        main()

        # Check GitHub output format
        with Path(self.temp_output.name).open() as f:
            output = f.read()

        assert "status=success" in output
        assert "action=test_action" in output
        assert "inputs_validated=" in output

    def test_main_error_reporting(self):
        """Test that validation errors are properly reported."""
        os.environ["INPUT_ACTION_TYPE"] = "test-action"
        os.environ["INPUT_TEST"] = "invalid"

        # Create a mock validator that returns errors
        mock_validator = MagicMock()
        mock_validator.validate_inputs.return_value = False
        mock_validator.errors = ["Test error 1", "Test error 2"]

        # Patch get_validator at module level
        with patch("validator.get_validator") as mock_get_validator:
            mock_get_validator.return_value = mock_validator

            from validator import main

            with pytest.raises(SystemExit) as exc_info:
                main()
            assert exc_info.value.code == 1

        # Check output file contains error count
        with Path(self.temp_output.name).open() as f:
            output = f.read()
        assert "status=failure" in output
        assert "errors=2" in output


class TestValidatorIntegration:
    """Integration tests for the validator system."""

    def setup_method(self):
        """Set up test environment."""
        self.temp_output = tempfile.NamedTemporaryFile(mode="w", delete=False)
        os.environ["GITHUB_OUTPUT"] = self.temp_output.name
        self.temp_output.close()

    def teardown_method(self):
        """Clean up after tests."""
        if hasattr(self, "temp_output") and Path(self.temp_output.name).exists():
            os.unlink(self.temp_output.name)

        # Clear environment
        for key in list(os.environ.keys()):
            if key.startswith("INPUT_"):
                del os.environ[key]

    def test_registry_loads_correct_validator(self):
        """Test that registry loads the correct validator for each action."""
        from validators.registry import ValidatorRegistry

        registry = ValidatorRegistry()

        # Test that we get validators for known actions
        docker_validator = registry.get_validator("docker-build")
        assert docker_validator is not None
        assert hasattr(docker_validator, "validate_inputs")

        # Test fallback for unknown action
        unknown_validator = registry.get_validator("unknown-action")
        assert unknown_validator is not None
        assert hasattr(unknown_validator, "validate_inputs")

    def test_custom_validator_loading(self):
        """Test that custom validators are loaded when available."""
        from validators.registry import ValidatorRegistry

        registry = ValidatorRegistry()

        # sync-labels has a custom validator
        validator = registry.get_validator("sync-labels")
        assert validator is not None
        assert validator.__class__.__name__ == "CustomValidator"

    def test_convention_based_validation(self):
        """Test that convention-based validation works."""
        from validators.registry import ValidatorRegistry

        registry = ValidatorRegistry()
        validator = registry.get_validator("test-action")

        # Test different convention patterns
        test_inputs = {
            "dry-run": "true",  # Boolean
            "token": "${{ github.token }}",  # Token
            "version": "1.2.3",  # Version
            "email": "test@example.com",  # Email
        }

        # Convention validator should handle these
        result = validator.validate_inputs(test_inputs)
        # The result depends on the specific validation logic
        assert isinstance(result, bool)
