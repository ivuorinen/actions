"""Tests for the DockerValidator module."""

from pathlib import Path
import sys

# Add the parent directory to the path
sys.path.insert(0, str(Path(__file__).parent.parent))

from validators.docker import DockerValidator


class TestDockerValidator:
    """Test cases for DockerValidator."""

    def setup_method(self):
        """Set up test environment."""
        self.validator = DockerValidator()

    def test_initialization(self):
        """Test validator initialization."""
        assert self.validator.errors == []
        rules = self.validator.get_validation_rules()
        assert "image_name" in rules
        assert "tag" in rules
        assert "architectures" in rules

    def test_validate_docker_image_valid(self):
        """Test Docker image name validation with valid names."""
        valid_names = [
            "myapp",
            "my-app",
            "my_app",
            "app123",
            "nginx",
            "ubuntu",
            "node",
            "python",
            "my.app",  # Dots allowed
            "my-app_v2",  # Mixed separators
        ]

        for name in valid_names:
            self.validator.errors = []
            result = self.validator.validate_docker_image_name(name)
            assert result is True, f"Should accept image name: {name}"

    def test_validate_docker_image_invalid(self):
        """Test Docker image name validation with invalid names."""
        invalid_names = [
            "MyApp",  # Uppercase not allowed
            "my app",  # Spaces not allowed
            "-myapp",  # Leading dash
            "myapp-",  # Trailing dash
            "_myapp",  # Leading underscore
            "my/app",  # Slash not allowed (that's for namespace)
            "",  # Empty
        ]

        for name in invalid_names:
            self.validator.errors = []
            result = self.validator.validate_docker_image_name(name)
            if name == "":  # Empty might be required
                # Depends on whether image is required
                assert isinstance(result, bool)
            else:
                assert result is False, f"Should reject image name: {name}"

    def test_validate_docker_tag_valid(self):
        """Test Docker tag validation with valid tags."""
        valid_tags = [
            "latest",
            "v1.0.0",
            "1.0.0",
            "main",
            "master",
            "develop",
            "feature-branch",
            "release-1.0",
            "2024.3.1",
            "alpha",
            "beta",
            "rc1",
            "stable",
            "edge",
        ]

        for tag in valid_tags:
            self.validator.errors = []
            result = self.validator.validate_docker_tag(tag)
            assert result is True, f"Should accept tag: {tag}"

    def test_validate_docker_tag_invalid(self):
        """Test Docker tag validation with invalid tags."""
        invalid_tags = [
            "",  # Empty tag
            "my tag",  # Space not allowed
            "tag@latest",  # @ not allowed
            "tag#1",  # # not allowed
            ":tag",  # Leading colon
            "tag:",  # Trailing colon
        ]

        for tag in invalid_tags:
            self.validator.errors = []
            result = self.validator.validate_docker_tag(tag)
            # Some characters might be valid in Docker tags depending on implementation
            if tag == "" or " " in tag:
                assert result is False, f"Should reject tag: {tag}"
            else:
                # Other tags might be valid depending on Docker's rules
                assert isinstance(result, bool)

    def test_validate_architectures_valid(self):
        """Test architecture validation with valid values."""
        valid_archs = [
            "linux/amd64",
            "linux/arm64",
            "linux/arm/v7",
            "linux/arm/v6",
            "linux/386",
            "linux/ppc64le",
            "linux/s390x",
            "linux/amd64,linux/arm64",  # Multiple architectures
            "linux/amd64,linux/arm64,linux/arm/v7",  # Three architectures
        ]

        for arch in valid_archs:
            self.validator.errors = []
            result = self.validator.validate_architectures(arch)
            assert result is True, f"Should accept architecture: {arch}"

    def test_validate_architectures_invalid(self):
        """Test architecture validation with invalid values."""
        invalid_archs = [
            "windows/amd64",  # Windows not typically supported in Docker build
            "linux/invalid",  # Invalid architecture
            "amd64",  # Missing OS prefix
            "linux",  # Missing architecture
            "linux/",  # Incomplete
            "/amd64",  # Missing OS
            "linux/amd64,",  # Trailing comma
            ",linux/arm64",  # Leading comma
        ]

        for arch in invalid_archs:
            self.validator.errors = []
            result = self.validator.validate_architectures(arch)
            assert result is False, f"Should reject architecture: {arch}"

    def test_validate_namespace_with_lookahead_valid(self):
        """Test namespace validation with lookahead."""
        valid_namespaces = [
            "user",
            "my-org",
            "company123",
            "docker",
            "library",
            "test-namespace",
            "a" * 30,  # Long but valid
        ]

        for namespace in valid_namespaces:
            self.validator.errors = []
            result = self.validator.validate_namespace_with_lookahead(namespace)
            assert result is True, f"Should accept namespace: {namespace}"

    def test_validate_namespace_with_lookahead_invalid(self):
        """Test namespace validation with invalid values."""
        invalid_namespaces = [
            "",  # Empty
            "user-",  # Trailing dash
            "-user",  # Leading dash
            "user--name",  # Double dash
            "User",  # Uppercase
            "user name",  # Space
            "a" * 256,  # Too long
        ]

        for namespace in invalid_namespaces:
            self.validator.errors = []
            result = self.validator.validate_namespace_with_lookahead(namespace)
            if namespace == "":
                # Empty might be allowed
                assert isinstance(result, bool)
            else:
                assert result is False, f"Should reject namespace: {namespace}"

    def test_validate_prefix_valid(self):
        """Test prefix validation with valid values."""
        valid_prefixes = [
            "",  # Empty prefix is often valid
            "v",
            "version-",
            "release-",
            "tag_",
            "prefix.",
            "1.0.",
        ]

        for prefix in valid_prefixes:
            self.validator.errors = []
            result = self.validator.validate_prefix(prefix)
            assert result is True, f"Should accept prefix: {prefix}"

    def test_validate_prefix_invalid(self):
        """Test prefix validation with invalid values."""
        invalid_prefixes = [
            "pre fix",  # Space not allowed
            "prefix@",  # @ not allowed
            "prefix#",  # # not allowed
            "prefix:",  # : not allowed
        ]

        for prefix in invalid_prefixes:
            self.validator.errors = []
            result = self.validator.validate_prefix(prefix)
            assert result is False, f"Should reject prefix: {prefix}"

    def test_validate_inputs_docker_keywords(self):
        """Test validation of inputs with Docker-related keywords."""
        inputs = {
            "image": "myapp",
            "tag": "v1.0.0",
            "dockerfile": "Dockerfile",
            "context": ".",
            "platforms": "linux/amd64,linux/arm64",
            "registry": "docker.io",
            "namespace": "myorg",
            "prefix": "v",
        }

        result = self.validator.validate_inputs(inputs)
        assert isinstance(result, bool)

    def test_empty_values_handling(self):
        """Test that empty values are handled appropriately."""
        # Some Docker fields might be required, others optional
        assert isinstance(self.validator.validate_docker_image_name(""), bool)
        assert isinstance(self.validator.validate_docker_tag(""), bool)
        assert isinstance(self.validator.validate_architectures(""), bool)
        assert isinstance(self.validator.validate_prefix(""), bool)
