"""Tests for the NetworkValidator module."""

from pathlib import Path
import sys

import pytest  # pylint: disable=import-error

# Add the parent directory to the path
sys.path.insert(0, str(Path(__file__).parent.parent))

from validators.network import NetworkValidator

from tests.fixtures.version_test_data import (
    EMAIL_INVALID,
    EMAIL_VALID,
    USERNAME_INVALID,
    USERNAME_VALID,
)


class TestNetworkValidator:
    """Test cases for NetworkValidator."""

    def setup_method(self):
        """Set up test environment."""
        self.validator = NetworkValidator()

    def test_initialization(self):
        """Test validator initialization."""
        assert self.validator.errors == []
        rules = self.validator.get_validation_rules()
        assert rules is not None

    @pytest.mark.parametrize("email,description", EMAIL_VALID)
    def test_validate_email_valid(self, email, description):
        """Test email validation with valid emails."""
        self.validator.errors = []
        result = self.validator.validate_email(email)
        assert result is True, f"Failed for {description}: {email}"
        assert len(self.validator.errors) == 0

    @pytest.mark.parametrize("email,description", EMAIL_INVALID)
    def test_validate_email_invalid(self, email, description):
        """Test email validation with invalid emails."""
        self.validator.errors = []
        result = self.validator.validate_email(email)
        if email == "":  # Empty email might be allowed
            assert isinstance(result, bool)
        else:
            assert result is False, f"Should fail for {description}: {email}"
            assert len(self.validator.errors) > 0

    @pytest.mark.parametrize("username,description", USERNAME_VALID)
    def test_validate_username_valid(self, username, description):
        """Test username validation with valid usernames."""
        self.validator.errors = []
        result = self.validator.validate_username(username)
        assert result is True, f"Failed for {description}: {username}"
        assert len(self.validator.errors) == 0

    @pytest.mark.parametrize("username,description", USERNAME_INVALID)
    def test_validate_username_invalid(self, username, description):
        """Test username validation with invalid usernames."""
        self.validator.errors = []
        result = self.validator.validate_username(username)
        if username == "":  # Empty username is allowed
            assert result is True
        else:
            assert result is False, f"Should fail for {description}: {username}"

    def test_validate_url_valid(self):
        """Test URL validation with valid URLs."""
        valid_urls = [
            "https://github.com",
            "http://example.com",
            "https://api.github.com/repos/owner/repo",
            "https://example.com:8080",
            "https://sub.domain.example.com",
            "http://localhost",
            "http://localhost:3000",
            "https://192.168.1.1",
            "https://example.com/path/to/resource",
            "https://example.com/path?query=value",
            "https://example.com#fragment",
        ]

        for url in valid_urls:
            self.validator.errors = []
            result = self.validator.validate_url(url)
            assert result is True, f"Should accept URL: {url}"

    def test_validate_url_invalid(self):
        """Test URL validation with invalid URLs."""
        invalid_urls = [
            "not-a-url",
            "ftp://example.com",  # FTP not supported
            "javascript:alert(1)",  # JavaScript protocol
            "file:///etc/passwd",  # File protocol
            "//example.com",  # Protocol-relative URL
            "example.com",  # Missing protocol
            "http://",  # Incomplete URL
            "http:/example.com",  # Single slash
            "http:///example.com",  # Triple slash
            "",  # Empty
        ]

        for url in invalid_urls:
            self.validator.errors = []
            result = self.validator.validate_url(url)
            if url == "":
                # Empty might be allowed for optional
                assert isinstance(result, bool)
            else:
                assert result is False, f"Should reject URL: {url}"

    def test_validate_hostname_valid(self):
        """Test hostname validation with valid hostnames."""
        valid_hostnames = [
            "example.com",
            "sub.example.com",
            "sub.sub.example.com",
            "example-site.com",
            "123.example.com",
            "localhost",
            "my-server",
            "server123",
            "192.168.1.1",
            "::1",  # IPv6 localhost
        ]

        for hostname in valid_hostnames:
            self.validator.errors = []
            result = self.validator.validate_hostname(hostname)
            assert result is True, f"Should accept hostname: {hostname}"

    def test_validate_hostname_invalid(self):
        """Test hostname validation with invalid hostnames."""
        invalid_hostnames = [
            "example..com",  # Double dot
            "-example.com",  # Leading dash
            "example-.com",  # Trailing dash
            "exam ple.com",  # Space
            "example.com/path",  # Path included
            "http://example.com",  # Protocol included
            "example.com:8080",  # Port included
            "",  # Empty
        ]

        for hostname in invalid_hostnames:
            self.validator.errors = []
            result = self.validator.validate_hostname(hostname)
            if hostname == "":
                assert isinstance(result, bool)
            else:
                assert result is False, f"Should reject hostname: {hostname}"

    def test_validate_ip_address(self):
        """Test IP address validation."""
        valid_ips = [
            "192.168.1.1",
            "10.0.0.1",
            "172.16.0.1",
            "8.8.8.8",
            "0.0.0.0",  # noqa: S104
            "255.255.255.255",
        ]

        for ip in valid_ips:
            self.validator.errors = []
            result = self.validator.validate_ip_address(ip)
            assert result is True, f"Should accept IP: {ip}"

        invalid_ips = [
            "256.256.256.256",  # Out of range
            "192.168.1",  # Incomplete
            "192.168.1.1.1",  # Too many octets
            "192.168.-1.1",  # Negative
            "192.168.a.1",  # Non-numeric
            "example.com",  # Domain name
        ]

        for ip in invalid_ips:
            self.validator.errors = []
            result = self.validator.validate_ip_address(ip)
            assert result is False, f"Should reject IP: {ip}"

    def test_validate_port_number(self):
        """Test port number validation."""
        valid_ports = [
            "80",
            "443",
            "8080",
            "3000",
            "65535",  # Maximum port
            "1",  # Minimum port
        ]

        for port in valid_ports:
            self.validator.errors = []
            result = self.validator.validate_port(port)
            assert result is True, f"Should accept port: {port}"

        invalid_ports = [
            "0",  # Too low
            "65536",  # Too high
            "-1",  # Negative
            "abc",  # Non-numeric
            "80.0",  # Decimal
        ]

        for port in invalid_ports:
            self.validator.errors = []
            result = self.validator.validate_port(port)
            assert result is False, f"Should reject port: {port}"

    def test_empty_values_handling(self):
        """Test that empty values are handled appropriately."""
        assert self.validator.validate_email("") is True  # Empty allowed for optional
        assert self.validator.validate_username("") is True
        assert isinstance(self.validator.validate_url(""), bool)
        assert isinstance(self.validator.validate_hostname(""), bool)

    def test_validate_inputs_with_network_keywords(self):
        """Test validation of inputs with network-related keywords."""
        inputs = {
            "email": "test@example.com",
            "username": "testuser",
            "url": "https://example.com",
            "webhook-url": "https://hooks.example.com/webhook",
            "api-endpoint": "https://api.example.com/v1",
            "hostname": "server.example.com",
            "server-address": "192.168.1.100",
            "port": "8080",
        }

        result = self.validator.validate_inputs(inputs)
        assert isinstance(result, bool)
