#!/usr/bin/env python
import os
from pathlib import Path
import re
import sys

import yaml


class ActionValidator:
    """Centralized validation for GitHub Actions using Python regex."""

    # GitHub token patterns (production-ready)
    GITHUB_TOKEN_PATTERNS = {
        "classic": r"^gh[efpousr]_[a-zA-Z0-9]{36}$",
        "fine_grained": r"^github_pat_[a-zA-Z0-9_]{82}$",
        "installation": r"^ghs_[a-zA-Z0-9]{36}$",
    }

    def __init__(self):
        self.action_type = os.getenv("INPUT_ACTION_TYPE", "").replace("-", "_")
        self.errors = []
        self.rules = self.load_validation_rules()

    def load_validation_rules(self) -> dict:
        """Load validation rules from centralized rules directory."""
        # Find the rules directory relative to this script
        script_dir = Path(__file__).resolve().parent
        rules_file = script_dir / "rules" / f"{self.action_type.replace('_', '-')}.yml"

        if rules_file.exists():
            try:
                with rules_file.open() as f:
                    rules = yaml.safe_load(f)
                    print(f"::notice::Loaded validation rules from {rules_file}")
                    return rules
            except Exception as e:
                print(f"::warning::Failed to load rules from {rules_file}: {e!s}")
                return {}
        else:
            print(f"::debug::Rules file {rules_file} not found, using hardcoded validation")
            return {}

    def validate_github_token(self, token: str, required: bool = False) -> bool:
        """Validate GitHub token format with proper PCRE patterns."""
        if not token or token.strip() == "":
            if required:
                self.errors.append("GitHub token is required but not provided")
                return False
            return True

        # Allow GitHub Actions expressions
        if token == "${{ github.token }}" or (token.startswith("${{") and token.endswith("}}")):
            return True

        # Check against known GitHub token patterns
        for token_type, pattern in self.GITHUB_TOKEN_PATTERNS.items():
            if re.match(pattern, token):
                return True

        self.errors.append(
            "Invalid GitHub token format. Expected: gh[efpousr]_* (36 chars), github_pat_* (82 chars), or ghs_* (36 chars)",
        )
        return False

    def validate_namespace_with_lookahead(self, namespace: str) -> bool:
        """Validate namespace using lookahead pattern (for csharp-publish)."""
        if not namespace or namespace.strip() == "":
            self.errors.append("Namespace cannot be empty")
            return False

        # Original pattern with lookahead: ^[a-zA-Z0-9]([a-zA-Z0-9]|-(?=[a-zA-Z0-9])){0,38}$
        pattern = r"^[a-zA-Z0-9]([a-zA-Z0-9]|-(?=[a-zA-Z0-9])){0,38}$"

        if re.match(pattern, namespace):
            return True
        self.errors.append(
            f'Invalid namespace format: "{namespace}". Must be 1-39 characters, alphanumeric and hyphens, no trailing hyphens',
        )
        return False

    def validate_email(self, email: str) -> bool:
        """Validate email format."""
        if not email or email.strip() == "":
            self.errors.append("Email cannot be empty")
            return False

        # More comprehensive email validation
        # Must have exactly one @ symbol with content before and after
        at_count = email.count("@")
        if at_count != 1:
            self.errors.append(f'Invalid email format: "{email}". Expected exactly one @ symbol')
            return False

        local, domain = email.split("@")

        # Local part cannot be empty
        if not local:
            self.errors.append(f'Invalid email format: "{email}". Missing local part before @')
            return False

        # Domain must contain at least one dot with content before and after
        if "." not in domain or domain.startswith(".") or domain.endswith("."):
            self.errors.append(f'Invalid email format: "{email}". Invalid domain format')
            return False

        return True

    def validate_username(self, username: str) -> bool:
        """Validate username with injection protection."""
        if not username or username.strip() == "":
            return True  # Username is often optional

        # Check for command injection patterns
        injection_patterns = [";", "&&", "|", "`", "$("]
        for pattern in injection_patterns:
            if pattern in username:
                self.errors.append(
                    f'Invalid username: "{username}". Command injection patterns not allowed',
                )
                return False

        # Check length (GitHub username limit)
        if len(username) > 39:
            self.errors.append(
                f"Username too long: {len(username)} characters. GitHub usernames are max 39 characters",
            )
            return False

        return True

    def validate_version(self, version: str, version_type: str = "semantic") -> bool:
        """Validate version strings (dotnet, terraform, node, etc.)."""
        if not version or version.strip() == "":
            return True  # Version is often optional

        # Remove common prefixes for validation
        clean_version = version.lstrip("v")

        patterns = {
            "dotnet": r"^[0-9]+(\.[0-9]+(\.[0-9]+)?)?(-[0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*)?$",
            "terraform": r"^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.-]+)?$",
            "semantic": r"^[0-9]+(\.[0-9]+(\.[0-9]+)?)?(-[0-9A-Za-z.-]+)?(\+[0-9A-Za-z.-]+)?$",
            "strict_semantic": r"^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?(\+[0-9A-Za-z.-]+)?$",
            "node": r"^[0-9]+(\.[0-9]+(\.[0-9]+)?)?$",
        }

        pattern = patterns.get(version_type, patterns["semantic"])
        if re.match(pattern, clean_version):
            return True
        self.errors.append(f'Invalid {version_type} version format: "{version}"')
        return False

    def validate_calver(self, version: str) -> bool:
        """Validate CalVer (Calendar Versioning) strings."""
        if not version or version.strip() == "":
            return True  # Version is often optional

        # Remove common prefixes for validation
        clean_version = version.lstrip("v")

        # Check specific CalVer patterns with proper date validation
        import re

        # YYYY.MM.DD format (e.g., 2024.3.15) - treat as date if third component looks like a day (1-31)
        match = re.match(r"^([0-9]{4})\.([0-9]{1,2})\.([0-9]{1,2})$", clean_version)
        if match:
            year, month, day = match.groups()
            year, month, day = int(year), int(month), int(day)
            # If it looks like a date (day 1-31), validate as date
            if 1 <= month <= 12 and 1 <= day <= 31:
                # Validate day ranges for specific months
                if (month in [1, 3, 5, 7, 8, 10, 12] and day <= 31) or (
                    month in [4, 6, 9, 11] and day <= 30
                ):
                    return True
                if month == 2 and day <= 29:  # Feb with basic leap year tolerance
                    return True
                # Invalid day for the month
                self.errors.append(f"Invalid day for month {month}: {day}")
                return False
            # Invalid month
            self.errors.append(f"Invalid month: {month}")
            return False

        # YYYY.MM.PATCH format (e.g., 2024.3.100) - for larger patch numbers
        match = re.match(r"^([0-9]{4})\.([0-9]{1,2})\.([0-9]{3,})$", clean_version)
        if match:
            year, month, patch = match.groups()
            if 1 <= int(month) <= 12:
                return True

        # YYYY.0M.0D format (e.g., 2024.03.05)
        match = re.match(r"^([0-9]{4})\.0([0-9])\.0([0-9])$", clean_version)
        if match:
            year, month, day = match.groups()
            if 1 <= int(month) <= 9 and 1 <= int(day) <= 9:
                return True

        # YY.MM.MICRO format (e.g., 24.3.1)
        match = re.match(r"^([0-9]{2})\.([0-9]{1,2})\.([0-9]+)$", clean_version)
        if match:
            year, month, micro = match.groups()
            if 1 <= int(month) <= 12:
                return True

        # YYYY.MM format (e.g., 2024.3)
        match = re.match(r"^([0-9]{4})\.([0-9]{1,2})$", clean_version)
        if match:
            year, month = match.groups()
            if 1 <= int(month) <= 12:
                return True

        # YYYY-MM-DD format (e.g., 2024-03-15)
        match = re.match(r"^([0-9]{4})\-([0-9]{2})\-([0-9]{2})$", clean_version)
        if match:
            year, month, day = match.groups()
            if 1 <= int(month) <= 12 and 1 <= int(day) <= 31:
                return True

        self.errors.append(
            f'Invalid CalVer format: "{version}". Expected formats like YYYY.MM.PATCH, YY.MM.MICRO, or YYYY.MM.DD',
        )
        return False

    def validate_calver_or_semver(self, version: str) -> bool:
        """Validate either CalVer or SemVer format - flexible version validation."""
        if not version or version.strip() == "":
            return True  # Version is often optional (required check is done separately)

        # Save current errors to restore if both validations fail
        original_errors = self.errors.copy()

        # Remove common prefixes for validation
        clean_version = version.lstrip("v")

        # Check if it looks like CalVer (starts with 4-digit year or specific 2-digit year patterns)
        looks_like_calver = (
            re.match(r"^[0-9]{4}\.", clean_version)  # YYYY.
            or re.match(r"^[0-9]{4}-[0-9]{2}-", clean_version)  # YYYY-MM-
            or (
                re.match(r"^[0-9]{2}\.[0-9]{1,2}\.", clean_version)
                and int(clean_version.split(".")[0]) >= 20
            )  # YY.MM. where YY >= 20
        )

        if looks_like_calver:
            # If it looks like CalVer, it must be valid CalVer
            self.errors = []
            if self.validate_calver(version):
                self.errors = original_errors
                return True
            # If it looks like CalVer but fails validation, don't try SemVer
            self.errors = original_errors
            self.errors.append(
                f'Invalid CalVer format: "{version}". Expected valid calendar-based version',
            )
            return False

        # Doesn't look like CalVer, try SemVer
        self.errors = []
        if self.validate_version(version, "semantic"):
            self.errors = original_errors
            return True

        # Failed SemVer validation
        self.errors = original_errors
        self.errors.append(
            f'Invalid version format: "{version}". Expected either CalVer (e.g., 2024.3.1) or SemVer (e.g., 1.2.3)',
        )
        return False

    def validate_docker_image_name(self, image_name: str) -> bool:
        """Validate Docker image name format."""
        if not image_name or image_name.strip() == "":
            return True  # Image name is often optional

        # Docker image name pattern (no slashes allowed per docker-build action)
        pattern = r"^[a-z0-9]+([._-][a-z0-9]+)*$"
        if re.match(pattern, image_name):
            return True
        self.errors.append(
            f'Invalid image name format: "{image_name}". Must contain only lowercase letters, digits, periods, hyphens, and underscores',
        )
        return False

    def validate_docker_tag(self, tag: str) -> bool:
        """Validate Docker tag format."""
        if not tag or tag.strip() == "":
            self.errors.append("Docker tag cannot be empty")
            return False

        # Docker tag pattern (semantic version, latest, or valid Docker tag)
        pattern = r"^(v?[0-9]+\.[0-9]+\.[0-9]+(-[\w.]+)?(\+[\w.]+)?|latest|[a-zA-Z][-a-zA-Z0-9._]{0,127})$"
        if re.match(pattern, tag):
            return True
        self.errors.append(
            f'Invalid tag format: "{tag}". Expected semantic version, "latest", or valid Docker tag',
        )
        return False

    def validate_architectures(self, architectures: str) -> bool:
        """Validate Docker architectures."""
        if not architectures or architectures.strip() == "":
            return True

        valid_archs = [
            "linux/amd64",
            "linux/arm64",
            "linux/arm/v7",
            "linux/arm/v6",
            "linux/386",
            "linux/ppc64le",
            "linux/s390x",
        ]
        archs = [arch.strip() for arch in architectures.split(",")]

        for arch in archs:
            if arch not in valid_archs:
                self.errors.append(
                    f'Invalid architecture: "{arch}". Supported: {", ".join(valid_archs)}',
                )
                return False

        return True

    def validate_numeric_range(
        self,
        value: str,
        min_val: int = 0,
        max_val: int = 100,
        name: str = "value",
    ) -> bool:
        """Validate numeric inputs with range checking."""
        if not value or value.strip() == "":
            return True

        try:
            num = int(value)
            if min_val <= num <= max_val:
                return True
            self.errors.append(
                f"Invalid {name}: {num}. Must be between {min_val} and {max_val}",
            )
            return False
        except ValueError:
            self.errors.append(f'Invalid {name}: "{value}". Must be a number')
            return False

    def validate_file_path(self, path: str, name: str = "path") -> bool:
        """Validate file paths for security."""
        if not path or path.strip() == "":
            return True

        # Check for path traversal
        if ".." in path or path.startswith("/"):
            self.errors.append(f'Invalid {name}: "{path}". Path traversal not allowed')
            return False

        return True

    def validate_branch_name(self, branch: str) -> bool:
        """Validate git branch name."""
        if not branch or branch.strip() == "":
            return True

        # Check for command injection
        injection_patterns = [";", "&&", "|"]
        for pattern in injection_patterns:
            if pattern in branch:
                self.errors.append(
                    f'Invalid branch name: "{branch}". Command injection patterns not allowed',
                )
                return False

        # Check for invalid git characters
        if ".." in branch or "~" in branch or "^" in branch:
            self.errors.append(
                f'Invalid branch name: "{branch}". Invalid git branch name characters',
            )
            return False

        # Check for valid characters
        if not re.match(r"^[a-zA-Z0-9/_.-]+$", branch):
            self.errors.append(f'Invalid branch name: "{branch}". Contains invalid characters')
            return False

        # Check for invalid start/end characters
        if (
            branch.startswith(".")
            or branch.endswith(".")
            or branch.startswith("-")
            or branch.startswith("/")
            or branch.endswith("/")
        ):
            self.errors.append(
                f'Invalid branch name: "{branch}". Cannot start/end with ".", "-", or "/"',
            )
            return False

        return True

    def validate_boolean(self, value: str, name: str = "boolean") -> bool:
        """Validate boolean inputs."""
        if not value or value.strip() == "":
            return True

        if value.lower() not in ["true", "false"]:
            self.errors.append(f'Invalid {name}: "{value}". Must be "true" or "false"')
            return False

        return True

    def validate_prefix(self, prefix: str) -> bool:
        """Validate release prefix format."""
        if not prefix or prefix.strip() == "":
            return True

        # Only alphanumeric, dots, underscores, and hyphens
        if re.match(r"^[a-zA-Z0-9_.-]*$", prefix):
            return True
        self.errors.append(
            f'Invalid prefix format: "{prefix}". Only alphanumeric characters, dots, underscores, and hyphens allowed',
        )
        return False

    def validate_security_patterns(self, value: str, name: str = "input") -> bool:
        """Check for common security injection patterns."""
        if not value or value.strip() == "":
            return True

        # Common injection patterns
        injection_patterns = [
            r";\s*(rm|del|format|shutdown|reboot|cat|ls|whoami|id|pwd)",
            r"&&\s*(rm|del|format|shutdown|reboot|cat|ls|whoami|id|pwd)",
            r"\|\s*(rm|del|format|shutdown|reboot|cat|ls|whoami|id|pwd)",
            r"`[^`]*`",  # Command substitution
            r"\$\([^)]*\)",  # Command substitution
        ]

        for pattern in injection_patterns:
            if re.search(pattern, value, re.IGNORECASE):
                self.errors.append(
                    f'Potential security injection pattern detected in {name}: "{value}"',
                )
                return False

        return True

    def validate_with_rules(self, inputs: dict) -> bool:
        """Apply validation based on loaded rules."""
        if not self.rules:
            return True  # No rules loaded, skip rules-based validation

        valid = True
        conventions = self.rules.get("conventions", {})
        overrides = self.rules.get("overrides", {})
        required_inputs = self.rules.get("required_inputs", [])

        # Validate required inputs are present
        for req_input in required_inputs:
            if not inputs.get(req_input, "").strip():
                self.errors.append(f"Required input '{req_input}' is missing or empty")
                valid = False

        # Apply convention-based validation
        for input_name, value in inputs.items():
            # Skip if explicitly overridden to null
            if input_name in overrides and overrides[input_name] is None:
                continue

            # Get validator from conventions or overrides
            validator = overrides.get(input_name) or conventions.get(input_name)
            if not validator:
                continue  # No specific validation defined

            # Apply appropriate validation based on convention
            required = input_name in required_inputs

            if validator == "github_token":
                valid &= self.validate_github_token(value, required)
            elif validator == "namespace_with_lookahead":
                valid &= self.validate_namespace_with_lookahead(value)
            elif validator == "email":
                valid &= self.validate_email(value)
            elif validator == "username":
                valid &= self.validate_username(value)
            elif validator == "docker_image_name":
                valid &= self.validate_docker_image_name(value)
            elif validator == "docker_tag":
                valid &= self.validate_docker_tag(value)
            elif validator == "docker_architectures":
                valid &= self.validate_architectures(value)
            elif validator == "file_path":
                valid &= self.validate_file_path(value, input_name)
            elif validator == "branch_name":
                valid &= self.validate_branch_name(value)
            elif validator == "boolean":
                valid &= self.validate_boolean(value, input_name)
            elif validator == "prefix":
                valid &= self.validate_prefix(value)
            elif validator.startswith("dotnet_version"):
                valid &= self.validate_version(value, "dotnet")
            elif validator.startswith("terraform_version"):
                valid &= self.validate_version(value, "terraform")
            elif validator.startswith("semantic_version"):
                valid &= self.validate_version(value, "semantic")
            elif validator.startswith("node_version"):
                valid &= self.validate_version(value, "node")
            elif validator.startswith("calver_version"):
                valid &= self.validate_calver(value)
            elif validator.startswith("flexible_version"):
                valid &= self.validate_calver_or_semver(value)
            elif validator.startswith("numeric_range_"):
                # Parse range from validator name: numeric_range_1_10 -> min=1, max=10
                parts = validator.split("_")
                if len(parts) >= 4:
                    min_val = int(parts[2])
                    max_val = int(parts[3])
                    valid &= self.validate_numeric_range(value, min_val, max_val, input_name)

        return valid

    def validate_for_action_type(self) -> bool:
        """Main validation method that routes to action-specific validation."""
        valid = True

        # Get all environment variables for inputs
        inputs = {
            key[6:].lower().replace("_", "-"): value
            for key, value in os.environ.items()
            if key.startswith("INPUT_") and key != "INPUT_ACTION_TYPE"
        }

        # Try rules-based validation first
        if self.rules:
            print("::debug::Using rules-based validation")
            valid &= self.validate_with_rules(inputs)
        else:
            print("::debug::Using hardcoded validation logic")
            # Fallback to hardcoded action-specific validation
            if self.action_type == "csharp_publish":
                valid &= self.validate_github_token(inputs.get("token", ""), required=True)
                valid &= self.validate_namespace_with_lookahead(inputs.get("namespace", ""))
                valid &= self.validate_version(inputs.get("dotnet-version", ""), "dotnet")

            elif self.action_type == "docker_build":
                valid &= self.validate_docker_image_name(inputs.get("image-name", ""))
                valid &= self.validate_docker_tag(inputs.get("tag", ""))
                valid &= self.validate_architectures(inputs.get("architectures", ""))
                valid &= self.validate_file_path(inputs.get("dockerfile", ""), "dockerfile")
                valid &= self.validate_version(inputs.get("buildx-version", ""), "semantic")
                valid &= self.validate_numeric_range(
                    inputs.get("parallel-builds", ""),
                    0,
                    16,
                    "parallel-builds",
                )

            elif self.action_type in ["eslint_fix", "pr_lint", "pre_commit"]:
                valid &= self.validate_github_token(inputs.get("token", ""), required=True)
                valid &= self.validate_email(inputs.get("email", ""))
                valid &= self.validate_username(inputs.get("username", ""))
                valid &= self.validate_numeric_range(
                    inputs.get("max-retries", ""),
                    1,
                    10,
                    "max-retries",
                )

            elif self.action_type == "pre_commit":
                valid &= self.validate_file_path(
                    inputs.get("pre-commit-config", ""),
                    "pre-commit-config",
                )
                valid &= self.validate_branch_name(inputs.get("base-branch", ""))
                # Validate file extension
                config_file = inputs.get("pre-commit-config", "")
                if config_file and not (
                    config_file.endswith(".yaml") or config_file.endswith(".yml")
                ):
                    self.errors.append(
                        f'Invalid pre-commit-config: "{config_file}". Must be a .yaml or .yml file',
                    )
                    valid = False

            elif self.action_type == "terraform_lint_fix":
                valid &= self.validate_github_token(inputs.get("token", ""))
                valid &= self.validate_version(inputs.get("terraform-version", ""), "terraform")
                valid &= self.validate_version(inputs.get("tflint-version", ""), "terraform")
                valid &= self.validate_numeric_range(
                    inputs.get("max-retries", ""),
                    1,
                    10,
                    "max-retries",
                )

            elif self.action_type == "node_setup":
                valid &= self.validate_version(inputs.get("default-version", ""), "node")
                valid &= self.validate_version(inputs.get("force-version", ""), "node")
                valid &= self.validate_numeric_range(
                    inputs.get("max-retries", ""),
                    1,
                    10,
                    "max-retries",
                )

            elif self.action_type == "compress_images":
                valid &= self.validate_github_token(inputs.get("token", ""))
                valid &= self.validate_numeric_range(
                    inputs.get("image-quality", ""),
                    1,
                    100,
                    "image-quality",
                )
                valid &= self.validate_numeric_range(
                    inputs.get("png-quality", ""),
                    1,
                    100,
                    "png-quality",
                )

            elif self.action_type == "release_monthly":
                valid &= self.validate_github_token(inputs.get("token", ""), required=True)
                valid &= self.validate_boolean(inputs.get("dry-run", ""), "dry-run")
                valid &= self.validate_prefix(inputs.get("prefix", ""))

        # Apply security validation to all inputs
        for name, value in inputs.items():
            valid &= self.validate_security_patterns(value, name)

        return valid


if __name__ == "__main__":
    # Main execution block for GitHub Actions
    try:
        validator = ActionValidator()
        if validator.validate_for_action_type():
            print("::notice::All input validation checks passed")
            print("status=success", file=open(os.environ["GITHUB_OUTPUT"], "a"))
        else:
            print("::error::Input validation failed")
            for error in validator.errors:
                print(f"::error::{error}")
            print("status=failure", file=open(os.environ["GITHUB_OUTPUT"], "a"))
            print(
                f"error={'; '.join(validator.errors)}",
                file=open(os.environ["GITHUB_OUTPUT"], "a"),
            )
            sys.exit(1)
    except Exception as e:
        print(f"::error::Validation script error: {e!s}")
        print("status=failure", file=open(os.environ["GITHUB_OUTPUT"], "a"))
        print(
            f"error=Validation script error: {e!s}",
            file=open(os.environ["GITHUB_OUTPUT"], "a"),
        )
        sys.exit(1)
