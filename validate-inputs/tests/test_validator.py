"""Tests for the main validator entry point."""

import os
import sys
import tempfile
from pathlib import Path
from unittest.mock import MagicMock, patch

import pytest  # pylint: disable=import-error

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
        # Need persistent file for teardown, can't use context manager
        self.temp_output = tempfile.NamedTemporaryFile(mode="w", delete=False)  # noqa: SIM115
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
        # Need persistent file for teardown, can't use context manager
        self.temp_output = tempfile.NamedTemporaryFile(mode="w", delete=False)  # noqa: SIM115
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

        # All four inputs are valid for their detected conventions, so the
        # convention validator must ACCEPT them. The old assertion
        # (`isinstance(result, bool)`) accepted both True and False, so a
        # regression inverting the verdict would have passed silently.
        assert validator.validate_inputs(test_inputs) is True
        assert validator.errors == []

        # A malformed value for one convention must flip the verdict to False.
        invalid = registry.get_validator("test-action-invalid")
        assert (
            invalid.validate_inputs(
                {
                    "dry-run": "true",
                    "token": "${{ github.token }}",
                    "version": "1.2.3",
                    "email": "not-an-email",
                },
            )
            is False
        )
        assert invalid.has_errors() is True


class TestSanitize:
    """Tests for _sanitize — GITHUB_OUTPUT injection prevention (N-094 regression)."""

    def test_sanitize_safe_value(self):
        from validator import _sanitize

        assert _sanitize("safe") == "safe"
        assert _sanitize("success") == "success"

    def test_sanitize_strips_newlines(self):
        """Newlines in a value must not inject extra keys into GITHUB_OUTPUT."""
        from validator import _sanitize

        assert _sanitize("line1\nline2") == "line1 line2"
        assert _sanitize("line1\r\nline2") == "line1 line2"
        assert _sanitize("key=val\nINJECTED=evil") == "key=val INJECTED=evil"

    def test_sanitize_strips_carriage_returns(self):
        from validator import _sanitize

        assert _sanitize("value\rmore") == "valuemore"

    def test_sanitize_non_string_input(self):
        from validator import _sanitize

        assert _sanitize(42) == "42"
        assert _sanitize(None) == "None"


class TestValidatorEntryPointBranches:
    """Cover live validator.py main() branches the suite previously skipped.

    pyproject's default coverage source is ``validators`` only, so the
    entry-point's action-name security gate, the fail-on-error switch, and the
    custom rules-file override had no regression guard.
    """

    def setup_method(self):
        for key in list(os.environ.keys()):
            if key.startswith("INPUT_"):
                del os.environ[key]
        # Need persistent file for teardown, can't use context manager
        self.temp_output = tempfile.NamedTemporaryFile(mode="w", delete=False)  # noqa: SIM115
        os.environ["GITHUB_OUTPUT"] = self.temp_output.name
        self.temp_output.close()

    def teardown_method(self):
        if hasattr(self, "temp_output") and Path(self.temp_output.name).exists():
            os.unlink(self.temp_output.name)
        for key in list(os.environ.keys()):
            if key.startswith("INPUT_"):
                del os.environ[key]

    @pytest.mark.parametrize("bad_name", ["../evil", "act;rm", "UPPER", "a b", "x|y", "$(id)"])
    def test_invalid_action_name_is_rejected(self, bad_name):
        """The _ACTION_TYPE_RE gate must reject shell/path metacharacters in the action name."""
        os.environ["INPUT_ACTION_TYPE"] = bad_name

        from validator import main

        with pytest.raises(SystemExit) as exc_info:
            main()
        assert exc_info.value.code == 1

    def test_fail_on_error_false_does_not_exit(self):
        """fail-on-error=false: a failing validation writes status=failure but does NOT exit."""
        os.environ["INPUT_ACTION_TYPE"] = "test-action"
        os.environ["INPUT_FAIL_ON_ERROR"] = "false"

        mock_validator = MagicMock()
        mock_validator.validate_inputs.return_value = False
        mock_validator.errors = ["boom"]
        mock_validator.get_validation_rules.return_value = {}

        with patch("validator.get_validator", return_value=mock_validator):
            from validator import main

            # Must return normally — no SystemExit.
            main()

        with Path(self.temp_output.name).open() as f:
            output = f.read()
        assert "status=failure" in output
        assert "errors=1" in output

    def test_rules_file_triggers_load_rules(self):
        """A custom rules-file (INPUT_RULES_FILE) is loaded onto the validator."""
        # Need persistent file across the patched main() call.
        rules = tempfile.NamedTemporaryFile(mode="w", suffix=".yml", delete=False)  # noqa: SIM115
        rules.write("rules: {}\n")
        rules.close()
        os.environ["INPUT_ACTION_TYPE"] = "test-action"
        os.environ["INPUT_RULES_FILE"] = rules.name

        mock_validator = MagicMock()
        mock_validator.validate_inputs.return_value = True
        mock_validator.get_validation_rules.return_value = {"x": 1}

        try:
            with patch("validator.get_validator", return_value=mock_validator):
                from validator import main

                main()
            mock_validator.load_rules.assert_called_once_with(Path(rules.name))
        finally:
            os.unlink(rules.name)

    def test_rules_count_falls_back_to_input_count(self):
        """When get_validation_rules() returns None, rules-applied falls back to the input count."""
        os.environ["INPUT_ACTION_TYPE"] = "test-action"
        os.environ["INPUT_ONLYONE"] = "value"

        mock_validator = MagicMock()
        mock_validator.validate_inputs.return_value = True
        mock_validator.errors = []
        mock_validator.get_validation_rules.return_value = None

        with patch("validator.get_validator", return_value=mock_validator):
            from validator import main

            main()

        with Path(self.temp_output.name).open() as f:
            output = f.read()
        # collect_inputs() saw exactly one INPUT_ (onlyone); ACTION_TYPE is excluded.
        assert "rules=1" in output
