"""Tests for validation_core.py's legacy 4-positional-arg CLI interface."""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[2]
VALIDATION_CORE = PROJECT_ROOT / "_tests" / "shared" / "validation_core.py"


def _run(args: list[str]) -> subprocess.CompletedProcess:
    return subprocess.run(
        [sys.executable, str(VALIDATION_CORE), *args],
        capture_output=True,
        text=True,
        check=False,
        cwd=PROJECT_ROOT,
    )


class TestLegacyDispatcher:
    def test_legacy_form_handles_normal_positional_args(self) -> None:
        result = _run(["release-monthly", "prefix", "", "success"])
        assert result.returncode == 0, result.stderr

    def test_legacy_form_accepts_value_starting_with_dash(self) -> None:
        # `-rc.1` starts with `-` — must not be intercepted by argparse.
        # The legacy dispatcher must route it through validate_input and
        # return a definite success/failure, not crash with
        # "unrecognized arguments".
        result = _run(["release-monthly", "prefix", "-rc.1", "failure"])
        assert result.returncode in (0, 1)
        assert "unrecognized arguments" not in result.stderr

    def test_non_legacy_help_still_goes_to_argparse(self) -> None:
        result = _run(["--help"])
        assert result.returncode == 0
        assert "--validate" in result.stdout or "--validate" in result.stderr

    def test_non_legacy_validate_subcommand_works(self) -> None:
        result = _run(["--validate", "release-monthly", "prefix", ""])
        assert result.returncode == 0, result.stderr
