# GitHub Actions Monorepo - Overview

## Repository Info

- **Path**: /Users/ivuorinen/Code/ivuorinen/actions
- **Branch**: main
- **External Usage**: `ivuorinen/actions/<action-name>@main`
- **Total Actions**: 44 self-contained actions
- **Dogfooding**: Workflows use local actions (pr-lint, codeql-analysis, security-scan)

## Structure

```text
/
├── <action-dirs>/           # 44 self-contained actions
│   ├── action.yml          # Action definition
│   ├── README.md           # Auto-generated
│   └── CustomValidator.py  # Optional validator
├── validate-inputs/         # Centralized validation
│   ├── validators/         # 9 specialized modules
│   ├── scripts/            # Rule/test generators
│   └── tests/              # 769 pytest tests
├── _tests/                 # ShellSpec framework
├── _tools/                 # Development utilities
├── .github/workflows/      # CI/CD workflows
└── Makefile               # Build automation
```

## Action Categories (44 total)

**Setup (7)**: node-setup, set-git-config, php-version-detect, python-version-detect, python-version-detect-v2, go-version-detect, dotnet-version-detect

**Linting (13)**: ansible-lint-fix, biome-check/fix, csharp-lint-check, eslint-check/fix, go-lint, pr-lint, pre-commit, prettier-check/fix, python-lint-fix, terraform-lint-fix

**Security (1)**: security-scan (actionlint, Gitleaks, Trivy scanning)

**Build (3)**: csharp-build, go-build, docker-build

**Publishing (5)**: npm-publish, docker-publish, docker-publish-gh, docker-publish-hub, csharp-publish

**Testing (3)**: php-tests, php-laravel-phpunit, php-composer

**Repository (9)**: github-release, release-monthly, sync-labels, stale, compress-images, common-cache, common-file-check, common-retry, codeql-analysis

**Utilities (3)**: version-file-parser, version-validator, validate-inputs

## Key Principles

### Self-Contained Design

- No dependencies between actions
- Externally usable via GitHub Actions marketplace
- Custom validators colocated with actions

### Quality Standards

- **Zero Tolerance**: No failing tests, no linting issues
- **Production Ready**: Only when ALL checks pass
- **EditorConfig**: 2-space indent, LF, UTF-8, max 200 chars (120 for MD)

### Security Model

- SHA-pinned external actions (55 SHA-pinned, 0 unpinned)
- Token validation, injection detection
- Path traversal protection
- `set -euo pipefail` in all shell scripts

## Development Workflow

```bash
make all        # Full pipeline: docs, format, lint, test
make dev        # Format + lint
make lint       # All linters (markdownlint, yaml-lint, shellcheck, ruff)
make test       # All tests (pytest + ShellSpec)
```

## Testing Framework

- **ShellSpec**: GitHub Actions and shell scripts
- **pytest**: Python validators (769 tests, 100% pass rate)
- **Test Generator**: Automatic scaffolding for new actions

## Current Status

- ✅ All tests passing (769/769)
- ✅ Zero linting issues
- ✅ Modular validator architecture
- ✅ Convention-based validation
- ✅ Test generation system
- ✅ Full backward compatibility

## Dogfooding Strategy

The repository actively dogfoods its own actions in workflows:

**Fully Dogfooded Workflows**:

- **pr-lint.yml**: Uses `./pr-lint` (was 204 lines, now 112 lines - 45% reduction)
- **action-security.yml**: Uses `./security-scan` (was 264 lines, now 82 lines - 69% reduction)
- **codeql-new.yml**: Uses `./codeql-analysis`
- **sync-labels.yml**: Uses `./sync-labels`
- **version-maintenance.yml**: Uses `./action-versioning`

**Intentionally External**:

- **build-testing-image.yml**: Uses docker/\* actions directly (needs metadata extraction)
- Core GitHub actions (checkout, upload-artifact, setup-\*) kept for standardization

**Benefits**:

- Early detection of action issues
- Real-world testing of actions
- Reduced workflow duplication
- Improved maintainability
- Better documentation through usage examples
