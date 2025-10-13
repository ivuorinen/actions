"""Network-related validators for URLs, emails, and other network inputs."""

from __future__ import annotations

import re

from .base import BaseValidator


class NetworkValidator(BaseValidator):
    """Validator for network-related inputs like URLs, emails, scopes."""

    def validate_inputs(self, inputs: dict[str, str]) -> bool:
        """Validate network-related inputs."""
        valid = True

        for input_name, value in inputs.items():
            if "email" in input_name:
                valid &= self.validate_email(value, input_name)
            elif "url" in input_name or ("registry" in input_name and "url" in input_name):
                valid &= self.validate_url(value, input_name)
            elif "scope" in input_name:
                valid &= self.validate_scope(value, input_name)
            elif "username" in input_name or "user" in input_name:
                valid &= self.validate_username(value)

        return valid

    def get_required_inputs(self) -> list[str]:
        """Network validators typically don't define required inputs."""
        return []

    def get_validation_rules(self) -> dict:
        """Return network validation rules."""
        return {
            "email": "Valid email format",
            "url": "Valid URL starting with http:// or https://",
            "scope": "NPM scope format (@organization)",
            "username": "Valid username without injection patterns",
        }

    def validate_email(self, email: str, name: str = "email") -> bool:
        """Validate email format.

        Args:
            email: The email address to validate
            name: The input name for error messages

        Returns:
            True if valid, False otherwise
        """
        if not email or email.strip() == "":
            return True  # Email is often optional

        # Allow GitHub Actions expressions
        if self.is_github_expression(email):
            return True

        # Check for spaces
        if " " in email:
            self.add_error(f'Invalid {name}: "{email}". Spaces not allowed in email')
            return False

        # Check @ symbol
        at_count = email.count("@")
        if at_count != 1:
            self.add_error(
                f'Invalid {name}: "{email}". Expected exactly one @ symbol, found {at_count}',
            )
            return False

        local, domain = email.split("@")

        # Validate local part
        if not local:
            self.add_error(f'Invalid {name}: "{email}". Missing local part before @')
            return False

        # Validate domain
        if not domain:
            self.add_error(f'Invalid {name}: "{email}". Missing domain after @')
            return False

        # Domain must have at least one dot
        if "." not in domain:
            self.add_error(f'Invalid {name}: "{email}". Domain must contain a dot')
            return False

        # Check for dots at start/end of domain
        if domain.startswith(".") or domain.endswith("."):
            self.add_error(f'Invalid {name}: "{email}". Domain cannot start/end with dot')
            return False

        # Check for consecutive dots
        if ".." in email:
            self.add_error(f'Invalid {name}: "{email}". Cannot contain consecutive dots')
            return False

        # Basic character validation
        email_pattern = r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"
        if not re.match(email_pattern, email):
            self.add_error(f'Invalid {name}: "{email}". Invalid email format')
            return False

        return True

    def validate_url(self, value: str, name: str = "url") -> bool:
        """Validate URL format.

        Args:
            value: The URL to validate
            name: The input name for error messages

        Returns:
            True if valid, False otherwise
        """
        if not value or value.strip() == "":
            self.add_error(f"{name} cannot be empty")
            return False

        # Allow GitHub Actions expressions
        if self.is_github_expression(value):
            return True

        # Must start with http:// or https://
        if not (value.startswith(("http://", "https://"))):
            self.add_error(f'Invalid {name}: "{value}". Must start with http:// or https://')
            return False

        # Check for obvious injection patterns
        injection_patterns = [";", "&", "|", "`", "$(", "${"]
        for pattern in injection_patterns:
            if pattern in value:
                self.add_error(f'Potential security injection in {name}: contains "{pattern}"')
                return False

        # Basic URL validation (with optional port)
        url_pattern = r"^https?://[\w.-]+(?:\.[a-zA-Z]{2,})?(?::\d{1,5})?(?:[/?#][^\s]*)?$"
        if not re.match(url_pattern, value):
            self.add_error(f'Invalid {name}: "{value}". Invalid URL format')
            return False

        return True

    def validate_scope(self, value: str, name: str = "scope") -> bool:
        """Validate scope format (e.g., NPM scope).

        Args:
            value: The scope to validate
            name: The input name for error messages

        Returns:
            True if valid, False otherwise
        """
        if not value or value.strip() == "":
            return True  # Scope is optional

        # NPM scope should start with @
        if not value.startswith("@"):
            self.add_error(f'Invalid {name}: "{value}". Must start with @')
            return False

        # Remove @ and validate the rest
        scope_name = value[1:]

        if not scope_name:
            self.add_error(f'Invalid {name}: "{value}". Scope name cannot be empty')
            return False

        # Must start with lowercase letter
        if not scope_name[0].islower():
            self.add_error(
                f'Invalid {name}: "{value}". Scope name must start with lowercase letter',
            )
            return False

        # Check for valid scope characters
        if not re.match(r"^[a-z][a-z0-9._~-]*$", scope_name):
            self.add_error(
                f'Invalid {name}: "{value}". '
                "Scope can only contain lowercase letters, numbers, dots, "
                "underscores, tildes, and hyphens",
            )
            return False

        # Check for security patterns
        return self.validate_security_patterns(value, name)

    def validate_username(self, username: str, name: str = "username") -> bool:
        """Validate username with injection protection.

        Args:
            username: The username to validate
            name: The input name for error messages

        Returns:
            True if valid, False otherwise
        """
        if not username or username.strip() == "":
            return True  # Username is often optional

        # Check for command injection patterns
        injection_patterns = [";", "&&", "||", "|", "`", "$(", "${"]
        for pattern in injection_patterns:
            if pattern in username:
                self.add_error(
                    f'Invalid {name}: "{username}". Command injection patterns not allowed',
                )
                return False

        # Check length (GitHub username limit)
        if len(username) > 39:
            self.add_error(
                f"{name.capitalize()} too long: {len(username)} characters. "
                "GitHub usernames max 39 characters",
            )
            return False

        # GitHub username validation (also allow underscores)
        if not re.match(r"^[a-zA-Z0-9](?:[a-zA-Z0-9_-]*[a-zA-Z0-9])?$", username):
            self.add_error(
                f'Invalid {name}: "{username}". '
                "Must start and end with alphanumeric, can contain hyphens and underscores",
            )
            return False

        return True

    def validate_registry_url(self, value: str, name: str = "registry-url") -> bool:
        """Validate registry URL format.

        Args:
            value: The registry URL to validate
            name: The input name for error messages

        Returns:
            True if valid, False otherwise
        """
        if not value or value.strip() == "":
            return True  # Registry URL is often optional

        # Common registry URLs
        known_registries = [
            "https://registry.npmjs.org/",
            "https://npm.pkg.github.com/",
            "https://registry.yarnpkg.com/",
            "https://pypi.org/simple/",
            "https://test.pypi.org/simple/",
            "https://rubygems.org/",
            "https://nuget.org/api/v2/",
        ]

        # Check if it's a known registry
        for registry in known_registries:
            if value.startswith(registry):
                return True

        # Otherwise validate as general URL
        return self.validate_url(value, name)

    def validate_repository_url(self, value: str, name: str = "repository-url") -> bool:
        """Validate repository URL format.

        Args:
            value: The repository URL to validate
            name: The input name for error messages

        Returns:
            True if valid, False otherwise
        """
        if not value or value.strip() == "":
            return True  # Repository URL is often optional

        # Common repository URL patterns
        repo_patterns = [
            r"^https://github\.com/[a-zA-Z0-9-]+/[a-zA-Z0-9._-]+(?:\.git)?$",
            r"^https://gitlab\.com/[a-zA-Z0-9-]+/[a-zA-Z0-9._-]+(?:\.git)?$",
            r"^https://bitbucket\.org/[a-zA-Z0-9-]+/[a-zA-Z0-9._-]+(?:\.git)?$",
        ]

        for pattern in repo_patterns:
            if re.match(pattern, value):
                return True

        # Otherwise validate as general URL
        return self.validate_url(value, name)

    def validate_hostname(self, hostname: str, name: str = "hostname") -> bool:
        """Validate hostname format.

        Args:
            hostname: The hostname to validate
            name: The input name for error messages

        Returns:
            True if valid, False otherwise
        """
        if not hostname or hostname.strip() == "":
            return True  # Hostname is often optional

        # Check length (max 253 characters)
        if len(hostname) > 253:
            self.add_error(f'Invalid {name}: "{hostname}". Hostname too long (max 253 characters)')
            return False

        # Check for valid hostname pattern
        # Each label can be 1-63 chars, alphanumeric and hyphens, not starting/ending with hyphen
        hostname_pattern = r"^(?!-)(?:[a-zA-Z0-9-]{1,63}(?<!-)\.)*[a-zA-Z0-9-]{1,63}(?<!-)$"

        if re.match(hostname_pattern, hostname):
            return True

        # Also allow localhost and IPv6 loopback
        if hostname in ["localhost", "::1", "::"]:
            return True

        # Also check if it's an IP address (which can be a valid hostname)
        if self.validate_ip_address(hostname):
            return True

        self.add_error(f'Invalid {name}: "{hostname}". Must be a valid hostname')
        return False

    def validate_ip_address(self, ip: str, name: str = "ip_address") -> bool:
        """Validate IP address (IPv4 or IPv6).

        Args:
            ip: The IP address to validate
            name: The input name for error messages

        Returns:
            True if valid, False otherwise
        """
        if not ip or ip.strip() == "":
            return True  # IP address is often optional

        # IPv4 pattern
        ipv4_pattern = (
            r"^(?:(?:25[0-5]|2[0-4]\d|[01]?\d\d?)\.){3}"
            r"(?:25[0-5]|2[0-4]\d|[01]?\d\d?)$"
        )
        if re.match(ipv4_pattern, ip):
            return True

        # Simplified IPv6 pattern (full validation is complex)
        # This covers most common cases: full form, loopback (::1), and unspecified (::)
        ipv6_pattern = r"^(?:(?:[0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}|::1|::)$"
        if re.match(ipv6_pattern, ip):
            return True

        # Allow compressed IPv6
        if "::" in ip:
            # Very basic check for compressed IPv6
            parts = ip.split("::")
            if len(parts) == 2:
                # Check if parts look like hex
                for part in parts:
                    if part and not all(c in "0123456789abcdefABCDEF:" for c in part):
                        self.add_error(f'Invalid {name}: "{ip}". Not a valid IP address')
                        return False
                return True

        self.add_error(f'Invalid {name}: "{ip}". Must be a valid IPv4 or IPv6 address')
        return False

    def validate_port(self, port: str, name: str = "port") -> bool:
        """Validate port number.

        Args:
            port: The port number to validate (as string)
            name: The input name for error messages

        Returns:
            True if valid, False otherwise
        """
        if not port or port.strip() == "":
            return True  # Port is often optional

        # Check if it's a number
        try:
            port_num = int(port)
        except ValueError:
            self.add_error(f'Invalid {name}: "{port}". Port must be a number')
            return False

        # Check valid range (1-65535)
        if port_num < 1 or port_num > 65535:
            self.add_error(f"Invalid {name}: {port}. Port must be between 1 and 65535")
            return False

        return True
