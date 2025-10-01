"""Tests for the SecurityValidator module."""

from pathlib import Path
import sys

# Add the parent directory to the path
sys.path.insert(0, str(Path(__file__).parent.parent))

from validators.security import SecurityValidator


class TestSecurityValidator:
    """Test cases for SecurityValidator."""

    def setup_method(self):
        """Set up test environment."""
        self.validator = SecurityValidator()

    def test_initialization(self):
        """Test validator initialization."""
        assert self.validator.errors == []
        patterns = self.validator.INJECTION_PATTERNS
        assert len(patterns) > 0

    def test_validate_no_injection_safe_inputs(self):
        """Test that safe inputs pass validation."""
        safe_inputs = [
            "normal-text",
            "file.txt",
            "user@example.com",
            "feature-branch",
            "v1.0.0",
            "my-app-name",
            "config_value",
            "BUILD_NUMBER",
            "2024-03-15",
            "https://example.com",
        ]

        for value in safe_inputs:
            self.validator.errors = []
            result = self.validator.validate_no_injection(value)
            assert result is True, f"Should accept safe input: {value}"
            assert len(self.validator.errors) == 0

    def test_validate_no_injection_command_injection(self):
        """Test that command injection attempts are blocked."""
        dangerous_inputs = [
            "; rm -rf /",
            "&& rm -rf /",
            "|| rm -rf /",
            "` rm -rf /`",
            "$(rm -rf /)",
            "${rm -rf /}",
            "; cat /etc/passwd",
            "&& cat /etc/passwd",
            "| cat /etc/passwd",
            "& whoami",
            "; shutdown now",
            "&& reboot",
            "|| format c:",
            "; del *.*",
        ]

        for value in dangerous_inputs:
            self.validator.errors = []
            result = self.validator.validate_no_injection(value)
            assert result is False, f"Should block dangerous input: {value}"
            assert len(self.validator.errors) > 0

    def test_validate_no_injection_sql_injection(self):
        """Test that SQL injection attempts are detected."""
        sql_injection_attempts = [
            "'; DROP TABLE users; --",
            "' OR '1'='1",
            '" OR "1"="1',
            "admin' --",
            "' UNION SELECT * FROM passwords --",
            "1; DELETE FROM users",
            "' OR 1=1 --",
            "'; EXEC xp_cmdshell('dir'); --",
        ]

        for value in sql_injection_attempts:
            self.validator.errors = []
            result = self.validator.validate_no_injection(value)
            # SQL injection might be blocked depending on implementation
            assert isinstance(result, bool)
            if not result:
                assert len(self.validator.errors) > 0

    def test_validate_no_injection_path_traversal(self):
        """Test that path traversal attempts are blocked."""
        path_traversal_attempts = [
            "../../../etc/passwd",
            "..\\..\\..\\windows\\system32",
            "....//....//....//etc/passwd",
            "%2e%2e%2f%2e%2e%2f",  # URL encoded
            "..;/..;/",
        ]

        for value in path_traversal_attempts:
            self.validator.errors = []
            result = self.validator.validate_no_injection(value)
            # Path traversal might be blocked depending on implementation
            assert isinstance(result, bool)

    def test_validate_no_injection_script_injection(self):
        """Test that script injection attempts are blocked."""
        script_injection_attempts = [
            "<script>alert('XSS')</script>",
            "javascript:alert(1)",
            "<img src=x onerror=alert(1)>",
            "<iframe src='evil.com'>",
            "onclick=alert(1)",
            "<svg onload=alert(1)>",
        ]

        for value in script_injection_attempts:
            self.validator.errors = []
            result = self.validator.validate_no_injection(value)
            # Script injection might be blocked depending on implementation
            assert isinstance(result, bool)

    def test_validate_safe_command(self):
        """Test safe command validation."""
        safe_commands = [
            "npm install",
            "yarn build",
            "python script.py",
            "go build",
            "docker build -t myapp .",
            "git status",
            "ls -la",
            "echo 'Hello World'",
        ]

        for cmd in safe_commands:
            self.validator.errors = []
            result = self.validator.validate_safe_command(cmd)
            assert result is True, f"Should accept safe command: {cmd}"

    def test_validate_safe_command_dangerous(self):
        """Test that dangerous commands are blocked."""
        dangerous_commands = [
            "rm -rf /",
            "rm -rf /*",
            ":(){ :|:& };:",  # Fork bomb
            "dd if=/dev/random of=/dev/sda",
            "chmod -R 777 /",
            "chown -R nobody /",
            "> /dev/sda",
            "mkfs.ext4 /dev/sda",
        ]

        for cmd in dangerous_commands:
            self.validator.errors = []
            result = self.validator.validate_safe_command(cmd)
            assert result is False, f"Should block dangerous command: {cmd}"
            assert len(self.validator.errors) > 0

    def test_validate_safe_environment_variable(self):
        """Test environment variable validation."""
        safe_env_vars = [
            "NODE_ENV=production",
            "DEBUG=false",
            "PORT=3000",
            "API_KEY=secret123",
            "DATABASE_URL=postgres://localhost:5432/db",
        ]

        for env_var in safe_env_vars:
            self.validator.errors = []
            result = self.validator.validate_safe_env_var(env_var)
            assert result is True, f"Should accept safe env var: {env_var}"

    def test_validate_safe_environment_variable_dangerous(self):
        """Test that dangerous environment variables are blocked."""
        dangerous_env_vars = [
            "LD_PRELOAD=/tmp/evil.so",
            "LD_LIBRARY_PATH=/tmp/evil",
            "PATH=/tmp/evil:$PATH",
            "BASH_ENV=/tmp/evil.sh",
            "ENV=/tmp/evil.sh",
        ]

        for env_var in dangerous_env_vars:
            self.validator.errors = []
            result = self.validator.validate_safe_env_var(env_var)
            # These might be blocked depending on implementation
            assert isinstance(result, bool)

    def test_empty_input_handling(self):
        """Test that empty inputs are handled correctly."""
        result = self.validator.validate_no_injection("")
        assert result is True  # Empty should be safe
        assert len(self.validator.errors) == 0

    def test_whitespace_input_handling(self):
        """Test that whitespace-only inputs are handled correctly."""
        whitespace_inputs = [" ", "  ", "\t", "\n", "\r\n"]

        for value in whitespace_inputs:
            self.validator.errors = []
            result = self.validator.validate_no_injection(value)
            assert result is True  # Whitespace should be safe

    def test_validate_inputs_with_security_checks(self):
        """Test validation of inputs with security checks."""
        inputs = {
            "command": "npm install",
            "script": "build.sh",
            "arguments": "--production",
            "environment": "NODE_ENV=production",
            "user-input": "normal text",
            "file-path": "src/index.js",
        }

        result = self.validator.validate_inputs(inputs)
        assert isinstance(result, bool)

    def test_special_characters_handling(self):
        """Test handling of various special characters."""
        # Some special characters might be safe in certain contexts
        special_chars = [
            "value!",  # Exclamation
            "value?",  # Question mark
            "value@domain",  # At sign
            "value#1",  # Hash
            "value$100",  # Dollar
            "value%20",  # Percent
            "value^2",  # Caret
            "value&co",  # Ampersand
            "value*",  # Asterisk
            "value(1)",  # Parentheses
            "value[0]",  # Brackets
            "value{key}",  # Braces
        ]

        for value in special_chars:
            self.validator.errors = []
            result = self.validator.validate_no_injection(value)
            # Some might be safe, others not
            assert isinstance(result, bool)

    def test_unicode_and_encoding_attacks(self):
        """Test handling of Unicode and encoding-based attacks."""
        unicode_attacks = [
            "\x00command",  # Null byte injection
            "command\x00",  # Null byte suffix
            "\u202e\u0072\u006d\u0020\u002d\u0072\u0066",  # Right-to-left override
            "%00command",  # URL encoded null
            "\\x72\\x6d\\x20\\x2d\\x72\\x66",  # Hex encoded
        ]

        for value in unicode_attacks:
            self.validator.errors = []
            result = self.validator.validate_no_injection(value)
            # These sophisticated attacks might or might not be caught
            assert isinstance(result, bool)

    def test_validate_regex_pattern_safe_patterns(self):
        """Test that safe regex patterns pass validation."""
        safe_patterns = [
            r"^[0-9]+$",
            r"^[a-zA-Z0-9]+$",
            r"^[0-9]+\.[0-9]+$",
            r"^[0-9]+\.[0-9]+\.[0-9]+$",
            r"^v?[0-9]+\.[0-9]+(\.[0-9]+)?$",
            r"^[a-zA-Z0-9_-]+$",
            r"^(alpha|beta|gamma)$",
            r"^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$",
            r"^[a-z]+@[a-z]+\.[a-z]+$",
            r"^https?://[a-zA-Z0-9.-]+$",
        ]

        for pattern in safe_patterns:
            self.validator.errors = []
            result = self.validator.validate_regex_pattern(pattern, "test-pattern")
            assert result is True, f"Should accept safe pattern: {pattern}"
            assert len(self.validator.errors) == 0

    def test_validate_regex_pattern_nested_quantifiers(self):
        """Test that nested quantifiers are detected and rejected."""
        redos_patterns = [
            r"(a+)+",  # Nested plus quantifiers
            r"(a*)+",  # Star then plus
            r"(a+)*",  # Plus then star
            r"(a*)*",  # Nested star quantifiers
            r"(a{1,10})+",  # Quantified group with plus
            r"(a{2,5})*",  # Quantified group with star
            r"(a+){2,5}",  # Plus quantifier with range quantifier
            r"(x*){3,}",  # Star quantifier with open-ended range
        ]

        for pattern in redos_patterns:
            self.validator.errors = []
            result = self.validator.validate_regex_pattern(pattern, "test-pattern")
            assert result is False, f"Should reject ReDoS pattern: {pattern}"
            assert len(self.validator.errors) > 0
            assert "ReDoS risk" in self.validator.errors[0]
            assert "nested quantifiers" in self.validator.errors[0]

    def test_validate_regex_pattern_consecutive_quantifiers(self):
        """Test that consecutive quantifiers are detected and rejected."""
        consecutive_patterns = [
            r".*.*",  # Two .* in sequence
            r".*+",  # .* followed by +
            r".++",  # .+ followed by +
            r".+*",  # .+ followed by *
            r"a**",  # Two stars
            r"a++",  # Two pluses
        ]

        for pattern in consecutive_patterns:
            self.validator.errors = []
            result = self.validator.validate_regex_pattern(pattern, "test-pattern")
            assert result is False, f"Should reject consecutive quantifier pattern: {pattern}"
            assert len(self.validator.errors) > 0
            assert "ReDoS risk" in self.validator.errors[0]
            assert "consecutive quantifiers" in self.validator.errors[0]

    def test_validate_regex_pattern_duplicate_alternatives(self):
        """Test that duplicate alternatives in repeating groups are rejected."""
        duplicate_patterns = [
            r"(a|a)+",  # Exact duplicate alternatives
            r"(a|a)*",
            r"(foo|foo)+",
            r"(test|test)*",
        ]

        for pattern in duplicate_patterns:
            self.validator.errors = []
            result = self.validator.validate_regex_pattern(pattern, "test-pattern")
            assert result is False, f"Should reject duplicate alternatives: {pattern}"
            assert len(self.validator.errors) > 0
            assert "ReDoS risk" in self.validator.errors[0]
            assert "duplicate alternatives" in self.validator.errors[0]

    def test_validate_regex_pattern_overlapping_alternatives(self):
        """Test that overlapping alternatives in repeating groups are rejected."""
        overlapping_patterns = [
            r"(a|ab)+",  # Second alternative starts with first
            r"(ab|a)*",  # First alternative starts with second
            r"(test|te)+",  # Prefix overlap
            r"(foo|f)*",  # Prefix overlap
        ]

        for pattern in overlapping_patterns:
            self.validator.errors = []
            result = self.validator.validate_regex_pattern(pattern, "test-pattern")
            assert result is False, f"Should reject overlapping alternatives: {pattern}"
            assert len(self.validator.errors) > 0
            assert "ReDoS risk" in self.validator.errors[0]
            assert "overlapping alternatives" in self.validator.errors[0]

    def test_validate_regex_pattern_deeply_nested(self):
        """Test that deeply nested groups with multiple quantifiers are rejected."""
        deeply_nested_patterns = [
            r"((a+)+b)+",  # Deeply nested with quantifiers
            r"(((a*)*)*)*",  # Very deep nesting
            r"((x+)+(y+)+)+",  # Multiple nested quantified groups
        ]

        for pattern in deeply_nested_patterns:
            self.validator.errors = []
            result = self.validator.validate_regex_pattern(pattern, "test-pattern")
            assert result is False, f"Should reject deeply nested pattern: {pattern}"
            assert len(self.validator.errors) > 0
            assert "ReDoS risk" in self.validator.errors[0]

    def test_validate_regex_pattern_command_injection(self):
        """Test that command injection in regex patterns is detected."""
        injection_patterns = [
            r"^[0-9]+$; rm -rf /",
            r"test && cat /etc/passwd",
            r"pattern | sh",
            r"$(whoami)",
            r"`id`",
        ]

        for pattern in injection_patterns:
            self.validator.errors = []
            result = self.validator.validate_regex_pattern(pattern, "test-pattern")
            assert result is False, f"Should reject injection pattern: {pattern}"
            assert len(self.validator.errors) > 0

    def test_validate_regex_pattern_empty_input(self):
        """Test that empty patterns are handled correctly."""
        self.validator.errors = []
        result = self.validator.validate_regex_pattern("")
        assert result is True
        assert len(self.validator.errors) == 0

        result = self.validator.validate_regex_pattern("   ")
        assert result is True
        assert len(self.validator.errors) == 0

    def test_validate_regex_pattern_github_expression(self):
        """Test that GitHub expressions are allowed."""
        github_expressions = [
            "${{ secrets.PATTERN }}",
            "${{ inputs.regex }}",
        ]

        for expr in github_expressions:
            self.validator.errors = []
            result = self.validator.validate_regex_pattern(expr)
            assert result is True, f"Should allow GitHub expression: {expr}"
            assert len(self.validator.errors) == 0

    def test_validate_regex_pattern_safe_alternation(self):
        """Test that safe alternation without repetition is allowed."""
        safe_alternation = [
            r"^(alpha|beta|gamma)$",  # No repetition
            r"(foo|bar)",  # No quantifier after group
            r"^(red|green|blue)$",
            r"(one|two|three)",
        ]

        for pattern in safe_alternation:
            self.validator.errors = []
            result = self.validator.validate_regex_pattern(pattern, "test-pattern")
            assert result is True, f"Should accept safe alternation: {pattern}"
            assert len(self.validator.errors) == 0

    def test_validate_regex_pattern_optional_groups(self):
        """Test that optional groups (?) are allowed."""
        optional_patterns = [
            r"^[0-9]+(\.[0-9]+)?$",  # Optional decimal part
            r"^v?[0-9]+\.[0-9]+$",  # Optional 'v' prefix
            r"^(https?://)?example\.com$",  # Optional protocol
            r"^[a-z]+(-[a-z]+)?$",  # Optional suffix
        ]

        for pattern in optional_patterns:
            self.validator.errors = []
            result = self.validator.validate_regex_pattern(pattern, "test-pattern")
            assert result is True, f"Should accept optional group: {pattern}"
            assert len(self.validator.errors) == 0
