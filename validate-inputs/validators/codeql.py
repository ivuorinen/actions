"""CodeQL-specific validators for code analysis actions."""

from __future__ import annotations

import re
from typing import ClassVar

from .base import BaseValidator


class CodeQLValidator(BaseValidator):
    """Validator for CodeQL analysis action inputs."""

    # Supported CodeQL languages
    SUPPORTED_LANGUAGES: ClassVar[set[str]] = {
        "javascript",
        "typescript",
        "python",
        "java",
        "csharp",
        "cpp",
        "c",
        "go",
        "ruby",
        "swift",
        "kotlin",
        "actions",
    }

    # Standard query suites
    STANDARD_SUITES: ClassVar[set[str]] = {
        "security-extended",
        "security-and-quality",
        "code-scanning",
        "default",
    }

    # Valid build modes
    BUILD_MODES: ClassVar[set[str]] = {"none", "manual", "autobuild"}

    def validate_inputs(self, inputs: dict[str, str]) -> bool:
        """Validate CodeQL-specific inputs."""
        valid = True

        for input_name, value in inputs.items():
            if input_name == "language":
                valid &= self.validate_codeql_language(value)
            elif input_name == "queries":
                valid &= self.validate_codeql_queries(value)
            elif input_name == "packs":
                valid &= self.validate_codeql_packs(value)
            elif input_name in {"build-mode", "build_mode"}:
                valid &= self.validate_codeql_build_mode(value)
            elif input_name == "config":
                valid &= self.validate_codeql_config(value)
            elif input_name == "category":
                valid &= self.validate_category_format(value)
            elif input_name == "threads":
                valid &= self.validate_threads(value)
            elif input_name == "ram":
                valid &= self.validate_ram(value)

        return valid

    def get_required_inputs(self) -> list[str]:
        """Get required inputs for CodeQL analysis."""
        return ["language"]  # Language is required for CodeQL

    def get_validation_rules(self) -> dict:
        """Return CodeQL validation rules."""
        return {
            "language": list(self.SUPPORTED_LANGUAGES),
            "queries": list(self.STANDARD_SUITES),
            "build_modes": list(self.BUILD_MODES),
            "threads": "1-128",
            "ram": "256-32768 MB",
        }

    def validate_codeql_language(self, value: str) -> bool:
        """Validate CodeQL language.

        Args:
            value: The language to validate

        Returns:
            True if valid, False otherwise
        """
        if not value or value.strip() == "":
            self.add_error("CodeQL language cannot be empty")
            return False

        language = value.strip().lower()

        if language in self.SUPPORTED_LANGUAGES:
            return True

        self.add_error(
            f'Invalid CodeQL language: "{value}". '
            f"Supported languages: {', '.join(sorted(self.SUPPORTED_LANGUAGES))}",
        )
        return False

    def validate_codeql_queries(self, value: str) -> bool:
        """Validate CodeQL query suites.

        Args:
            value: The queries to validate

        Returns:
            True if valid, False otherwise
        """
        if not value or value.strip() == "":
            self.add_error("CodeQL queries cannot be empty")
            return False

        # Allow GitHub Actions expressions
        if self.is_github_expression(value):
            return True

        # Split by comma and validate each query
        queries = [q.strip() for q in value.split(",") if q.strip()]

        for query in queries:
            query_lower = query.lower()

            # Check if it's a standard suite
            if query_lower in self.STANDARD_SUITES:
                continue

            # Check if it's a query file path
            if query.endswith((".ql", ".qls")):
                # Validate as file path
                if not self.validate_path_security(query, "query file"):
                    return False
                continue

            # Check if it contains path separators (custom query path)
            if "/" in query or "\\" in query:
                if not self.validate_path_security(query, "query path"):
                    return False
                continue

            # If none of the above, it's invalid
            self.add_error(f'Invalid CodeQL query suite: "{query}"')
            return False

        return True

    def validate_codeql_packs(self, value: str) -> bool:
        """Validate CodeQL query packs.

        Args:
            value: The packs to validate

        Returns:
            True if valid, False otherwise
        """
        if not value or value.strip() == "":
            return True  # Packs are optional

        # Split by comma and validate each pack
        packs = [p.strip() for p in value.split(",") if p.strip()]

        # Pack format: pack-name or owner/repo or owner/repo@version
        pack_pattern = r"^[a-zA-Z0-9._/-]+(@[a-zA-Z0-9._-]+)?$"

        for pack in packs:
            if not re.match(pack_pattern, pack):
                self.add_error(
                    f'Invalid CodeQL pack format: "{pack}". '
                    "Expected format: pack-name, owner/repo, or owner/repo@version",
                )
                return False

        return True

    def validate_codeql_build_mode(self, value: str) -> bool:
        """Validate CodeQL build mode.

        Args:
            value: The build mode to validate

        Returns:
            True if valid, False otherwise
        """
        if not value or value.strip() == "":
            return True  # Build mode is optional

        mode = value.strip().lower()

        if mode in self.BUILD_MODES:
            return True

        self.add_error(
            f'Invalid CodeQL build mode: "{value}". '
            f"Valid options: {', '.join(sorted(self.BUILD_MODES))}",
        )
        return False

    def validate_codeql_config(self, value: str) -> bool:
        """Validate CodeQL configuration.

        Args:
            value: The config to validate

        Returns:
            True if valid, False otherwise
        """
        if not value or value.strip() == "":
            return True  # Config is optional

        # Check for dangerous YAML patterns
        dangerous_patterns = [
            r"!!python/",  # Python object execution
            r"!!ruby/",  # Ruby execution
            r"!!perl/",  # Perl execution
            r"!!js/",  # JavaScript execution
        ]

        for pattern in dangerous_patterns:
            if re.search(pattern, value, re.IGNORECASE):
                self.add_error(f"Dangerous pattern in CodeQL config: {pattern}")
                return False

        return True

    def validate_category_format(self, value: str) -> bool:
        """Validate analysis category format.

        Args:
            value: The category to validate

        Returns:
            True if valid, False otherwise
        """
        if not value or value.strip() == "":
            return True  # Category is optional

        # Allow GitHub Actions expressions
        if self.is_github_expression(value):
            return True

        # Category should start with /
        if not value.startswith("/"):
            self.add_error(f'Category must start with "/": {value}')
            return False

        # Check for valid characters
        if not re.match(r"^/[a-zA-Z0-9_:/-]+$", value):
            self.add_error(f"Invalid category format: {value}")
            return False

        return True

    def validate_threads(self, value: str, name: str = "threads") -> bool:
        """Validate thread count (1-128).

        Args:
            value: The thread count to validate
            name: The input name for error messages

        Returns:
            True if valid, False otherwise
        """
        if not value or value.strip() == "":
            return True  # Optional

        try:
            threads = int(value.strip())
            if 1 <= threads <= 128:
                return True
            self.add_error(f"Invalid {name}: {threads}. Must be between 1 and 128")
            return False
        except ValueError:
            self.add_error(f'Invalid {name}: "{value}". Must be a number')
            return False

    def validate_ram(self, value: str, name: str = "ram") -> bool:
        """Validate RAM in MB (256-32768).

        Args:
            value: The RAM value to validate
            name: The input name for error messages

        Returns:
            True if valid, False otherwise
        """
        if not value or value.strip() == "":
            return True  # Optional

        try:
            ram = int(value.strip())
            if 256 <= ram <= 32768:
                return True
            self.add_error(f"Invalid {name}: {ram}. Must be between 256 and 32768 MB")
            return False
        except ValueError:
            self.add_error(f'Invalid {name}: "{value}". Must be a number')
            return False

    # Convenience methods for convention-based validation
    def validate_numeric_range_1_128(self, value: str, name: str = "threads") -> bool:
        """Alias for thread validation."""
        return self.validate_threads(value, name)

    def validate_numeric_range_256_32768(self, value: str, name: str = "ram") -> bool:
        """Alias for RAM validation."""
        return self.validate_ram(value, name)
