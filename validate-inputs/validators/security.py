"""Security validator for detecting injection patterns and security issues."""

from __future__ import annotations

import re
from typing import ClassVar

from .base import BaseValidator


class SecurityValidator(BaseValidator):
    """Validator for security-related checks across all inputs."""

    # Common injection patterns to detect
    INJECTION_PATTERNS: ClassVar[list[tuple[str, str]]] = [
        (r";\s*rm\s+-rf", "rm -rf command"),
        (r";\s*del\s+", "del command"),
        (r"&&\s*curl\s+", "curl command injection"),
        (r"&&\s*wget\s+", "wget command injection"),
        (r"\|\s*sh\b", "pipe to shell"),
        (r"\|\s*bash\b", "pipe to bash"),
        (r"`[^`]+`", "command substitution"),
        (r"\$\([^)]+\)", "command substitution"),
        (r"\${[^}]+}", "variable expansion"),
        (r"<script[^>]*>", "script tag injection"),
        (r"javascript:", "javascript protocol"),
        (r"data:text/html", "data URI injection"),
    ]

    def validate_inputs(self, inputs: dict[str, str]) -> bool:
        """Validate all inputs for security issues."""
        valid = True

        for input_name, value in inputs.items():
            # Skip empty values
            if not value or not value.strip():
                continue

            # Apply security validation to all inputs
            valid &= self.validate_security_patterns(value, input_name)

            # Additional checks for specific input types
            if "path" in input_name or "file" in input_name:
                valid &= self.validate_path_security(value, input_name)
            elif "url" in input_name or "uri" in input_name:
                valid &= self.validate_url_security(value, input_name)
            elif "command" in input_name or "cmd" in input_name:
                valid &= self.validate_command_security(value, input_name)

        return valid

    def get_required_inputs(self) -> list[str]:
        """Security validator doesn't define required inputs."""
        return []

    def get_validation_rules(self) -> dict:
        """Return security validation rules."""
        return {
            "injection_patterns": "Command injection detection",
            "path_traversal": "Path traversal prevention",
            "xss_prevention": "Cross-site scripting prevention",
        }

    def validate_injection_patterns(self, value: str, name: str = "input") -> bool:
        """Check for advanced injection patterns.

        Args:
            value: The value to check
            name: The input name for error messages

        Returns:
            True if no injection patterns found, False otherwise
        """
        if not value or value.strip() == "":
            return True

        # Check against known injection patterns
        for pattern, description in self.INJECTION_PATTERNS:
            if re.search(pattern, value, re.IGNORECASE):
                self.add_error(f"Security issue in {name}: detected {description}")
                return False

        return True

    def validate_url_security(self, url: str, name: str = "url") -> bool:
        """Validate URL for security issues.

        Args:
            url: The URL to validate
            name: The input name for error messages

        Returns:
            True if secure, False otherwise
        """
        if not url or url.strip() == "":
            return True

        # Check for javascript: protocol
        if url.lower().startswith("javascript:"):
            self.add_error(f"Security issue in {name}: javascript: protocol not allowed")
            return False

        # Check for data: URI with HTML
        if url.lower().startswith("data:") and "text/html" in url.lower():
            self.add_error(f"Security issue in {name}: data:text/html URIs not allowed")
            return False

        # Check for file: protocol
        if url.lower().startswith("file:"):
            self.add_error(f"Security issue in {name}: file: protocol not allowed")
            return False

        return True

    def validate_command_security(self, command: str, name: str = "command") -> bool:
        """Validate command for security issues.

        Args:
            command: The command to validate
            name: The input name for error messages

        Returns:
            True if secure, False otherwise
        """
        if not command or command.strip() == "":
            return True

        # Dangerous commands that should not be allowed
        dangerous_commands = [
            "rm -rf",
            "rm -fr",
            "format c:",
            "del /f /s /q",
            "shutdown",
            "reboot",
            ":(){:|:&};:",  # Fork bomb
            "dd if=/dev/zero",
            "dd if=/dev/random",  # Also dangerous
            "mkfs",
            "chmod -R 777",  # Dangerous permission change
            "chmod 777",
            "chown -R",  # Dangerous ownership change
        ]

        command_lower = command.lower()
        for dangerous in dangerous_commands:
            if dangerous.lower() in command_lower:
                self.add_error(
                    f"Security issue in {name}: dangerous command pattern '{dangerous}' detected",
                )
                return False

        # Check for base64 encoded commands (often used to hide malicious code)
        if re.search(r"base64\s+-d|base64\s+--decode", command, re.IGNORECASE):
            self.add_error(f"Security issue in {name}: base64 decode operations not allowed")
            return False

        return True

    def validate_content_security(self, content: str, name: str = "content") -> bool:
        """Validate content for XSS and injection.

        Args:
            content: The content to validate
            name: The input name for error messages

        Returns:
            True if secure, False otherwise
        """
        if not content or content.strip() == "":
            return True

        # Check for script tags (match any content between script and >)
        if re.search(r"<script[^>]*>.*?</script[^>]*>", content, re.IGNORECASE | re.DOTALL):
            self.add_error(f"Security issue in {name}: script tags not allowed")
            return False

        # Check for event handlers
        event_handlers = [
            "onclick",
            "onload",
            "onerror",
            "onmouseover",
            "onfocus",
            "onblur",
            "onchange",
            "onsubmit",
        ]
        for handler in event_handlers:
            if re.search(rf"\b{handler}\s*=", content, re.IGNORECASE):
                self.add_error(f"Security issue in {name}: event handler '{handler}' not allowed")
                return False

        # Check for iframe injection
        if re.search(r"<iframe[^>]*>", content, re.IGNORECASE):
            self.add_error(f"Security issue in {name}: iframe tags not allowed")
            return False

        return True

    def validate_prefix_security(self, prefix: str, name: str = "prefix") -> bool:
        """Validate prefix for security issues.

        Args:
            prefix: The prefix to validate
            name: The input name for error messages

        Returns:
            True if secure, False otherwise
        """
        if not prefix or prefix.strip() == "":
            return True

        # Only alphanumeric, dots, underscores, and hyphens
        if not re.match(r"^[a-zA-Z0-9_.-]*$", prefix):
            self.add_error(f"Security issue in {name}: '{prefix}' contains invalid characters")
            return False

        return True

    def validate_no_injection(self, value: str, name: str = "input") -> bool:
        """Comprehensive injection detection.

        Args:
            value: The value to check
            name: The input name for error messages

        Returns:
            True if no injection patterns found, False otherwise
        """
        if not value or value.strip() == "":
            return True

        # Allow GitHub expressions (they're safe in Actions context)
        if self.is_github_expression(value):
            return True

        # Check for command injection patterns
        if not self.validate_security_patterns(value, name):
            return False

        # Check for single & (background execution)
        if re.search(r"(?<![&])&(?![&])", value):
            self.add_error(f"Background execution pattern '&' detected in {name}")
            return False

        # Check for advanced injection patterns
        if not self.validate_injection_patterns(value, name):
            return False

        # Check for SQL injection patterns
        sql_patterns = [
            r"'\s*OR\s+'[^']*'\s*=\s*'[^']*",  # ' OR '1'='1
            r'"\s*OR\s+"[^"]*"\s*=\s*"[^"]*',  # " OR "1"="1
            r"'\s*OR\s+\d+\s*=\s*\d+",  # ' OR 1=1
            r";\s*DROP\s+TABLE",  # ; DROP TABLE
            r";\s*DELETE\s+FROM",  # ; DELETE FROM
            r"UNION\s+SELECT",  # UNION SELECT
            r"--\s*$",  # SQL comment at end
            r";\s*EXEC\s+",  # ; EXEC
            r"xp_cmdshell",  # SQL Server command execution
        ]

        for pattern in sql_patterns:
            if re.search(pattern, value, re.IGNORECASE):
                self.add_error(f"SQL injection pattern detected in {name}")
                return False

        # Check for script injection patterns
        return self.validate_content_security(value, name)

    def validate_safe_command(self, command: str, name: str = "command") -> bool:
        """Validate that a command is safe to execute.

        Args:
            command: The command to validate
            name: The input name for error messages

        Returns:
            True if command appears safe, False otherwise
        """
        if not command or command.strip() == "":
            return True

        # Allow GitHub expressions (they're safe in Actions context)
        if self.is_github_expression(command):
            return True

        # Use existing command security validation
        if not self.validate_command_security(command, name):
            return False

        # Check for dangerous redirect to device files
        if re.search(r">\s*/dev/", command):
            self.add_error(f"Security issue in {name}: redirect to device file not allowed")
            return False

        # Check for filesystem creation commands
        if re.search(r"\bmkfs", command, re.IGNORECASE):
            self.add_error(f"Security issue in {name}: filesystem creation commands not allowed")
            return False

        # Additional checks for safe commands
        # Block shell metacharacters that could be dangerous
        dangerous_chars = ["&", "|", ";", "$", "`", "\\", "!", "{", "}", "[", "]", "(", ")"]
        for char in dangerous_chars:
            if char in command:
                # Allow some safe uses
                if char == "&" and "&&" not in command and "&>" not in command:
                    continue

                self.add_error(f"Potentially dangerous character '{char}' in {name}")
                return False

        return True

    def validate_safe_environment_variable(self, value: str, name: str = "env_var") -> bool:
        """Validate environment variable value for security.

        Args:
            value: The environment variable value
            name: The input name for error messages

        Returns:
            True if safe, False otherwise
        """
        if not value or value.strip() == "":
            return True

        # Check for command substitution in env vars
        if "$(" in value or "`" in value or "${" in value:
            self.add_error(f"Command substitution not allowed in environment variable {name}")
            return False

        # Check for newlines (could be used to inject multiple commands)
        if "\n" in value or "\r" in value:
            self.add_error(f"Newlines not allowed in environment variable {name}")
            return False

        # Check for null bytes (could be used for string termination attacks)
        if "\x00" in value:
            self.add_error(f"Null bytes not allowed in environment variable {name}")
            return False

        # Check for shell special chars that might cause issues
        if re.search(r"[;&|]", value) and re.search(
            r";\s*(rm|del|format|shutdown|reboot)",
            value,
            re.IGNORECASE,
        ):
            self.add_error(f"Dangerous command pattern in environment variable {name}")
            return False

        return True

    # Alias for test compatibility
    def validate_safe_env_var(self, value: str, name: str = "env_var") -> bool:
        """Alias for validate_safe_environment_variable for test compatibility."""
        return self.validate_safe_environment_variable(value, name)

    def validate_no_secrets(self, value: str, name: str = "input") -> bool:
        """Validate that no secrets or sensitive data are present.

        Args:
            value: The value to check
            name: The input name for error messages

        Returns:
            True if no secrets detected, False otherwise
        """
        if not value or value.strip() == "":
            return True

        # Check for GitHub tokens
        github_token_patterns = [
            r"ghp_[a-zA-Z0-9]{36}",  # GitHub personal access token
            r"gho_[a-zA-Z0-9]{36}",  # GitHub OAuth token
            r"ghu_[a-zA-Z0-9]{36}",  # GitHub user token
            r"ghs_[a-zA-Z0-9]{36}",  # GitHub server token
            r"ghr_[a-zA-Z0-9]{36}",  # GitHub refresh token
            r"github_pat_[a-zA-Z0-9_]{48,}",  # GitHub fine-grained PAT
        ]

        for pattern in github_token_patterns:
            if re.search(pattern, value):
                self.add_error(f"Potential GitHub token detected in {name}")
                return False

        # Check for API key patterns
        api_key_patterns = [
            r"api[_-]?key\s*[:=]\s*['\"]?[a-zA-Z0-9]{20,}",  # Generic API key
            r"secret[_-]?key\s*[:=]\s*['\"]?[a-zA-Z0-9]{20,}",  # Secret key
            r"access[_-]?key\s*[:=]\s*['\"]?[a-zA-Z0-9]{20,}",  # Access key
        ]

        for pattern in api_key_patterns:
            if re.search(pattern, value, re.IGNORECASE):
                self.add_error(f"Potential API key detected in {name}")
                return False

        # Check for password patterns
        password_patterns = [
            r"password\s*[:=]\s*['\"]?[^\s'\"]{8,}",  # Password assignment
            r"passwd\s*[:=]\s*['\"]?[^\s'\"]{8,}",  # Passwd assignment
            r"pwd\s*[:=]\s*['\"]?[^\s'\"]{8,}",  # Pwd assignment
        ]

        for pattern in password_patterns:
            if re.search(pattern, value, re.IGNORECASE):
                self.add_error(f"Potential password detected in {name}")
                return False

        # Check for private key markers
        private_key_markers = [
            "-----BEGIN RSA PRIVATE KEY-----",
            "-----BEGIN PRIVATE KEY-----",
            "-----BEGIN OPENSSH PRIVATE KEY-----",
            "-----BEGIN DSA PRIVATE KEY-----",
            "-----BEGIN EC PRIVATE KEY-----",
        ]

        for marker in private_key_markers:
            if marker in value:
                self.add_error(f"Private key detected in {name}")
                return False

        # Check for Base64 encoded secrets (common for credentials)
        # Look for long base64 strings that might be credentials
        # and if it contains words like secret, key, token, password
        if re.search(r"[A-Za-z0-9+/]{40,}={0,2}", value) or (
            re.search(r"[A-Za-z0-9+/]{40,}={0,2}", value)
            and re.search(r"(secret|key|token|password|credential)", value, re.IGNORECASE)
        ):
            self.add_error(f"Potential encoded secret detected in {name}")
            return False

        return True
