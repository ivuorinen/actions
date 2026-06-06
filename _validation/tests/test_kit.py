"""Unit tests for every check in the validation kit.

``CASES`` holds valid/invalid examples per check type; ``test_every_check_is_covered``
guarantees no check is added to the kit without tests. Security-sensitive behaviour
(token formats, path traversal, injection, SemVer pre-releases, CalVer day rollover) is
asserted explicitly so a regression cannot pass silently.
"""

from __future__ import annotations

import kit
import pytest

# check type -> {"valid": [...accepted...], "invalid": [...rejected...]}
CASES: dict[str, dict[str, list[str]]] = {
    "github_token": {
        "valid": [
            "ghp_" + "a" * 36,
            "gho_" + "b" * 36,
            "ghu_" + "c" * 36,
            "ghs_" + "d" * 36,
            "ghs_1234567_" + "e" * 200 + "." + "f" * 40 + "." + "g" * 256,
            "ghr_" + "h" * 36,
            "ghe_" + "i" * 36,
            "github_pat_" + "j" * 71,
            "$NPM_TOKEN",
            "${{ secrets.GITHUB_TOKEN }}",
        ],
        "invalid": [
            "plain-token",
            "ghp_short",
            "github_pat_" + "a" * 49,
            "ghs_" + "a" * 35,
            "$(rm -rf /)",
            "${ evil; }",
        ],
    },
    "semantic_version": {
        "valid": [
            "1.2.3",
            "v1.2.3",
            "10.20.30",
            "1.0",
            "1",
            "1.0.0-rc.1",
            "2.0.0+build.1",
            "latest",
        ],
        "invalid": ["1.2.a", "a.b.c", "1.2.3-", "1.2.3+", "1.2.3.4.5"],
    },
    "strict_semantic_version": {
        "valid": ["1.2.3", "1.2.3-rc.1", "1.2.3+build.7", "latest"],
        "invalid": ["1.2", "1", "v1.2.3", "abc"],
    },
    "no_prefix_version": {
        "valid": ["1.2.3", "1.2", "1"],
        "invalid": ["v1.2.3", "V1.2.3", "abc"],
    },
    "calver_version": {
        "valid": ["2025.04.05", "2025.4.5", "2025.04", "2025-04-05", "24.3.1", "v2024.3.1"],
        "invalid": ["2024.13.1", "2024.2.30", "2024.3.32", "24.3", "2024.3.1.1"],
    },
    "dotnet_version": {
        "valid": ["8", "8.0", "8.0.100", "8.0.x", "8.0.100-preview.1"],
        "invalid": ["v8", "8.0.0.0", "abc"],
    },
    "terraform_version": {
        "valid": ["1.5.7", "1.5.7-rc1", "v1.5.7", "latest"],
        "invalid": ["1.5", "abc"],
    },
    "node_version": {
        "valid": ["20", "20.1", "20.11.0", "v20", "lts/*", "latest", "lts", "node"],
        "invalid": ["abc", "20.x"],
    },
    "go_version": {
        "valid": ["1.21", "1.21.5", "1.21.x", "v1.21", "stable", "oldstable"],
        "invalid": ["abc", "1"],
    },
    "docker_architectures": {
        "valid": ["linux/amd64", "linux/amd64,linux/arm64", "linux/arm/v7"],
        "invalid": ["windows/amd64", "linux/amd64,bogus"],
    },
    "docker_image_name": {
        "valid": ["myapp", "registry.example.com/ns/app", "my-app", "ns/sub/app"],
        "invalid": ["MyApp", "my app", "/leading"],
    },
    "docker_tag": {
        "valid": ["v1.0.0", "latest", "sha-1234567", "1.0.0", "a"],
        "invalid": ["-bad", "bad-", "in valid"],
    },
    "cache_mode": {"valid": ["max", "min", "inline"], "invalid": ["fast", "MAX"]},
    "network_mode": {"valid": ["host", "none", "default"], "invalid": ["bridge"]},
    "sbom_format": {"valid": ["spdx-json", "cyclonedx-json"], "invalid": ["spdx", "json"]},
    "registry_enum": {"valid": ["dockerhub", "github", "both"], "invalid": ["gcr"]},
    "cache_config": {
        "valid": ["type=gha", "type=registry,ref=x", "type=gha,mode=max"],
        "invalid": ["type=evil", "gha", "mode=max"],
    },
    "namespace_with_lookahead": {
        "valid": ["my-org", "abc", "a1-b2"],
        "invalid": ["My-Org", "-bad", "a" * 256],
    },
    "codeql_language": {
        "valid": ["python", "javascript,python", "go", "csharp"],
        "invalid": ["cobol", "python,bogus"],
    },
    "codeql_build_mode": {"valid": ["none", "manual", "autobuild"], "invalid": ["auto"]},
    "codeql_queries": {
        "valid": ["security-extended", "security-and-quality,default", "my/pack"],
        "invalid": ["a,,b", "bad query"],
    },
    "codeql_packs": {
        "valid": ["scope/name", "scope/name@1.0.0", "a/b,c/d"],
        "invalid": ["a,,b", "bad pack"],
    },
    "codeql_config": {
        "valid": ["name: my-config", "paths:\n  - src"],
        "invalid": ["!!python/object/apply:os.system", "x: !!ruby/object {}"],
    },
    "category_format": {
        "valid": ["my-analysis", "/my:cat", "a/b/c"],
        "invalid": ["bad cat", "a;b"],
    },
    "file_path": {
        "valid": ["file.txt", "path/to/file.txt", "folder/sub/file.ext"],
        "invalid": ["../file.txt", "/absolute/path", "~/home", "path/../file", "%2e%2e/etc"],
    },
    "output_path": {
        "valid": ["../results", "results", "out/sarif", "results/codeql.sarif"],
        "invalid": ["/absolute", "~/home", "a;b", "$(x)"],
    },
    "branch_name": {
        "valid": ["main", "feature/x", "release-1.0", "dev_branch"],
        "invalid": ["a..b", "~x", "x^", "a:b", "-bad", ".bad", "/bad"],
    },
    "file_extensions": {
        "valid": [".js", ".js,.ts", ".jsx,.tsx,.mjs"],
        "invalid": ["js", ".js,,.ts", ".j-s"],
    },
    "path_list": {
        "valid": ["src/", "a,b", "*.js", "src/**/*.ts"],
        "invalid": ["a;b", "../x", "$(x)"],
    },
    "email": {
        "valid": ["a@b.com", "user+tag@example.org", "test.email@domain.co.uk"],
        "invalid": ["notanemail", "@example.com", "user@"],
    },
    "url": {
        "valid": ["https://example.com", "http://a.b:8080/p", "https://reg.npmjs.org"],
        "invalid": ["ftp://x.com", "javascript:alert(1)", "https://x;rm"],
    },
    "scope": {"valid": ["@my-org", "@a"], "invalid": ["my-org", "@1bad"]},
    "username": {
        "valid": ["user", "user-name", "user_name", "a" * 39],
        "invalid": ["a" * 40, "user;name", "-bad"],
    },
    "git_author_name": {
        "valid": ["GitHub Actions", "github-actions[bot]", "Ismo Vuorinen", "user_name"],
        "invalid": ["a;b", "a`b`", "a\nb", "a" * 101],
    },
    "boolean": {"valid": ["true", "false", "TRUE", "False"], "invalid": ["yes", "1", "maybe"]},
    "mode_enum": {"valid": ["check", "fix"], "invalid": ["lint"]},
    "report_format": {"valid": ["json", "sarif", "github-actions"], "invalid": ["yaml"]},
    "coverage_driver": {"valid": ["none", "xdebug", "pcov", "xdebug3"], "invalid": ["phpdbg"]},
    "framework_mode": {"valid": ["auto", "laravel", "generic"], "invalid": ["symfony"]},
    "language_enum": {"valid": ["php", "python", "go", "dotnet"], "invalid": ["ruby"]},
    "severity_enum": {
        "valid": ["HIGH", "HIGH,CRITICAL", "LOW,MEDIUM,HIGH"],
        "invalid": ["high", "HIGH,BOGUS"],
    },
    "scanner_list": {"valid": ["vuln", "vuln,secret,config"], "invalid": ["vuln,bogus"]},
    "linter_list": {
        "valid": ["gosec", "gosec,govet", "errcheck"],
        "invalid": ["gosec,,govet", "lint;er", "lint er"],
    },
    "plugin_list": {
        "valid": [
            "prettier-plugin-x",
            "@scope/plugin",
            "a,b",
            "a|b",
            "conventional-changelog-conventionalcommits@^9.3.1",
            "@scope/plugin@1.0.0",
        ],
        "invalid": ["a,,b", "bad plugin"],
    },
    "php_extensions": {
        "valid": ["mbstring", "mbstring, gd", "intl,bcmath"],
        "invalid": ["a,,b", "ext;ra"],
    },
    "key_value_list": {
        "valid": ["FOO=bar", "FOO=bar\nBAZ=qux", "KEY="],
        "invalid": ["FOO=bar;rm", "noequals", "1BAD=x"],
    },
    "timeout_with_unit": {"valid": ["5m", "30s", "500ms", "1h"], "invalid": ["5", "5min", "m5"]},
    "prefix": {"valid": ["v", "rel-", "a.b_c"], "invalid": ["a b", "a@b", "a:b"]},
    "json_format": {"valid": ["{}", '{"a": 1}', "[1, 2, 3]"], "invalid": ["{bad", "not json"]},
    "command_args": {
        "valid": ["--no-progress --prefer-dist", "--optimize-autoloader"],
        "invalid": ["rm; foo", "$(whoami)", "a`b`"],
    },
    "license_key": {
        "valid": ["ABC-123_x", "$GITLEAKS_LICENSE", "${{ secrets.LIC }}", "b64+val/ue="],
        "invalid": ["has space", "a;b", "$(rm -rf /)"],
    },
    "positive_integer": {"valid": ["1", "100"], "invalid": ["0", "-1", "abc"]},
    "numeric_range_1_10": {"valid": ["1", "10", "5"], "invalid": ["0", "11", "abc"]},
    "numeric_range_0_16": {"valid": ["0", "16", "8"], "invalid": ["17", "-1"]},
    "numeric_range_0_100": {"valid": ["0", "100", "50"], "invalid": ["101", "-1"]},
    "numeric_range_1_128": {"valid": ["1", "128"], "invalid": ["0", "129"]},
    "numeric_range_256_32768": {"valid": ["256", "32768"], "invalid": ["255", "32769"]},
    "numeric_range_0_10000": {"valid": ["0", "10000"], "invalid": ["10001", "-1"]},
}


