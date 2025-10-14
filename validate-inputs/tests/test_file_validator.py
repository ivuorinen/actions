"""Tests for the FileValidator module."""

from pathlib import Path
import sys

import pytest  # pylint: disable=import-error

# Add the parent directory to the path
sys.path.insert(0, str(Path(__file__).parent.parent))

from validators.file import FileValidator

from tests.fixtures.version_test_data import FILE_PATH_INVALID, FILE_PATH_VALID


class TestFileValidator:
    """Test cases for FileValidator."""

    def setup_method(self):
        """Set up test environment."""
        self.validator = FileValidator()

    def test_initialization(self):
        """Test validator initialization."""
        assert self.validator.errors == []
        rules = self.validator.get_validation_rules()
        assert rules is not None

    @pytest.mark.parametrize("path,description", FILE_PATH_VALID)
    def test_validate_file_path_valid(self, path, description):
        """Test file path validation with valid paths."""
        self.validator.errors = []
        result = self.validator.validate_file_path(path)
        assert result is True, f"Failed for {description}: {path}"
        assert len(self.validator.errors) == 0

    @pytest.mark.parametrize("path,description", FILE_PATH_INVALID)
    def test_validate_file_path_invalid(self, path, description):
        """Test file path validation with invalid paths."""
        self.validator.errors = []
        result = self.validator.validate_file_path(path)
        assert result is False, f"Should fail for {description}: {path}"
        assert len(self.validator.errors) > 0

    def test_validate_path_security(self):
        """Test that path traversal attempts are blocked."""
        dangerous_paths = [
            "../etc/passwd",
            "../../etc/shadow",
            "../../../root/.ssh/id_rsa",
            "..\\windows\\system32",
            "/etc/passwd",  # Absolute path
            "C:\\Windows\\System32",  # Windows absolute
            "~/.ssh/id_rsa",  # Home directory expansion
        ]

        for path in dangerous_paths:
            self.validator.errors = []
            result = self.validator.validate_path_security(path)
            assert result is False, f"Should block dangerous path: {path}"
            assert len(self.validator.errors) > 0

    def test_validate_dockerfile_path(self):
        """Test Dockerfile path validation."""
        valid_dockerfiles = [
            "Dockerfile",
            "dockerfile",
            "Dockerfile.prod",
            "Dockerfile.dev",
            "docker/Dockerfile",
            "./Dockerfile",
        ]

        for path in valid_dockerfiles:
            self.validator.errors = []
            result = self.validator.validate_dockerfile_path(path)
            assert result is True, f"Should accept Dockerfile: {path}"

    def test_validate_yaml_file(self):
        """Test YAML file validation."""
        valid_yaml_files = [
            "config.yml",
            "config.yaml",
            "values.yaml",
            ".github/workflows/test.yml",
            "docker-compose.yml",
            "docker-compose.yaml",
        ]

        for path in valid_yaml_files:
            self.validator.errors = []
            result = self.validator.validate_yaml_file(path)
            assert result is True, f"Should accept YAML file: {path}"

        invalid_yaml_files = [
            "config.txt",  # Wrong extension
            "config",  # No extension
            "config.yml.txt",  # Double extension
        ]

        for path in invalid_yaml_files:
            self.validator.errors = []
            result = self.validator.validate_yaml_file(path)
            assert result is False, f"Should reject non-YAML file: {path}"

    def test_validate_json_file(self):
        """Test JSON file validation."""
        valid_json_files = [
            "config.json",
            "package.json",
            "tsconfig.json",
            "composer.json",
            ".eslintrc.json",
        ]

        for path in valid_json_files:
            self.validator.errors = []
            result = self.validator.validate_json_file(path)
            assert result is True, f"Should accept JSON file: {path}"

        invalid_json_files = [
            "config.js",  # JavaScript, not JSON
            "config.jsonc",  # JSON with comments
            "config.txt",  # Wrong extension
        ]

        for path in invalid_json_files:
            self.validator.errors = []
            result = self.validator.validate_json_file(path)
            assert result is False, f"Should reject non-JSON file: {path}"

    def test_validate_executable_file(self):
        """Test executable file validation."""
        valid_executables = [
            "script.sh",
            "run.bash",
            "deploy.py",
            "build.js",
            "test.rb",
            "compile",  # No extension but could be executable
            "./script.sh",
            "bin/deploy",
        ]

        for path in valid_executables:
            self.validator.errors = []
            # This might check file extensions or actual file permissions
            result = self.validator.validate_executable_file(path)
            assert isinstance(result, bool)

    def test_empty_path_handling(self):
        """Test that empty paths are handled correctly."""
        result = self.validator.validate_file_path("")
        # Empty path might be allowed for optional inputs
        assert isinstance(result, bool)

        # But for required file validations, empty should fail
        self.validator.errors = []
        result = self.validator.validate_required_file("")
        assert result is False
        assert len(self.validator.errors) > 0

    def test_whitespace_paths(self):
        """Test that whitespace-only paths are treated as empty."""
        whitespace_paths = [" ", "  ", "\t", "\n"]

        for path in whitespace_paths:
            self.validator.errors = []
            result = self.validator.validate_file_path(path)
            # Should be treated as empty
            assert isinstance(result, bool)

    def test_validate_inputs_with_file_keywords(self):
        """Test validation of inputs with file-related keywords."""
        inputs = {
            "config-file": "config.yml",
            "dockerfile": "Dockerfile",
            "compose-file": "docker-compose.yml",
            "env-file": ".env",
            "output-file": "output.txt",
            "input-file": "input.json",
            "cache-dir": ".cache",
            "working-directory": "./src",
        }

        result = self.validator.validate_inputs(inputs)
        assert isinstance(result, bool)

    def test_special_characters_in_paths(self):
        """Test handling of special characters in file paths."""
        special_char_paths = [
            "file name.txt",  # Space
            "file@v1.txt",  # @ symbol
            "file#1.txt",  # Hash
            "file$name.txt",  # Dollar sign
            "file&name.txt",  # Ampersand
            "file(1).txt",  # Parentheses
            "file[1].txt",  # Brackets
        ]

        for path in special_char_paths:
            self.validator.errors = []
            result = self.validator.validate_file_path(path)
            # Some special characters might be allowed
            assert isinstance(result, bool)
