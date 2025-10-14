"""Tests for the base validator class."""

from __future__ import annotations

from pathlib import Path
import sys
import unittest
from unittest.mock import patch

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent.parent))

from validators.base import BaseValidator


class ConcreteValidator(BaseValidator):
    """Concrete implementation for testing."""

    def validate_inputs(self, inputs: dict[str, str]) -> bool:
        """Simple validation implementation."""
        return self.validate_required_inputs(inputs)

    def get_required_inputs(self) -> list[str]:
        """Return test required inputs."""
        return ["required1", "required2"]

    def get_validation_rules(self) -> dict:
        """Return test validation rules."""
        return {"test": "rules"}


class TestBaseValidator(unittest.TestCase):  # pylint: disable=too-many-public-methods
    """Test the BaseValidator abstract class."""

    def setUp(self):  # pylint: disable=attribute-defined-outside-init
        """Set up test fixtures."""
        self.validator = ConcreteValidator("test_action")

    def test_initialization(self):
        """Test validator initialization."""
        assert self.validator.action_type == "test_action"
        assert self.validator.errors == []
        assert self.validator._rules == {}

    def test_error_management(self):
        """Test error handling methods."""
        # Initially no errors
        assert not self.validator.has_errors()

        # Add an error
        self.validator.add_error("Test error")
        assert self.validator.has_errors()
        assert len(self.validator.errors) == 1
        assert self.validator.errors[0] == "Test error"

        # Add another error
        self.validator.add_error("Another error")
        assert len(self.validator.errors) == 2

        # Clear errors
        self.validator.clear_errors()
        assert not self.validator.has_errors()
        assert self.validator.errors == []

    def test_validate_required_inputs(self):
        """Test required input validation."""
        # Missing required inputs
        inputs = {}
        assert not self.validator.validate_required_inputs(inputs)
        assert len(self.validator.errors) == 2

        # Clear for next test
        self.validator.clear_errors()

        # One required input missing
        inputs = {"required1": "value1"}
        assert not self.validator.validate_required_inputs(inputs)
        assert len(self.validator.errors) == 1
        assert "required2" in self.validator.errors[0]

        # Clear for next test
        self.validator.clear_errors()

        # All required inputs present
        inputs = {"required1": "value1", "required2": "value2"}
        assert self.validator.validate_required_inputs(inputs)
        assert not self.validator.has_errors()

        # Empty required input
        inputs = {"required1": "value1", "required2": "  "}
        assert not self.validator.validate_required_inputs(inputs)
        assert "required2" in self.validator.errors[0]

    def test_validate_security_patterns(self):
        """Test security pattern validation."""
        # Safe value
        assert self.validator.validate_security_patterns("safe_value")
        assert not self.validator.has_errors()

        # Command injection patterns
        dangerous_values = [
            "value; rm -rf /",
            "value && malicious",
            "value || exit",
            "value | grep",
            "value `command`",
            "$(command)",
            "${variable}",
            "../../../etc/passwd",
            "..\\..\\windows",
        ]

        for dangerous in dangerous_values:
            self.validator.clear_errors()
            assert not self.validator.validate_security_patterns(dangerous, "test_input"), (
                f"Failed to detect dangerous pattern: {dangerous}"
            )
            assert self.validator.has_errors()

    def test_validate_path_security(self):
        """Test path security validation."""
        # Valid paths
        valid_paths = [
            "relative/path/file.txt",
            "file.txt",
            "./local/file",
            "subdir/another/file.yml",
        ]

        for path in valid_paths:
            self.validator.clear_errors()
            assert self.validator.validate_path_security(path), (
                f"Incorrectly rejected valid path: {path}"
            )
            assert not self.validator.has_errors()

        # Invalid paths
        invalid_paths = [
            "/absolute/path",
            "C:\\Windows\\System32",
            "../parent/directory",
            "path/../../../etc",
            "..\\..\\windows",
        ]

        for path in invalid_paths:
            self.validator.clear_errors()
            assert not self.validator.validate_path_security(path), (
                f"Failed to reject invalid path: {path}"
            )
            assert self.validator.has_errors()

    def test_validate_empty_allowed(self):
        """Test empty value validation."""
        # Non-empty value
        assert self.validator.validate_empty_allowed("value", "test")
        assert not self.validator.has_errors()

        # Empty string
        assert not self.validator.validate_empty_allowed("", "test")
        assert self.validator.has_errors()
        assert "cannot be empty" in self.validator.errors[0]

        # Whitespace only
        self.validator.clear_errors()
        assert not self.validator.validate_empty_allowed("   ", "test")
        assert self.validator.has_errors()

    @patch("pathlib.Path.exists")
    @patch("pathlib.Path.open")
    @patch("yaml.safe_load")
    def test_load_rules(self, mock_yaml_load, mock_path_open, mock_exists):
        """Test loading validation rules from YAML."""
        # The mock_path_open is handled by the patch decorator
        del mock_path_open  # Unused but required by decorator
        # Mock YAML content
        mock_rules = {
            "required_inputs": ["input1"],
            "conventions": {"token": "github_token"},
        }
        mock_yaml_load.return_value = mock_rules
        mock_exists.return_value = True

        # Create a Path object
        from pathlib import Path

        rules_path = Path("/fake/path/rules.yml")

        # Load the rules
        rules = self.validator.load_rules(rules_path)

        assert rules == mock_rules
        assert self.validator._rules == mock_rules

    def test_github_actions_output(self):
        """Test GitHub Actions output formatting."""
        # Success case
        output = self.validator.get_github_actions_output()
        assert output["status"] == "success"
        assert output["error"] == ""

        # Failure case
        self.validator.add_error("Error 1")
        self.validator.add_error("Error 2")
        output = self.validator.get_github_actions_output()
        assert output["status"] == "failure"
        assert output["error"] == "Error 1; Error 2"


if __name__ == "__main__":
    unittest.main()
