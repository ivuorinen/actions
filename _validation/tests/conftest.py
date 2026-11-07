"""Pytest setup for the validation suite.

Puts ``_validation/`` on ``sys.path`` so the tests import the build-time modules exactly
the way ``generate.py`` does (``import kit`` / ``import spec`` / ``import generate``).
"""

from __future__ import annotations

from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
# sync-labels/sync.py ships standalone in its action dir; test_sync_labels_parity imports it.
sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "sync-labels"))
