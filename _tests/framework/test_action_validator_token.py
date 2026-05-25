"""Tests for ActionValidator.validate_github_token.

Exercises both stateful (40 chars) and stateless JWT (~520 chars) installation token
formats. Per GitHub's 2026-04-27 rollout, ``${{ github.token }}`` expands to a
``ghs_APPID_JWT`` token at workflow runtime, so the framework validator must accept it.

See: https://github.blog/changelog/2026-05-15-github-app-installation-tokens-per-request-override-header
"""

# pyright: reportMissingImports=false
# pylint: disable=import-error,wrong-import-position
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).parent))

from validation import ActionValidator


class TestActionValidatorToken:
    """Token-format tests for the framework ActionValidator class."""

    def setup_method(self) -> None:
        """Create a fresh ActionValidator per test."""
        self.validator = ActionValidator()  # pylint: disable=attribute-defined-outside-init

    def test_ghs_stateful_token(self) -> None:
        """Stateful installation token: ghs_ + 36 alphanumeric (40 chars total)."""
        ok, err = self.validator.validate_github_token("ghs_" + "a" * 36)
        assert ok is True, err

    def test_ghs_stateless_jwt_token(self) -> None:
        """Stateless ghs_APPID_JWT format with two dots and underscores."""
        jwt_header = "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9"
        jwt_payload = "a" * 200
        jwt_signature = "b" * 256
        token = f"ghs_1234567_{jwt_header}.{jwt_payload}.{jwt_signature}"
        ok, err = self.validator.validate_github_token(token)
        assert ok is True, err

    def test_ghs_length_boundaries(self) -> None:
        """ghs_ body length must satisfy 36 <= len <= 1024 exactly."""
        assert self.validator.validate_github_token("ghs_" + "a" * 36)[0] is True
        assert self.validator.validate_github_token("ghs_" + "a" * 35)[0] is False
        assert self.validator.validate_github_token("ghs_" + "a" * 1024)[0] is True
        assert self.validator.validate_github_token("ghs_" + "a" * 1025)[0] is False

    def test_ghs_invalid_chars_rejected(self) -> None:
        """ghs_ body allows only [A-Za-z0-9._] — plus/slash/space rejected."""
        for bad in ("ghs_" + "a" * 35 + "+", "ghs_" + "a" * 35 + "/", "ghs_" + "a" * 35 + " "):
            ok, _ = self.validator.validate_github_token(bad)
            assert ok is False, f"should reject: {bad!r}"

    def test_ghp_classic_still_works(self) -> None:
        """Classic PAT (ghp_ + 36 alphanumeric) is accepted."""
        ok, _ = self.validator.validate_github_token("ghp_" + "a" * 36)
        assert ok is True

    def test_github_pat_fine_grained(self) -> None:
        """Fine-grained PAT (github_pat_ + 50-255 chars) is accepted."""
        ok, _ = self.validator.validate_github_token("github_pat_" + "a" * 71)
        assert ok is True

    def test_github_expression_accepted(self) -> None:
        """``${{ github.token }}`` and similar expressions are accepted."""
        ok, _ = self.validator.validate_github_token("${{ github.token }}")
        assert ok is True

    def test_wrong_prefix_rejected(self) -> None:
        """Tokens with no recognized prefix are rejected."""
        ok, _ = self.validator.validate_github_token("wrong_prefix_" + "a" * 36)
        assert ok is False
