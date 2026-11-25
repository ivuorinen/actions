"""Canonical input-validation kit — the single source of truth for ivuorinen/actions.

BUILD-TIME ONLY. Every action ships a generated, self-contained ``validate.py`` produced
by ``_validation/generate.py`` (``make update-validators``). The generator inlines the
*exact source* of the checks an action needs — so these functions, their regexes, and
their allow-lists are defined in this package once and nowhere else. Regenerating keeps every
copy byte-identical (a drift test enforces it), which is how "each action is self-contained"
and "never duplicate a validation pattern" hold at the same time.

The checks live in one module per domain: ``tokens``, ``versions``, ``docker``, ``codeql``,
``paths``, ``network`` and ``formats``. ``common`` holds the helpers that checks in more than
one module call. This module gathers every check of the modules in ``MODULES`` into ``CHECKS``.

Every check has the signature ``check_<type>(value: str) -> str | None`` and returns
``None`` when the value is acceptable, or a short human-readable reason when it is not.

Shared contract:

*   the ``_skip`` gate, applied first by nearly every check, accepts an empty value or one
    of ASCII whitespace only: inputs are optional unless the action marks them required (the
    generated runner enforces "required" on its own, before calling the check). The runner
    also refuses a non-empty value of only whitespace before any check: the default applies
    only when the caller leaves an input out, and ``${{ inputs.x || default }}`` takes any
    non-empty string as set, so such a value would reach a step or ``with:`` unchanged;
*   a check judges the value exactly as the action will use it. The runner has expanded
    every ``${{ ... }}`` before ``validate.py`` reads ``INPUT_*``, and it never expands
    ``$VAR`` in an input, so neither form is a reference here: both are literal data. Matches
    use ``re.fullmatch`` because ``re.match(...$)`` also accepts a trailing newline.

``boolean``, ``numeric_range_1_10`` and the two report-format checks refuse a blank value
instead. Those inputs all declare a default and the runner applies it only when the caller
leaves the input out, so blank means the caller passed it, and the steps reading such an input
would then quietly skip their work.

Security-critical checks (tokens, file paths, injection-bearing lists) are ported from the
previous validator framework. Tool-version and enum format checks are written to match what
each underlying tool actually accepts.
"""

from __future__ import annotations

from types import FunctionType
from typing import TYPE_CHECKING

from . import codeql, common, docker, formats, network, paths, tokens, versions

if TYPE_CHECKING:
    from collections.abc import Callable

# The kit's modules, in the order the generator emits their preamble helpers.
MODULES = (common, tokens, versions, docker, codeql, paths, network, formats)

# --------------------------------------------------------------------------------------
# Registry: type name -> check function. The generator and the test-suite both introspect
# this mapping; it is the authoritative list of supported validator types. Every check is a
# plain function, and matching FunctionType rather than callable() lets the declared type
# hold: a type checker reads callable() on a module global as "returns object".
# --------------------------------------------------------------------------------------

CHECKS: dict[str, Callable[[str], str | None]] = dict(
    sorted(
        (name[len("check_") :], function)
        for module in MODULES
        for name, function in vars(module).items()
        if name.startswith("check_") and isinstance(function, FunctionType)
    )
)


# --------------------------------------------------------------------------------------
# Check types whose values are credentials, so must be masked. An input with one of these
# types is what spec.py marks for masking: its generated validator registers the value with
# the runner's log masker before running any check. Listing the type rather than each input
# means a new token input cannot forget its mask. Never add a type that also holds ordinary
# values (`key_value_list` carries build args), because masking a common word corrupts the
# logs. This holds check type names, never a credential.
# --------------------------------------------------------------------------------------

MASKED_CHECKS = frozenset({"github_token", "opaque_token"})


