"""Validator registry for dynamic validator discovery and loading.

Manages the registration and instantiation of validators.
"""

from __future__ import annotations

import importlib
import importlib.util
import logging
import sys
from pathlib import Path
from typing import TYPE_CHECKING

from .convention_mapper import ConventionMapper
from .conventions import ConventionBasedValidator

if TYPE_CHECKING:
    from .base import BaseValidator


class ValidatorRegistry:
    """Registry for managing and discovering validators.

    Provides dynamic loading of custom validators and fallback to convention-based validation.
    """

    def __init__(self) -> None:
        """Initialize the validator registry."""
        self._validators: dict[str, type[BaseValidator]] = {}
        self._validator_instances: dict[str, BaseValidator] = {}
        self._convention_mapper = ConventionMapper()

    def register(self, action_type: str, validator_class: type[BaseValidator]) -> None:
        """Register a validator class for an action type.

        Args:
            action_type: The action type identifier
            validator_class: The validator class to register
        """
        self._validators[action_type] = validator_class

    def register_validator(self, action_type: str, validator_class: type[BaseValidator]) -> None:
        """Register a validator class for an action type (alias for register).

        Args:
            action_type: The action type identifier
            validator_class: The validator class to register
        """
        self.register(action_type, validator_class)
        # Also create and cache an instance
        validator_instance = validator_class(action_type)
        self._validator_instances[action_type] = validator_instance

    def get_validator(self, action_type: str) -> BaseValidator:
        """Get a validator instance for the given action type.

        First attempts to load a custom validator from the action directory,
        then falls back to convention-based validation.

        Args:
            action_type: The action type identifier

        Returns:
            A validator instance for the action
        """
        # Check cache first
        if action_type in self._validator_instances:
            return self._validator_instances[action_type]

        # Try to load custom validator
        validator = self._load_custom_validator(action_type)

        # Fall back to convention-based validator
        if not validator:
            validator = self._load_convention_validator(action_type)

        # Cache and return
        self._validator_instances[action_type] = validator
        return validator

    def _load_custom_validator(self, action_type: str) -> BaseValidator | None:
        """Attempt to load a custom validator from the action directory.

        Args:
            action_type: The action type identifier

        Returns:
            Custom validator instance or None if not found
        """
        # Convert action_type to directory name (e.g., sync_labels -> sync-labels)
        action_dir = action_type.replace("_", "-")

        # Look for CustomValidator.py in the action directory
        project_root = Path(__file__).parent.parent.parent
        custom_validator_path = project_root / action_dir / "CustomValidator.py"

        if not custom_validator_path.exists():
            return None

        try:
            # Load the module dynamically
            spec = importlib.util.spec_from_file_location(
                f"{action_type}_custom_validator",
                custom_validator_path,
            )
            if not spec or not spec.loader:
                return None

            module = importlib.util.module_from_spec(spec)
            sys.modules[spec.name] = module
            spec.loader.exec_module(module)

            # Get the CustomValidator class
            if hasattr(module, "CustomValidator"):
                validator_class = module.CustomValidator
                return validator_class(action_type)

        except (ImportError, AttributeError, TypeError, ValueError) as e:
            # Log at debug level - custom validators are optional
            # Catch common errors during dynamic module loading:
            # - ImportError: Module dependencies not found
            # - AttributeError: Module doesn't have CustomValidator
            # - TypeError: Validator instantiation failed
            # - ValueError: Invalid validator configuration
            logger = logging.getLogger(__name__)
            logger.debug("Could not load custom validator for %s: %s", action_type, e)

        return None

    def _load_convention_validator(self, action_type: str) -> BaseValidator:
        """Load a convention-based validator for the action type.

        Args:
            action_type: The action type identifier

        Returns:
            Convention-based validator instance
        """
        return ConventionBasedValidator(action_type)

    def clear_cache(self) -> None:
        """Clear the validator instance cache."""
        self._validator_instances.clear()

    def list_registered(self) -> list[str]:
        """List all registered action types.

        Returns:
            List of registered action type identifiers
        """
        return list(self._validators.keys())

    def is_registered(self, action_type: str) -> bool:
        """Check if an action type has a registered validator.

        Args:
            action_type: The action type identifier

        Returns:
            True if a validator is registered, False otherwise
        """
        return action_type in self._validators

    def get_validator_by_type(self, validator_type: str) -> BaseValidator | None:
        """Get a validator instance by its type name.

        Args:
            validator_type: The validator type name (e.g., 'BooleanValidator', 'TokenValidator')

        Returns:
            A validator instance or None if not found
        """
        # Map of validator type names to modules
        validator_modules = {
            "BooleanValidator": "boolean",
            "CodeQLValidator": "codeql",
            "DockerValidator": "docker",
            "FileValidator": "file",
            "NetworkValidator": "network",
            "NumericValidator": "numeric",
            "SecurityValidator": "security",
            "TokenValidator": "token",
            "VersionValidator": "version",
        }

        module_name = validator_modules.get(validator_type)
        if not module_name:
            return None

        try:
            # Import the module
            module = importlib.import_module(f"validators.{module_name}")
            # Get the validator class
            validator_class = getattr(module, validator_type, None)
            if validator_class:
                # Create an instance with a dummy action type
                return validator_class("temp")
        except (ImportError, AttributeError):
            # Silently ignore if custom validator module doesn't exist or class not found
            pass

        return None


# Global registry instance
_registry = ValidatorRegistry()


def get_validator(action_type: str) -> BaseValidator:
    """Get a validator for the given action type.

    Args:
        action_type: The action type identifier

    Returns:
        A validator instance for the action
    """
    return _registry.get_validator(action_type)


def register_validator(action_type: str, validator_class: type[BaseValidator]) -> None:
    """Register a validator class for an action type.

    Args:
        action_type: The action type identifier
        validator_class: The validator class to register
    """
    _registry.register(action_type, validator_class)


def clear_cache() -> None:
    """Clear the global validator cache."""
    _registry.clear_cache()
