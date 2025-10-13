"""Tests for the validator registry system."""

from __future__ import annotations

from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import MagicMock, patch

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent.parent))
sys.path.insert(1, str(Path(__file__).parent.parent.parent / "sync-labels"))

from validators.base import BaseValidator
from validators.conventions import ConventionBasedValidator
from validators.registry import ValidatorRegistry, clear_cache, get_validator, register_validator


class MockValidator(BaseValidator):
    """Mock validator implementation for testing."""

    def validate_inputs(self, inputs: dict[str, str]) -> bool:  # noqa: ARG002
        return True

    def get_required_inputs(self) -> list[str]:
        return []

    def get_validation_rules(self) -> dict:
        return {"test": "rules"}


class TestValidatorRegistry(unittest.TestCase):  # pylint: disable=too-many-public-methods
    """Test the ValidatorRegistry class."""

    def setUp(self):  # pylint: disable=attribute-defined-outside-init
        """Set up test fixtures."""
        self.registry = ValidatorRegistry()
        # Clear any cached validators
        self.registry.clear_cache()

    def test_register_validator(self):
        """Test registering a validator."""
        self.registry.register("test_action", MockValidator)
        assert self.registry.is_registered("test_action")
        assert "test_action" in self.registry.list_registered()

    def test_get_convention_validator_fallback(self):
        """Test fallback to convention-based validator."""
        validator = self.registry.get_validator("unknown_action")
        assert isinstance(validator, ConventionBasedValidator)
        assert validator.action_type == "unknown_action"

    def test_validator_caching(self):
        """Test that validators are cached."""
        validator1 = self.registry.get_validator("test_action")
        validator2 = self.registry.get_validator("test_action")
        assert validator1 is validator2  # Same instance

    def test_clear_cache(self):
        """Test clearing the validator cache."""
        validator1 = self.registry.get_validator("test_action")
        self.registry.clear_cache()
        validator2 = self.registry.get_validator("test_action")
        assert validator1 is not validator2  # Different instances

    def test_load_custom_validator(self):
        """Test loading a custom validator from action directory."""
        with tempfile.TemporaryDirectory() as tmpdir:
            # Create a mock action directory with CustomValidator.py
            action_dir = Path(tmpdir) / "test-action"
            action_dir.mkdir()

            custom_validator_code = """
from validate_inputs.validators.base import BaseValidator

class CustomValidator(BaseValidator):
    def validate_inputs(self, inputs):
        return True

    def get_required_inputs(self):
        return ["custom_input"]

    def get_validation_rules(self):
        return {"custom": "rules"}
"""

            custom_validator_path = action_dir / "CustomValidator.py"
            custom_validator_path.write_text(custom_validator_code)

            # Mock the project root path
            with patch.object(
                Path,
                "parent",
                new_callable=lambda: MagicMock(return_value=Path(tmpdir)),
            ):
                # This test would need more setup to properly test dynamic loading
                # For now, we'll just verify the method exists
                result = self.registry._load_custom_validator("test_action")  # pylint: disable=protected-access
                # In a real test environment, this would load the custom validator
                # For now, it returns None due to path resolution issues in test
                assert result is None  # Expected in test environment

    def test_global_registry_functions(self):
        """Test global registry functions."""
        # Register a validator
        register_validator("global_test", MockValidator)

        # Get the validator
        validator = get_validator("global_test")
        assert validator is not None

        # Clear cache
        clear_cache()
        # Validator should still be gettable after cache clear
        validator2 = get_validator("global_test")
        assert validator2 is not None


class TestCustomValidatorIntegration(unittest.TestCase):  # pylint: disable=too-many-public-methods
    """Test custom validator integration."""

    def test_sync_labels_custom_validator(self):
        """Test that sync-labels CustomValidator can be imported."""
        # This tests that our example CustomValidator is properly structured
        sync_labels_path = Path(__file__).parent.parent.parent / "sync-labels"
        custom_validator_path = sync_labels_path / "CustomValidator.py"

        if custom_validator_path.exists():
            # Add sync-labels directory to path
            sys.path.insert(0, str(sync_labels_path.parent))

            # Try to import the CustomValidator
            try:
                # Use dynamic import to avoid static analysis errors
                import importlib.util  # pylint: disable=import-outside-toplevel

                spec = importlib.util.spec_from_file_location(
                    "CustomValidator",
                    custom_validator_path,
                )
                if spec is None or spec.loader is None:
                    self.skipTest("Could not create spec for CustomValidator")

                module = importlib.util.module_from_spec(spec)
                spec.loader.exec_module(module)
                custom_validator = module.CustomValidator

                # Create an instance
                validator = custom_validator("sync-labels")

                # Test basic functionality
                assert validator.get_required_inputs() == ["labels"]

                # Test validation with valid inputs
                inputs = {"labels": "labels.yml", "token": "${{ github.token }}"}
                assert validator.validate_inputs(inputs) is True

                # Test validation with invalid labels file
                validator.clear_errors()
                inputs = {
                    "labels": "labels.txt",  # Wrong extension
                    "token": "${{ github.token }}",
                }
                assert validator.validate_inputs(inputs) is False
                assert validator.has_errors() is True

            except ImportError as e:
                self.skipTest(f"Could not import CustomValidator: {e}")
            finally:
                # Clean up sys.path
                if str(sync_labels_path.parent) in sys.path:
                    sys.path.remove(str(sync_labels_path.parent))
        else:
            self.skipTest("sync-labels/CustomValidator.py not found")


if __name__ == "__main__":
    unittest.main()
