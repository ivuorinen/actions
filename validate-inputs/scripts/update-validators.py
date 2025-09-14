#!/usr/bin/env python3

"""update-validators.py

Automatically generates validation rules for GitHub Actions
by scanning action.yml files and applying convention-based detection.

Usage:
  python update-validators.py [--dry-run] [--action action-name]
"""

import argparse
from pathlib import Path
import re
import sys
from typing import Any, Dict, List, Optional

import yaml


class ValidationRuleGenerator:
    def __init__(self, dry_run: bool = False, specific_action: Optional[str] = None):
        self.dry_run = dry_run
        self.specific_action = specific_action
        self.actions_dir = Path(__file__).parent.parent.parent.resolve()
        self.rules_dir = Path(__file__).parent.parent / "rules"

        # Convention patterns for automatic detection
        # Order matters - more specific patterns should come first
        self.conventions = {
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
            "docker_tag": re.compile(r"\b(tag|image[_-]?tag)\b", re.IGNORECASE),
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
            "numeric_range_0_100": re.compile(r"\b(quality|percent|percentage)\b", re.IGNORECASE),
            # File and path patterns
            "file_path": re.compile(
                r"\b(path|file|dir|directory|config|dockerfile|ignore[_-]?file)\b",
                re.IGNORECASE,
            ),
            "branch_name": re.compile(r"\b(branch|ref|base[_-]?branch)\b", re.IGNORECASE),
            # User and identity patterns
            "email": re.compile(r"\b(email|mail)\b", re.IGNORECASE),
            "username": re.compile(r"\b(user|username|commit[_-]?user)\b", re.IGNORECASE),
            # Boolean patterns (broad, should be lower priority)
            "boolean": re.compile(
                r"\b(dry-?run|verbose|enable|disable|auto|skip|force|cache|provenance|sbom|scan|sign|fail[_-]?on[_-]?error)\b",
                re.IGNORECASE,
            ),
            # Prefix pattern
            "prefix": re.compile(r"\bprefix\b", re.IGNORECASE),
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
            "eslint-version": "semantic_version",
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
            "registry-url": None,  # URL format
            "scope": None,  # NPM scope
            "plugins": None,  # Prettier plugins
            "file-extensions": None,  # File extension list
            "file-pattern": None,  # Glob pattern
            "enable-linters": None,  # Linter list
            "disable-linters": None,  # Linter list
            "success-codes": None,  # Exit code list
            "retry-codes": None,  # Exit code list
            "ignore-paths": None,  # Path patterns
            "key-files": None,  # Cache key files
            "restore-keys": None,  # Cache restore keys
            "env-vars": None,  # Environment variables
            # Numeric inputs with different ranges
            "timeout": "numeric_range_1_10",
            "retry-delay": "numeric_range_1_10",
            "max-warnings": "numeric_range_0_100",
        }

    def get_action_directories(self) -> List[str]:
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

    def parse_action_file(self, action_name: str) -> Optional[Dict[str, Any]]:
        """Parse action.yml file to extract inputs"""
        action_file = self.actions_dir / action_name / "action.yml"

        try:
            with open(action_file, encoding="utf-8") as f:
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

    def detect_validation_type(self, input_name: str, input_data: Dict[str, Any]) -> Optional[str]:
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

    def sort_object_by_keys(self, obj: Dict[str, Any]) -> Dict[str, Any]:
        """Sort object keys alphabetically for consistent output"""
        return {key: obj[key] for key in sorted(obj.keys())}

    def generate_rules_for_action(self, action_name: str) -> Optional[Dict[str, Any]]:
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
                "has_security_validation": any(v == "github_token" for v in conventions.values()),
            },
        }

        return rules

    def write_rules_file(self, action_name: str, rules: Dict[str, Any]) -> None:
        """Write rules to YAML file"""
        rules_file = self.rules_dir / f"{action_name}.yml"

        header = f"""# Validation rules for {action_name} action
# Generated by update-validators.py v{rules["generator_version"]} - DO NOT EDIT MANUALLY
# Schema version: {rules["schema_version"]}
# Coverage: {rules["validation_coverage"]}% ({rules["statistics"]["validated_inputs"]}/{rules["statistics"]["total_inputs"]} inputs)
#
# This file defines validation rules for the {action_name} GitHub Action.
# Rules are automatically applied by validate-inputs action when this action is used.
#

"""

        yaml_content = yaml.dump(
            rules,
            indent=2,
            width=120,
            default_flow_style=False,
            allow_unicode=True,
        )

        content = header + yaml_content

        if self.dry_run:
            print(f"[DRY RUN] Would write {rules_file}:")
            print(content)
            print("---")
        else:
            with open(rules_file, "w", encoding="utf-8") as f:
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
                "✨ Validation rules updated! Run 'git diff validate-inputs/rules/' to review changes.",
            )

    def validate_rules_files(self) -> bool:
        """Validate existing rules files"""
        print("🔍 Validating existing rules files...")

        rules_files = list(self.rules_dir.glob("*.yml"))

        valid = 0
        invalid = 0

        for rules_file in rules_files:
            try:
                with open(rules_file, encoding="utf-8") as f:
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


def main():
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
