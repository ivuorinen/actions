"""Tests for network validator."""

from validators.network import NetworkValidator


class TestNetworkValidator:
    """Test cases for NetworkValidator."""

    def setup_method(self):
        """Set up test fixtures."""
        self.validator = NetworkValidator("test-action")

    def teardown_method(self):
        """Clean up after tests."""
        self.validator.clear_errors()

    def test_initialization(self):
        """Test validator initialization."""
        assert self.validator.action_type == "test-action"
        assert len(self.validator.errors) == 0

    def test_get_required_inputs(self):
        """Test get_required_inputs returns empty list."""
        required = self.validator.get_required_inputs()
        assert isinstance(required, list)
        assert len(required) == 0

    def test_get_validation_rules(self):
        """Test get_validation_rules returns dict."""
        rules = self.validator.get_validation_rules()
        assert isinstance(rules, dict)
        assert "email" in rules
        assert "url" in rules
        assert "scope" in rules
        assert "username" in rules

    # Email validation tests
    def test_valid_emails(self):
        """Test valid email addresses."""
        assert self.validator.validate_email("user@example.com") is True
        assert self.validator.validate_email("test.user+tag@company.co.uk") is True
        assert self.validator.validate_email("123@example.com") is True
        assert self.validator.validate_email("user_name@domain.org") is True

    def test_invalid_emails(self):
        """Test invalid email addresses."""
        self.validator.clear_errors()
        assert self.validator.validate_email("invalid") is False
        assert self.validator.has_errors()

        self.validator.clear_errors()
        assert self.validator.validate_email("@example.com") is False
        assert "Missing local part" in " ".join(self.validator.errors)

        self.validator.clear_errors()
        assert self.validator.validate_email("user@") is False
        assert "Missing domain" in " ".join(self.validator.errors)

    def test_email_empty_optional(self):
        """Test email allows empty (optional)."""
        assert self.validator.validate_email("") is True
        assert self.validator.validate_email("  ") is True

    def test_email_with_spaces(self):
        """Test email rejects spaces."""
        self.validator.clear_errors()
        assert self.validator.validate_email("user name@example.com") is False
        assert "Spaces not allowed" in " ".join(self.validator.errors)

    def test_email_multiple_at_symbols(self):
        """Test email rejects multiple @ symbols."""
        self.validator.clear_errors()
        assert self.validator.validate_email("user@@example.com") is False
        assert "@" in " ".join(self.validator.errors)

    def test_email_consecutive_dots(self):
        """Test email rejects consecutive dots."""
        self.validator.clear_errors()
        assert self.validator.validate_email("user..name@example.com") is False
        assert "consecutive dots" in " ".join(self.validator.errors)

    def test_email_domain_without_dot(self):
        """Test email rejects domain without dot."""
        self.validator.clear_errors()
        assert self.validator.validate_email("user@localhost") is False
        assert "must contain a dot" in " ".join(self.validator.errors)

    def test_email_domain_starts_or_ends_with_dot(self):
        """Test email rejects domain starting/ending with dot."""
        self.validator.clear_errors()
        assert self.validator.validate_email("user@.example.com") is False
        assert "cannot start/end with dot" in " ".join(self.validator.errors)

        self.validator.clear_errors()
        assert self.validator.validate_email("user@example.com.") is False
        assert "cannot start/end with dot" in " ".join(self.validator.errors)

    # URL validation tests
    def test_valid_urls(self):
        """Test valid URL formats."""
        assert self.validator.validate_url("https://example.com") is True
        assert self.validator.validate_url("http://localhost:8080") is True
        assert self.validator.validate_url("https://api.example.com/v1/endpoint") is True
        assert self.validator.validate_url("http://192.168.1.1") is True
        assert self.validator.validate_url("https://example.com/path?query=value") is True

    def test_invalid_urls(self):
        """Test invalid URL formats."""
        self.validator.clear_errors()
        assert self.validator.validate_url("not-a-url") is False
        assert self.validator.has_errors()

        self.validator.clear_errors()
        assert self.validator.validate_url("ftp://example.com") is False
        assert "http://" in " ".join(self.validator.errors)

    def test_url_empty_not_allowed(self):
        """Test URL rejects empty (not optional)."""
        self.validator.clear_errors()
        assert self.validator.validate_url("") is False
        assert "cannot be empty" in " ".join(self.validator.errors)

    def test_url_injection_patterns(self):
        """Test URL rejects injection patterns."""
        injection_urls = [
            "https://example.com;rm -rf /",
            "https://example.com&malicious",
            "https://example.com|pipe",
            "https://example.com`whoami`",
            "https://example.com$(cmd)",
            "https://example.com${var}",
        ]
        for url in injection_urls:
            self.validator.clear_errors()
            assert self.validator.validate_url(url) is False
            assert self.validator.has_errors()

    # Scope validation tests
    def test_validate_scope_valid(self):
        """Test valid NPM scope formats."""
        assert self.validator.validate_scope("@organization") is True
        assert self.validator.validate_scope("@my-org") is True
        assert self.validator.validate_scope("@org_name") is True
        assert self.validator.validate_scope("@org.name") is True

    def test_validate_scope_invalid(self):
        """Test invalid scope formats."""
        self.validator.clear_errors()
        assert self.validator.validate_scope("organization") is False
        assert "Must start with @" in " ".join(self.validator.errors)

        self.validator.clear_errors()
        assert self.validator.validate_scope("@") is False
        assert "cannot be empty" in " ".join(self.validator.errors)

        self.validator.clear_errors()
        assert self.validator.validate_scope("@Organization") is False
        assert "lowercase" in " ".join(self.validator.errors)

    def test_validate_scope_empty(self):
        """Test scope allows empty (optional)."""
        assert self.validator.validate_scope("") is True

    # Username validation tests
    def test_validate_username_valid(self):
        """Test valid usernames."""
        assert self.validator.validate_username("user") is True
        assert self.validator.validate_username("user123") is True
        assert self.validator.validate_username("user-name") is True
        assert self.validator.validate_username("user_name") is True
        assert self.validator.validate_username("a" * 39) is True  # Max length

    def test_validate_username_invalid(self):
        """Test invalid usernames."""
        self.validator.clear_errors()
        assert self.validator.validate_username("user;name") is False
        assert "injection" in " ".join(self.validator.errors)

        self.validator.clear_errors()
        assert self.validator.validate_username("a" * 40) is False
        assert "39 characters" in " ".join(self.validator.errors)

        self.validator.clear_errors()
        assert self.validator.validate_username("-username") is False
        assert "alphanumeric" in " ".join(self.validator.errors)

    def test_validate_username_empty(self):
        """Test username allows empty (optional)."""
        assert self.validator.validate_username("") is True

    # Registry URL tests
    def test_validate_registry_url_known(self):
        """Test known registry URLs."""
        assert self.validator.validate_registry_url("https://registry.npmjs.org/") is True
        assert self.validator.validate_registry_url("https://npm.pkg.github.com/") is True
        assert self.validator.validate_registry_url("https://pypi.org/simple/") is True

    def test_validate_registry_url_custom(self):
        """Test custom registry URLs."""
        assert self.validator.validate_registry_url("https://custom-registry.com") is True

    def test_validate_registry_url_empty(self):
        """Test registry URL allows empty (optional)."""
        assert self.validator.validate_registry_url("") is True

    # Repository URL tests
    def test_validate_repository_url_github(self):
        """Test GitHub repository URLs."""
        assert self.validator.validate_repository_url("https://github.com/user/repo") is True
        assert self.validator.validate_repository_url("https://github.com/user/repo.git") is True

    def test_validate_repository_url_gitlab(self):
        """Test GitLab repository URLs."""
        assert self.validator.validate_repository_url("https://gitlab.com/user/repo") is True
        assert self.validator.validate_repository_url("https://gitlab.com/user/repo.git") is True

    def test_validate_repository_url_bitbucket(self):
        """Test Bitbucket repository URLs."""
        assert self.validator.validate_repository_url("https://bitbucket.org/user/repo") is True

    def test_validate_repository_url_empty(self):
        """Test repository URL allows empty (optional)."""
        assert self.validator.validate_repository_url("") is True

    # Hostname validation tests
    def test_validate_hostname_valid(self):
        """Test valid hostnames."""
        assert self.validator.validate_hostname("example.com") is True
        assert self.validator.validate_hostname("sub.example.com") is True
        assert self.validator.validate_hostname("localhost") is True
        assert self.validator.validate_hostname("192.168.1.1") is True  # IP as hostname

    def test_validate_hostname_invalid(self):
        """Test invalid hostnames."""
        self.validator.clear_errors()
        assert self.validator.validate_hostname("a" * 254) is False
        assert "too long" in " ".join(self.validator.errors)

        self.validator.clear_errors()
        assert self.validator.validate_hostname("-invalid.com") is False

    def test_validate_hostname_ipv6_loopback(self):
        """Test IPv6 loopback addresses as hostnames."""
        assert self.validator.validate_hostname("::1") is True
        assert self.validator.validate_hostname("::") is True

    def test_validate_hostname_empty(self):
        """Test hostname allows empty (optional)."""
        assert self.validator.validate_hostname("") is True

    # IP address validation tests
    def test_validate_ip_address_ipv4(self):
        """Test valid IPv4 addresses."""
        assert self.validator.validate_ip_address("192.168.1.1") is True
        assert self.validator.validate_ip_address("127.0.0.1") is True
        assert self.validator.validate_ip_address("10.0.0.1") is True
        assert self.validator.validate_ip_address("255.255.255.255") is True

    def test_validate_ip_address_ipv4_invalid(self):
        """Test invalid IPv4 addresses."""
        self.validator.clear_errors()
        assert self.validator.validate_ip_address("256.1.1.1") is False

        self.validator.clear_errors()
        assert self.validator.validate_ip_address("192.168.1") is False

    def test_validate_ip_address_ipv6(self):
        """Test valid IPv6 addresses."""
        assert self.validator.validate_ip_address("::1") is True  # Loopback
        assert self.validator.validate_ip_address("::") is True  # Unspecified
        assert self.validator.validate_ip_address("2001:0db8:85a3:0000:0000:8a2e:0370:7334") is True
        assert self.validator.validate_ip_address("2001:db8::1") is True  # Compressed

    def test_validate_ip_address_ipv6_invalid(self):
        """Test invalid IPv6 addresses."""
        self.validator.clear_errors()
        assert self.validator.validate_ip_address("gggg::1") is False

    def test_validate_ip_address_empty(self):
        """Test IP address allows empty (optional)."""
        assert self.validator.validate_ip_address("") is True

    # Port validation tests
    def test_validate_port_valid(self):
        """Test valid port numbers."""
        assert self.validator.validate_port("80") is True
        assert self.validator.validate_port("443") is True
        assert self.validator.validate_port("8080") is True
        assert self.validator.validate_port("1") is True  # Min
        assert self.validator.validate_port("65535") is True  # Max

    def test_validate_port_invalid(self):
        """Test invalid port numbers."""
        self.validator.clear_errors()
        assert self.validator.validate_port("0") is False
        assert "between 1 and 65535" in " ".join(self.validator.errors)

        self.validator.clear_errors()
        assert self.validator.validate_port("65536") is False
        assert "between 1 and 65535" in " ".join(self.validator.errors)

        self.validator.clear_errors()
        assert self.validator.validate_port("abc") is False
        assert "must be a number" in " ".join(self.validator.errors)

    def test_validate_port_empty(self):
        """Test port allows empty (optional)."""
        assert self.validator.validate_port("") is True

    # validate_inputs tests
    def test_validate_inputs_with_email(self):
        """Test validate_inputs recognizes email inputs."""
        inputs = {"user-email": "test@example.com", "reply-email": "reply@example.com"}
        result = self.validator.validate_inputs(inputs)
        assert result is True

    def test_validate_inputs_with_url(self):
        """Test validate_inputs recognizes URL inputs."""
        inputs = {
            "api-url": "https://api.example.com",
            "registry-url": "https://registry.npmjs.org/",
        }
        result = self.validator.validate_inputs(inputs)
        assert result is True

    def test_validate_inputs_with_scope(self):
        """Test validate_inputs recognizes scope inputs."""
        inputs = {"npm-scope": "@organization"}
        result = self.validator.validate_inputs(inputs)
        assert result is True

    def test_validate_inputs_with_username(self):
        """Test validate_inputs recognizes username inputs."""
        inputs = {"username": "testuser", "user": "anotheruser"}
        result = self.validator.validate_inputs(inputs)
        assert result is True

    def test_validate_inputs_with_invalid_values(self):
        """Test validate_inputs with invalid values."""
        inputs = {"email": "invalid-email", "url": "not-a-url"}
        result = self.validator.validate_inputs(inputs)
        assert result is False
        assert len(self.validator.errors) >= 2

    def test_github_expressions(self):
        """Test GitHub expression handling."""
        assert self.validator.validate_url("${{ secrets.WEBHOOK_URL }}") is True
        assert self.validator.validate_email("${{ github.event.pusher.email }}") is True

    def test_error_messages(self):
        """Test that error messages are meaningful."""
        self.validator.clear_errors()
        self.validator.validate_email("user@", "test-email")
        assert len(self.validator.errors) == 1
        assert "test-email" in self.validator.errors[0]

        self.validator.clear_errors()
        self.validator.validate_url("", "my-url")
        assert len(self.validator.errors) == 1
        assert "my-url" in self.validator.errors[0]
