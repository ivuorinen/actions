"""Comprehensive tests for the update-validators.py script."""

import argparse
import importlib.util
import sys
import tempfile
from pathlib import Path
from unittest.mock import patch

import yaml  # pylint: disable=import-error

# Add the scripts directory to the path to import the script
scripts_dir = Path(__file__).parent.parent / "scripts"
sys.path.insert(0, str(scripts_dir))

spec = importlib.util.spec_from_file_location(
    "update_validators",
    scripts_dir / "update-validators.py",
)
if spec is None or spec.loader is None:
    msg = "Could not load update-validators.py module"
    raise ImportError(msg)
update_validators = importlib.util.module_from_spec(spec)
spec.loader.exec_module(update_validators)

ValidationRuleGenerator = update_validators.ValidationRuleGenerator
main = update_validators.main


class TestValidationRuleGenerator:
    """Test cases for ValidationRuleGenerator class."""

    def setup_method(self):
        """Set up test environment before each test."""
        # Create a temporary directory structure for testing
        self.temp_dir = tempfile.mkdtemp()
        self.temp_path = Path(self.temp_dir)

        # Create mock actions directory structure
        self.actions_dir = self.temp_path / "actions"
        self.actions_dir.mkdir()

        # Create validate-inputs directory
        self.validate_inputs_dir = self.actions_dir / "validate-inputs"
        self.validate_inputs_dir.mkdir()
        self.rules_dir = self.validate_inputs_dir / "rules"
        self.rules_dir.mkdir()

    def teardown_method(self):
        """Clean up after each test."""
        import shutil

        shutil.rmtree(self.temp_dir)

    def create_mock_action(self, name: str, inputs: dict, description: str = "Test action") -> Path:
        """Create a mock action directory with action.yml file."""
        action_dir = self.actions_dir / name
        action_dir.mkdir()

        action_yml = {"name": f"{name} Action", "description": description, "inputs": inputs}

        action_file = action_dir / "action.yml"
        with action_file.open("w") as f:
            yaml.dump(action_yml, f)

        return action_file

    def test_init(self):
        """Test ValidationRuleGenerator initialization."""
        generator = ValidationRuleGenerator(dry_run=True, specific_action="test")
        assert generator.dry_run is True
        assert generator.specific_action == "test"
        assert "github_token" in generator.conventions
        assert "semantic_version" in generator.conventions

    def test_get_action_directories(self):
        """Test getting action directories."""
        # Create some mock actions
        self.create_mock_action("test-action", {"version": {"required": True}})
        self.create_mock_action("another-action", {"token": {"required": False}})

        # Create a directory without action.yml (should be ignored)
        (self.actions_dir / "not-an-action").mkdir()

        # Create a hidden directory (should be ignored)
        (self.actions_dir / ".hidden").mkdir()

        with patch.object(ValidationRuleGenerator, "__init__", lambda _self, **_kwargs: None):
            generator = ValidationRuleGenerator()
            generator.actions_dir = self.actions_dir

        actions = generator.get_action_directories()

        # Should find both valid actions, exclude validate-inputs, hidden dirs, and dirs
        # without action.yml
        expected = {"test-action", "another-action"}
        assert set(actions) == expected

    def test_parse_action_file_success(self):
        """Test successful parsing of action.yml file."""
        inputs = {
            "version": {"description": "Version to release", "required": True},
            "token": {
                "description": "GitHub token",
                "required": False,
                "default": "${{ github.token }}",
            },
        }

        self.create_mock_action("test-action", inputs, "Test action for parsing")

        with patch.object(ValidationRuleGenerator, "__init__", lambda _self, **_kwargs: None):
            generator = ValidationRuleGenerator()
            generator.actions_dir = self.actions_dir

        result = generator.parse_action_file("test-action")

        assert result is not None
        assert result["name"] == "test-action Action"
        assert result["description"] == "Test action for parsing"
        assert result["inputs"] == inputs

    def test_parse_action_file_missing_file(self):
        """Test parsing when action.yml file doesn't exist."""
        with patch.object(ValidationRuleGenerator, "__init__", lambda _self, **_kwargs: None):
            generator = ValidationRuleGenerator()
            generator.actions_dir = self.actions_dir

        result = generator.parse_action_file("nonexistent-action")
        assert result is None

    def test_parse_action_file_invalid_yaml(self):
        """Test parsing when action.yml contains invalid YAML."""
        action_dir = self.actions_dir / "invalid-action"
        action_dir.mkdir()

        # Write invalid YAML
        action_file = action_dir / "action.yml"
        with action_file.open("w") as f:
            f.write("invalid: yaml: content: [unclosed")

        with patch.object(ValidationRuleGenerator, "__init__", lambda _self, **_kwargs: None):
            generator = ValidationRuleGenerator()
            generator.actions_dir = self.actions_dir

        result = generator.parse_action_file("invalid-action")
        assert result is None

    def test_detect_validation_type_special_cases(self):
        """Test validation type detection for special cases."""
        generator = ValidationRuleGenerator()

        # Test special cases from the mapping
        assert generator.detect_validation_type("build-args", {}) is None
        assert generator.detect_validation_type("version", {}) == "flexible_version"
        assert (
            generator.detect_validation_type("dotnet-version", {}) == "dotnet_version"
        )  # Convention-based, not special case
        assert generator.detect_validation_type("pre-commit-config", {}) == "file_path"

        # Test convention-based detection for dotnet_version pattern (not in special cases)
        assert generator.detect_validation_type("dotnet_version", {}) == "dotnet_version"

    def test_detect_validation_type_conventions(self):
        """Test validation type detection using conventions."""
        generator = ValidationRuleGenerator()

        # Test token detection
        assert generator.detect_validation_type("token", {}) == "github_token"
        assert generator.detect_validation_type("github-token", {}) == "github_token"
        assert generator.detect_validation_type("auth_token", {}) == "github_token"

        # Test version detection
        assert generator.detect_validation_type("app-version", {}) == "semantic_version"
        assert generator.detect_validation_type("release-version", {}) == "calver_version"

        # Test docker detection
        assert generator.detect_validation_type("image-name", {}) == "docker_image_name"
        assert generator.detect_validation_type("tag", {}) == "docker_tag"
        assert generator.detect_validation_type("architectures", {}) == "docker_architectures"

        # Test boolean detection
        assert generator.detect_validation_type("dry-run", {}) == "boolean"
        assert generator.detect_validation_type("verbose", {}) == "boolean"
        assert generator.detect_validation_type("enable-cache", {}) == "boolean"

    def test_detect_validation_type_description_fallback(self):
        """Test validation type detection using description when name doesn't match."""
        generator = ValidationRuleGenerator()

        # Test fallback to description
        result = generator.detect_validation_type(
            "my_field",
            {"description": "GitHub token for authentication"},
        )
        assert result == "github_token"

        result = generator.detect_validation_type(
            "custom_flag",
            {"description": "Enable verbose output"},
        )
        assert result == "boolean"

    def test_detect_validation_type_calver_description(self):
        """Test CalVer detection based on description keywords."""
        generator = ValidationRuleGenerator()

        # For version field, special case takes precedence (flexible_version)
        result = generator.detect_validation_type(
            "version",
            {"description": "Release version in calendar format"},
        )
        assert result == "flexible_version"  # Special case overrides description

        # Test CalVer detection in other version fields with description
        result = generator.detect_validation_type(
            "release-version",
            {"description": "Monthly release version"},
        )
        assert result == "calver_version"

    def test_detect_validation_type_no_match(self):
        """Test when no validation type can be detected."""
        generator = ValidationRuleGenerator()

        result = generator.detect_validation_type(
            "unknown_field",
            {"description": "Some random field with no special meaning"},
        )
        assert result is None

    def test_sort_object_by_keys(self):
        """Test object key sorting."""
        generator = ValidationRuleGenerator()

        unsorted = {"z": 1, "a": 2, "m": 3, "b": 4}
        sorted_obj = generator.sort_object_by_keys(unsorted)

        assert list(sorted_obj.keys()) == ["a", "b", "m", "z"]
        assert sorted_obj["a"] == 2
        assert sorted_obj["z"] == 1

    def test_generate_rules_for_action_success(self):
        """Test successful rule generation for an action."""
        inputs = {
            "version": {"description": "Version to release", "required": True},
            "token": {
                "description": "GitHub token",
                "required": False,
                "default": "${{ github.token }}",
            },
            "dry-run": {"description": "Perform a dry run", "required": False, "default": "false"},
        }

        self.create_mock_action("test-action", inputs, "Test action for rule generation")

        # Initialize generator normally but override paths
        generator = ValidationRuleGenerator(dry_run=False)
        generator.actions_dir = self.actions_dir
        generator.rules_dir = self.rules_dir

        rules = generator.generate_rules_for_action("test-action")

        assert rules is not None
        assert rules["action"] == "test-action"
        assert rules["description"] == "Test action for rule generation"
        assert "version" in rules["required_inputs"]
        assert "token" in rules["optional_inputs"]
        assert "dry-run" in rules["optional_inputs"]

        # Check conventions detection
        assert rules["conventions"]["version"] == "flexible_version"  # Special case
        assert rules["conventions"]["token"] == "github_token"
        assert rules["conventions"]["dry-run"] == "boolean"

        # Check statistics
        assert rules["statistics"]["total_inputs"] == 3
        assert rules["statistics"]["validated_inputs"] == 3
        assert rules["validation_coverage"] == 100

    def test_generate_rules_for_action_missing_action(self):
        """Test rule generation for non-existent action."""
        with patch.object(ValidationRuleGenerator, "__init__", lambda _self, **_kwargs: None):
            generator = ValidationRuleGenerator()
            generator.actions_dir = self.actions_dir

        rules = generator.generate_rules_for_action("nonexistent-action")
        assert rules is None

    def test_write_rules_file_dry_run(self):
        """Test writing rules file in dry run mode."""
        rules = {
            "action": "test-action",
            "schema_version": "1.0",
            "generator_version": "1.0.0",
            "last_updated": "2024-01-01T00:00:00",
            "validation_coverage": 75,
            "statistics": {"validated_inputs": 3, "total_inputs": 4},
        }

        with patch.object(ValidationRuleGenerator, "__init__", lambda _self, **_kwargs: None):
            generator = ValidationRuleGenerator()
            generator.actions_dir = self.temp_path / "actions"
            generator.actions_dir.mkdir(parents=True, exist_ok=True)
            (generator.actions_dir / "test-action").mkdir(parents=True, exist_ok=True)
            generator.dry_run = True

        # Capture stdout
        with patch("builtins.print") as mock_print:
            generator.write_rules_file("test-action", rules)

        # Verify dry run output was printed
        print_calls = [call.args[0] for call in mock_print.call_args_list]
        assert any("[DRY RUN]" in call for call in print_calls)

        # Verify no file was created
        rules_file = generator.actions_dir / "test-action" / "rules.yml"
        assert not rules_file.exists()

    def test_write_rules_file_actual_write(self):
        """Test actually writing rules file."""
        rules = {
            "action": "test-action",
            "schema_version": "1.0",
            "generator_version": "1.0.0",
            "last_updated": "2024-01-01T00:00:00",
            "validation_coverage": 75,
            "statistics": {"validated_inputs": 3, "total_inputs": 4},
            "required_inputs": ["version"],
            "conventions": {"version": "semantic_version"},
        }

        with patch.object(ValidationRuleGenerator, "__init__", lambda _self, **_kwargs: None):
            generator = ValidationRuleGenerator()
            generator.actions_dir = self.temp_path / "actions"
            generator.actions_dir.mkdir(parents=True, exist_ok=True)
            (generator.actions_dir / "test-action").mkdir(parents=True, exist_ok=True)
            generator.dry_run = False

        generator.write_rules_file("test-action", rules)

        # Verify file was created
        rules_file = generator.actions_dir / "test-action" / "rules.yml"
        assert rules_file.exists()

        # Verify file content
        with rules_file.open() as f:
            content = f.read()

        assert "# Validation rules for test-action action" in content
        assert "DO NOT EDIT MANUALLY" in content
        assert "Coverage: 75%" in content

        # Verify YAML can be parsed
        yaml_content = content.split("\n\n", 1)[1]  # Skip header
        parsed = yaml.safe_load(yaml_content)
        assert parsed["action"] == "test-action"

    def test_validate_rules_files_success(self):
        """Test validation of existing rules files."""
        # Create a valid rules file
        rules = {
            "action": "test-action",
            "required_inputs": ["version"],
            "optional_inputs": ["token"],
            "conventions": {"version": "semantic_version"},
        }

        # Create action directory structure
        action_dir = self.temp_path / "actions" / "test-action"
        action_dir.mkdir(parents=True, exist_ok=True)

        rules_file = action_dir / "rules.yml"
        with rules_file.open("w") as f:
            yaml.dump(rules, f)

        with patch.object(ValidationRuleGenerator, "__init__", lambda _self, **_kwargs: None):
            generator = ValidationRuleGenerator()
            generator.actions_dir = self.temp_path / "actions"

        result = generator.validate_rules_files()
        assert result is True

    def test_validate_rules_files_missing_fields(self):
        """Test validation of rules files with missing required fields."""
        # Create an invalid rules file (missing required fields)
        rules = {
            "action": "test-action",
            # Missing required_inputs, optional_inputs, conventions
        }

        # Create action directory structure
        action_dir = self.temp_path / "actions" / "test-action"
        action_dir.mkdir(parents=True, exist_ok=True)

        rules_file = action_dir / "rules.yml"
        with rules_file.open("w") as f:
            yaml.dump(rules, f)

        with patch.object(ValidationRuleGenerator, "__init__", lambda _self, **_kwargs: None):
            generator = ValidationRuleGenerator()
            generator.actions_dir = self.temp_path / "actions"

        with patch("builtins.print") as mock_print:
            result = generator.validate_rules_files()

        assert result is False
        # Verify error was printed
        print_calls = [call.args[0] for call in mock_print.call_args_list]
        assert any("Missing fields" in call for call in print_calls)

    def test_validate_rules_files_invalid_yaml(self):
        """Test validation of rules files with invalid YAML."""
        # Create action directory structure
        action_dir = self.temp_path / "actions" / "test-action"
        action_dir.mkdir(parents=True, exist_ok=True)

        # Create an invalid YAML file
        rules_file = action_dir / "rules.yml"
        with rules_file.open("w") as f:
            f.write("invalid: yaml: content: [unclosed")

        with patch.object(ValidationRuleGenerator, "__init__", lambda _self, **_kwargs: None):
            generator = ValidationRuleGenerator()
            generator.actions_dir = self.temp_path / "actions"

        with patch("builtins.print") as mock_print:
            result = generator.validate_rules_files()

        assert result is False
        # Verify error was printed
        print_calls = [call.args[0] for call in mock_print.call_args_list]
        assert any("rules.yml:" in call for call in print_calls)


