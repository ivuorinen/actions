# Project Structure and Architecture

## Repository Structure

```text
/Users/ivuorinen/Code/ivuorinen/actions/
├── Action Directories/            # Each action is self-contained
│   ├── action.yml                # Action definition
│   ├── README.md                 # Auto-generated documentation
│   └── CustomValidator.py        # Optional custom validator
├── validate-inputs/               # Centralized validation system
│   ├── validator.py              # Main entry point
│   ├── validators/               # Modular validator architecture
│   │   ├── base.py              # Abstract base class
│   │   ├── registry.py          # Dynamic validator discovery
│   │   ├── conventions.py       # Convention-based detection
│   │   ├── boolean.py           # Boolean validation
│   │   ├── codeql.py           # CodeQL-specific validation
│   │   ├── docker.py           # Docker validation
│   │   ├── file.py             # File path validation
│   │   ├── network.py          # Network/URL validation
│   │   ├── numeric.py          # Numeric validation
│   │   ├── security.py         # Security pattern detection
│   │   ├── token.py            # Token validation
│   │   └── version.py          # Version validation
│   ├── rules/                    # Auto-generated YAML rules
│   ├── scripts/                  # Rule generation utilities
│   └── tests/                    # Comprehensive pytest suite (292 tests)
├── _tests/                       # ShellSpec testing framework
│   ├── unit/                    # Unit tests for actions
│   ├── framework/               # Testing utilities
│   └── shared/                  # Shared test components
├── _tools/                       # Development utilities
│   ├── docker-testing-tools/    # Docker test environment
│   └── fix-local-action-refs.py # Action reference fixer
├── .github/                      # GitHub configuration
│   └── workflows/               # CI/CD workflows
├── .serena/                     # Serena AI configuration
│   └── memories/               # Project knowledge base
├── Makefile                     # Build automation
├── pyproject.toml              # Python configuration
├── CLAUDE.md                   # Project instructions
└── README.md                   # Auto-generated catalog
```

## Modular Validator Architecture

### Core Components

- **BaseValidator**: Abstract interface for all validators
- **ValidatorRegistry**: Dynamic discovery and loading
- **ConventionMapper**: Automatic validation based on naming patterns

### Specialized Validators

1. **TokenValidator**: GitHub, NPM, PyPI, Docker tokens
2. **VersionValidator**: SemVer, CalVer, language-specific
3. **BooleanValidator**: Case-insensitive boolean values
4. **NumericValidator**: Ranges and numeric constraints
5. **DockerValidator**: Images, tags, platforms, registries
6. **FileValidator**: Paths, extensions, security checks
7. **NetworkValidator**: URLs, emails, IPs, ports
8. **SecurityValidator**: Injection detection, secrets
9. **CodeQLValidator**: Queries, languages, categories

### Custom Validators

- `sync-labels/CustomValidator.py` - YAML file validation
- `docker-build/CustomValidator.py` - Complex build validation
- `codeql-analysis/CustomValidator.py` - Language and query validation
- `docker-publish/CustomValidator.py` - Registry and credential validation

## Action Categories

### Setup Actions (7)

- `node-setup`, `set-git-config`, `php-version-detect`
- `python-version-detect`, `python-version-detect-v2`
- `go-version-detect`, `dotnet-version-detect`

### Linting Actions (13)

- `ansible-lint-fix`, `biome-check`, `biome-fix`
- `csharp-lint-check`, `eslint-check`, `eslint-fix`
- `go-lint`, `pr-lint`, `pre-commit`
- `prettier-check`, `prettier-fix`
- `python-lint-fix`, `terraform-lint-fix`

### Build Actions (3)

- `csharp-build`, `go-build`, `docker-build`

### Publishing Actions (5)

- `npm-publish`, `docker-publish`
- `docker-publish-gh`, `docker-publish-hub`
- `csharp-publish`

### Testing Actions (3)

- `php-tests`, `php-laravel-phpunit`, `php-composer`

### Repository Management (9)

- `github-release`, `release-monthly`
- `sync-labels`, `stale`
- `compress-images`, `common-cache`
- `common-file-check`, `common-retry`
- `codeql-analysis`

### Utilities (2)

- `version-file-parser`, `version-validator`

## Key Architectural Principles

### Self-Contained Design

- Each action directory contains everything needed
- No dependencies between actions
- External usability via `ivuorinen/actions/action-name@main`
- Custom validators colocated with actions

### Modular Validation System

- Specialized validators for different input types
- Convention-based automatic detection (100+ patterns)
- Priority system for pattern matching
- Error propagation between validators
- Full GitHub expression support (`${{ }}`)

### Testing Strategy

- **ShellSpec**: Shell scripts and GitHub Actions
- **pytest**: Python validation system (100% pass rate)
- **Coverage**: All validators have dedicated test files
- **Standards**: Zero tolerance for failures

### Security Model

- SHA-pinned external actions
- Token pattern validation
- Injection detection
- Path traversal protection
- Security validator for sensitive data

## Development Workflow

### Core Commands

```bash
make all                    # Full build pipeline
make dev                    # Format and lint
make lint                   # All linters
make test                   # All tests
make update-validators      # Generate validation rules
```

### Quality Standards

- **EditorConfig**: Blocking enforcement
- **Linting**: Zero issues required
- **Testing**: 100% pass rate required
- **Production Ready**: Only when ALL checks pass

### Documentation

- Auto-generated README files via `action-docs`
- Consistent formatting and structure
- Cross-referenced action catalog
- Comprehensive inline documentation
