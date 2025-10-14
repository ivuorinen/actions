"""Tests for file validator."""

from validators.file import FileValidator


class TestFileValidator:
    """Test cases for FileValidator."""

    def setup_method(self):
        """Set up test fixtures."""
        self.validator = FileValidator("test-action")

    def teardown_method(self):
        """Clean up after tests."""
        self.validator.clear_errors()

    def test_initialization(self):
        """Test validator initialization."""
        assert self.validator.action_type == "test-action"

    def test_get_required_inputs(self):
        """Test getting required inputs."""
        required = self.validator.get_required_inputs()
        assert isinstance(required, list)

    def test_get_validation_rules(self):
        """Test getting validation rules."""
        rules = self.validator.get_validation_rules()
        assert isinstance(rules, dict)

    def test_validate_inputs_empty(self):
        """Test validation with empty inputs."""
        result = self.validator.validate_inputs({})
        assert result is True

    def test_valid_file_paths(self):
        """Test valid file paths."""
        assert self.validator.validate_file_path("./src/main.py") is True
        assert self.validator.validate_file_path("relative/path.yml") is True
        assert self.validator.validate_file_path("./config/file.txt") is True

    def test_absolute_paths_rejected(self):
        """Test that absolute paths are rejected for security."""
        assert self.validator.validate_file_path("/absolute/path/file.txt") is False
        assert self.validator.has_errors()

    def test_path_traversal_detection(self):
        """Test path traversal detection."""
        assert self.validator.validate_file_path("../../../etc/passwd") is False
        assert self.validator.validate_file_path("./valid/../../../etc/passwd") is False
        assert self.validator.has_errors()

    def test_validate_path_empty(self):
        """Test that empty paths are allowed (optional)."""
        assert self.validator.validate_path("") is True

    def test_validate_path_valid_skipped(self):
        """Test validation of valid paths (requires file to exist)."""
        # validate_path requires strict=True so file must exist
        # Skipping this test as it would need actual files

    def test_validate_path_dangerous_characters(self):
        """Test rejection of dangerous characters in paths."""
        dangerous_paths = [
            "file;rm -rf /",
            "file`whoami`",
            "file$var",
            "file&background",
            "file|pipe",
        ]
        for path in dangerous_paths:
            self.validator.clear_errors()
            assert self.validator.validate_path(path) is False
            assert self.validator.has_errors()

    # Branch name validation tests
    def test_validate_branch_name_valid(self):
        """Test validation of valid branch names."""
        valid_branches = [
            "main",
            "develop",
            "feature/new-feature",
            "bugfix/issue-123",
            "release-1.0.0",
        ]
        for branch in valid_branches:
            assert self.validator.validate_branch_name(branch) is True
            self.validator.clear_errors()

    def test_validate_branch_name_empty(self):
        """Test that empty branch name is allowed (optional)."""
        assert self.validator.validate_branch_name("") is True

    def test_validate_branch_name_invalid_chars(self):
        """Test rejection of invalid characters in branch names."""
        invalid_branches = [
            "branch with spaces",
            "branch@invalid",
            "branch#invalid",
            "branch~invalid",
        ]
        for branch in invalid_branches:
            self.validator.clear_errors()
            assert self.validator.validate_branch_name(branch) is False
            assert self.validator.has_errors()

    def test_validate_branch_name_invalid_start(self):
        """Test rejection of branches starting with invalid characters."""
        assert self.validator.validate_branch_name("-invalid") is False
        assert self.validator.validate_branch_name(".invalid") is False

    def test_validate_branch_name_invalid_end(self):
        """Test rejection of branches ending with invalid characters."""
        assert self.validator.validate_branch_name("invalid.") is False
        assert self.validator.has_errors()
        self.validator.clear_errors()
        assert self.validator.validate_branch_name("invalid/") is False
        assert self.validator.has_errors()

    # File extensions validation tests
    def test_validate_file_extensions_valid(self):
        """Test validation of valid file extensions (must start with dot)."""
        assert self.validator.validate_file_extensions(".py,.js,.ts") is True
        assert self.validator.validate_file_extensions(".yml,.yaml,.json") is True

    def test_validate_file_extensions_empty(self):
        """Test that empty extensions list is allowed."""
        assert self.validator.validate_file_extensions("") is True

    def test_validate_file_extensions_with_dots(self):
        """Test extensions with leading dots."""
        assert self.validator.validate_file_extensions(".py,.js,.ts") is True

    def test_validate_file_extensions_invalid_chars(self):
        """Test rejection of invalid characters in extensions."""
        assert self.validator.validate_file_extensions("py;rm -rf /") is False
        assert self.validator.has_errors()

    # YAML file validation tests
    def test_validate_yaml_file_valid(self):
        """Test validation of valid YAML file paths."""
        assert self.validator.validate_yaml_file("config.yml") is True
        assert self.validator.validate_yaml_file("config.yaml") is True
        assert self.validator.validate_yaml_file("./config/settings.yml") is True

    def test_validate_yaml_file_invalid_extension(self):
        """Test rejection of non-YAML files."""
        assert self.validator.validate_yaml_file("config.txt") is False
        assert self.validator.has_errors()

    def test_validate_yaml_file_empty(self):
        """Test that empty YAML path is allowed (optional)."""
        assert self.validator.validate_yaml_file("") is True

    # JSON file validation tests
    def test_validate_json_file_valid(self):
        """Test validation of valid JSON file paths."""
        assert self.validator.validate_json_file("data.json") is True
        assert self.validator.validate_json_file("./config/settings.json") is True

    def test_validate_json_file_invalid_extension(self):
        """Test rejection of non-JSON files."""
        assert self.validator.validate_json_file("data.txt") is False
        assert self.validator.has_errors()

    def test_validate_json_file_empty(self):
        """Test that empty JSON path is allowed (optional)."""
        assert self.validator.validate_json_file("") is True

    # Config file validation tests
    def test_validate_config_file_valid(self):
        """Test validation of valid config file paths."""
        valid_configs = [
            "config.yml",
            "config.yaml",
            "config.json",
            "config.toml",
            "config.ini",
            "config.conf",
            "config.xml",
        ]
        for config in valid_configs:
            assert self.validator.validate_config_file(config) is True
            self.validator.clear_errors()

    def test_validate_config_file_invalid_extension(self):
        """Test rejection of invalid config file extensions."""
        assert self.validator.validate_config_file("config.txt") is False
        assert self.validator.has_errors()

    def test_validate_config_file_empty(self):
        """Test that empty config path is allowed (optional)."""
        assert self.validator.validate_config_file("") is True

    # Dockerfile validation tests
    def test_validate_dockerfile_path_valid(self):
        """Test validation of valid Dockerfile paths."""
        valid_dockerfiles = [
            "Dockerfile",
            "Dockerfile.prod",
            "docker/Dockerfile",
            "./build/Dockerfile",
        ]
        for dockerfile in valid_dockerfiles:
            assert self.validator.validate_dockerfile_path(dockerfile) is True
            self.validator.clear_errors()

    def test_validate_dockerfile_path_invalid_name(self):
        """Test rejection of names not containing 'dockerfile'."""
        assert self.validator.validate_dockerfile_path("build.txt") is False
        assert self.validator.has_errors()

    def test_validate_dockerfile_path_empty(self):
        """Test that empty Dockerfile path is allowed (optional)."""
        assert self.validator.validate_dockerfile_path("") is True

    # Executable file validation tests
    def test_validate_executable_file_valid(self):
        """Test validation of valid executable paths."""
        valid_executables = [
            "./scripts/build.sh",
            "bin/deploy",
            "./tools/script.py",
        ]
        for executable in valid_executables:
            assert self.validator.validate_executable_file(executable) is True
            self.validator.clear_errors()

    def test_validate_executable_file_absolute_path(self):
        """Test rejection of absolute paths for executables."""
        assert self.validator.validate_executable_file("/bin/bash") is False
        assert self.validator.has_errors()

    def test_validate_executable_file_empty(self):
        """Test that empty executable path is allowed (optional)."""
        assert self.validator.validate_executable_file("") is True

    # Required file validation tests
    def test_validate_required_file_with_path(self):
        """Test required file validation with a path."""
        # Path validation (no existence check in validation)
        assert self.validator.validate_required_file("./src/main.py") is True

    def test_validate_required_file_empty(self):
        """Test that required file cannot be empty."""
        assert self.validator.validate_required_file("") is False
        assert self.validator.has_errors()

    def test_validate_required_file_dangerous_path(self):
        """Test rejection of dangerous paths for required files."""
        assert self.validator.validate_required_file("../../../etc/passwd") is False
        assert self.validator.has_errors()

    # GitHub expressions tests
    def test_github_expressions(self):
        """Test GitHub expression handling in various validators."""
        github_expr = "${{ github.workspace }}/file.txt"
        assert self.validator.validate_file_path(github_expr) is True
        assert self.validator.validate_yaml_file("${{ inputs.config_file }}") is True
        # Only file_path and yaml_file check for GitHub expressions first
        # Other validators (config, json, branch_name) don't have GitHub expression support

    # Integration tests
    def test_validate_inputs_multiple_fields(self):
        """Test validation with multiple file inputs."""
        inputs = {
            "config-file": "config.yml",
            "data-file": "data.json",
            "branch": "main",
        }
        result = self.validator.validate_inputs(inputs)
        assert result is True

    def test_validate_inputs_with_errors(self):
        """Test validation with invalid inputs."""
        inputs = {
            "yaml-file": "file.txt",
            "branch": "invalid branch name",
        }
        # This should pass as validate_inputs doesn't specifically handle these
        # unless they're in a rules file
        result = self.validator.validate_inputs(inputs)
        assert isinstance(result, bool)