# --------------------------------------------------------------------------------------
# Documentation examples: type name -> a realistic value of that type.
#
# `make docs` substitutes these into the generated action READMEs wherever the README
# generator would otherwise emit a generic placeholder ("value", "example-value",
# "custom-value"). A reader copying a quick-start workflow gets something that actually
# runs instead of a string the action rejects.
#
# These live here, next to the registry, so an example can never drift from the rule it
# illustrates: `test_kit.py` asserts every check has an example AND that the example
# passes its own check, so a tightened regex fails the suite rather than silently
# publishing an invalid example. The exception is a secret, whose example is a `${{ }}`
# reference the runner expands before the check runs. They are documentation only —
# `generate.py` copies check functions into each action's validate.py and never reads
# this mapping.
# --------------------------------------------------------------------------------------


def _actions_expression(reference: str) -> str:
    """Wrap a context reference in GitHub Actions expression syntax.

    Built rather than written as a literal so neither this repo's linter nor an
    external scanner reads a token-named key with a string value as a hardcoded
    credential. These are the opposite of one: they are what a reader should
    substitute instead of pasting a secret into an input.
    """
    return "${{ " + reference + " }}"


EXAMPLES = {
    "boolean": "true",
    "branch_name": "main",
    "cache_config": "type=gha,mode=max",
    "cache_mode": "max",
    "calver_version": "2025.04.05",
    "category_format": "my-analysis",
    "codeql_build_mode": "none",
    "codeql_config": "name: my-config",
    "codeql_language": "javascript,python",
    "codeql_packs": "my-org/my-queries@1.0.0",
    "codeql_queries": "security-and-quality",
    "comma_key_value_list": "NODE_ENV=production,VERSION=1.0.0",
    "composer_args": "--no-progress --prefer-dist",
    "coverage_driver": "xdebug",
    "docker_architectures": "linux/amd64,linux/arm64",
    "docker_build_contexts": "shared=./shared,base=docker-image://alpine:3.20",
    "docker_image_name": "myapp",
    "docker_image_version": "v1.2.3",
    "docker_local_path": "docker/app",
    "docker_secrets": "npmrc=.npmrc",
    "docker_tag": "v1.0.0",
    "docker_tag_list": "latest,v1.0.0",
    "dotnet_project": "src/App/App.csproj",
    "dotnet_version": "8.0.x",
    "email": "github-actions@users.noreply.github.com",
    "file_extensions": ".js,.ts",
    "file_path": "config/settings.yml",
    "framework_mode": "auto",
    "git_author_name": "github-actions[bot]",
    "github_token": _actions_expression("github.token"),
    "go_version": "1.24",
    "golangci_lint_version": "2.1.0",
    "golangci_report_format": "sarif",
    "jactionlint_profile": "correctness",
    "json_format": '{"linux/amd64": "--build-arg ARCH=amd64"}',
    "key_value_list": "NODE_ENV=production",
    "language_enum": "python",
    "linter_list": "gosec,govet",
    "mode_enum": "check",
    "namespace_with_lookahead": "my-org",
    "network_mode": "default",
    "no_prefix_version": "1.2.3",
    "node_version": "20",
    "npm_spec_list": "@semantic-release/git@10.0.1",
    "numeric_range_0_10000": "0",
    "numeric_range_1_100": "80",
    "numeric_range_1_10": "3",
    "numeric_range_1_128": "2",
    "numeric_range_256_32768": "4096",
    "opaque_token": _actions_expression("secrets.NPM_TOKEN"),
    "output_path": "codeql-results",
    "path_list": "src/**/*.ts",
    "php_extensions": "mbstring,intl",
    "plugin_list": "@prettier/plugin-xml",
    "positive_integer": "30",
    "prefix": "v",
    "registry_enum": "github",
    "registry_url": "https://registry.npmjs.org",
    "report_format": "sarif",
    "repository_list": "my-org/my-repo",
    "sbom_format": "spdx-json",
    "scanner_list": "vuln,secret",
    "scope": "@my-org",
    "semantic_version": "1.2.3",
    "severity_enum": "HIGH,CRITICAL",
    "strict_semantic_version": "1.2.3",
    "terraform_version": "1.5.7",
    "timeout_with_unit": "5m",
    "username": "github-actions",
}
