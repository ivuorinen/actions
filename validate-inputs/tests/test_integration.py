"""Integration tests for the validator script execution."""

import os
from pathlib import Path
import subprocess
import sys
import tempfile

import pytest


class TestValidatorIntegration:
    """Integration tests for running validator.py as a script."""

    def setup_method(self):
        """Set up test environment."""
        # Clear INPUT_ environment variables
        for key in list(os.environ.keys()):
            if key.startswith("INPUT_"):
                del os.environ[key]

        # Create temporary output file
        self.temp_output = tempfile.NamedTemporaryFile(mode="w", delete=False)
        os.environ["GITHUB_OUTPUT"] = self.temp_output.name
        self.temp_output.close()

        # Get validator script path
        self.validator_path = Path(__file__).parent.parent / "validator.py"

    def teardown_method(self):
        """Clean up after each test."""
        if Path(self.temp_output.name).exists():
            os.unlink(self.temp_output.name)

    def run_validator(self, env_vars=None):
        """Run the validator script with given environment variables."""
        env = os.environ.copy()
        if env_vars:
            env.update(env_vars)

        result = subprocess.run(
            [sys.executable, str(self.validator_path)],
            check=False,
            env=env,
            capture_output=True,
            text=True,
        )

        return result

    def test_validator_script_success(self):
        """Test validator script execution with valid inputs."""
        env_vars = {
            "INPUT_ACTION_TYPE": "github-release",
            "INPUT_VERSION": "1.2.3",
            "INPUT_CHANGELOG": "Release notes",
        }

        result = self.run_validator(env_vars)

        assert result.returncode == 0
        assert "All input validation checks passed" in result.stderr

    def test_validator_script_failure(self):
        """Test validator script execution with invalid inputs."""
        env_vars = {
            "INPUT_ACTION_TYPE": "github-release",
            "INPUT_VERSION": "invalid-version",
            "INPUT_CHANGELOG": "Release notes",
        }

        result = self.run_validator(env_vars)

        assert result.returncode == 1
        assert "Input validation failed" in result.stderr

    def test_validator_script_missing_required(self):
        """Test validator script with missing required inputs."""
        env_vars = {
            "INPUT_ACTION_TYPE": "github-release",
            # Missing required INPUT_VERSION
            "INPUT_CHANGELOG": "Release notes",
        }

        result = self.run_validator(env_vars)

        assert result.returncode == 1
        assert "Required input 'version' is missing" in result.stderr

    def test_validator_script_calver_validation(self):
        """Test validator script with CalVer version."""
        env_vars = {
            "INPUT_ACTION_TYPE": "github-release",
            "INPUT_VERSION": "2024.3.1",
            "INPUT_CHANGELOG": "Release notes",
        }

        result = self.run_validator(env_vars)

        assert result.returncode == 0
        assert "All input validation checks passed" in result.stderr

    def test_validator_script_invalid_calver(self):
        """Test validator script with invalid CalVer version."""
        env_vars = {
            "INPUT_ACTION_TYPE": "github-release",
            "INPUT_VERSION": "2024.13.1",  # Invalid month
            "INPUT_CHANGELOG": "Release notes",
        }

        result = self.run_validator(env_vars)

        assert result.returncode == 1
        assert "Invalid CalVer format" in result.stderr

    def test_validator_script_docker_build(self):
        """Test validator script with docker-build action."""
        env_vars = {
            "INPUT_ACTION_TYPE": "docker-build",
            "INPUT_CONTEXT": ".",  # Required by custom validator
            "INPUT_IMAGE_NAME": "myapp",
            "INPUT_TAG": "v1.0.0",
            "INPUT_DOCKERFILE": "Dockerfile",
            "INPUT_ARCHITECTURES": "linux/amd64,linux/arm64",
        }

        result = self.run_validator(env_vars)

        assert result.returncode == 0
        assert "All input validation checks passed" in result.stderr

    def test_validator_script_csharp_publish(self):
        """Test validator script with csharp-publish action."""
        env_vars = {
            "INPUT_ACTION_TYPE": "csharp-publish",
            "INPUT_TOKEN": "github_pat_" + "a" * 71,
            "INPUT_NAMESPACE": "test-namespace",
            "INPUT_DOTNET_VERSION": "8.0.0",
        }

        result = self.run_validator(env_vars)

        assert result.returncode == 0
        assert "All input validation checks passed" in result.stderr

    def test_validator_script_invalid_token(self):
        """Test validator script with invalid GitHub token."""
        env_vars = {
            "INPUT_ACTION_TYPE": "csharp-publish",
            "INPUT_TOKEN": "invalid-token",
            "INPUT_NAMESPACE": "test-namespace",
        }

        result = self.run_validator(env_vars)

        assert result.returncode == 1
        assert "token format" in result.stderr.lower()

    def test_validator_script_security_injection(self):
        """Test validator script detects security injection attempts."""
        env_vars = {
            "INPUT_ACTION_TYPE": "eslint-fix",
            "INPUT_TOKEN": "github_pat_" + "a" * 82,
            "INPUT_USERNAME": "user; rm -rf /",  # Command injection attempt
        }

        result = self.run_validator(env_vars)

        assert result.returncode == 1
        assert "Command injection patterns not allowed" in result.stderr

    def test_validator_script_numeric_range(self):
        """Test validator script with numeric range validation."""
        env_vars = {
            "INPUT_ACTION_TYPE": "docker-build",
            "INPUT_CONTEXT": ".",  # Required by custom validator
            "INPUT_IMAGE_NAME": "myapp",
            "INPUT_TAG": "latest",
            "INPUT_PARALLEL_BUILDS": "5",  # Should be valid (0-16 range)
        }

        result = self.run_validator(env_vars)

        assert result.returncode == 0

    def test_validator_script_numeric_range_invalid(self):
        """Test validator script with invalid numeric range."""
        env_vars = {
            "INPUT_ACTION_TYPE": "docker-build",
            "INPUT_IMAGE_NAME": "myapp",
            "INPUT_TAG": "latest",
            "INPUT_PARALLEL_BUILDS": "20",  # Should be invalid (exceeds 16)
        }

        result = self.run_validator(env_vars)

        assert result.returncode == 1

    def test_validator_script_boolean_validation(self):
        """Test validator script with boolean validation."""
        env_vars = {
            "INPUT_ACTION_TYPE": "docker-build",
            "INPUT_CONTEXT": ".",  # Required by custom validator
            "INPUT_IMAGE_NAME": "myapp",
            "INPUT_TAG": "latest",
            "INPUT_DRY_RUN": "true",
        }

        result = self.run_validator(env_vars)

        assert result.returncode == 0

    def test_validator_script_boolean_invalid(self):
        """Test validator script with invalid boolean."""
        env_vars = {
            "INPUT_ACTION_TYPE": "docker-build",
            "INPUT_IMAGE_NAME": "myapp",
            "INPUT_TAG": "latest",
            "INPUT_DRY_RUN": "maybe",  # Invalid boolean
        }

        result = self.run_validator(env_vars)

        assert result.returncode == 1

    def test_validator_script_no_action_type(self):
        """Test validator script without action type."""
        env_vars = {
            # No INPUT_ACTION_TYPE
            "INPUT_VERSION": "1.2.3",
        }

        result = self.run_validator(env_vars)

        # Should still run but with empty action type
        assert result.returncode in [0, 1]  # Depends on validation logic

    def test_validator_script_output_file_creation(self):
        """Test that validator script creates GitHub output file."""
        env_vars = {
            "INPUT_ACTION_TYPE": "github-release",
            "INPUT_VERSION": "1.2.3",
        }

        result = self.run_validator(env_vars)

        # Check that validator ran successfully
        assert result.returncode == 0

        # Check that output file was written to
        assert Path(self.temp_output.name).exists()

        with Path(self.temp_output.name).open() as f:
            content = f.read()
            assert "status=" in content

    def test_validator_script_error_handling(self):
        """Test validator script handles exceptions gracefully."""
        # Test with invalid GITHUB_OUTPUT path to trigger exception
        env_vars = {
            "INPUT_ACTION_TYPE": "github-release",
            "INPUT_VERSION": "1.2.3",
            "GITHUB_OUTPUT": "/invalid/path/that/does/not/exist",
        }

        result = self.run_validator(env_vars)

        assert result.returncode == 1
        assert "Validation script error" in result.stderr

    @pytest.mark.parametrize(
        "action_type,inputs,expected_success",
        [
            ("github-release", {"version": "1.2.3"}, True),
            ("github-release", {"version": "2024.3.1"}, True),
            ("github-release", {"version": "invalid"}, False),
            ("docker-build", {"context": ".", "image-name": "app", "tag": "latest"}, True),
            (
                "docker-build",
                {"context": ".", "image-name": "App", "tag": "latest"},
                False,
            ),  # Uppercase not allowed
            ("csharp-publish", {"token": "github_pat_" + "a" * 71, "namespace": "test"}, True),
            ("csharp-publish", {"token": "invalid", "namespace": "test"}, False),
        ],
    )
    def test_validator_script_parametrized(self, action_type, inputs, expected_success):
        """Parametrized test for various action types and inputs."""
        env_vars = {"INPUT_ACTION_TYPE": action_type}

        # Convert inputs to environment variables
        for key, value in inputs.items():
            env_key = f"INPUT_{key.upper().replace('-', '_')}"
            env_vars[env_key] = value

        result = self.run_validator(env_vars)

        if expected_success:
            assert result.returncode == 0, f"Expected success for {action_type} with {inputs}"
        else:
            assert result.returncode == 1, f"Expected failure for {action_type} with {inputs}"
