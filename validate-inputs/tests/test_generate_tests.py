"""Tests for the test generation system."""

import importlib.util
from pathlib import Path
import sys
import tempfile

import yaml

# Import the test generator
scripts_path = Path(__file__).parent.parent / "scripts"
sys.path.insert(0, str(scripts_path))

spec = importlib.util.spec_from_file_location("generate_tests", scripts_path / "generate-tests.py")
if spec is None or spec.loader is None:
    sys.exit("Failed to load generate-tests module")

generate_tests = importlib.util.module_from_spec(spec)
spec.loader.exec_module(generate_tests)
# Import as GeneratorClass to avoid pytest collection warning
GeneratorClass = generate_tests.TestGenerator


class TestTestGenerator:
    """Test cases for the test generation system."""

    def setup_method(self):
        """Set up test fixtures."""
        self.temp_dir = Path(tempfile.mkdtemp())
        self.generator = GeneratorClass(self.temp_dir)

    def teardown_method(self):
        """Clean up test fixtures."""
        # Clean up temp directory
        import shutil

        if self.temp_dir.exists():
            shutil.rmtree(self.temp_dir)

    def test_generator_initialization(self):
        """Test that generator initializes correctly."""
        assert self.generator.project_root == self.temp_dir
        assert self.generator.validate_inputs_dir == self.temp_dir / "validate-inputs"
        assert self.generator.tests_dir == self.temp_dir / "_tests"
        assert self.generator.generated_count == 0
        assert self.generator.skipped_count == 0

    def test_skip_existing_shellspec_test(self):
        """Test that existing ShellSpec tests are not overwritten."""
        # Create action directory with action.yml
        action_dir = self.temp_dir / "test-action"
        action_dir.mkdir(parents=True)

        action_yml = action_dir / "action.yml"
        action_yml.write_text(
            yaml.dump(
                {
                    "name": "Test Action",
                    "description": "Test action for testing",
                    "inputs": {"test-input": {"required": True}},
                },
            ),
        )

        # Create existing test file
        test_file = self.temp_dir / "_tests" / "unit" / "test-action" / "validation.spec.sh"
        test_file.parent.mkdir(parents=True, exist_ok=True)
        test_file.write_text("# Existing test")

        # Run generator
        self.generator.generate_action_tests()

        # Verify test was not overwritten
        assert test_file.read_text() == "# Existing test"
        assert self.generator.skipped_count == 1
        assert self.generator.generated_count == 0

    def test_generate_new_shellspec_test(self):
        """Test generation of new ShellSpec test."""
        # Create action directory with action.yml
        action_dir = self.temp_dir / "test-action"
        action_dir.mkdir(parents=True)

        action_yml = action_dir / "action.yml"
        action_yml.write_text(
            yaml.dump(
                {
                    "name": "Test Action",
                    "description": "Test action for testing",
                    "inputs": {
                        "token": {"required": True, "description": "GitHub token"},
                        "version": {"required": False, "default": "1.0.0"},
                    },
                },
            ),
        )

        # Run generator
        self.generator.generate_action_tests()

        # Verify test was created
        test_file = self.temp_dir / "_tests" / "unit" / "test-action" / "validation.spec.sh"
        assert test_file.exists()
        assert test_file.stat().st_mode & 0o111  # Check executable

        content = test_file.read_text()
        assert "Test Action Input Validation" in content
        assert "should fail when required inputs are missing" in content
        assert "should fail without token" in content
        assert "should pass with all valid inputs" in content

        assert self.generator.generated_count == 1
        assert self.generator.skipped_count == 0

    def test_skip_existing_pytest_test(self):
        """Test that existing pytest tests are not overwritten."""
        # Create validators directory
        validators_dir = self.temp_dir / "validate-inputs" / "validators"
        validators_dir.mkdir(parents=True, exist_ok=True)

        # Create validator file
        validator_file = validators_dir / "test_validator.py"
        validator_file.write_text("class TestValidator: pass")

        # Create existing test file
        test_file = self.temp_dir / "validate-inputs" / "tests" / "test_test_validator.py"
        test_file.parent.mkdir(parents=True, exist_ok=True)
        test_file.write_text("# Existing test")

        # Run generator
        self.generator.generate_validator_tests()

        # Verify test was not overwritten
        assert test_file.read_text() == "# Existing test"
        assert self.generator.skipped_count == 1

    def test_generate_new_pytest_test(self):
        """Test generation of new pytest test."""
        # Create validators directory
        validators_dir = self.temp_dir / "validate-inputs" / "validators"
        validators_dir.mkdir(parents=True, exist_ok=True)

        # Create validator file
        validator_file = validators_dir / "example_validator.py"
        validator_file.write_text("class ExampleValidator: pass")

        # Ensure tests directory exists
        tests_dir = self.temp_dir / "validate-inputs" / "tests"
        tests_dir.mkdir(parents=True, exist_ok=True)

        # Run generator
        self.generator.generate_validator_tests()

        # Verify test was created
        test_file = tests_dir / "test_example_validator.py"
        assert test_file.exists()

        content = test_file.read_text()
        assert "Tests for example_validator validator" in content
        assert "from validators.example_validator import ExampleValidator" in content
        assert "class TestExampleValidator:" in content
        assert "def test_validate_inputs(self):" in content

    def test_generate_custom_validator_test(self):
        """Test generation of custom validator test."""
        # Create action with custom validator
        action_dir = self.temp_dir / "docker-build"
        action_dir.mkdir(parents=True)

        custom_validator = action_dir / "CustomValidator.py"
        custom_validator.write_text("class CustomValidator: pass")

        # Ensure tests directory exists
        tests_dir = self.temp_dir / "validate-inputs" / "tests"
        tests_dir.mkdir(parents=True, exist_ok=True)

        # Run generator
        self.generator.generate_custom_validator_tests()

        # Verify test was created
        test_file = tests_dir / "test_docker-build_custom.py"
        assert test_file.exists()

        content = test_file.read_text()
        assert "Tests for docker-build custom validator" in content
        assert "from CustomValidator import CustomValidator" in content
        assert "test_docker_specific_validation" in content  # Docker-specific test

    def test_get_example_value_patterns(self):
        """Test example value generation for different input patterns."""
        # Token patterns
        assert (
            self.generator._get_example_value("github-token", {}) == "${{ secrets.GITHUB_TOKEN }}"
        )
        assert self.generator._get_example_value("npm-token", {}) == "${{ secrets.GITHUB_TOKEN }}"

        # Version patterns
        assert self.generator._get_example_value("version", {}) == "1.2.3"
        assert self.generator._get_example_value("node-version", {}) == "1.2.3"

        # Path patterns
        assert self.generator._get_example_value("file-path", {}) == "./path/to/file"
        assert self.generator._get_example_value("directory", {}) == "./path/to/file"

        # URL patterns
        assert self.generator._get_example_value("webhook-url", {}) == "https://example.com"
        assert self.generator._get_example_value("endpoint", {}) == "https://example.com"

        # Boolean patterns
        assert self.generator._get_example_value("dry-run", {}) == "false"
        assert self.generator._get_example_value("debug", {}) == "false"
        assert self.generator._get_example_value("push", {}) == "true"

        # Default from config
        assert self.generator._get_example_value("anything", {"default": "custom"}) == "custom"

        # Fallback
        assert self.generator._get_example_value("unknown-input", {}) == "test-value"

    def test_generate_input_test_cases(self):
        """Test generation of input-specific test cases."""
        # Boolean input
        cases = self.generator._generate_input_test_cases("dry-run", {})
        assert len(cases) == 1
        assert "should accept boolean values" in cases[0]
        assert "should reject invalid boolean" in cases[0]

        # Version input
        cases = self.generator._generate_input_test_cases("version", {})
        assert len(cases) == 1
        assert "should accept valid version" in cases[0]
        assert "should accept version with v prefix" in cases[0]

        # Token input
        cases = self.generator._generate_input_test_cases("github-token", {})
        assert len(cases) == 1
        assert "should accept GitHub token" in cases[0]
        assert "should accept classic PAT" in cases[0]

        # Path input
        cases = self.generator._generate_input_test_cases("config-file", {})
        assert len(cases) == 1
        assert "should accept valid path" in cases[0]
        assert "should reject path traversal" in cases[0]

        # No specific pattern
        cases = self.generator._generate_input_test_cases("custom-input", {})
        assert len(cases) == 0

    def test_generate_pytest_content_by_type(self):
        """Test that different validator types get appropriate test methods."""
        # Version validator
        content = self.generator._generate_pytest_content("version_validator")
        assert "test_valid_semantic_version" in content
        assert "test_valid_calver" in content

        # Token validator
        content = self.generator._generate_pytest_content("token_validator")
        assert "test_valid_github_token" in content
        assert "test_other_token_types" in content

        # Boolean validator
        content = self.generator._generate_pytest_content("boolean_validator")
        assert "test_valid_boolean_values" in content
        assert "test_invalid_boolean_values" in content

        # Docker validator
        content = self.generator._generate_pytest_content("docker_validator")
        assert "test_valid_image_names" in content
        assert "test_valid_platforms" in content

        # Generic validator
        content = self.generator._generate_pytest_content("unknown_validator")
        assert "test_validate_inputs" in content
        assert "TODO: Add specific test cases" in content

    def test_skip_special_directories(self):
        """Test that special directories are skipped."""
        # Create special directories that should be skipped
        dot_dir = self.temp_dir / ".hidden"
        dot_dir.mkdir()
        (dot_dir / "action.yml").write_text("name: Hidden")

        underscore_dir = self.temp_dir / "_internal"
        underscore_dir.mkdir()
        (underscore_dir / "action.yml").write_text("name: Internal")

        validate_dir = self.temp_dir / "validate-inputs"
        validate_dir.mkdir()
        (validate_dir / "action.yml").write_text("name: Validate")

        # Run generator
        self.generator.generate_action_tests()

        # Verify no tests were created for special directories
        assert not (self.temp_dir / "_tests" / "unit" / ".hidden").exists()
        assert not (self.temp_dir / "_tests" / "unit" / "_internal").exists()
        assert not (self.temp_dir / "_tests" / "unit" / "validate-inputs").exists()

        assert self.generator.generated_count == 0

    def test_full_generation_workflow(self):
        """Test the complete generation workflow."""
        # Setup test environment
        self._setup_test_environment()

        # Run full generation
        self.generator.generate_all_tests()

        # Verify counts
        assert self.generator.generated_count > 0
        assert self.generator.skipped_count >= 0

        # Verify some files were created
        shellspec_test = self.temp_dir / "_tests" / "unit" / "test-action" / "validation.spec.sh"
        assert shellspec_test.exists()

    def _setup_test_environment(self):
        """Set up a minimal test environment."""
        # Create an action
        action_dir = self.temp_dir / "test-action"
        action_dir.mkdir(parents=True)
        (action_dir / "action.yml").write_text(
            yaml.dump({"name": "Test", "inputs": {"test": {"required": True}}}),
        )

        # Create validate-inputs structure
        (self.temp_dir / "validate-inputs" / "validators").mkdir(parents=True, exist_ok=True)
        (self.temp_dir / "validate-inputs" / "tests").mkdir(parents=True, exist_ok=True)