def test_every_check_is_covered():
    assert set(CASES) == set(kit.CHECKS), "every kit check must have CASES (and vice versa)"


@pytest.mark.parametrize("check", sorted(CASES))
def test_valid_values_accepted(check):
    fn = kit.CHECKS[check]
    for value in CASES[check]["valid"]:
        assert fn(value) is None, f"{check} should accept {value!r}"


@pytest.mark.parametrize("check", sorted(CASES))
def test_invalid_values_rejected(check):
    fn = kit.CHECKS[check]
    for value in CASES[check]["invalid"]:
        assert fn(value) is not None, f"{check} should reject {value!r}"


@pytest.mark.parametrize("check", sorted(kit.CHECKS))
def test_empty_value_is_optional(check):
    assert kit.CHECKS[check]("") is None
    assert kit.CHECKS[check]("   ") is None


@pytest.mark.parametrize("check", sorted(kit.CHECKS))
def test_github_expression_passes_through(check):
    assert kit.CHECKS[check]("${{ inputs.whatever }}") is None


def test_expression_cannot_smuggle_traversal():
    # a value that *starts* as an expression but appends real traversal must NOT pass
    assert kit.check_file_path("${{ env.X }}/../etc/passwd") is not None


def test_token_rejects_partial_prefix_only():
    assert kit.check_github_token("ghp_") is not None
    assert kit.check_github_token("github_pat_") is not None


def test_calver_rejects_impossible_dates():
    assert kit.check_calver_version("2025.02.30") is not None  # Feb 30
    assert kit.check_calver_version("2024.02.29") is None  # 2024 is a leap year
    assert kit.check_calver_version("2025.02.29") is not None  # 2025 is not


def test_semver_prerelease_and_build_metadata():
    assert kit.check_semantic_version("1.0.0-rc.1") is None
    assert kit.check_semantic_version("2.0.0-rc.1+build.1") is None
    assert kit.check_semantic_version("1.0.0-") is not None


def test_returns_are_strings_or_none():
    for check, fn in kit.CHECKS.items():
        result = fn("definitely-not-valid-%%%")
        assert result is None or isinstance(result, str), f"{check} returned {type(result)}"
