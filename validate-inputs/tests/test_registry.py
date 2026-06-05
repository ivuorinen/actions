"""Tests for the validator registry system."""

from __future__ import annotations

import shutil
import sys
import unittest
from pathlib import Path

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

    def test_load_custom_validator_present_file_loads(self):
        """A present, valid CustomValidator.py is dynamically loaded and instantiated.

        The custom validator lives at ``<repo-root>/<action-dir>/CustomValidator.py``,
        which is exactly how ``_load_custom_validator`` resolves the path
        (``Path(registry.py).parent.parent.parent / action_dir``). The previous
        version of this test created the file under a ``TemporaryDirectory`` the
        loader never consults and asserted ``None``, exercising nothing.
        """
        repo_root = Path(__file__).parent.parent.parent
        action_dir = repo_root / "zz-nitpick-valid-cv"
        action_dir.mkdir(exist_ok=True)
        try:
            (action_dir / "CustomValidator.py").write_text(
                "from validators.base import BaseValidator\n\n"
                "class CustomValidator(BaseValidator):\n"
                "    def validate_inputs(self, inputs):\n"
                "        return True\n\n"
                "    def get_required_inputs(self):\n"
                "        return []\n\n"
                "    def get_validation_rules(self):\n"
                "        return {}\n",
            )
            validator = self.registry._load_custom_validator("zz_nitpick_valid_cv")  # pylint: disable=protected-access
            assert validator is not None
            assert validator.validate_inputs({}) is True
        finally:
            shutil.rmtree(action_dir, ignore_errors=True)

    def test_broken_present_custom_validator_raises(self):
        """A present-but-broken CustomValidator.py must fail loudly, not silently downgrade.

        Mirrors the loud-failure contract of ``get_validator_by_type``: a syntax
        error in a first-party CustomValidator.py must surface in CI rather than
        silently fall back to convention validation with weakened checks.
        """
        repo_root = Path(__file__).parent.parent.parent
        action_dir = repo_root / "zz-nitpick-broken-cv"
        action_dir.mkdir(exist_ok=True)
        try:
            # Unclosed parenthesis -> SyntaxError raised by exec_module.
            (action_dir / "CustomValidator.py").write_text("class CustomValidator(\n")
            with self.assertRaises(SyntaxError):
                self.registry._load_custom_validator("zz_nitpick_broken_cv")  # pylint: disable=protected-access
        finally:
            shutil.rmtree(action_dir, ignore_errors=True)

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

                # Test basic functionality.
                # `labels` is optional at the action.yml level — the "Run Label
                # Syncer" step applies a runtime default via
                # `${{ inputs.labels || format('{0}/labels.yml', github.action_path) }}`.
                # CustomValidator.get_required_inputs() reflects the action's
                # public contract, so the list is empty.
                assert validator.get_required_inputs() == []

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
