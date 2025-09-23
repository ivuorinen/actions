"""File and path validators."""

from __future__ import annotations

from pathlib import Path
import re

from .base import BaseValidator


class FileValidator(BaseValidator):
    """Validator for file paths, extensions, and related inputs."""

    def validate_inputs(self, inputs: dict[str, str]) -> bool:
        """Validate file-related inputs."""
        valid = True

        for input_name, value in inputs.items():
            if "file" in input_name or "path" in input_name or "directory" in input_name:
                valid &= self.validate_file_path(value, input_name)
            elif "branch" in input_name:
                valid &= self.validate_branch_name(value)
            elif "extension" in input_name:
                valid &= self.validate_file_extensions(value, input_name)

        return valid

    def get_required_inputs(self) -> list[str]:
        """File validators typically don't define required inputs."""
        return []

    def get_validation_rules(self) -> dict:
        """Return file validation rules."""
        return {
            "file_path": "Relative paths only, no path traversal",
            "branch_name": "Valid git branch name",
            "file_extensions": "Comma-separated list starting with dots",
        }

    def validate_path(self, path: str, name: str = "path") -> bool:
        """Validate general file paths.

        Args:
            path: The file path to validate
            name: The input name for error messages

        Returns:
            True if valid, False otherwise
        """
        if not path or path.strip() == "":
            return True  # Path is often optional

        # Allow GitHub Actions expressions
        if self.is_github_expression(path):
            return True

        p = Path(path)

        try:
            safe_path = p.resolve(strict=True)
        except FileNotFoundError:
            self.add_error(f'Invalid {name}: "{path}". Path does not exist')
            return False

        # Use base class security validation
        return self.validate_path_security(str(safe_path.absolute()), name)

    def validate_file_path(self, path: str, name: str = "path") -> bool:
        """Validate file paths for security.

        Args:
            path: The file path to validate
            name: The input name for error messages

        Returns:
            True if valid, False otherwise
        """
        if not path or path.strip() == "":
            return True  # Path is often optional

        # Allow GitHub Actions expressions
        if self.is_github_expression(path):
            return True

        # Use base class security validation
        if not self.validate_path_security(path, name):
            return False

        # Additional file path validation
        # Check for valid characters
        if not re.match(r"^[a-zA-Z0-9._/\-\s]+$", path):
            self.add_error(f'Invalid {name}: "{path}". Contains invalid characters')
            return False

        return True

    def validate_branch_name(self, branch: str) -> bool:
        """Validate git branch name.

        Args:
            branch: The branch name to validate

        Returns:
            True if valid, False otherwise
        """
        if not branch or branch.strip() == "":
            return True  # Branch name is often optional

        # Check for command injection
        injection_patterns = [";", "&&", "||", "|", "`", "$("]
        for pattern in injection_patterns:
            if pattern in branch:
                self.add_error(
                    f'Invalid branch name: "{branch}". '
                    f'Command injection pattern "{pattern}" not allowed',
                )
                return False

        # Check for invalid git characters
        if ".." in branch or "~" in branch or "^" in branch or ":" in branch:
            self.add_error(
                f'Invalid branch name: "{branch}". Contains invalid git branch characters',
            )
            return False

        # Check for valid characters
        if not re.match(r"^[a-zA-Z0-9/_.\-]+$", branch):
            self.add_error(
                f'Invalid branch name: "{branch}". '
                "Must contain only alphanumeric, slash, underscore, dot, and hyphen",
            )
            return False

        # Check for invalid start/end characters
        if branch.startswith((".", "-", "/")) or branch.endswith((".", "/")):
            self.add_error(
                f'Invalid branch name: "{branch}". Cannot start/end with ".", "-", or "/"',
            )
            return False

        # Check for consecutive slashes
        if "//" in branch:
            self.add_error(f'Invalid branch name: "{branch}". Cannot contain consecutive slashes')
            return False

        return True

    def validate_file_extensions(self, value: str, name: str = "file-extensions") -> bool:
        """Validate file extensions format.

        Args:
            value: Comma-separated list of file extensions
            name: The input name for error messages

        Returns:
            True if valid, False otherwise
        """
        if not value or value.strip() == "":
            return True  # File extensions are optional

        extensions = [ext.strip() for ext in value.split(",")]

        for ext in extensions:
            if not ext:
                continue  # Skip empty entries

            # Must start with a dot
            if not ext.startswith("."):
                self.add_error(
                    f'Invalid file extension: "{ext}" in {name}. Extensions must start with a dot',
                )
                return False

            # Check for valid extension format
            if not re.match(r"^\.[a-zA-Z0-9]+$", ext):
                self.add_error(
                    f'Invalid file extension format: "{ext}" in {name}. '
                    "Must be dot followed by alphanumeric characters",
                )
                return False

            # Check for security patterns
            if self.validate_security_patterns(ext, f"{name} extension"):
                continue
            return False

        return True

    def validate_yaml_file(self, path: str, name: str = "yaml-file") -> bool:
        """Validate YAML file path.

        Args:
            path: The YAML file path to validate
            name: The input name for error messages

        Returns:
            True if valid, False otherwise
        """
        # Allow GitHub Actions expressions
        if self.is_github_expression(path):
            return True

        if not self.validate_file_path(path, name):
            return False

        if path and not (path.endswith((".yml", ".yaml"))):
            self.add_error(f'Invalid {name}: "{path}". Must be a .yml or .yaml file')
            return False

        return True

    def validate_json_file(self, path: str, name: str = "json-file") -> bool:
        """Validate JSON file path.

        Args:
            path: The JSON file path to validate
            name: The input name for error messages

        Returns:
            True if valid, False otherwise
        """
        if not self.validate_file_path(path, name):
            return False

        if path and not path.endswith(".json"):
            self.add_error(f'Invalid {name}: "{path}". Must be a .json file')
            return False

        return True

    def validate_config_file(self, path: str, name: str = "config-file") -> bool:
        """Validate configuration file path.

        Args:
            path: The config file path to validate
            name: The input name for error messages

        Returns:
            True if valid, False otherwise
        """
        if not self.validate_file_path(path, name):
            return False

        # Config files typically have specific extensions
        valid_extensions = [
            ".yml",
            ".yaml",
            ".json",
            ".toml",
            ".ini",
            ".conf",
            ".config",
            ".cfg",
            ".xml",
        ]

        if path:
            has_valid_ext = any(path.endswith(ext) for ext in valid_extensions)
            if not has_valid_ext:
                self.add_error(
                    f'Invalid {name}: "{path}". '
                    f"Expected config file extension: {', '.join(valid_extensions)}",
                )
                return False

        return True

    def validate_dockerfile_path(self, path: str, name: str = "dockerfile") -> bool:
        """Validate Dockerfile path.

        Args:
            path: The Dockerfile path to validate
            name: The input name for error messages

        Returns:
            True if valid, False otherwise
        """
        if not path or path.strip() == "":
            return True  # Dockerfile path is often optional

        # First validate general file path security
        if not self.validate_file_path(path, name):
            return False

        # Check if it looks like a Dockerfile
        # Accept: Dockerfile, dockerfile, Dockerfile.*, docker/Dockerfile, etc.
        basename = Path(path).name.lower()

        # Must contain 'dockerfile' in the basename
        if "dockerfile" not in basename:
            self.add_error(
                f"Invalid {name}: \"{path}\". File name must contain 'Dockerfile' or 'dockerfile'",
            )
            return False

        return True

    def validate_executable_file(self, path: str, name: str = "executable") -> bool:
        """Validate executable file path.

        Args:
            path: The executable file path to validate
            name: The input name for error messages

        Returns:
            True if valid, False otherwise
        """
        if not path or path.strip() == "":
            return True  # Executable path is often optional

        # First validate general file path security
        if not self.validate_file_path(path, name):
            return False

        # Check for common executable extensions (for Windows)

        # Check for potential security issues with executables
        basename = Path(path).name.lower()

        # Block obviously dangerous executable names
        dangerous_names = [
            "cmd",
            "powershell",
            "bash",
            "sh",
            "rm",
            "del",
            "format",
            "fdisk",
            "shutdown",
            "reboot",
        ]

        name_without_ext = Path(basename).stem
        if name_without_ext in dangerous_names:
            self.add_error(
                f'Invalid {name}: "{path}". '
                f"Potentially dangerous executable name: {name_without_ext}",
            )
            return False

        return True

    def validate_required_file(self, path: str, name: str = "file") -> bool:
        """Validate a required file path (cannot be empty).

        Args:
            path: The file path to validate
            name: The input name for error messages

        Returns:
            True if valid, False otherwise
        """
        if not path or path.strip() == "":
            self.add_error(f"Required {name} path cannot be empty")
            return False

        # Validate the path itself
        return self.validate_file_path(path, name)
