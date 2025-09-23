"""Tests for custom validators in action directories."""

from pathlib import Path
import sys

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent.parent))

from validators.registry import ValidatorRegistry


class TestCustomValidators:
    """Test custom validators for various actions."""

    def test_sync_labels_custom_validator(self):
        """Test sync-labels custom validator."""
        registry = ValidatorRegistry()
        validator = registry.get_validator("sync-labels")

        # Should load the custom validator
        assert validator.__class__.__name__ == "CustomValidator"

        # Test valid inputs
        inputs = {
            "labels": ".github/labels.yml",
            "token": "${{ github.token }}",
        }
        assert validator.validate_inputs(inputs) is True
        assert not validator.has_errors()

        # Test invalid YAML extension
        validator.clear_errors()
        inputs = {"labels": ".github/labels.txt"}
        assert validator.validate_inputs(inputs) is False
        assert "Must be a .yml or .yaml file" in str(validator.errors)

        # Test path traversal
        validator.clear_errors()
        inputs = {"labels": "../../../etc/passwd"}
        assert validator.validate_inputs(inputs) is False
        assert validator.has_errors()

    def test_docker_build_custom_validator(self):
        """Test docker-build custom validator."""
        registry = ValidatorRegistry()
        validator = registry.get_validator("docker-build")

        # Should load the custom validator
        assert validator.__class__.__name__ == "CustomValidator"

        # Test valid inputs
        inputs = {
            "context": ".",
            "dockerfile": "./Dockerfile",
            "platforms": "linux/amd64,linux/arm64",
            "tags": "myimage:latest\nmyimage:v1.0.0",
            "push": "true",
        }
        assert validator.validate_inputs(inputs) is True
        assert not validator.has_errors()

        # Test missing required context
        validator.clear_errors()
        inputs = {}
        assert validator.validate_inputs(inputs) is False
        assert "context" in str(validator.errors)

        # Test invalid platform
        validator.clear_errors()
        inputs = {
            "context": ".",
            "platforms": "invalid/platform",
        }
        assert validator.validate_inputs(inputs) is False
        assert "Invalid platform" in str(validator.errors)

        # Test invalid build args format
        validator.clear_errors()
        inputs = {
            "context": ".",
            "build-args": "INVALID_FORMAT",
        }
        assert validator.validate_inputs(inputs) is False
        assert "KEY=value format" in str(validator.errors)

        # Test cache configuration
        validator.clear_errors()
        inputs = {
            "context": ".",
            "cache-from": "type=gha",
            "cache-to": "type=gha,mode=max",
        }
        assert validator.validate_inputs(inputs) is True
        assert not validator.has_errors()

    def test_codeql_analysis_custom_validator(self):
        """Test codeql-analysis custom validator."""
        registry = ValidatorRegistry()
        validator = registry.get_validator("codeql-analysis")

        # Should load the custom validator
        assert validator.__class__.__name__ == "CustomValidator"

        # Test valid inputs
        inputs = {
            "language": "javascript,python",
            "queries": "security-extended",
            "categories": "/security",
            "threads": "4",
            "ram": "4096",
            "debug": "false",
        }
        assert validator.validate_inputs(inputs) is True
        assert not validator.has_errors()

        # Test missing required language
        validator.clear_errors()
        inputs = {}
        assert validator.validate_inputs(inputs) is False
        assert "language" in str(validator.errors)

        # Test invalid language
        validator.clear_errors()
        inputs = {"language": "cobol"}
        assert validator.validate_inputs(inputs) is False
        assert "Unsupported CodeQL language" in str(validator.errors)

        # Test valid config file
        validator.clear_errors()
        inputs = {
            "language": "javascript",
            "config-file": ".github/codeql/codeql-config.yml",
        }
        assert validator.validate_inputs(inputs) is True
        assert not validator.has_errors()

        # Test invalid config file extension
        validator.clear_errors()
        inputs = {
            "language": "javascript",
            "config-file": "config.txt",
        }
        assert validator.validate_inputs(inputs) is False
        err = 'Invalid config-file: "config.txt". Must be a .yml or .yaml file'
        assert err in str(validator.errors)

        # Test pack validation
        validator.clear_errors()
        inputs = {
            "language": "javascript",
            "packs": "codeql/javascript-queries@1.2.3,github/codeql-go",
        }
        assert validator.validate_inputs(inputs) is True
        assert not validator.has_errors()

        # Test invalid pack format
        validator.clear_errors()
        inputs = {
            "language": "javascript",
            "packs": "invalid-pack-format",
        }
        assert validator.validate_inputs(inputs) is False
        assert "namespace/pack-name" in str(validator.errors)

    def test_docker_publish_custom_validator(self):
        """Test docker-publish custom validator."""
        registry = ValidatorRegistry()
        validator = registry.get_validator("docker-publish")

        # Should load the custom validator
        assert validator.__class__.__name__ == "CustomValidator"

        # Test valid inputs
        inputs = {
            "image": "myorg/myapp",
            "registry": "docker.io",
            "tags": "latest,v1.0.0",
            "username": "${{ secrets.DOCKER_USERNAME }}",
            "password": "${{ secrets.DOCKER_PASSWORD }}",
            "platforms": "linux/amd64,linux/arm64",
            "push": "true",
        }
        result = validator.validate_inputs(inputs)
        if not result:
            pass
        assert result is True
        assert not validator.has_errors()

        # Test missing required image
        validator.clear_errors()
        inputs = {}
        assert validator.validate_inputs(inputs) is False
        assert "image" in str(validator.errors)

        # Test registry validation
        validator.clear_errors()
        inputs = {
            "image": "myapp",
            "registry": "ghcr.io",
        }
        assert validator.validate_inputs(inputs) is True
        assert not validator.has_errors()

        # Test invalid registry
        validator.clear_errors()
        inputs = {
            "image": "myapp",
            "registry": "not-a-valid-registry",
        }
        assert validator.validate_inputs(inputs) is False
        assert validator.has_errors()

        # Test platform validation - only Linux platforms are valid for Docker
        validator.clear_errors()
        inputs = {
            "image": "myapp",
            "platforms": "linux/amd64,linux/arm64,linux/arm/v7",
        }
        result = validator.validate_inputs(inputs)
        if not result:
            pass
        assert result is True
        assert not validator.has_errors()

        # Test invalid platform OS
        validator.clear_errors()
        inputs = {
            "image": "myapp",
            "platforms": "freebsd/amd64",
        }
        assert validator.validate_inputs(inputs) is False
        assert validator.has_errors()

        # Test provenance settings
        validator.clear_errors()
        inputs = {
            "image": "myapp",
            "provenance": "mode=max",
            "sbom": "true",
        }
        assert validator.validate_inputs(inputs) is True
        assert not validator.has_errors()

        # Test invalid provenance mode
        validator.clear_errors()
        inputs = {
            "image": "myapp",
            "provenance": "mode=invalid",
        }
        assert validator.validate_inputs(inputs) is False
        assert "must be 'min' or 'max'" in str(validator.errors)

    def test_custom_validator_error_propagation(self):
        """Test that errors from sub-validators propagate correctly."""
        registry = ValidatorRegistry()

        # Test sync-labels with invalid token
        validator = registry.get_validator("sync-labels")
        validator.clear_errors()
        inputs = {
            "labels": ".github/labels.yml",
            "token": "invalid-token-format",
        }
        assert validator.validate_inputs(inputs) is False
        # Should have error from token validator
        assert validator.has_errors()

        # Test docker-build with injection attempt
        validator = registry.get_validator("docker-build")
        validator.clear_errors()
        inputs = {
            "context": ".",
            "build-args": "ARG1=value1\nARG2=; rm -rf /",
        }
        assert validator.validate_inputs(inputs) is False
        errors = str(validator.errors).lower()
        assert "injection" in errors or "security" in errors

    def test_custom_validators_github_expressions(self):
        """Test that custom validators handle GitHub expressions correctly."""
        registry = ValidatorRegistry()

        # All custom validators should accept GitHub expressions
        test_cases = [
            (
                "sync-labels",
                {
                    "labels": "${{ github.workspace }}/.github/labels.yml",
                    "token": "${{ secrets.GITHUB_TOKEN }}",
                },
            ),
            (
                "docker-build",
                {
                    "context": "${{ github.workspace }}",
                    "dockerfile": "${{ inputs.dockerfile }}",
                    "tags": "${{ steps.meta.outputs.tags }}",
                },
            ),
            (
                "codeql-analysis",
                {
                    "language": "${{ matrix.language }}",
                    "queries": "${{ inputs.queries }}",
                },
            ),
            (
                "docker-publish",
                {
                    "image": "${{ env.IMAGE_NAME }}",
                    "tags": "${{ steps.meta.outputs.tags }}",
                    "registry": "${{ vars.REGISTRY }}",
                },
            ),
        ]

        for action_type, inputs in test_cases:
            validator = registry.get_validator(action_type)
            validator.clear_errors()
            # Add required fields if needed
            if action_type == "docker-build":
                inputs["context"] = inputs.get("context", ".")
            elif action_type == "codeql-analysis":
                inputs["language"] = inputs.get("language", "javascript")
            elif action_type == "docker-publish":
                inputs["image"] = inputs.get("image", "myapp")

            assert validator.validate_inputs(inputs) is True
            assert not validator.has_errors(), f"Failed for {action_type}: {validator.errors}"
