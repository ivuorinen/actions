"""Modular validation system for GitHub Actions inputs.

This package provides a flexible, extensible validation framework for GitHub Actions.
"""

from .base import BaseValidator
from .registry import ValidatorRegistry

__all__ = ["BaseValidator", "ValidatorRegistry"]
__version__ = "2.0.0"
