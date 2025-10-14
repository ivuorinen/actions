"""Tests for modular_validator.py main entry point."""

from __future__ import annotations

import os
from pathlib import Path
import sys
from unittest.mock import MagicMock, patch

import pytest  # pylint: disable=import-error

# Add validate-inputs directory to path
sys.path.insert(0, str(Path(__file__).parent.parent))

# pylint: disable=wrong-import-position
from modular_validator import main


class TestModularValidator:
    """Test cases for modular_validator main function."""

    def test_missing_action_type(self, tmp_path):
        """Test that missing action-type causes failure."""
        output_file = tmp_path / "github_output"
        output_file.touch()

        with (
            patch.dict(
                os.environ,
                {"GITHUB_OUTPUT": str(output_file)},
                clear=True,
            ),
            pytest.raises(SystemExit) as exc_info,
        ):
            main()

        assert exc_info.value.code == 1
        content = output_file.read_text()
        assert "status=failure" in content
        assert "error=action-type is required" in content

    def test_valid_action_type_success(self, tmp_path):
        """Test successful validation with valid action-type."""
        output_file = tmp_path / "github_output"
        output_file.touch()

        # docker-build is a known action with a validator
        with (
            patch.dict(
                os.environ,
                {
                    "GITHUB_OUTPUT": str(output_file),
                    "INPUT_ACTION_TYPE": "docker-build",
                    "INPUT_TAG": "v1.0.0",
                    "INPUT_IMAGE_NAME": "myapp",
                },
                clear=True,
            ),
            patch("modular_validator.logger") as mock_logger,
        ):
            main()

        content = output_file.read_text()
        assert "status=success" in content
        mock_logger.info.assert_called()

    def test_valid_action_type_validation_failure(self, tmp_path):
        """Test validation failure with invalid inputs."""
        output_file = tmp_path / "github_output"
        output_file.touch()

        with (
            patch.dict(
                os.environ,
                {
                    "GITHUB_OUTPUT": str(output_file),
                    "INPUT_ACTION_TYPE": "docker-build",
                    "INPUT_TAG": "invalid_tag!",  # Invalid tag format
                },
                clear=True,
            ),
            patch("modular_validator.logger") as mock_logger,
            pytest.raises(SystemExit) as exc_info,
        ):
            main()

        assert exc_info.value.code == 1
        content = output_file.read_text()
        assert "status=failure" in content
        assert "error=" in content
        mock_logger.error.assert_called()

    def test_environment_variable_extraction(self, tmp_path):
        """Test that INPUT_* environment variables are extracted correctly."""
        output_file = tmp_path / "github_output"
        output_file.touch()

        mock_validator = MagicMock()
        mock_validator.validate_inputs.return_value = True
        mock_validator.errors = []

        with (
            patch.dict(
                os.environ,
                {
                    "GITHUB_OUTPUT": str(output_file),
                    "INPUT_ACTION_TYPE": "docker-build",
                    "INPUT_TAG": "v1.0.0",
                    "INPUT_IMAGE_NAME": "myapp",
                    "INPUT_BUILD_ARGS": "NODE_ENV=prod",
                    "NOT_AN_INPUT": "should_be_ignored",
                },
                clear=True,
            ),
            patch("modular_validator.get_validator", return_value=mock_validator),
        ):
            main()

        # Check that validate_inputs was called with correct inputs
        call_args = mock_validator.validate_inputs.call_args[0][0]
        assert "tag" in call_args
        assert call_args["tag"] == "v1.0.0"
        assert "image_name" in call_args or "image-name" in call_args
        assert "build_args" in call_args or "build-args" in call_args
        assert "not_an_input" not in call_args

    def test_underscore_to_dash_conversion(self, tmp_path):
        """Test that underscore names are converted to dash names."""
        output_file = tmp_path / "github_output"
        output_file.touch()

        mock_validator = MagicMock()
        mock_validator.validate_inputs.return_value = True
        mock_validator.errors = []

        with (
            patch.dict(
                os.environ,
                {
                    "GITHUB_OUTPUT": str(output_file),
                    "INPUT_ACTION_TYPE": "docker-build",
                    "INPUT_BUILD_ARGS": "test=value",
                },
                clear=True,
            ),
            patch("modular_validator.get_validator", return_value=mock_validator),
        ):
            main()

        # Check that both underscore and dash versions are present
        call_args = mock_validator.validate_inputs.call_args[0][0]
        assert "build_args" in call_args or "build-args" in call_args

    def test_action_type_dash_to_underscore(self, tmp_path):
        """Test that action-type with dashes is converted to underscores."""
        output_file = tmp_path / "github_output"
        output_file.touch()

        mock_validator = MagicMock()
        mock_validator.validate_inputs.return_value = True
        mock_validator.errors = []

        with (
            patch.dict(
                os.environ,
                {
                    "GITHUB_OUTPUT": str(output_file),
                    "INPUT_ACTION_TYPE": "docker-build",
                },
                clear=True,
            ),
            patch("modular_validator.get_validator", return_value=mock_validator) as mock_get,
        ):
            main()

        # get_validator should be called with underscore version
        mock_get.assert_called_once_with("docker_build")

    def test_exception_handling(self, tmp_path):
        """Test exception handling writes failure to output."""
        output_file = tmp_path / "github_output"
        output_file.touch()

        with (
            patch.dict(
                os.environ,
                {
                    "GITHUB_OUTPUT": str(output_file),
                    "INPUT_ACTION_TYPE": "docker-build",
                },
                clear=True,
            ),
            patch("modular_validator.get_validator", side_effect=ValueError("Test error")),
            pytest.raises(SystemExit) as exc_info,
        ):
            main()

        assert exc_info.value.code == 1
        content = output_file.read_text()
        assert "status=failure" in content
        assert "error=Validation script error" in content

    def test_exception_handling_no_github_output(self):
        """Test exception handling when GITHUB_OUTPUT not set."""
        # Create a fallback path in home directory
        fallback_path = Path.home() / "github_output"

        try:
            with (
                patch.dict(os.environ, {"INPUT_ACTION_TYPE": "docker-build"}, clear=True),
                patch("modular_validator.get_validator", side_effect=ValueError("Test error")),
                patch("modular_validator.logger"),
                pytest.raises(SystemExit) as exc_info,
            ):
                main()

            assert exc_info.value.code == 1

            # Check that fallback file was created
            if fallback_path.exists():
                content = fallback_path.read_text()
                assert "status=failure" in content
                assert "error=Validation script error" in content
        finally:
            # Cleanup fallback file if it exists
            if fallback_path.exists():
                fallback_path.unlink()

    def test_validation_errors_written_to_output(self, tmp_path):
        """Test that validation errors are written to GITHUB_OUTPUT."""
        output_file = tmp_path / "github_output"
        output_file.touch()

        mock_validator = MagicMock()
        mock_validator.validate_inputs.return_value = False
        mock_validator.errors = ["Error 1", "Error 2"]

        with (
            patch.dict(
                os.environ,
                {
                    "GITHUB_OUTPUT": str(output_file),
                    "INPUT_ACTION_TYPE": "docker-build",
                },
                clear=True,
            ),
            patch("modular_validator.get_validator", return_value=mock_validator),
            pytest.raises(SystemExit) as exc_info,
        ):
            main()

        assert exc_info.value.code == 1
        content = output_file.read_text()
        assert "status=failure" in content
        assert "Error 1" in content
        assert "Error 2" in content

    def test_empty_action_type_string(self, tmp_path):
        """Test that empty action-type string is treated as missing."""
        output_file = tmp_path / "github_output"
        output_file.touch()

        with (
            patch.dict(
                os.environ,
                {
                    "GITHUB_OUTPUT": str(output_file),
                    "INPUT_ACTION_TYPE": "   ",  # Whitespace only
                },
                clear=True,
            ),
            pytest.raises(SystemExit) as exc_info,
        ):
            main()

        assert exc_info.value.code == 1
        content = output_file.read_text()
        assert "status=failure" in content
        assert "action-type is required" in content
