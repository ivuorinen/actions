# Project Structure and Architecture

## Repository Structure

```text
/Users/ivuorinen/Code/ivuorinen/actions/
├── 41 Action Directories/          # Each action is self-contained
│   ├── action.yml                  # Action definition
│   └── README.md                   # Auto-generated documentation
├── validate-inputs/                # Centralized validation system
│   ├── validator.py               # Python validation logic
│   ├── rules/                     # Auto-generated validation rules
│   ├── scripts/                   # Rule generation and utilities
│   └── tests/                     # Python unit tests
├── _tests/                        # Testing framework
│   ├── run-tests.sh              # Test runner script
│   ├── unit/                     # Unit tests (ShellSpec)
│   ├── integration/              # Integration tests
│   └── framework/                # Testing utilities
├── Makefile                      # Build automation and tasks
├── pyproject.toml               # Python configuration and dependencies
├── CLAUDE.md                    # Project instructions for Claude
└── README.md                    # Auto-generated action catalog
```

## Action Categories and Examples

### Setup Actions (7)

- `node-setup`: Node.js environment with version detection
- `php-version-detect`: PHP version from composer.json/phprc
- `python-version-detect-v2`: Python version with enhanced detection
- `set-git-config`: Git configuration for actions

### Linting Actions (13)

- `eslint-fix`: JavaScript/TypeScript linting with auto-fix
- `prettier-fix`: Code formatting with auto-commit
- `python-lint-fix`: Python linting with ruff
- `pre-commit`: Pre-commit hooks execution

### Build/Testing Actions (6)

- `docker-build`: Multi-architecture Docker builds
- `go-build`: Go project compilation
- `php-tests`: PHPUnit test execution
- `php-laravel-phpunit`: Laravel-specific testing

### Publishing Actions (5)

- `npm-publish`: NPM package publishing
- `docker-publish-gh`: GitHub Package publishing
- `csharp-publish`: .NET package publishing

### Repository Management (8)

- `github-release`: Automated releases
- `sync-labels`: Repository label synchronization
- `compress-images`: Image optimization
- `common-cache`: Standardized caching

## Key Architectural Principles

### Self-Contained Design

- Each action directory contains everything needed for that action
- No dependencies between actions
- External usability via `ivuorinen/actions/action-name@main`

### Centralized Validation

- `validate-inputs/` provides common input validation
- Python-based with PCRE regex support
- Auto-generated rules from action.yml files
- Convention-based validation (token, version, email patterns)

### Dual Testing Strategy

- **ShellSpec**: Shell script and GitHub Actions testing
- **pytest**: Python validation system testing
- Both unit and integration test coverage

### Security Model

- All external actions SHA-pinned (not tag-based)
- No secrets committed to repository
- GitHub token patterns validated
- Command injection and path traversal protection

## Development Workflow Integration

### Documentation Generation

- README.md files auto-generated via `action-docs`
- Catalog generation with cross-references
- Consistent formatting and structure

### Quality Assurance

- EditorConfig enforcement (blocking)
- Multi-layer linting (markdown, YAML, shell, Python)
- Comprehensive test coverage requirements
- Automated validation rule updates

### Build System

- Makefile provides consistent interface
- Parallel execution capabilities
- Color-coded output for clarity
- Error handling and rollback on failures
