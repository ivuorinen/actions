"""Convention-based validator that uses naming patterns to determine validation rules.

This validator automatically applies validation based on input naming conventions.
"""

from __future__ import annotations

from pathlib import Path
from typing import Any

import yaml  # pylint: disable=import-error

from .base import BaseValidator
from .convention_mapper import ConventionMapper

TOKEN_TYPES = {
    "github": "github_token",
    "npm": "npm_token",
    "docker": "docker_token",
}

VERSION_MAPPINGS = {
    "python": "python_version",
    "node": "node_version",
    "go": "go_version",
    "php": "php_version",
    "terraform": "terraform_version",
    "dotnet": "dotnet_version",
    "net": "dotnet_version",
}

FILE_TYPES = {
    "yaml": "yaml_file",
    "yml": "yaml_file",
    "json": "json_file",
}


class ConventionBasedValidator(BaseValidator):
    """Validator that applies validation based on naming conventions.

    Automatically detects validation requirements based on input names
    and applies appropriate validators.
    """

    def __init__(self, action_type: str) -> None:
        """Initialize the convention-based validator.

        Args:
            action_type: The type of GitHub Action being validated
        """
        super().__init__(action_type)
        self._rules = self.load_rules()
        self._validator_modules: dict[str, Any] = {}
        self._convention_mapper = ConventionMapper()  # Use the ConventionMapper
        self._load_validator_modules()

    def _load_validator_modules(self) -> None:
        """Lazy-load validator modules as needed."""
        # These will be imported as needed to avoid circular imports

    def load_rules(self, rules_path: Path | None = None) -> dict[str, Any]:
        """Load validation rules from YAML file.

        Args:
            rules_path: Optional path to the rules YAML file

        Returns:
            Dictionary of validation rules
        """
        if rules_path and rules_path.exists():
            rules_file = rules_path
        else:
            # Find the rules file for this action in the action folder
            # Convert underscores back to dashes for the folder name
            action_name = self.action_type.replace("_", "-")
            project_root = Path(__file__).parent.parent.parent
            rules_file = project_root / action_name / "rules.yml"

        if not rules_file.exists():
            # Return default empty rules if no rules file exists
            return {
                "action_type": self.action_type,
                "required_inputs": [],
                "optional_inputs": [],
                "conventions": {},
                "overrides": {},
            }

        try:
            with Path(rules_file).open() as f:
                rules = yaml.safe_load(f) or {}

            # Ensure all expected keys exist
            rules.setdefault("required_inputs", [])
            rules.setdefault("optional_inputs", [])
            rules.setdefault("conventions", {})
            rules.setdefault("overrides", {})

            # Build conventions from optional_inputs if not explicitly set
            if not rules["conventions"] and rules["optional_inputs"]:
                conventions = {}
                optional_inputs = rules["optional_inputs"]

                # Handle both list and dict formats for optional_inputs
                if isinstance(optional_inputs, list):
                    # List format: just input names
                    for input_name in optional_inputs:
                        conventions[input_name] = self._infer_validator_type(input_name, {})
                elif isinstance(optional_inputs, dict):
                    # Dict format: input names with config
                    for input_name, input_config in optional_inputs.items():
                        conventions[input_name] = self._infer_validator_type(
                            input_name, input_config
                        )

                rules["conventions"] = conventions

            return rules
        except Exception:
            return {
                "action_type": self.action_type,
                "required_inputs": [],
                "optional_inputs": [],
                "conventions": {},
                "overrides": {},
            }

    def _infer_validator_type(self, input_name: str, input_config: dict[str, Any]) -> str | None:
        """Infer the validator type from input name and configuration.

        Args:
            input_name: The name of the input
            input_config: The input configuration from rules

        Returns:
            The inferred validator type or None
        """
        # Check for explicit validator type in config
        if isinstance(input_config, dict) and "validator" in input_config:
            return input_config["validator"]

        # Infer based on name patterns
        name_lower = input_name.lower().replace("-", "_")

        # Try to determine validator type
        validator_type = self._check_exact_matches(name_lower)

        if validator_type is None:
            validator_type = self._check_pattern_based_matches(name_lower)

        return validator_type

    def _check_exact_matches(self, name_lower: str) -> str | None:
        """Check for exact pattern matches."""
        exact_matches = {
            # Docker patterns
            "platforms": "docker_architectures",
            "architectures": "docker_architectures",
            "cache_from": "cache_mode",
            "cache_to": "cache_mode",
            "sbom": "sbom_format",
            "registry": "registry_url",
            "registry_url": "registry_url",
            "tags": "docker_tags",
            # File patterns
            "file": "file_path",
            "path": "file_path",
            "file_path": "file_path",
            "config_file": "file_path",
            "dockerfile": "file_path",
            "branch": "branch_name",
            "branch_name": "branch_name",
            "ref": "branch_name",
            # Network patterns
            "email": "email",
            "url": "url",
            "endpoint": "url",
            "webhook": "url",
            "repository_url": "repository_url",
            "repo_url": "repository_url",
            "scope": "scope",
            "username": "username",
            "user": "username",
            # Boolean patterns
            "dry_run": "boolean",
            "draft": "boolean",
            "prerelease": "boolean",
            "push": "boolean",
            "delete": "boolean",
            "all_files": "boolean",
            "force": "boolean",
            "skip": "boolean",
            "enabled": "boolean",
            "disabled": "boolean",
            "verbose": "boolean",
            "debug": "boolean",
            # Numeric patterns
            "retries": "retries",
            "retry": "retries",
            "attempts": "retries",
            "timeout": "timeout",
            "timeout_ms": "timeout",
            "timeout_seconds": "timeout",
            "threads": "threads",
            "workers": "threads",
            "concurrency": "threads",
            # Other patterns
            "category": "category_format",
            "cache": "package_manager_enum",
            "package_manager": "package_manager_enum",
            "format": "report_format",
            "output_format": "report_format",
            "report_format": "report_format",
            "mode": "string",
        }
        return exact_matches.get(name_lower)

    def _check_pattern_based_matches(self, name_lower: str) -> str | None:  # noqa: PLR0912
        """Check for pattern-based matches."""
        result = None

        # Token patterns
        if "token" in name_lower:
            token_types = TOKEN_TYPES
            for key, value in token_types.items():
                if key in name_lower:
                    result = value
                    break
            if result is None:
                result = "github_token"  # Default token type

        # Docker patterns
        elif name_lower.startswith("docker_"):
            result = f"docker_{name_lower[7:]}"

        # Version patterns
        elif "version" in name_lower:
            version_mappings = VERSION_MAPPINGS
            for key, value in version_mappings.items():
                if key in name_lower:
                    result = value
                    break
            if result is None:
                result = "flexible_version"  # Default to flexible version

        # File suffix patterns
        elif name_lower.endswith("_file") and name_lower != "config_file":
            file_types = FILE_TYPES
            for key, value in file_types.items():
                if key in name_lower:
                    result = value
                    break
            if result is None:
                result = "file_path"

        # CodeQL patterns
        elif name_lower.startswith("codeql_"):
            result = name_lower

        # Cache-related check (special case for returning None)
        elif "cache" in name_lower and name_lower != "cache":
            result = None  # cache-related but not numeric

        return result

    def get_required_inputs(self) -> list[str]:
        """Get the list of required input names from rules.

        Returns:
            List of required input names
        """
        return self._rules.get("required_inputs", [])

    def get_validation_rules(self) -> dict[str, Any]:
        """Get the validation rules.

        Returns:
            Dictionary of validation rules
        """
        return self._rules

    def validate_inputs(self, inputs: dict[str, str]) -> bool:
        """Validate inputs based on conventions and rules.

        Args:
            inputs: Dictionary of input names to values

        Returns:
            True if all inputs are valid, False otherwise
        """
        valid = True

        # First validate required inputs
        valid &= self.validate_required_inputs(inputs)

        # Get conventions and overrides from rules
        conventions = self._rules.get("conventions", {})
        overrides = self._rules.get("overrides", {})
        optional_inputs = self._rules.get("optional_inputs", [])
        required_inputs = self.get_required_inputs()

        # Validate each input
        for input_name, value in inputs.items():
            # Skip if explicitly overridden to null
            if input_name in overrides and overrides[input_name] is None:
                continue

            # Check if input is defined in the action's rules
            is_defined_input = (
                input_name in required_inputs
                or input_name in optional_inputs
                or input_name in conventions
                or input_name in overrides
            )

            # Skip validation for undefined inputs with empty values
            # This prevents auto-validation of irrelevant inputs from the
            # validate-inputs action's own input list
            if not is_defined_input and (
                not value or (isinstance(value, str) and not value.strip())
            ):
                continue

            # Get validator type from overrides or conventions
            validator_type = self._get_validator_type(input_name, conventions, overrides)

            if validator_type:
                # Check if this is a required input
                is_required = input_name in required_inputs
                valid &= self._apply_validator(
                    input_name, value, validator_type, is_required=is_required
                )

        return valid

    def _get_validator_type(
        self,
        input_name: str,
        conventions: dict[str, str],
        overrides: dict[str, str],
    ) -> str | None:
        """Determine the validator type for an input.

        Args:
            input_name: The name of the input
            conventions: Convention mappings
            overrides: Override mappings

        Returns:
            The validator type or None if no validator found
        """
        # Check overrides first
        if input_name in overrides:
            return overrides[input_name]

        # Check exact convention match
        if input_name in conventions:
            return conventions[input_name]

        # Check with dash/underscore conversion
        if "_" in input_name:
            dash_version = input_name.replace("_", "-")
            if dash_version in overrides:
                return overrides[dash_version]
            if dash_version in conventions:
                return conventions[dash_version]
        elif "-" in input_name:
            underscore_version = input_name.replace("-", "_")
            if underscore_version in overrides:
                return overrides[underscore_version]
            if underscore_version in conventions:
                return conventions[underscore_version]

        # Fall back to convention mapper for pattern-based detection
        return self._convention_mapper.get_validator_type(input_name)

    def _apply_validator(
        self,
        input_name: str,
        value: str,
        validator_type: str,
        *,
        is_required: bool,
    ) -> bool:
        """Apply the appropriate validator to an input value.

        Args:
            input_name: The name of the input
            value: The value to validate
            validator_type: The type of validator to apply
            is_required: Whether the input is required

        Returns:
            True if valid, False otherwise
        """
        # Get the validator module and method
        validator_module, method_name = self._get_validator_method(validator_type)

        if not validator_module:
            # Unknown validator type, skip validation
            return True

        try:
            # Call the validation method
            if hasattr(validator_module, method_name):
                method = getattr(validator_module, method_name)

                # Some validators need additional parameters
                if validator_type == "github_token" and method_name == "validate_github_token":
                    result = method(value, required=is_required)
                elif "numeric_range" in validator_type:
                    # Parse range from validator type
                    min_val, max_val = self._parse_numeric_range(validator_type)
                    result = method(value, min_val, max_val, input_name)
                else:
                    # Standard validation call
                    result = method(value, input_name)

                # Copy errors from the validator module to this validator
                # Skip if validator_module is self (for internal validators)
                if validator_module is not self and hasattr(validator_module, "errors"):
                    for error in validator_module.errors:
                        if error not in self.errors:
                            self.add_error(error)
                    # Clear the module's errors after copying
                    validator_module.errors = []

                return result
            # Method not found, skip validation
            return True

        except Exception as e:
            self.add_error(f"Validation error for {input_name}: {e}")
            return False

    def _get_validator_method(self, validator_type: str) -> tuple[Any, str]:  # noqa: C901, PLR0912
        """Get the validator module and method name for a validator type.

        Args:
            validator_type: The validator type string

        Returns:
            Tuple of (validator_module, method_name)
        """
        # Lazy import validators to avoid circular dependencies

        # Token validators
        if validator_type in [
            "github_token",
            "npm_token",
            "docker_token",
            "namespace_with_lookahead",
        ]:
            if "token" not in self._validator_modules:
                from . import token

                self._validator_modules["token"] = token.TokenValidator()
            return self._validator_modules["token"], f"validate_{validator_type}"

        # Docker validators
        if validator_type.startswith("docker_") or validator_type in [
            "cache_mode",
            "sbom_format",
            "registry_enum",
        ]:
            if "docker" not in self._validator_modules:
                from . import docker

                self._validator_modules["docker"] = docker.DockerValidator()
            if validator_type.startswith("docker_"):
                method = f"validate_{validator_type[7:]}"  # Remove "docker_" prefix
            elif validator_type == "registry_enum":
                method = "validate_registry"
            else:
                method = f"validate_{validator_type}"
            return self._validator_modules["docker"], method

        # Version validators
        if "version" in validator_type or validator_type in ["calver", "semantic", "flexible"]:
            if "version" not in self._validator_modules:
                from . import version

                self._validator_modules["version"] = version.VersionValidator()
            return self._validator_modules["version"], f"validate_{validator_type}"

        # File validators
        if validator_type in [
            "file_path",
            "branch_name",
            "file_extensions",
            "yaml_file",
            "json_file",
            "config_file",
        ]:
            if "file" not in self._validator_modules:
                from . import file

                self._validator_modules["file"] = file.FileValidator()
            return self._validator_modules["file"], f"validate_{validator_type}"

        # Network validators
        if validator_type in [
            "email",
            "url",
            "scope",
            "username",
            "registry_url",
            "repository_url",
        ]:
            if "network" not in self._validator_modules:
                from . import network

                self._validator_modules["network"] = network.NetworkValidator()
            return self._validator_modules["network"], f"validate_{validator_type}"

        # Boolean validator
        if validator_type == "boolean":
            if "boolean" not in self._validator_modules:
                from . import boolean

                self._validator_modules["boolean"] = boolean.BooleanValidator()
            return self._validator_modules["boolean"], "validate_boolean"

        # Numeric validators
        if validator_type.startswith("numeric_range") or validator_type in [
            "retries",
            "timeout",
            "threads",
        ]:
            if "numeric" not in self._validator_modules:
                from . import numeric

                self._validator_modules["numeric"] = numeric.NumericValidator()
            if validator_type.startswith("numeric_range"):
                return self._validator_modules["numeric"], "validate_range"
            return self._validator_modules["numeric"], f"validate_{validator_type}"

        # Security validators
        if validator_type in ["security_patterns", "injection_patterns", "prefix", "regex_pattern"]:
            if "security" not in self._validator_modules:
                from . import security

                self._validator_modules["security"] = security.SecurityValidator()
            if validator_type == "prefix":
                # Use no_injection for prefix - checks for injection patterns
                # without character restrictions
                return self._validator_modules["security"], "validate_no_injection"
            return self._validator_modules["security"], f"validate_{validator_type}"

        # CodeQL validators
        if validator_type.startswith("codeql_") or validator_type in ["category_format"]:
            if "codeql" not in self._validator_modules:
                from . import codeql

                self._validator_modules["codeql"] = codeql.CodeQLValidator()
            return self._validator_modules["codeql"], f"validate_{validator_type}"

        # PHP-specific validators
        if validator_type in ["php_extensions", "coverage_driver"]:
            # Return self for PHP-specific validation methods
            return self, f"_validate_{validator_type}"

        # Package manager and report format validators
        if validator_type in ["package_manager_enum", "report_format"]:
            # These could be in a separate module, but for now we'll put them in file validator
            if "file" not in self._validator_modules:
                from . import file

                self._validator_modules["file"] = file.FileValidator()
            # These methods need to be added to file validator or a new module
            return None, ""

        # Default: no validator
        return None, ""

    def _parse_numeric_range(self, validator_type: str) -> tuple[int, int]:
        """Parse min and max values from a numeric_range validator type.

        Args:
            validator_type: String like "numeric_range_1_100"

        Returns:
            Tuple of (min_value, max_value)
        """
        parts = validator_type.split("_")
        if len(parts) >= 4:
            try:
                return int(parts[2]), int(parts[3])
            except ValueError:
                pass
        # Default range
        return 0, 100

    def _validate_php_extensions(self, value: str, input_name: str) -> bool:
        """Validate PHP extensions format.

        Args:
            value: The extensions value (comma-separated list)
            input_name: The input name for error messages

        Returns:
            True if valid, False otherwise
        """
        import re

        if not value:
            return True

        # Check for injection patterns
        if re.search(r"[;&|`$()@#]", value):
            self.add_error(f"Potential injection detected in {input_name}: {value}")
            return False

        # Check format - should be alphanumeric, underscores, commas, spaces only
        if not re.match(r"^[a-zA-Z0-9_,\s]+$", value):
            self.add_error(f"Invalid format for {input_name}: {value}")
            return False

        return True

    def _validate_coverage_driver(self, value: str, input_name: str) -> bool:
        """Validate coverage driver enum.

        Args:
            value: The coverage driver value
            input_name: The input name for error messages

        Returns:
            True if valid, False otherwise
        """
        valid_drivers = ["none", "xdebug", "pcov", "xdebug3"]

        if value and value not in valid_drivers:
            self.add_error(
                f"Invalid {input_name}: {value}. Must be one of: {', '.join(valid_drivers)}"
            )
            return False

        return True
