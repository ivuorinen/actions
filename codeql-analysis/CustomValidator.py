#!/usr/bin/env python3
"""Custom validator for codeql-analysis action.

This validator handles CodeQL-specific validation including:
- Query validation (built-in and custom queries)
- Category validation (security, quality, etc.)
- Resource limits (threads, RAM)
- Language detection and validation
- Database and configuration validation
"""

from __future__ import annotations

from pathlib import Path
import sys

# Add validate-inputs directory to path to import validators
validate_inputs_path = Path(__file__).parent.parent / "validate-inputs"
sys.path.insert(0, str(validate_inputs_path))

from validators.base import BaseValidator
from validators.boolean import BooleanValidator
from validators.codeql import CodeQLValidator
from validators.file import FileValidator
from validators.numeric import NumericValidator
from validators.token import TokenValidator


class CustomValidator(BaseValidator):
    """Custom validator for codeql-analysis action.

    Provides comprehensive validation for CodeQL analysis configuration.
    """

    def __init__(self, action_type: str = "codeql-analysis") -> None:
        """Initialize the codeql-analysis validator."""
        super().__init__(action_type)
        self.codeql_validator = CodeQLValidator(action_type)
        self.file_validator = FileValidator(action_type)
        self.numeric_validator = NumericValidator(action_type)
        self.token_validator = TokenValidator(action_type)
        self.boolean_validator = BooleanValidator(action_type)

    def validate_inputs(self, inputs: dict[str, str]) -> bool:
        """Validate codeql-analysis specific inputs.

        Args:
            inputs: Dictionary of input names to values

        Returns:
            True if all validations pass, False otherwise
        """
        valid = True

        # Validate language (required, but we handle empty check in validate_language)
        if "language" in inputs:
            valid &= self.validate_language(inputs["language"])
        else:
            # Language is required but missing entirely
            self.add_error("Required input 'language' is missing")
            valid = False

        # Validate queries
        if "queries" in inputs:
            valid &= self.validate_queries(inputs["queries"])

        # Validate categories
        if "categories" in inputs:
            valid &= self.validate_categories(inputs["categories"])
        elif "category" in inputs:
            # Support both 'category' and 'categories'
            valid &= self.validate_category(inputs["category"])

        # Validate config file
        if inputs.get("config-file"):
            valid &= self.validate_config_file(inputs["config-file"])

        # Validate database path
        if inputs.get("database"):
            valid &= self.validate_database(inputs["database"])

        # Validate threads
        if inputs.get("threads"):
            result = self.codeql_validator.validate_threads(inputs["threads"])
            for error in self.codeql_validator.errors:
                if error not in self.errors:
                    self.add_error(error)
            self.codeql_validator.clear_errors()
            valid &= result

        # Validate RAM
        if inputs.get("ram"):
            result = self.codeql_validator.validate_ram(inputs["ram"])
            for error in self.codeql_validator.errors:
                if error not in self.errors:
                    self.add_error(error)
            self.codeql_validator.clear_errors()
            valid &= result

        # Validate debug mode
        if inputs.get("debug"):
            valid &= self.validate_debug(inputs["debug"])

        # Validate upload options
        if inputs.get("upload-database"):
            valid &= self.validate_upload_database(inputs["upload-database"])

        if inputs.get("upload-sarif"):
            valid &= self.validate_upload_sarif(inputs["upload-sarif"])

        # Validate custom options
        if inputs.get("packs"):
            valid &= self.validate_packs(inputs["packs"])

        if inputs.get("external-repository-token"):
            valid &= self.validate_external_token(inputs["external-repository-token"])

        # Validate token
        if "token" in inputs:
            valid &= self.validate_token(inputs["token"])

        # Validate working-directory
        if inputs.get("working-directory"):
            valid &= self.validate_working_directory(inputs["working-directory"])

        # Validate upload-results
        if "upload-results" in inputs:
            valid &= self.validate_upload_results(inputs["upload-results"])

        return valid

    def get_required_inputs(self) -> list[str]:
        """Get list of required inputs for codeql-analysis.

        Returns:
            List of required input names
        """
        # Language is typically required for CodeQL
        return ["language"]

    def get_validation_rules(self) -> dict:
        """Get validation rules for codeql-analysis.

        Returns:
            Dictionary of validation rules
        """
        return {
            "language": "Programming language(s) to analyze (required)",
            "queries": "CodeQL query suites to run",
            "categories": "Categories to include (security, quality, etc.)",
            "config-file": "Path to CodeQL configuration file",
            "database": "Path to CodeQL database",
            "threads": "Number of threads (1-128)",
            "ram": "RAM limit in MB (256-32768)",
            "debug": "Enable debug mode (true/false)",
            "upload-database": "Upload database to GitHub (true/false)",
            "upload-sarif": "Upload SARIF results (true/false)",
            "packs": "CodeQL packs to use",
            "external-repository-token": "Token for external repositories",
        }

    def validate_language(self, language: str) -> bool:
        """Validate programming language specification.

        Args:
            language: Language(s) to analyze

        Returns:
            True if valid, False otherwise
        """
        # Check for empty language first
        if not language or not language.strip():
            self.add_error("CodeQL language cannot be empty")
            return False

        # Allow GitHub Actions expressions
        if self.is_github_expression(language):
            return True

        # CodeQL supported languages
        supported_languages = [
            "cpp",
            "c",
            "c++",
            "csharp",
            "c#",
            "go",
            "java",
            "kotlin",
            "javascript",
            "js",
            "typescript",
            "ts",
            "python",
            "py",
            "ruby",
            "rb",
            "swift",
            "actions",
        ]

        # Can be single language or comma-separated list
        languages = [lang.strip().lower() for lang in language.split(",")]

        for lang in languages:
            if not lang:
                self.add_error("CodeQL language cannot be empty")
                return False

            # Check if it's a supported language
            if lang not in supported_languages:
                self.add_error(
                    f"Unsupported CodeQL language: {lang}. "
                    f"Supported: {', '.join(supported_languages)}"
                )
                return False

        return True

    def validate_queries(self, queries: str) -> bool:
        """Validate CodeQL queries specification.

        Args:
            queries: Query specification

        Returns:
            True if valid, False otherwise
        """
        # Check for empty queries first
        if not queries or not queries.strip():
            self.add_error("CodeQL queries cannot be empty")
            return False

        # Use the CodeQL validator
        result = self.codeql_validator.validate_codeql_queries(queries)
        # Copy any errors from codeql validator
        for error in self.codeql_validator.errors:
            if error not in self.errors:
                self.add_error(error)
        self.codeql_validator.clear_errors()
        return result

    def validate_categories(self, categories: str) -> bool:
        """Validate CodeQL categories.

        Args:
            categories: Categories specification

        Returns:
            True if valid, False otherwise
        """
        # Use the CodeQL validator
        result = self.codeql_validator.validate_category_format(categories)
        # Copy any errors from codeql validator
        for error in self.codeql_validator.errors:
            if error not in self.errors:
                self.add_error(error)
        self.codeql_validator.clear_errors()
        return result

    def validate_category(self, category: str) -> bool:
        """Validate CodeQL category (singular).

        Args:
            category: Category specification

        Returns:
            True if valid, False otherwise
        """
        # Use the CodeQL validator
        result = self.codeql_validator.validate_category_format(category)
        # Copy any errors from codeql validator
        for error in self.codeql_validator.errors:
            if error not in self.errors:
                self.add_error(error)
        self.codeql_validator.clear_errors()
        return result

    def validate_config_file(self, config_file: str) -> bool:
        """Validate CodeQL configuration file path.

        Args:
            config_file: Path to config file

        Returns:
            True if valid, False otherwise
        """
        if not config_file or not config_file.strip():
            return True

        # Allow GitHub Actions expressions
        if self.is_github_expression(config_file):
            return True

        # Use FileValidator for yaml file validation
        result = self.file_validator.validate_yaml_file(config_file, "config-file")

        # Copy any errors from file validator
        for error in self.file_validator.errors:
            if error not in self.errors:
                self.add_error(error)
        self.file_validator.clear_errors()

        return result

    def validate_database(self, database: str) -> bool:
        """Validate CodeQL database path.

        Args:
            database: Database path

        Returns:
            True if valid, False otherwise
        """
        # Allow GitHub Actions expressions
        if self.is_github_expression(database):
            return True

        # Use FileValidator for path validation
        result = self.file_validator.validate_file_path(database, "database")

        # Copy any errors from file validator
        for error in self.file_validator.errors:
            if error not in self.errors:
                self.add_error(error)
        self.file_validator.clear_errors()

        # Database paths often contain the language
        # e.g., "codeql-database/javascript" or "/tmp/codeql_databases/python"
        # Just validate it's a reasonable path after basic validation
        if result and database.startswith("/tmp/"):  # noqa: S108
            return True

        return result

    def validate_debug(self, debug: str) -> bool:
        """Validate debug mode setting.

        Args:
            debug: Debug mode value

        Returns:
            True if valid, False otherwise
        """
        # Allow GitHub Actions expressions
        if self.is_github_expression(debug):
            return True

        # Use BooleanValidator
        result = self.boolean_validator.validate_boolean(debug, "debug")

        # Copy any errors from boolean validator
        for error in self.boolean_validator.errors:
            if error not in self.errors:
                self.add_error(error)
        self.boolean_validator.clear_errors()

        return result

    def validate_upload_database(self, upload: str) -> bool:
        """Validate upload-database setting.

        Args:
            upload: Upload setting

        Returns:
            True if valid, False otherwise
        """
        # Allow GitHub Actions expressions
        if self.is_github_expression(upload):
            return True

        # Use BooleanValidator
        result = self.boolean_validator.validate_boolean(upload, "upload-database")

        # Copy any errors from boolean validator
        for error in self.boolean_validator.errors:
            if error not in self.errors:
                self.add_error(error)
        self.boolean_validator.clear_errors()

        return result

    def validate_upload_sarif(self, upload: str) -> bool:
        """Validate upload-sarif setting.

        Args:
            upload: Upload setting

        Returns:
            True if valid, False otherwise
        """
        # Allow GitHub Actions expressions
        if self.is_github_expression(upload):
            return True

        # Use BooleanValidator
        result = self.boolean_validator.validate_boolean(upload, "upload-sarif")

        # Copy any errors from boolean validator
        for error in self.boolean_validator.errors:
            if error not in self.errors:
                self.add_error(error)
        self.boolean_validator.clear_errors()

        return result

    def validate_packs(self, packs: str) -> bool:
        """Validate CodeQL packs.

        Args:
            packs: Packs specification

        Returns:
            True if valid, False otherwise
        """
        # Allow GitHub Actions expressions
        if self.is_github_expression(packs):
            return True

        if not packs or not packs.strip():
            return True

        # Split by comma and validate each pack
        pack_list = [p.strip() for p in packs.split(",")]

        for pack in pack_list:
            if not pack:
                continue

            # Local pack path
            if pack.startswith("./") or pack.startswith("../"):
                if not self.validate_path_security(pack):
                    return False
            # Remote pack with version
            elif "@" in pack:
                name_part, version_part = pack.rsplit("@", 1)
                # Validate pack name format
                if not self._validate_pack_name(name_part):
                    return False
                # Basic version validation
                if not version_part:
                    self.add_error(f"Pack version cannot be empty: {pack}")
                    return False
            # Remote pack without version
            elif not self._validate_pack_name(pack):
                return False

        return True

    def _validate_pack_name(self, pack_name: str) -> bool:
        """Validate CodeQL pack name format.

        Args:
            pack_name: Pack name to validate

        Returns:
            True if valid, False otherwise
        """
        # Pack names are typically in format: namespace/pack-name
        # e.g., codeql/javascript-queries, github/codeql-go

        if "/" not in pack_name:
            self.add_error(f"Pack name should be in format 'namespace/pack-name': {pack_name}")
            return False

        namespace, name = pack_name.split("/", 1)

        # Validate namespace (alphanumeric, hyphens, underscores)
        if not namespace or not all(c.isalnum() or c in "-_" for c in namespace):
            self.add_error(f"Invalid pack namespace: {namespace}")
            return False

        # Validate pack name
        if not name or not all(c.isalnum() or c in "-_" for c in name):
            self.add_error(f"Invalid pack name: {name}")
            return False

        return True

    def validate_external_token(self, token: str) -> bool:
        """Validate external repository token.

        Args:
            token: Token value

        Returns:
            True if valid, False otherwise
        """
        # Use the TokenValidator for proper validation
        result = self.token_validator.validate_github_token(token, required=False)

        # Copy any errors from token validator
        for error in self.token_validator.errors:
            if error not in self.errors:
                self.add_error(error)
        self.token_validator.clear_errors()

        return result

    def validate_token(self, token: str) -> bool:
        """Validate GitHub token.

        Args:
            token: Token value

        Returns:
            True if valid, False otherwise
        """
        # Check for empty token
        if not token or not token.strip():
            self.add_error("Input 'token' is missing or empty")
            return False

        # Use the TokenValidator for proper validation
        result = self.token_validator.validate_github_token(token, required=True)

        # Copy any errors from token validator
        for error in self.token_validator.errors:
            if error not in self.errors:
                self.add_error(error)
        self.token_validator.clear_errors()

        return result

    def validate_working_directory(self, directory: str) -> bool:
        """Validate working directory path.

        Args:
            directory: Directory path

        Returns:
            True if valid, False otherwise
        """
        # Allow GitHub Actions expressions
        if self.is_github_expression(directory):
            return True

        # Use FileValidator for path validation
        result = self.file_validator.validate_file_path(directory, "working-directory")

        # Copy any errors from file validator
        for error in self.file_validator.errors:
            if error not in self.errors:
                self.add_error(error)
        self.file_validator.clear_errors()

        return result

    def validate_upload_results(self, value: str) -> bool:
        """Validate upload-results boolean value.

        Args:
            value: Boolean value to validate

        Returns:
            True if valid, False otherwise
        """
        # Check for empty
        if not value or not value.strip():
            self.add_error("upload-results cannot be empty")
            return False

        # Allow GitHub Actions expressions
        if self.is_github_expression(value):
            return True

        # Check for uppercase TRUE/FALSE first
        if value in ["TRUE", "FALSE"]:
            self.add_error("Must be lowercase 'true' or 'false'")
            return False

        # Use BooleanValidator for normal validation
        result = self.boolean_validator.validate_boolean(value, "upload-results")

        # Copy any errors from boolean validator
        for error in self.boolean_validator.errors:
            if error not in self.errors:
                self.add_error(error)
        self.boolean_validator.clear_errors()

        return result
