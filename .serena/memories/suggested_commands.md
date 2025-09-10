# Essential Development Commands

## Primary Development Workflow

### Complete Development Cycle

```bash
make all                    # Generate docs, format, lint, test everything
make dev                    # Format then lint (good for development)
make ci                     # CI workflow - check, docs, lint (no formatting)
```

### Individual Operations

```bash
make docs                   # Generate documentation for all actions
make format                 # Format all files (markdown, YAML, JSON, Python)
make lint                   # Run all linters
make check                  # Quick syntax and tool checks
make clean                  # Clean up temporary files and caches
```

## Testing Commands

### All Tests

```bash
make test                   # Run all tests (Python + GitHub Actions)
make test-coverage          # Run tests with coverage reporting
```

### Python Testing

```bash
make test-python            # Run Python validation tests
make test-python-coverage   # Run Python tests with coverage
make dev-python            # Format, lint, and test Python code
```

### GitHub Actions Testing

```bash
make test-actions           # Run GitHub Actions tests (ShellSpec)
make test-unit             # Run unit tests only
make test-integration      # Run integration tests only
make test-action ACTION=node-setup  # Test specific action
```

### Validation System

```bash
make update-validators      # Update validation rules for all actions
make update-validators-dry  # Preview validation rules changes
make test-update-validators # Test the validation rule generator
```

## Formatting Commands (Auto-fixing)

```bash
make format-markdown        # Format markdown files
make format-yaml-json      # Format YAML and JSON files
make format-tables         # Format markdown tables
make format-python         # Format Python files with ruff
```

## Linting Commands

```bash
make lint-markdown         # Lint markdown files
make lint-yaml            # Lint YAML files
make lint-shell           # Lint shell scripts with shellcheck
make lint-python          # Lint Python files with ruff
```

## Tool Installation

```bash
make install-tools         # Install/update all required tools
make check-tools          # Check if required tools are available
```

## Manual Tool Usage (when needed)

### Core Linting Sequence

```bash
# This is the exact sequence used by make lint
npx markdownlint-cli2 --fix "**/*.md"
npx prettier --write "**/*.md" "**/*.yml" "**/*.yaml" "**/*.json"
npx markdown-table-formatter "**/*.md"
npx yaml-lint "**/*.yml" "**/*.yaml"
actionlint
shellcheck **/*.sh
uv run ruff check --fix validate-inputs/
uv run ruff format validate-inputs/
```

### Python Development

```bash
uvx ruff check --fix       # Lint and fix Python files
uvx ruff format           # Format Python files
uv run pytest            # Run Python tests
uv run pytest --cov      # Run Python tests with coverage
```

## System-Specific Commands (Darwin/macOS)

### File Operations

```bash
rg "pattern"              # Fast code search (ripgrep)
fd "filename"            # Fast file finding
ls -la                   # List files with details
pwd                      # Show current directory
```

### Git Operations

```bash
git status               # Check repository status
git diff                 # Show changes
git add .               # Stage all changes
# Note: Never use `git commit` - manual commits not allowed
```

### Node.js (via nvm)

```bash
# nvm available at /Users/ivuorinen/.local/share/nvm/nvm.sh
source /Users/ivuorinen/.local/share/nvm/nvm.sh
nvm use                  # Activate Node.js version from .nvmrc
```

## Monitoring and Statistics

```bash
make stats               # Show repository statistics
make watch               # Watch files and auto-format on changes (requires entr)
```

## When Tasks Are Completed

### Required Quality Checks

Always run these commands after completing any coding task:

1. `make lint` - Fix all linting issues (blocking requirement)
2. `make test` - Ensure all tests pass
3. Check EditorConfig compliance (automatic via linting)

### Never Do These

- Never use `git commit` (manual commits not allowed)
- Never use `--no-verify` with git commands
- Never modify linting configuration unless explicitly told
- Never create files unless absolutely necessary