class TestCLIFunctionality:
    """Test CLI functionality and main function."""

    def test_main_dry_run(self):
        """Test main function with --dry-run flag."""
        test_args = ["update-validators.py", "--dry-run"]

        with patch("sys.argv", test_args), patch.object(
            ValidationRuleGenerator,
            "generate_rules",
        ) as mock_generate:
            main()
            mock_generate.assert_called_once()

    def test_main_specific_action(self):
        """Test main function with --action flag."""
        test_args = ["update-validators.py", "--action", "test-action"]

        with patch("sys.argv", test_args), patch.object(
            ValidationRuleGenerator,
            "generate_rules",
        ) as mock_generate:
            main()
            mock_generate.assert_called_once()

    def test_main_validate_success(self):
        """Test main function with --validate flag (success case)."""
        test_args = ["update-validators.py", "--validate"]

        with patch("sys.argv", test_args), patch.object(
            ValidationRuleGenerator,
            "validate_rules_files",
            return_value=True,
        ), patch("sys.exit") as mock_exit:
            main()
            mock_exit.assert_called_once_with(0)

    def test_main_validate_failure(self):
        """Test main function with --validate flag (failure case)."""
        test_args = ["update-validators.py", "--validate"]

        with patch("sys.argv", test_args), patch.object(
            ValidationRuleGenerator,
            "validate_rules_files",
            return_value=False,
        ), patch("sys.exit") as mock_exit:
            main()
            mock_exit.assert_called_once_with(1)

    def test_argparse_configuration(self):
        """Test argument parser configuration."""
        parser = argparse.ArgumentParser()
        parser.add_argument("--dry-run", action="store_true")
        parser.add_argument("--action", metavar="NAME")
        parser.add_argument("--validate", action="store_true")

        # Test dry-run flag
        args = parser.parse_args(["--dry-run"])
        assert args.dry_run is True
        assert args.action is None
        assert args.validate is False

        # Test action flag
        args = parser.parse_args(["--action", "test-action"])
        assert args.dry_run is False
        assert args.action == "test-action"
        assert args.validate is False

        # Test validate flag
        args = parser.parse_args(["--validate"])
        assert args.dry_run is False
        assert args.action is None
        assert args.validate is True


