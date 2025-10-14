"""Tests for validate-inputs custom validator."""
# pylint: disable=invalid-name  # Test file name matches action name

from pathlib import Path
import sys

# Add action directory to path to import custom validator
action_path = Path(__file__).parent.parent.parent / "validate-inputs"
if str(action_path) not in sys.path:
    sys.path.insert(0, str(action_path))

# Force reload to avoid cached imports from other test files
if "CustomValidator" in sys.modules:
    del sys.modules["CustomValidator"]

from CustomValidator import CustomValidator


class TestCustomValidateInputsValidator:
    """Test cases for validate-inputs custom validator."""

    def setup_method(self):
        """Set up test fixtures."""
        self.validator = CustomValidator("validate-inputs")

    def teardown_method(self):
        """Clean up after tests."""
        self.validator.clear_errors()

    def test_initialization(self):
        """Test validator initialization."""
        assert self.validator.action_type == "validate-inputs"
        assert self.validator.boolean_validator is not None
        assert self.validator.file_validator is not None

    def test_validate_inputs_empty(self):
        """Test validation with empty inputs."""
        inputs = {}
        result = self.validator.validate_inputs(inputs)
        assert result is True
        assert not self.validator.has_errors()

    def test_validate_action_valid(self):
        """Test validation with valid action names."""
        valid_actions = [
            "docker-build",
            "npm-publish",
            "pre-commit",
            "version-validator",
            "common_cache",
        ]

        for action in valid_actions:
            self.validator.clear_errors()
            inputs = {"action": action}
            result = self.validator.validate_inputs(inputs)
            assert result is True, f"Should accept action: {action}"
            assert not self.validator.has_errors()

    def test_validate_action_type_valid(self):
        """Test validation with valid action-type."""
        inputs = {"action-type": "docker-build"}
        result = self.validator.validate_inputs(inputs)
        assert result is True
        assert not self.validator.has_errors()

    def test_validate_action_empty(self):
        """Test validation rejects empty action name."""
        inputs = {"action": ""}
        result = self.validator.validate_inputs(inputs)
        assert result is False
        assert self.validator.has_errors()
        assert any("empty" in error.lower() for error in self.validator.errors)

    def test_validate_action_dangerous_characters(self):
        """Test validation rejects actions with dangerous characters."""
        dangerous_actions = [
            "action;rm -rf /",
            "action`whoami`",
            "action$var",
            "action&background",
            "action|pipe",
            "action>redirect",
            "action<input",
            "action\nne wline",
            "action\rcarriage",
            "action/slash",
        ]

        for action in dangerous_actions:
            self.validator.clear_errors()
            inputs = {"action": action}
            result = self.validator.validate_inputs(inputs)
            assert result is False, f"Should reject action: {action}"
            assert self.validator.has_errors()
            assert any("invalid characters" in error.lower() for error in self.validator.errors)

    def test_validate_action_invalid_format(self):
        """Test validation rejects invalid action name formats."""
        invalid_actions = [
            "Action",  # Uppercase
            "ACTION",  # All uppercase
            "1action",  # Starts with digit
            "action-",  # Ends with hyphen
            "-action",  # Starts with hyphen
            "action_",  # Ends with underscore
            "act!on",  # Special character
            "act ion",  # Space
        ]

        for action in invalid_actions:
            self.validator.clear_errors()
            inputs = {"action": action}
            result = self.validator.validate_inputs(inputs)
            assert result is False, f"Should reject action: {action}"
            assert self.validator.has_errors()

    def test_validate_action_github_expression(self):
        """Test validation accepts GitHub expressions."""
        inputs = {"action": "${{ inputs.action-name }}"}
        result = self.validator.validate_inputs(inputs)
        assert result is True
        assert not self.validator.has_errors()

    def test_validate_rules_file_valid(self):
        """Test validation with valid rules file paths."""
        valid_paths = [
            "./rules.yml",
            "rules/validation.yml",
            "config/rules.yaml",
        ]

        for path in valid_paths:
            self.validator.clear_errors()
            inputs = {"rules-file": path}
            result = self.validator.validate_inputs(inputs)
            # Result depends on file existence, but should not crash
            assert isinstance(result, bool)

    def test_validate_fail_on_error_valid(self):
        """Test validation with valid fail-on-error values."""
        valid_values = ["true", "false", "True", "False"]

        for value in valid_values:
            self.validator.clear_errors()
            inputs = {"fail-on-error": value}
            result = self.validator.validate_inputs(inputs)
            assert result is True, f"Should accept fail-on-error: {value}"
            assert not self.validator.has_errors()

    def test_validate_fail_on_error_empty(self):
        """Test validation rejects empty fail-on-error."""
        inputs = {"fail-on-error": ""}
        result = self.validator.validate_inputs(inputs)
        assert result is False
        assert self.validator.has_errors()
        assert any("cannot be empty" in error.lower() for error in self.validator.errors)

    def test_validate_fail_on_error_invalid(self):
        """Test validation rejects invalid fail-on-error values."""
        invalid_values = ["maybe", "invalid", "2", "unknown"]

        for value in invalid_values:
            self.validator.clear_errors()
            inputs = {"fail-on-error": value}
            result = self.validator.validate_inputs(inputs)
            assert result is False, f"Should reject fail-on-error: {value}"
            assert self.validator.has_errors()

    def test_validate_combined_inputs(self):
        """Test validation with multiple inputs."""
        inputs = {
            "action": "docker-build",
            "fail-on-error": "true",
        }
        result = self.validator.validate_inputs(inputs)
        assert result is True
        assert not self.validator.has_errors()

    def test_validate_combined_invalid(self):
        """Test validation with multiple invalid inputs."""
        inputs = {
            "action": "",
            "fail-on-error": "",
        }
        result = self.validator.validate_inputs(inputs)
        assert result is False
        assert self.validator.has_errors()
        # Should have errors for both inputs
        assert len(self.validator.errors) >= 2

    def test_get_required_inputs(self):
        """Test required inputs detection."""
        required = self.validator.get_required_inputs()
        assert isinstance(required, list)
        # No required inputs for validate-inputs action
        assert len(required) == 0

    def test_get_validation_rules(self):
        """Test validation rules."""
        rules = self.validator.get_validation_rules()
        assert isinstance(rules, dict)
        assert "action" in rules
        assert "action-type" in rules
        assert "rules-file" in rules
        assert "fail-on-error" in rules

        # Check rule structure
        assert rules["action"]["type"] == "string"
        assert rules["action"]["required"] is False
        assert "description" in rules["action"]

        assert rules["fail-on-error"]["type"] == "boolean"
        assert rules["fail-on-error"]["required"] is False

    def test_error_propagation_from_file_validator(self):
        """Test error propagation from file validator."""
        # Path with security issues
        inputs = {"rules-file": "../../../etc/passwd"}
        result = self.validator.validate_inputs(inputs)
        assert result is False
        assert self.validator.has_errors()
        # Should have error propagated from file validator
        assert any(
            "security" in error.lower() or "traversal" in error.lower()
            for error in self.validator.errors
        )

    def test_error_propagation_from_boolean_validator(self):
        """Test error propagation from boolean validator."""
        inputs = {"fail-on-error": "not-a-boolean"}
        result = self.validator.validate_inputs(inputs)
        assert result is False
        assert self.validator.has_errors()
        # Should have error propagated from boolean validator
        assert any("boolean" in error.lower() for error in self.validator.errors)

    def test_github_expressions_in_all_fields(self):
        """Test GitHub expressions accepted in all fields."""
        inputs = {
            "action": "${{ inputs.action }}",
            "rules-file": "${{ github.workspace }}/rules.yml",
            "fail-on-error": "${{ inputs.fail }}",
        }
        result = self.validator.validate_inputs(inputs)
        # GitHub expressions should be accepted
        assert result is True
        assert not self.validator.has_errors()
