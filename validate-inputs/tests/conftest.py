"""Test configuration and shared fixtures for validate-inputs tests."""

from __future__ import annotations

import pytest

from validators import registry


@pytest.fixture(autouse=True)
def reset_registry():
    """Reset the global validator registry between tests for isolation."""
    yield
    registry._registry.reset()
