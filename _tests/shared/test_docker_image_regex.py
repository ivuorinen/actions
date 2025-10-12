#!/usr/bin/env python3
"""Test docker image name regex fix for dots in validation_core.py."""

from pathlib import Path
import sys

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent))

from validation_core import ValidationCore


def test_docker_image_names_with_dots():
    """Test that docker image names with dots are accepted."""
    validator = ValidationCore()

    # Valid docker image names with dots (should pass)
    valid_names = [
        "my.app",
        "app.with.dots",
        "registry.example.com/myapp",
        "docker.io/library/nginx",
        "ghcr.io/owner/repo",
        "gcr.io/project-id/image",
        "quay.io/organization/app",
        "my.registry.local/app.name",
        "registry.example.com/namespace/app.name",
        "harbor.example.com/project/image.name",
        "nexus.company.local/docker/app",
    ]

    print("Testing valid Docker image names with dots:")
    for name in valid_names:
        is_valid, error = validator.validate_docker_image_name(name)
        status = "✓" if is_valid else "✗"
        print(f"  {status} {name:50s} {'PASS' if is_valid else f'FAIL: {error}'}")
        assert is_valid, f"Should accept: {name} (got error: {error})"

    # Invalid names (should fail)
    invalid_names = [
        "MyApp",  # Uppercase
        "my app",  # Space
        "-myapp",  # Leading dash
        "myapp-",  # Trailing dash
        "_myapp",  # Leading underscore
    ]

    print("\nTesting invalid Docker image names:")
    for name in invalid_names:
        is_valid, error = validator.validate_docker_image_name(name)
        status = "✓" if not is_valid else "✗"
        print(
            f"  {status} {name:50s} {'PASS (rejected)' if not is_valid else 'FAIL (should reject)'}"
        )
        assert not is_valid, f"Should reject: {name}"

    print("\n✅ All tests passed!")


if __name__ == "__main__":
    test_docker_image_names_with_dots()