class TestIntegrationScenarios:
    """Integration tests that verify end-to-end functionality."""

    def setup_method(self):
        """Set up test environment."""
        self.temp_dir = tempfile.mkdtemp()
        self.temp_path = Path(self.temp_dir)

        # Create mock project structure
        self.actions_dir = self.temp_path / "actions"
        self.actions_dir.mkdir()

        self.validate_inputs_dir = self.actions_dir / "validate-inputs"
        self.validate_inputs_dir.mkdir()
        self.rules_dir = self.validate_inputs_dir / "rules"
        self.rules_dir.mkdir()

    def teardown_method(self):
        """Clean up after tests."""
        import shutil

        shutil.rmtree(self.temp_dir)

    def create_realistic_action(self, name: str) -> None:
        """Create a realistic action for testing."""
        action_dir = self.actions_dir / name
        action_dir.mkdir()

        inputs = {
            "version": {"description": "Version to release", "required": True},
            "token": {
                "description": "GitHub token",
                "required": False,
                "default": "${{ github.token }}",
            },
            "dry-run": {"description": "Perform a dry run", "required": False, "default": "false"},
            "dockerfile": {
                "description": "Path to Dockerfile",
                "required": False,
                "default": "Dockerfile",
            },
        }

        action_yml = {
            "name": f"{name.title()} Action",
            "description": f"GitHub Action for {name}",
            "inputs": inputs,
            "runs": {"using": "composite", "steps": [{"run": "echo 'test'", "shell": "bash"}]},
        }

        with (action_dir / "action.yml").open("w") as f:
            yaml.dump(action_yml, f)

    def test_full_generation_workflow(self):
        """Test the complete rule generation workflow."""
        # Create multiple realistic actions
        self.create_realistic_action("docker-build")
        self.create_realistic_action("github-release")

        # Initialize generator pointing to our test directory
        generator = ValidationRuleGenerator(dry_run=False)
        generator.actions_dir = self.actions_dir

        # Run the generation
        with patch("builtins.print"):  # Suppress output
            generator.generate_rules()

        # Verify rules were generated in action folders
        docker_rules_file = self.actions_dir / "docker-build" / "rules.yml"
        github_rules_file = self.actions_dir / "github-release" / "rules.yml"

        assert docker_rules_file.exists()
        assert github_rules_file.exists()

        # Verify generated rules content
        with docker_rules_file.open() as f:
            docker_content = f.read()

        assert "# Validation rules for docker-build action" in docker_content
        assert "DO NOT EDIT MANUALLY" in docker_content

        # Parse and verify the YAML structure
        yaml_content = docker_content.split("\n\n", 1)[1]
        docker_rules = yaml.safe_load(yaml_content)

        assert docker_rules["action"] == "docker-build"
        assert "version" in docker_rules["required_inputs"]
        assert "token" in docker_rules["optional_inputs"]
        assert docker_rules["conventions"]["version"] == "flexible_version"
        assert docker_rules["conventions"]["token"] == "github_token"
        assert docker_rules["conventions"]["dry-run"] == "boolean"
        assert docker_rules["conventions"]["dockerfile"] == "file_path"

    def test_specific_action_generation(self):
        """Test generating rules for a specific action only."""
        self.create_realistic_action("docker-build")
        self.create_realistic_action("github-release")

        generator = ValidationRuleGenerator(dry_run=False, specific_action="docker-build")
        generator.actions_dir = self.actions_dir

        with patch("builtins.print"):
            generator.generate_rules()

        # Only docker-build rules should be generated
        docker_rules_file = self.actions_dir / "docker-build" / "rules.yml"
        github_rules_file = self.actions_dir / "github-release" / "rules.yml"

        assert docker_rules_file.exists()
        assert not github_rules_file.exists()

    def test_error_handling_during_generation(self):
        """Test error handling when action parsing fails."""
        # Create an action with invalid YAML
        action_dir = self.actions_dir / "invalid-action"
        action_dir.mkdir()

        with (action_dir / "action.yml").open("w") as f:
            f.write("invalid: yaml: content: [unclosed")

        generator = ValidationRuleGenerator(dry_run=False)
        generator.actions_dir = self.actions_dir
        generator.rules_dir = self.rules_dir

        with patch("builtins.print") as mock_print:
            generator.generate_rules()

        # Verify error was handled and reported
        print_calls = [str(call) for call in mock_print.call_args_list]
        assert any(
            "Failed to generate rules" in call or "Error processing" in call for call in print_calls
        )
