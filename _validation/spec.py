"""Per-action validation spec — the single source of the input -> check mapping.

This is hand-maintained (BUILD-TIME ONLY). ``generate.py`` reads it together with
``kit.py`` and emits a self-contained ``<action>/validate.py`` for each action.

Shape::

    SPECS[action] = {
        "required": [<input names that must be non-empty>],
        "checks":   {<input name>: "<kit check type>"},
    }

Rules for editing:
  * ``checks`` keys are the action's input names *exactly* as declared in its
    ``action.yml`` (the runner derives the ``INPUT_<UPPER_SNAKE>`` env var from them).
  * each check value must be a type defined in ``kit.py`` (``kit.CHECKS``);
    ``tests/test_spec.py`` fails if a value is unknown or an action's inputs and its
    spec drift apart.
  * after editing, run ``make update-validators`` to regenerate every ``validate.py``.
"""

from __future__ import annotations

from typing import TypedDict


class ActionSpec(TypedDict):
    """Validation spec for one action: which inputs are required and how each is checked."""

    required: list[str]
    checks: dict[str, str]


SPECS: dict[str, ActionSpec] = {
    "ansible-lint-fix": {
        "required": [],
        "checks": {
            "email": "email",
            "max-retries": "numeric_range_1_10",
            "token": "github_token",
            "username": "username",
        },
    },
    "biome-lint": {
        "required": [],
        "checks": {
            "email": "email",
            "fail-on-error": "boolean",
            "max-retries": "numeric_range_1_10",
            "mode": "mode_enum",
            "token": "github_token",
            "username": "username",
        },
    },
    "codeql-analysis": {
        "required": ["language"],
        "checks": {
            "build-mode": "codeql_build_mode",
            "category": "category_format",
            "checkout-ref": "branch_name",
            "config": "codeql_config",
            "config-file": "file_path",
            "language": "codeql_language",
            "output": "output_path",
            "packs": "codeql_packs",
            "queries": "codeql_queries",
            "ram": "numeric_range_256_32768",
            "skip-queries": "boolean",
            "source-root": "file_path",
            "threads": "numeric_range_1_128",
            "token": "github_token",
            "upload-results": "boolean",
            "working-directory": "file_path",
        },
    },
    "compress-images": {
        "required": [],
        "checks": {
            "email": "email",
            "ignore-paths": "path_list",
            "image-quality": "numeric_range_0_100",
            "png-quality": "numeric_range_0_100",
            "token": "github_token",
            "username": "username",
            "working-directory": "file_path",
        },
    },
    "csharp-build": {
        "required": [],
        "checks": {
            "dotnet-version": "dotnet_version",
            "max-retries": "numeric_range_1_10",
            "token": "github_token",
        },
    },
    "csharp-lint-check": {
        "required": [],
        "checks": {
            "dotnet-version": "dotnet_version",
            "token": "github_token",
        },
    },
    "csharp-publish": {
        "required": ["namespace"],
        "checks": {
            "dotnet-version": "dotnet_version",
            "max-retries": "numeric_range_1_10",
            "namespace": "namespace_with_lookahead",
            "token": "github_token",
        },
    },
    "docker-build": {
        "required": ["tag"],
        "checks": {
            "architectures": "docker_architectures",
            "auto-detect-platforms": "boolean",
            "build-args": "key_value_list",
            "build-contexts": "key_value_list",
            "buildkit-version": "semantic_version",
            "buildx-version": "semantic_version",
            "cache-export": "cache_config",
            "cache-from": "cache_config",
            "cache-import": "cache_config",
            "cache-mode": "cache_mode",
            "context": "file_path",
            "dockerfile": "file_path",
            "dry-run": "boolean",
            "image-name": "docker_image_name",
            "max-retries": "numeric_range_1_10",
            "network": "network_mode",
            "parallel-builds": "numeric_range_0_16",
            "platform-build-args": "json_format",
            "platform-fallback": "boolean",
            "push": "boolean",
            "sbom-format": "sbom_format",
            "scan-image": "boolean",
            "secrets": "key_value_list",
            "sign-image": "boolean",
            "tag": "docker_tag",
            "token": "github_token",
            "verbose": "boolean",
        },
    },
    "docker-publish": {
        "required": [],
        "checks": {
            "build-args": "key_value_list",
            "context": "file_path",
            "dockerfile": "file_path",
            "dockerhub-token": "github_token",
            "dockerhub-username": "username",
            "image-name": "docker_image_name",
            "platforms": "docker_architectures",
            "push": "boolean",
            "registry": "registry_enum",
            "tags": "docker_tag",
            "token": "github_token",
        },
    },
    "eslint-lint": {
        "required": [],
        "checks": {
            "cache": "boolean",
            "config-file": "file_path",
            "email": "email",
            "eslint-version": "semantic_version",
            "fail-on-error": "boolean",
            "file-extensions": "file_extensions",
            "ignore-file": "file_path",
            "max-retries": "numeric_range_1_10",
            "max-warnings": "numeric_range_0_10000",
            "mode": "mode_enum",
            "report-format": "report_format",
            "token": "github_token",
            "username": "username",
            "working-directory": "file_path",
        },
    },
    "go-build": {
        "required": [],
        "checks": {
            "destination": "file_path",
            "go-version": "semantic_version",
            "max-retries": "numeric_range_1_10",
            "token": "github_token",
        },
    },
    "go-lint": {
        "required": [],
        "checks": {
            "cache": "boolean",
            "config-file": "file_path",
            "disable-all": "boolean",
            "disable-linters": "linter_list",
            "enable-linters": "linter_list",
            "fail-on-error": "boolean",
            "go-version": "go_version",
            "golangci-lint-version": "semantic_version",
            "max-retries": "numeric_range_1_10",
            "only-new-issues": "boolean",
            "report-format": "report_format",
            "timeout": "timeout_with_unit",
            "token": "github_token",
            "working-directory": "file_path",
        },
    },
    "language-version-detect": {
        "required": ["language"],
        "checks": {
            "default-version": "no_prefix_version",
            "language": "language_enum",
            "token": "github_token",
        },
    },
    "npm-publish": {
        "required": ["npm_token"],
        "checks": {
            "npm_token": "github_token",
            "package-version": "strict_semantic_version",
            "registry-url": "url",
            "scope": "scope",
            "token": "github_token",
        },
    },
    "npm-semantic-release": {
        "required": ["npm_token"],
        "checks": {
            "extra_plugins": "plugin_list",
            "github_token": "github_token",
            "node-version": "node_version",
            "npm_token": "github_token",
            "registry-url": "url",
            "scope": "scope",
        },
    },
    "php-tests": {
        "required": [],
        "checks": {
            "composer-args": "command_args",
            "coverage": "coverage_driver",
            "email": "email",
            "extensions": "php_extensions",
            "framework": "framework_mode",
            "max-retries": "numeric_range_1_10",
            "php-version": "semantic_version",
            "token": "github_token",
            "username": "username",
        },
    },
    "pr-lint": {
        "required": [],
        "checks": {
            "email": "email",
            "token": "github_token",
            "username": "username",
        },
    },
    "pre-commit": {
        "required": [],
        "checks": {
            "base-branch": "branch_name",
            "commit_email": "email",
            "commit_user": "git_author_name",
            "pre-commit-config": "file_path",
            "token": "github_token",
        },
    },
    "prettier-lint": {
        "required": [],
        "checks": {
            "cache": "boolean",
            "config-file": "file_path",
            "email": "email",
            "fail-on-error": "boolean",
            "file-pattern": "path_list",
            "ignore-file": "file_path",
            "max-retries": "numeric_range_1_10",
            "mode": "mode_enum",
            "plugins": "plugin_list",
            "prettier-version": "semantic_version",
            "report-format": "report_format",
            "token": "github_token",
            "username": "username",
            "working-directory": "file_path",
        },
    },
    "python-lint-fix": {
        "required": [],
        "checks": {
            "autopep8-version": "semantic_version",
            "email": "email",
            "fail-on-error": "boolean",
            "flake8-version": "semantic_version",
            "max-retries": "numeric_range_1_10",
            "python-version": "semantic_version",
            "token": "github_token",
            "username": "username",
            "working-directory": "file_path",
        },
    },
    "release-monthly": {
        "required": ["token"],
        "checks": {
            "dry-run": "boolean",
            "prefix": "prefix",
            "token": "github_token",
        },
    },
    "security-scan": {
        "required": [],
        "checks": {
            "actionlint-enabled": "boolean",
            "gitleaks-config": "file_path",
            "gitleaks-license": "license_key",
            "token": "github_token",
            "trivy-scanners": "scanner_list",
            "trivy-severity": "severity_enum",
            "trivy-timeout": "timeout_with_unit",
        },
    },
    "stale": {
        "required": [],
        "checks": {
            "days-before-close": "positive_integer",
            "days-before-stale": "positive_integer",
            "token": "github_token",
        },
    },
    "sync-labels": {
        "required": [],
        "checks": {
            "labels": "file_path",
            "token": "github_token",
        },
    },
    "terraform-lint-fix": {
        "required": [],
        "checks": {
            "auto-fix": "boolean",
            "config-file": "file_path",
            "email": "email",
            "fail-on-error": "boolean",
            "format": "report_format",
            "max-retries": "numeric_range_1_10",
            "terraform-version": "terraform_version",
            "tflint-version": "terraform_version",
            "token": "github_token",
            "username": "username",
            "working-directory": "file_path",
        },
    },
}
