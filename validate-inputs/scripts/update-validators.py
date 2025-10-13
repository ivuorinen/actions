#!/usr/bin/env python3

"""update-validators.py

Automatically generates validation rules for GitHub Actions
by scanning action.yml files and applying convention-based detection.

Usage:
  python update-validators.py [--dry-run] [--action action-name]
"""

from __future__ import annotations

import argparse
from pathlib import Path
import re
import sys
from typing import Any

import yaml  # pylint: disable=import-error


class ValidationRuleGenerator:
    """Generate validation rules for GitHub Actions automatically.

    This class scans GitHub Action YAML files and generates validation rules
    based on convention-based detection patterns and special case handling.
    """

    def __init__(self, *, dry_run: bool = False, specific_action: str | None = None) -> None:
        """Initialize the validation rule generator.

        Args:
            dry_run: If True, show what would be generated without writing files
            specific_action: If provided, only generate rules for this action
        """
        self.dry_run = dry_run
        self.specific_action = specific_action
        self.actions_dir = Path(__file__).parent.parent.parent.resolve()

        # Convention patterns for automatic detection
        # Order matters - more specific patterns should come first
        self.conventions = {
            # CodeQL-specific patterns (high priority)
            "codeql_language": re.compile(r"\blanguage\b", re.IGNORECASE),
            "codeql_queries": re.compile(r"\bquer(y|ies)\b", re.IGNORECASE),
            "codeql_packs": re.compile(r"\bpacks?\b", re.IGNORECASE),
            "codeql_build_mode": re.compile(r"\bbuild[_-]?mode\b", re.IGNORECASE),
            "codeql_config": re.compile(r"\bconfig\b", re.IGNORECASE),
            "category_format": re.compile(r"\bcategor(y|ies)\b", re.IGNORECASE),
            # GitHub token patterns (high priority)
            "github_token": re.compile(
                r"\b(github[_-]?token|gh[_-]?token|token|auth[_-]?token|api[_-]?key)\b",
                re.IGNORECASE,
            ),
            # CalVer version patterns (high priority - check before semantic)
            "calver_version": re.compile(
                r"\b(release[_-]?tag|release[_-]?version|monthly[_-]?version|date[_-]?version)\b",
                re.IGNORECASE,
            ),
            # Specific version types (high priority)
            "dotnet_version": re.compile(r"\bdotnet[_-]?version\b", re.IGNORECASE),
            "terraform_version": re.compile(r"\bterraform[_-]?version\b", re.IGNORECASE),
            "node_version": re.compile(r"\bnode[_-]?version\b", re.IGNORECASE),
            # Docker-specific patterns (high priority)
            "docker_image_name": re.compile(r"\bimage[_-]?name\b", re.IGNORECASE),
            "docker_tag": re.compile(r"\b(tags?|image[_-]?tags?)\b", re.IGNORECASE),
            "docker_architectures": re.compile(
                r"\b(arch|architecture|platform)s?\b",
                re.IGNORECASE,
            ),
            # Namespace with lookahead (specific pattern)
            "namespace_with_lookahead": re.compile(r"\bnamespace\b", re.IGNORECASE),
            # Numeric ranges (specific ranges)
            "numeric_range_0_16": re.compile(
                r"\b(parallel[_-]?builds?|builds?[_-]?parallel)\b",
                re.IGNORECASE,
            ),
            "numeric_range_1_10": re.compile(
                r"\b(retry|retries|attempt|attempts|max[_-]?retry)\b",
                re.IGNORECASE,
            ),
            "numeric_range_1_128": re.compile(r"\bthreads?\b", re.IGNORECASE),
            "numeric_range_256_32768": re.compile(r"\bram\b", re.IGNORECASE),
            "numeric_range_0_100": re.compile(
                r"\b(quality|percent|percentage)\b", re.IGNORECASE
            ),
            # File and path patterns
            "file_path": re.compile(
                r"\b(paths?|files?|dir|directory|config|dockerfile"
                r"|ignore[_-]?file|key[_-]?files?)\b",
                re.IGNORECASE,
            ),
            "file_pattern": re.compile(r"\b(file[_-]?pattern|glob[_-]?pattern)\b", re.IGNORECASE),
            "branch_name": re.compile(r"\b(branch|ref|base[_-]?branch)\b", re.IGNORECASE),
            # User and identity patterns
            "email": re.compile(r"\b(email|mail)\b", re.IGNORECASE),
            "username": re.compile(r"\b(user|username|commit[_-]?user)\b", re.IGNORECASE),
            # URL patterns (high priority)
            "url": re.compile(
                r"\b(url|registry[_-]?url|api[_-]?url|endpoint)\b", re.IGNORECASE
            ),
            # Scope and namespace patterns
            "scope": re.compile(r"\b(scope|namespace)\b", re.IGNORECASE),
            # Security patterns for text content that could contain injection
            "security_patterns": re.compile(
                r"\b(changelog|notes|message|content|description|body|text|comment|summary|release[_-]?notes)\b",
                re.IGNORECASE,
            ),
            # Regex pattern validation (ReDoS detection)
            "regex_pattern": re.compile(
                r"\b(regex|pattern|validation[_-]?regex|regex[_-]?pattern)\b",
                re.IGNORECASE,
            ),
            # Additional validation types
            "report_format": re.compile(
                r"\b(report[_-]?format|format)\b", re.IGNORECASE
            ),
            "plugin_list": re.compile(r"\b(plugins?|plugin[_-]?list)\b", re.IGNORECASE),
            "prefix": re.compile(r"\b(prefix|tag[_-]?prefix)\b", re.IGNORECASE),
            # Boolean patterns (broad, should be lower priority)
            "boolean": re.compile(
                r"\b(dry-?run|verbose|enable|disable|auto|skip|force|cache|provenance|sbom|scan|sign|fail[_-]?on[_-]?error|nightly)\b",
                re.IGNORECASE,
            ),
            # File extensions pattern
            "file_extensions": re.compile(r"\b(file[_-]?extensions?|extensions?)\b", re.IGNORECASE),
            # Registry pattern
            "registry": re.compile(r"\bregistry\b", re.IGNORECASE),
            # PHP-specific patterns
            "php_extensions": re.compile(r"\b(extensions?|php[_-]?extensions?)\b", re.IGNORECASE),
            "coverage_driver": re.compile(r"\b(coverage|coverage[_-]?driver)\b", re.IGNORECASE),
            # Generic version pattern (lowest priority - catches remaining version fields)
            "semantic_version": re.compile(r"\bversion\b", re.IGNORECASE),
        }

        # Special cases that need manual handling
        self.special_cases = {
            # CalVer fields that might not be detected
            "release-tag": "calver_version",
            # Flexible version fields (support both CalVer and SemVer)
            "version": "flexible_version",  # For github-release action
            # File paths that might not be detected
            "pre-commit-config": "file_path",
            "config-file": "file_path",
            "ignore-file": "file_path",
            "readme-file": "file_path",
            "working-directory": "file_path",
            # Version fields with specific types
            "buildx-version": "semantic_version",
            "buildkit-version": "semantic_version",
            "tflint-version": "terraform_version",
            "default-version": "semantic_version",
            "force-version": "semantic_version",
            "golangci-lint-version": "semantic_version",
            "prettier-version": "semantic_version",
            "eslint-version": "strict_semantic_version",
            "flake8-version": "semantic_version",
            "autopep8-version": "semantic_version",
            "composer-version": "semantic_version",
            # Tokens and passwords
            "dockerhub-password": "github_token",
            "npm_token": "github_token",
            "password": "github_token",
            # Complex fields that should skip validation
            "build-args": None,  # Can be empty
            "context": None,  # Default handled
            "cache-from": None,  # Complex cache syntax
            "cache-export": None,  # Complex cache syntax
            "cache-import": None,  # Complex cache syntax
            "build-contexts": None,  # Complex syntax
            "secrets": None,  # Complex syntax
            "platform-build-args": None,  # JSON format
            "extensions": None,  # PHP extensions list
            "tools": None,  # PHP tools list
            "args": None,  # Composer args
            "stability": None,  # Composer stability
            "registry-url": "url",  # URL format
            "scope": "scope",  # NPM scope
            "plugins": None,  # Prettier plugins
            "file-extensions": "file_extensions",  # File extension list
            "file-pattern": None,  # Glob pattern
            "enable-linters": None,  # Linter list
            "disable-linters": None,  # Linter list
            "success-codes": None,  # Exit code list
            "retry-codes": None,  # Exit code list
            "ignore-paths": None,  # Path patterns
            "key-files": None,  # Cache key files
            "restore-keys": None,  # Cache restore keys
            "env-vars": None,  # Environment variables
            # Action-specific fields that need special handling
            "type": None,  # Cache type enum (npm, composer, go, etc.) - complex enum,
            # skip validation
            "paths": None,  # File paths for caching (comma-separated) - complex format,
            # skip validation
            "command": None,  # Shell command - complex format, skip validation for safety
            "backoff-strategy": None,  # Retry strategy enum - complex enum, skip validation
            "shell": None,  # Shell type enum - simple enum, skip validation
            # Removed image-name and tag - now handled by docker_image_name and docker_tag patterns
            # Numeric inputs with different ranges
            "timeout": "numeric_range_1_3600",  # Timeout should support higher values
            "retry-delay": "numeric_range_1_300",  # Retry delay should support higher values
            "max-warnings": "numeric_range_0_10000",
            # version-file-parser specific fields
            "language": None,  # Simple enum (node, php, python, go, dotnet)
            "tool-versions-key": None,  # Simple string (nodejs, python, php, golang, dotnet)
            "dockerfile-image": None,  # Simple string (node, python, php, golang, dotnet)
            "validation-regex": "regex_pattern",  # Regex pattern - validate for ReDoS
        }

    def get_action_directories(self) -> list[str]:
        """Get all action directories"""
        entries = []
        for item in self.actions_dir.iterdir():
            if (
                item.is_dir()
                and not item.name.startswith(".")
                and item.name != "validate-inputs"
                and (item / "action.yml").exists()
            ):
                entries.append(item.name)
        return entries

    def parse_action_file(self, action_name: str) -> dict[str, Any] | None:
        """Parse action.yml file to extract inputs"""
        action_file = self.actions_dir / action_name / "action.yml"

        try:
            with action_file.open(encoding="utf-8") as f:
                content = f.read()
            action_data = yaml.safe_load(content)

            return {
                "name": action_data.get("name", action_name),
                "description": action_data.get("description", ""),
                "inputs": action_data.get("inputs", {}),
            }
        except Exception as error:
            print(f"Failed to parse {action_file}: {error}")
            return None

    def detect_validation_type(self, input_name: str, input_data: dict[str, Any]) -> str | None:
        """Detect validation type based on input name and description"""
        description = input_data.get("description", "")

        # Check special cases first - highest priority
        if input_name in self.special_cases:
            return self.special_cases[input_name]

        # Special handling for version fields that might be CalVer
        # Check if description mentions calendar/date/monthly/release
        if input_name == "version" and any(
            word in description.lower() for word in ["calendar", "date", "monthly", "release"]
        ):
            return "calver_version"

        # Apply convention patterns in order (more specific first)
        # Test input name first (highest confidence), then description
        for validator, pattern in self.conventions.items():
            if pattern.search(input_name):
                return validator  # Direct name match has highest confidence

        # If no name match, try description
        for validator, pattern in self.conventions.items():
            if pattern.search(description):
                return validator  # Description match has lower confidence

        return None  # No validation detected

    def sort_object_by_keys(self, obj: dict[str, Any]) -> dict[str, Any]:
        """Sort object keys alphabetically for consistent output"""
        return {key: obj[key] for key in sorted(obj.keys())}

    def generate_rules_for_action(self, action_name: str) -> dict[str, Any] | None:
        """Generate validation rules for a single action"""
        action_data = self.parse_action_file(action_name)
        if not action_data:
            return None

        required_inputs = []
        optional_inputs = []
        conventions = {}
        overrides = {}

        # Process each input
        for input_name, input_data in action_data["inputs"].items():
            is_required = input_data.get("required") in [True, "true"]
            if is_required:
                required_inputs.append(input_name)
            else:
                optional_inputs.append(input_name)

            # Detect validation type
            validation_type = self.detect_validation_type(input_name, input_data)
            if validation_type:
                conventions[input_name] = validation_type

        # Handle action-specific overrides using data-driven approach
        action_overrides = {
            "php-version-detect": {"default-version": "php_version"},
            "python-version-detect": {"default-version": "python_version"},
            "python-version-detect-v2": {"default-version": "python_version"},
            "dotnet-version-detect": {"default-version": "dotnet_version"},
            "go-version-detect": {"default-version": "go_version"},
            "npm-publish": {"package-version": "strict_semantic_version"},
            "docker-build": {
                "cache-mode": "cache_mode",
                "sbom-format": "sbom_format",
            },
            "common-cache": {
                "paths": "file_path",
                "key-files": "file_path",
            },
            "common-file-check": {
                "file-pattern": "file_path",
            },
            "common-retry": {
                "backoff-strategy": "backoff_strategy",
                "shell": "shell_type",
            },
            "node-setup": {
                "package-manager": "package_manager_enum",
            },
            "docker-publish": {
                "registry": "registry_enum",
                "cache-mode": "cache_mode",
                "platforms": None,  # Skip validation - complex platform format
            },
            "docker-publish-hub": {
                "password": "docker_password",
            },
            "go-lint": {
                "go-version": "go_version",
                "timeout": "timeout_with_unit",
                "only-new-issues": "boolean",
                "enable-linters": "linter_list",
                "disable-linters": "linter_list",
            },
            "prettier-check": {
                "check-only": "boolean",
                "file-pattern": "file_pattern",
                "plugins": "plugin_list",
            },
            "php-laravel-phpunit": {
                "extensions": "php_extensions",
            },
            "codeql-analysis": {
                "language": "codeql_language",
                "queries": "codeql_queries",
                "packs": "codeql_packs",
                "config": "codeql_config",
                "build-mode": "codeql_build_mode",
                "source-root": "file_path",
                "category": "category_format",
                "token": "github_token",
                "ram": "numeric_range_256_32768",
                "threads": "numeric_range_1_128",
                "output": "file_path",
                "skip-queries": "boolean",
                "add-snippets": "boolean",
            },
        }

        if action_name in action_overrides:
            # Apply overrides for existing conventions
            overrides.update(
                {
                    input_name: override_value
                    for input_name, override_value in action_overrides[action_name].items()
                    if input_name in conventions
                },
            )
            # Add missing inputs from overrides to conventions
            for input_name, override_value in action_overrides[action_name].items():
                if input_name not in conventions and input_name in action_data["inputs"]:
                    conventions[input_name] = override_value

        # Calculate statistics
        total_inputs = len(action_data["inputs"])
        validated_inputs = len(conventions)
        skipped_inputs = sum(1 for v in overrides.values() if v is None)
        coverage = round((validated_inputs / total_inputs) * 100) if total_inputs > 0 else 0

        # Generate rules object with enhanced metadata
        rules = {
            "schema_version": "1.0",
            "action": action_name,
            "description": action_data["description"],
            "generator_version": "1.0.0",
            "required_inputs": sorted(required_inputs),
            "optional_inputs": sorted(optional_inputs),
            "conventions": self.sort_object_by_keys(conventions),
            "overrides": self.sort_object_by_keys(overrides),
            "statistics": {
                "total_inputs": total_inputs,
                "validated_inputs": validated_inputs,
                "skipped_inputs": skipped_inputs,
                "coverage_percentage": coverage,
            },
            "validation_coverage": coverage,
            "auto_detected": True,
            "manual_review_required": coverage < 80 or validated_inputs == 0,
            "quality_indicators": {
                "has_required_inputs": len(required_inputs) > 0,
                "has_token_validation": "token" in conventions or "github-token" in conventions,
                "has_version_validation": any("version" in v for v in conventions.values() if v),
                "has_file_validation": any(v == "file_path" for v in conventions.values()),
                "has_security_validation": any(
                    v in ["github_token", "security_patterns"] for v in conventions.values()
                ),
            },
        }

        return rules

    def write_rules_file(self, action_name: str, rules: dict[str, Any]) -> None:
        """Write rules to YAML file in action folder"""
        rules_file = self.actions_dir / action_name / "rules.yml"
        generator_version = rules.get("generator_version", "unknown")
        schema_version = rules.get("schema_version", "unknown")
        validation_coverage = rules.get("validation_coverage", 0)
        validated_inputs = rules["statistics"].get("validated_inputs", 0)
        total_inputs = rules["statistics"].get("total_inputs", 0)

        header = f"""---
# Validation rules for {action_name} action
# Generated by update-validators.py v{generator_version} - DO NOT EDIT MANUALLY
# Schema version: {schema_version}
# Coverage: {validation_coverage}% ({validated_inputs}/{total_inputs} inputs)
#
# This file defines validation rules for the {action_name} GitHub Action.
# Rules are automatically applied by validate-inputs action when this
# action is used.
#

"""

        # Use a custom yaml dumper to ensure proper indentation
        class CustomYamlDumper(yaml.SafeDumper):
            def increase_indent(self, flow: bool = False, *, indentless: bool = False) -> None:  # noqa: FBT001, FBT002
                return super().increase_indent(flow, indentless=indentless)

        yaml_content = yaml.dump(
            rules,
            Dumper=CustomYamlDumper,
            indent=2,
            width=120,
            default_flow_style=False,
            allow_unicode=True,
            sort_keys=False,
        )

        content = header + yaml_content

        if self.dry_run:
            print(f"[DRY RUN] Would write {rules_file}:")
            print(content)
            print("---")
        else:
            with rules_file.open("w", encoding="utf-8") as f:
                f.write(content)
            print(f"✅ Generated {rules_file}")

    def generate_rules(self) -> None:
        """Generate rules for all actions or a specific action"""
        print("🔍 Scanning for GitHub Actions...")

        actions = self.get_action_directories()
        filtered_actions = actions

        if self.specific_action:
            filtered_actions = [name for name in actions if name == self.specific_action]
            if not filtered_actions:
                print(f"❌ Action '{self.specific_action}' not found")
                sys.exit(1)

        print(f"📝 Found {len(actions)} actions, processing {len(filtered_actions)}:")
        for name in filtered_actions:
            print(f"  - {name}")
        print()

        processed = 0
        failed = 0

        for action_name in filtered_actions:
            try:
                rules = self.generate_rules_for_action(action_name)
                if rules:
                    self.write_rules_file(action_name, rules)
                    processed += 1
                else:
                    print(f"⚠️  Failed to generate rules for {action_name}")
                    failed += 1
            except Exception as error:
                print(f"❌ Error processing {action_name}: {error}")
                failed += 1

        print()
        print("📊 Summary:")
        print(f"  - Processed: {processed}")
        print(f"  - Failed: {failed}")
        coverage = (
            round((processed / (processed + failed)) * 100) if (processed + failed) > 0 else 0
        )
        print(f"  - Coverage: {coverage}%")

        if not self.dry_run and processed > 0:
            print()
            print(
                "✨ Validation rules updated! Run 'git diff */rules.yml' to review changes.",
            )

    def validate_rules_files(self) -> bool:
        """Validate existing rules files"""
        print("🔍 Validating existing rules files...")

        # Find all rules.yml files in action directories
        rules_files = []
        for action_dir in self.actions_dir.iterdir():
            if action_dir.is_dir() and not action_dir.name.startswith("."):
                rules_file = action_dir / "rules.yml"
                if rules_file.exists():
                    rules_files.append(rules_file)

        valid = 0
        invalid = 0

        for rules_file in rules_files:
            try:
                with rules_file.open(encoding="utf-8") as f:
                    content = f.read()
                rules = yaml.safe_load(content)

                # Basic validation
                required = ["action", "required_inputs", "optional_inputs", "conventions"]
                missing = [field for field in required if field not in rules]

                if missing:
                    print(f"⚠️  {rules_file.name}: Missing fields: {', '.join(missing)}")
                    invalid += 1
                else:
                    valid += 1
            except Exception as error:
                print(f"❌ {rules_file.name}: {error}")
                invalid += 1

        print(f"✅ Validation complete: {valid} valid, {invalid} invalid")
        return invalid == 0


def main() -> None:
    """CLI handling"""
    parser = argparse.ArgumentParser(
        description="Automatically generates validation rules for GitHub Actions",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python update-validators.py --dry-run
  python update-validators.py --action csharp-publish
  python update-validators.py --validate
        """,
    )

    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show what would be generated without writing files",
    )
    parser.add_argument("--action", metavar="NAME", help="Generate rules for specific action only")
    parser.add_argument("--validate", action="store_true", help="Validate existing rules files")

    args = parser.parse_args()

    generator = ValidationRuleGenerator(dry_run=args.dry_run, specific_action=args.action)

    if args.validate:
        success = generator.validate_rules_files()
        sys.exit(0 if success else 1)
    else:
        generator.generate_rules()


if __name__ == "__main__":
    main()
