# CLAUDE.md - GitHub Actions Monorepo

Guidance for Claude Code (claude.ai/code) when working with this repository.

## Repository Overview

**41 GitHub Actions** in a flat directory structure, each self-contained with an `action.yml`.

**Recent Achievements (August 2025):**

- ✅ Fixed critical token interpolation issues (GitHub expressions properly unquoted)
- ✅ Implemented automated action catalog generation with reference links
- ✅ All actions verified working with proper GitHub Actions expressions
- ✅ Comprehensive testing infrastructure (ShellSpec + pytest)
- ✅ Python validation system with extensive test coverage
- ✅ Modern development tooling (uv, ruff, pytest-cov)
- ✅ Project is in excellent state with all self-containment goals achieved

### Actions by Category

**Setup (7)**: `node-setup`, `set-git-config`, `php-version-detect`, `python-version-detect`, `python-version-detect-v2`, `go-version-detect`, `dotnet-version-detect`

**Utilities (2)**: `version-file-parser`, `version-validator`

**Linting (13)**: `ansible-lint-fix`, `biome-check`, `biome-fix`, `csharp-lint-check`, `eslint-check`, `eslint-fix`, `go-lint`,
`pr-lint`, `pre-commit`, `prettier-check`, `prettier-fix`, `python-lint-fix`, `terraform-lint-fix`

**Testing (3)**: `php-tests`, `php-laravel-phpunit`, `php-composer`

**Build (3)**: `csharp-build`, `go-build`, `docker-build`

**Publishing (5)**: `npm-publish`, `docker-publish`, `docker-publish-gh`, `docker-publish-hub`, `csharp-publish`

**Repository (8)**: `github-release`, `release-monthly`, `sync-labels`, `stale`, `compress-images`, `common-cache`, `common-file-check`, `common-retry`

## Development

### Commands

```bash
make all                  # Generate docs, format, lint, test
make dev                  # Format then lint
make lint                 # Run all linters
make format               # Format all files
make docs                 # Generate documentation
make test                 # Run all tests (shell + Python)
make test-python          # Run Python tests only
make test-python-coverage # Run Python tests with coverage
make update-validators    # Update validation rules for all actions
make update-validators-dry # Preview validation rules changes
```

### Linting Sequence

```bash
npx markdownlint-cli2 --fix "**/*.md"
npx prettier --write "**/*.md" "**/*.yml" "**/*.yaml" "**/*.json"
npx markdown-table-formatter "**/*.md"
npx yaml-lint "**/*.yml" "**/*.yaml"
actionlint
find . -name "*.sh" -not -path "./_tests/*" -exec shellcheck -x {} +  # Excludes shellspec files
uv run ruff check --fix validate-inputs/
uv run ruff format validate-inputs/
```

## Architecture Rules

### Security

- All external actions SHA-pinned
- Token authentication with `${{ github.token }}` fallback
- Shell scripts use `set -euo pipefail`

### Quality Standards

- EditorConfig: 2-space indent, UTF-8, LF
- Max line: 200 chars (120 for Markdown)
- README.md auto-generated via `action-docs`
- Comprehensive error handling required

## Validation System

### Centralized Input Validation

All actions use the `validate-inputs` action for centralized, Python-based input validation:

- **Location**: `validate-inputs/` directory with embedded Python validation
- **Rules**: Auto-generated YAML files in `validate-inputs/rules/`
- **Coverage**: High automated validation rule generation
- **Security**: PCRE regex support, injection protection, lookahead patterns
- **Generator**: Python-based rule generator (`update-validators.py`)

### Convention-Based Detection

Validation rules are automatically generated using naming conventions:

- `token` → GitHub token validation
- `*-version` → Version string validation (SemVer, CalVer, or flexible)
- `email` → Email format validation
- `dockerfile` → File path validation
- `dry-run` → Boolean validation
- `architectures` → Docker architecture validation
- `*-retries` → Numeric range validation

### Version Validation Types

The system supports multiple version validation schemes:

- **`semantic_version`**: Traditional SemVer (e.g., `1.2.3`, `2.0.0-beta`)
- **`calver_version`**: Calendar Versioning (e.g., `2024.3.1`, `24.03.15`)
- **`flexible_version`**: Accepts both CalVer and SemVer formats
- **`dotnet_version`**: .NET-specific version format
- **`terraform_version`**: Terraform-specific version format
- **`node_version`**: Node.js version format

Supported CalVer formats:

- `YYYY.MM.PATCH` (e.g., 2024.3.1)
- `YYYY.MM.DD` (e.g., 2024.3.15)
- `YYYY.0M.0D` (e.g., 2024.03.05)
- `YY.MM.MICRO` (e.g., 24.3.1)
- `YYYY.MM` (e.g., 2024.3)
- `YYYY-MM-DD` (e.g., 2024-03-15)

### Maintenance Workflow

```bash
# When adding new action inputs:
make update-validators    # Regenerate all validation rules
git diff validate-inputs/rules/  # Review generated changes
```

## Testing Framework

### Dual Testing Architecture

The project uses a dual testing approach:

- **Shell Testing**: ShellSpec framework for GitHub Actions and shell scripts (`_tests/`)
- **Python Testing**: pytest framework for validation system (`validate-inputs/tests/`)

### Test Commands

```bash
# Run all tests
make test

# Run specific test types
make test-python           # Python validation tests
make test-actions          # Shell-based action tests
make test-update-validators # Test the validation rule generator

# Coverage reporting
make test-coverage         # All tests with coverage
make test-python-coverage  # Python tests with coverage
```

### Test Requirements

- All validation logic must have comprehensive test coverage
- Actions should be tested independently
- Integration tests verify end-to-end workflows
- Mock GitHub API responses for reliable testing

---

**Note**: All actions achieve 100% external usability via modular composition.

- `npx action-docs --update-readme` doesn't actually update the readme files.
