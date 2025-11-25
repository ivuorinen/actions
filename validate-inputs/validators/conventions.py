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
            "mode": "mode_enum",
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

        # Convention-based validators
        if validator_type in [
            "php_extensions",
            "coverage_driver",
            "mode_enum",
            "binary_enum",
            "multi_value_enum",
            "report_format",
            "format_enum",
            "linter_list",
            "timeout_with_unit",
            "severity_enum",
            "scanner_list",
            "exit_code_list",
            "key_value_list",
            "path_list",
            "network_mode",
            "language_enum",
            "framework_mode",
            "json_format",
            "cache_config",
        ]:
            # Return self for validation methods implemented in this class
            return self, f"_validate_{validator_type}"

        # Package manager validators
        if validator_type in ["package_manager_enum"]:
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

    def _validate_comma_separated_list(
        self,
        value: str,
        input_name: str,
        item_pattern: str | None = None,
        valid_items: list | None = None,
        check_injection: bool = False,
        item_name: str = "item",
    ) -> bool:
        """Validate comma-separated list of items (generic validator).

        This is a generic validator that can be used for any comma-separated list
        with either pattern-based or enum-based validation.

        Args:
            value: The comma-separated list value
            input_name: The input name for error messages
            item_pattern: Regex pattern each item must match (default: alphanumeric+hyphens+underscores)
            valid_items: Optional list of valid items for enum-style validation
            check_injection: Whether to check for shell injection patterns
            item_name: Descriptive name for items in error messages (e.g., "linter", "extension")

        Returns:
            True if valid, False otherwise

        Examples:
            >>> # Pattern-based validation
            >>> validator._validate_comma_separated_list(
            ...     "gosec,govet", "enable-linters",
            ...     item_pattern=r'^[a-zA-Z0-9_-]+$',
            ...     item_name="linter"
            ... )
            True

            >>> # Enum-based validation
            >>> validator._validate_comma_separated_list(
            ...     "vuln,config", "scanners",
            ...     valid_items=["vuln", "config", "secret", "license"],
            ...     item_name="scanner"
            ... )
            True
        """
        import re

        if not value or value.strip() == "":
            return True  # Optional

        # Security check for injection patterns
        if check_injection and re.search(r"[;&|`$()]", value):
            self.add_error(
                f"Potential injection detected in {input_name}: {value}. "
                f"Avoid using shell metacharacters (;, &, |, `, $, parentheses)"
            )
            return False

        # Split by comma and validate each item
        items = [item.strip() for item in value.split(",")]

        for item in items:
            if not item:  # Empty after strip
                self.add_error(f"Invalid {input_name}: {value}. Contains empty {item_name}")
                return False

            # Enum-based validation (if valid_items provided)
            if valid_items is not None:
                if item not in valid_items:
                    self.add_error(
                        f"Invalid {item_name} '{item}' in {input_name}. "
                        f"Must be one of: {', '.join(valid_items)}"
                    )
                    return False

            # Pattern-based validation (if no valid_items and pattern provided)
            elif item_pattern is not None:
                if not re.match(item_pattern, item):
                    self.add_error(
                        f"Invalid {item_name} '{item}' in {input_name}. "
                        f"Must match pattern: alphanumeric with hyphens/underscores"
                    )
                    return False

            # Default pattern if neither valid_items nor item_pattern provided
            elif not re.match(r"^[a-zA-Z0-9_-]+$", item):
                self.add_error(
                    f"Invalid {item_name} '{item}' in {input_name}. "
                    f"Must be alphanumeric with hyphens/underscores"
                )
                return False

        return True

    def _validate_php_extensions(self, value: str, input_name: str) -> bool:
        """Validate PHP extensions format.

        Wrapper for comma-separated list validator with PHP extension-specific rules.
        Allows alphanumeric characters, underscores, and spaces.
        Checks for shell injection patterns.

        Args:
            value: The extensions value (comma-separated list)
            input_name: The input name for error messages

        Returns:
            True if valid, False otherwise
        """
        return self._validate_comma_separated_list(
            value,
            input_name,
            item_pattern=r"^[a-zA-Z0-9_\s]+$",
            check_injection=True,
            item_name="extension",
        )

    def _validate_binary_enum(
        self,
        value: str,
        input_name: str,
        valid_values: list | None = None,
        case_sensitive: bool = True,
    ) -> bool:
        """Validate binary enum (two-value choice) (generic validator).

        This is a generic validator for two-value enums (e.g., check/fix, enabled/disabled).

        Args:
            value: The enum value
            input_name: The input name for error messages
            valid_values: List of exactly 2 valid values (default: ["check", "fix"])
            case_sensitive: Whether validation is case-sensitive (default: True)

        Returns:
            True if valid, False otherwise

        Examples:
            >>> # Default check/fix mode
            >>> validator._validate_binary_enum("check", "mode")
            True

            >>> # Custom binary enum
            >>> validator._validate_binary_enum(
            ...     "enabled", "status",
            ...     valid_values=["enabled", "disabled"]
            ... )
            True
        """
        if valid_values is None:
            valid_values = ["check", "fix"]

        if len(valid_values) != 2:
            raise ValueError(
                f"Binary enum requires exactly 2 valid values, got {len(valid_values)}"
            )

        if not value or value.strip() == "":
            return True  # Optional

        # Case-insensitive comparison if needed
        if not case_sensitive:
            value_lower = value.lower()
            valid_values_lower = [v.lower() for v in valid_values]
            if value_lower not in valid_values_lower:
                self.add_error(
                    f"Invalid {input_name}: {value}. Must be one of: {', '.join(valid_values)}"
                )
                return False
        else:
            if value not in valid_values:
                self.add_error(
                    f"Invalid {input_name}: {value}. Must be one of: {', '.join(valid_values)}"
                )
                return False

        return True

    def _validate_format_enum(
        self,
        value: str,
        input_name: str,
        valid_formats: list | None = None,
        allow_custom: bool = False,
    ) -> bool:
        """Validate output format enum (generic validator).

        Generic validator for tool output formats (SARIF, JSON, XML, etc.).
        Supports common formats across linting/analysis tools.

        Args:
            value: The format value
            input_name: The input name for error messages
            valid_formats: List of valid formats (default: comprehensive list)
            allow_custom: Whether to allow formats not in the predefined list (default: False)

        Returns:
            True if valid, False otherwise

        Examples:
            >>> # Default comprehensive format list
            >>> validator._validate_format_enum("json", "format")
            True

            >>> # Tool-specific format list
            >>> validator._validate_format_enum(
            ...     "sarif", "output-format",
            ...     valid_formats=["json", "sarif", "text"]
            ... )
            True
        """
        if valid_formats is None:
            # Comprehensive list of common formats across all tools
            valid_formats = [
                "checkstyle",
                "colored-line-number",
                "compact",
                "github-actions",
                "html",
                "json",
                "junit",
                "junit-xml",
                "line-number",
                "sarif",
                "stylish",
                "tab",
                "teamcity",
                "xml",
            ]

        if not value or value.strip() == "":
            return True  # Optional

        # Check if format is valid
        if value not in valid_formats and not allow_custom:
            self.add_error(
                f"Invalid {input_name}: {value}. Must be one of: {', '.join(valid_formats)}"
            )
            return False

        return True

    def _validate_multi_value_enum(
        self,
        value: str,
        input_name: str,
        valid_values: list | None = None,
        case_sensitive: bool = True,
        min_values: int = 2,
        max_values: int = 10,
    ) -> bool:
        """Validate multi-value enum (2-10 value choice) (generic validator).

        Generic validator for enums with 2-10 predefined values.
        For exactly 2 values, use _validate_binary_enum instead.

        Args:
            value: The enum value
            input_name: The input name for error messages
            valid_values: List of valid values (2-10 items required)
            case_sensitive: Whether validation is case-sensitive (default: True)
            min_values: Minimum number of valid values (default: 2)
            max_values: Maximum number of valid values (default: 10)

        Returns:
            True if valid, False otherwise

        Examples:
            >>> # Framework selection (3 values)
            >>> validator._validate_multi_value_enum(
            ...     "laravel", "framework",
            ...     valid_values=["auto", "laravel", "generic"]
            ... )
            True

            >>> # Language selection (4 values)
            >>> validator._validate_multi_value_enum(
            ...     "python", "language",
            ...     valid_values=["php", "python", "go", "dotnet"]
            ... )
            True
        """
        if valid_values is None:
            raise ValueError("valid_values is required for multi_value_enum validator")

        # Validate valid_values count
        if len(valid_values) < min_values:
            raise ValueError(
                f"Multi-value enum requires at least {min_values} valid values, got {len(valid_values)}"
            )

        if len(valid_values) > max_values:
            raise ValueError(
                f"Multi-value enum supports at most {max_values} valid values, got {len(valid_values)}"
            )

        if not value or value.strip() == "":
            return True  # Optional

        # Case-insensitive comparison if needed
        if not case_sensitive:
            value_lower = value.lower()
            valid_values_lower = [v.lower() for v in valid_values]
            if value_lower not in valid_values_lower:
                self.add_error(
                    f"Invalid {input_name}: {value}. Must be one of: {', '.join(valid_values)}"
                )
                return False
        else:
            if value not in valid_values:
                self.add_error(
                    f"Invalid {input_name}: {value}. Must be one of: {', '.join(valid_values)}"
                )
                return False

        return True

    def _validate_coverage_driver(self, value: str, input_name: str) -> bool:
        """Validate coverage driver enum.

        Wrapper for multi_value_enum validator with PHP coverage driver options.

        Args:
            value: The coverage driver value
            input_name: The input name for error messages

        Returns:
            True if valid, False otherwise

        Examples:
            Valid: "xdebug", "pcov", "xdebug3", "none", ""
            Invalid: "xdebug2", "XDEBUG", "coverage"
        """
        return self._validate_multi_value_enum(
            value,
            input_name,
            valid_values=["none", "xdebug", "pcov", "xdebug3"],
            case_sensitive=True,
        )

    def _validate_mode_enum(self, value: str, input_name: str) -> bool:
        """Validate mode enum for linting actions.

        Wrapper for binary_enum validator with check/fix modes.

        Args:
            value: The mode value
            input_name: The input name for error messages

        Returns:
            True if valid, False otherwise

        Examples:
            Valid: "check", "fix", ""
            Invalid: "invalid", "CHECK", "Fix"
        """
        return self._validate_binary_enum(
            value,
            input_name,
            valid_values=["check", "fix"],
            case_sensitive=True,
        )

    def _validate_report_format(self, value: str, input_name: str) -> bool:
        """Validate report format for linting/analysis actions.

        Wrapper for format_enum validator with comprehensive format list.
        Supports multiple report formats used across different tools.

        Args:
            value: The report format value
            input_name: The input name for error messages

        Returns:
            True if valid, False otherwise

        Examples:
            Valid: "json", "sarif", "checkstyle", "github-actions", ""
            Invalid: "invalid", "txt", "pdf"
        """
        return self._validate_format_enum(value, input_name)

    def _validate_linter_list(self, value: str, input_name: str) -> bool:
        """Validate comma-separated list of linter names.

        Wrapper for comma-separated list validator with linter-specific rules.
        Allows alphanumeric characters, hyphens, and underscores.

        Args:
            value: The linter list value
            input_name: The input name for error messages

        Returns:
            True if valid, False otherwise

        Examples:
            Valid: "gosec,govet,staticcheck", "errcheck"
            Invalid: "gosec,,govet", "invalid linter", "linter@123"
        """
        return self._validate_comma_separated_list(
            value,
            input_name,
            item_pattern=r"^[a-zA-Z0-9_-]+$",
            item_name="linter",
        )

    def _validate_timeout_with_unit(self, value: str, input_name: str) -> bool:
        """Validate timeout duration with unit (Go duration format).

        Args:
            value: The timeout value
            input_name: The input name for error messages

        Returns:
            True if valid, False otherwise
        """
        import re

        if not value or value.strip() == "":
            return True  # Optional

        # Go duration format: number + unit (ns, us/µs, ms, s, m, h)
        pattern = r"^[0-9]+(ns|us|µs|ms|s|m|h)$"

        if not re.match(pattern, value):
            self.add_error(
                f"Invalid {input_name}: {value}. Expected format: number with unit "
                "(e.g., 5m, 30s, 1h, 500ms)"
            )
            return False

        return True

    def _validate_severity_enum(self, value: str, input_name: str) -> bool:
        """Validate severity levels enum (generalized).

        Generic validator for security tool severity levels.
        Supports common severity formats used by various security tools.

        Default levels: UNKNOWN, LOW, MEDIUM, HIGH, CRITICAL (Trivy/CVSSv3 style)
        Case-sensitive by default.

        Args:
            value: The severity value (comma-separated for multiple levels)
            input_name: The input name for error messages

        Returns:
            True if valid, False otherwise
        """
        if not value or value.strip() == "":
            return True  # Optional

        # Standard severity levels (Trivy/CVSSv3/OWASP compatible)
        # Can be extended for specific tools by creating tool-specific validators
        valid_severities = ["UNKNOWN", "LOW", "MEDIUM", "HIGH", "CRITICAL"]

        # Split by comma and validate each severity
        severities = [s.strip() for s in value.split(",")]

        for severity in severities:
            if not severity:  # Empty after strip
                self.add_error(f"Invalid {input_name}: {value}. Contains empty severity level")
                return False

            # Case-sensitive validation
            if severity not in valid_severities:
                self.add_error(
                    f"Invalid {input_name}: {value}. Severity '{severity}' is not valid. "
                    f"Must be one of: {', '.join(valid_severities)}"
                )
                return False

        return True

    def _validate_scanner_list(self, value: str, input_name: str) -> bool:
        """Validate comma-separated list of scanner types (for Trivy).

        Wrapper for comma-separated list validator with Trivy scanner enum validation.
        Supports: vuln, config, secret, license

        Args:
            value: The scanner list value (comma-separated)
            input_name: The input name for error messages

        Returns:
            True if valid, False otherwise

        Examples:
            Valid: "vuln,config,secret", "vuln", "config,license"
            Invalid: "invalid", "vuln,invalid,config", "vuln,,config"
        """
        return self._validate_comma_separated_list(
            value,
            input_name,
            valid_items=["vuln", "config", "secret", "license"],
            item_name="scanner",
        )

    def _validate_exit_code_list(self, value: str, input_name: str) -> bool:
        """Validate comma-separated list of exit codes.

        Validates Unix/Linux exit codes (0-255) in comma-separated format.
        Used for retry logic, success codes, and error handling.

        Args:
            value: The exit code list value (comma-separated integers)
            input_name: The input name for error messages

        Returns:
            True if valid, False otherwise

        Examples:
            Valid: "0", "0,1,2", "5,10,15", "0,130", ""
            Invalid: "256", "0,256", "-1", "0,abc", "0,,1"
        """
        import re

        if not value or value.strip() == "":
            return True  # Optional

        # Split by comma and validate each exit code
        codes = [code.strip() for code in value.split(",")]

        for code in codes:
            if not code:  # Empty after strip
                self.add_error(f"Invalid {input_name}: {value}. Contains empty exit code")
                return False

            # Check if code is numeric
            if not re.match(r"^[0-9]+$", code):
                self.add_error(
                    f"Invalid exit code '{code}' in {input_name}. "
                    f"Exit codes must be integers (0-255)"
                )
                return False

            # Validate range (0-255 for Unix/Linux exit codes)
            code_int = int(code)
            if code_int < 0 or code_int > 255:
                self.add_error(
                    f"Invalid exit code '{code}' in {input_name}. Exit codes must be in range 0-255"
                )
                return False

        return True

    def _validate_key_value_list(
        self,
        value: str,
        input_name: str,
        key_pattern: str | None = None,
        check_injection: bool = True,
    ) -> bool:
        """Validate comma-separated list of key-value pairs (generic validator).

        Validates KEY=VALUE,KEY2=VALUE2 format commonly used for Docker build-args,
        environment variables, and other configuration parameters.

        Args:
            value: The key-value list value (comma-separated KEY=VALUE pairs)
            input_name: The input name for error messages
            key_pattern: Regex pattern for key validation (default: alphanumeric+underscores+hyphens)
            check_injection: Whether to check for shell injection patterns in values (default: True)

        Returns:
            True if valid, False otherwise

        Examples:
            Valid: "KEY=value", "KEY1=value1,KEY2=value2", "BUILD_ARG=hello", ""
            Invalid: "KEY", "=value", "KEY=", "KEY=value,", "KEY=val;whoami"
        """
        import re

        if not value or value.strip() == "":
            return True  # Optional

        if key_pattern is None:
            # Default: alphanumeric, underscores, hyphens (common for env vars and build args)
            key_pattern = r"^[a-zA-Z0-9_-]+$"

        # Security check for injection patterns in the entire value
        if check_injection and re.search(r"[;&|`$()]", value):
            self.add_error(
                f"Potential injection detected in {input_name}: {value}. "
                f"Avoid using shell metacharacters (;, &, |, `, $, parentheses)"
            )
            return False

        # Split by comma and validate each key-value pair
        pairs = [pair.strip() for pair in value.split(",")]

        for pair in pairs:
            if not pair:  # Empty after strip
                self.add_error(f"Invalid {input_name}: {value}. Contains empty key-value pair")
                return False

            # Check for KEY=VALUE format
            if "=" not in pair:
                self.add_error(
                    f"Invalid key-value pair '{pair}' in {input_name}. Expected format: KEY=VALUE"
                )
                return False

            # Split by first = only (value may contain =)
            parts = pair.split("=", 1)
            key = parts[0].strip()

            # Validate key is not empty
            if not key:
                self.add_error(
                    f"Invalid key-value pair '{pair}' in {input_name}. Key cannot be empty"
                )
                return False

            # Validate key pattern
            if not re.match(key_pattern, key):
                self.add_error(
                    f"Invalid key '{key}' in {input_name}. "
                    f"Keys must be alphanumeric with underscores/hyphens"
                )
                return False

            # Note: Value can be empty (KEY=) - this is valid for some use cases
            # Value validation is optional and handled by the check_injection flag above

        return True

    def _validate_path_list(
        self,
        value: str,
        input_name: str,
        allow_glob: bool = True,
        check_injection: bool = True,
    ) -> bool:
        """Validate comma-separated list of file paths or glob patterns (generic validator).

        Validates file paths and glob patterns commonly used for ignore-paths,
        restore-keys, file-pattern, and other path-based inputs.

        Args:
            value: The path list to validate
            input_name: Name of the input being validated
            allow_glob: Whether to allow glob patterns (*, **, ?, [])
            check_injection: Whether to check for shell injection patterns

        Examples:
            Valid: "*.js", "src/**/*.ts", "dist/,build/", ".github/workflows/*", ""
            Invalid: "../etc/passwd", "file;rm -rf /", "path|whoami"

        Returns:
            bool: True if valid, False otherwise
        """
        import re

        if not value or value.strip() == "":
            return True  # Optional

        # Security check for injection patterns
        if check_injection and re.search(r"[;&|`$()]", value):
            self.add_error(
                f"Potential injection detected in {input_name}: {value}. "
                f"Avoid using shell metacharacters (;, &, |, `, $, parentheses)"
            )
            return False

        # Split by comma and validate each path
        paths = [path.strip() for path in value.split(",")]

        for path in paths:
            if not path:  # Empty after strip
                self.add_error(f"Invalid {input_name}: {value}. Contains empty path")
                return False

            # Check for path traversal attempts
            if "../" in path or "/.." in path or path.startswith(".."):
                self.add_error(
                    f"Path traversal detected in {input_name}: {path}. Avoid using '..' in paths"
                )
                return False

            # Validate glob patterns if allowed
            if allow_glob:
                # Glob patterns are valid: *, **, ?, [], {}
                # Check for valid glob characters
                glob_pattern = r"^[a-zA-Z0-9_\-./\*\?\[\]\{\},@~+]+$"
                if not re.match(glob_pattern, path):
                    self.add_error(
                        f"Invalid path '{path}' in {input_name}. "
                        f"Paths may contain alphanumeric characters, hyphens, underscores, "
                        f"slashes, and glob patterns (*, **, ?, [], {{}})"
                    )
                    return False
            else:
                # No glob patterns allowed - only alphanumeric, hyphens, underscores, slashes
                path_pattern = r"^[a-zA-Z0-9_\-./,@~+]+$"
                if not re.match(path_pattern, path):
                    self.add_error(
                        f"Invalid path '{path}' in {input_name}. "
                        f"Paths may only contain alphanumeric characters, hyphens, "
                        f"underscores, and slashes"
                    )
                    return False

        return True

    def _validate_network_mode(self, value: str, input_name: str) -> bool:
        """Validate Docker network mode enum.

        Wrapper for multi_value_enum validator with Docker network mode options.

        Examples:
            Valid: "host", "none", "default", ""
            Invalid: "bridge", "NONE", "custom"

        Returns:
            bool: True if valid, False otherwise
        """
        return self._validate_multi_value_enum(
            value,
            input_name,
            valid_values=["host", "none", "default"],
            case_sensitive=True,
        )

    def _validate_language_enum(self, value: str, input_name: str) -> bool:
        """Validate language enum for version detection.

        Wrapper for multi_value_enum validator with supported language options.

        Examples:
            Valid: "php", "python", "go", "dotnet", ""
            Invalid: "node", "ruby", "PHP"

        Returns:
            bool: True if valid, False otherwise
        """
        return self._validate_multi_value_enum(
            value,
            input_name,
            valid_values=["php", "python", "go", "dotnet"],
            case_sensitive=True,
        )

    def _validate_framework_mode(self, value: str, input_name: str) -> bool:
        """Validate PHP framework detection mode.

        Wrapper for multi_value_enum validator with framework mode options.

        Examples:
            Valid: "auto", "laravel", "generic", ""
            Invalid: "symfony", "Auto", "LARAVEL"

        Returns:
            bool: True if valid, False otherwise
        """
        return self._validate_multi_value_enum(
            value,
            input_name,
            valid_values=["auto", "laravel", "generic"],
            case_sensitive=True,
        )

    def _validate_json_format(self, value: str, input_name: str) -> bool:
        """Validate JSON format string.

        Validates that input is valid JSON. Used for structured configuration
        data like platform-specific build arguments.

        Examples:
            Valid: '{"key":"value"}', '[]', '{"platforms":["linux/amd64"]}', ""
            Invalid: '{invalid}', 'not json', '{key:value}'

        Returns:
            bool: True if valid, False otherwise
        """
        import json

        if not value or value.strip() == "":
            return True  # Optional

        try:
            json.loads(value)
            return True
        except json.JSONDecodeError as e:
            self.add_error(f"Invalid JSON format in {input_name}: {value}. Error: {str(e)}")
            return False
        except Exception as e:
            self.add_error(f"Failed to validate JSON in {input_name}: {str(e)}")
            return False

    def _validate_cache_config(self, value: str, input_name: str) -> bool:
        """Validate Docker BuildKit cache configuration.

        Validates Docker cache export/import configuration format.
        Common formats: type=registry,ref=..., type=local,dest=..., type=gha

        Examples:
            Valid: "type=registry,ref=user/repo:cache", "type=local,dest=/tmp/cache",
                   "type=gha", "type=inline", ""
            Invalid: "invalid", "type=", "registry", "type=unknown"

        Returns:
            bool: True if valid, False otherwise
        """
        import re

        if not value or value.strip() == "":
            return True  # Optional

        # Check basic format: type=value[,key=value,...]
        if not re.match(r"^type=[a-z0-9-]+", value):
            self.add_error(
                f"Invalid cache config in {input_name}: {value}. "
                f"Must start with 'type=<cache-type>'"
            )
            return False

        # Valid cache types
        valid_types = ["registry", "local", "gha", "inline", "s3", "azblob", "oci"]

        # Extract type
        type_match = re.match(r"^type=([a-z0-9-]+)", value)
        if type_match:
            cache_type = type_match.group(1)
            if cache_type not in valid_types:
                self.add_error(
                    f"Invalid cache type '{cache_type}' in {input_name}. "
                    f"Valid types: {', '.join(valid_types)}"
                )
                return False

        # Validate key=value pairs format
        parts = value.split(",")
        for part in parts:
            if "=" not in part:
                self.add_error(
                    f"Invalid cache config format in {input_name}: {value}. "
                    f"Each part must be in 'key=value' format"
                )
                return False

        return True
