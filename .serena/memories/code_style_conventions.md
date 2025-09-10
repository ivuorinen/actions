# Code Style and Conventions

## EditorConfig Rules (.editorconfig)

**CRITICAL**: EditorConfig violations are blocking errors and must be fixed always.

- **Charset**: UTF-8
- **Line Endings**: LF (Unix style)
- **Indentation**: 2 spaces (except Makefiles use tabs)
- **Final Newline**: Required
- **Max Line Length**: 200 characters (120 for Markdown)
- **Trailing Whitespace**: Trimmed
- **Tab Width**: 2 spaces

## Python Style (Ruff Configuration)

- **Target Version**: Python 3.8+
- **Line Length**: 100 characters
- **Indent Width**: 4 spaces
- **Quote Style**: Double quotes
- **Import Style**: isort with forced sorting within sections
- **Docstring Convention**: Google style

### Enabled Rule Sets

Comprehensive linting with 30+ rule categories including:

- pycodestyle, Pyflakes, isort, pep8-naming
- Security (bandit), bugbear, comprehensions
- Performance optimizations, refactoring suggestions
- Type checking, logging best practices

### Relaxed Rules for GitHub Actions

- Allow print statements (GitHub Actions logging)
- Allow sys.exit calls and broad exception catches
- Allow subprocess calls and validation-specific patterns
- Relaxed docstring requirements for simple scripts

## Shell Script Standards

- **Error Handling**: `set -euo pipefail` (exit on error, undefined vars, pipe failures)
- **Security**: All external actions SHA-pinned
- **Token Authentication**: `${{ github.token }}` fallback pattern
- **Validation**: shellcheck compliance required

## YAML/GitHub Actions Style

- **Indentation**: 2 spaces consistent with EditorConfig
- **Token Security**: Proper GitHub expression syntax (unquoted when needed)
- **Validation**: actionlint and yaml-lint compliance
- **Documentation**: Auto-generated README.md via action-docs

## Security Standards

- **No Secrets**: Never commit secrets or keys to repository
- **No Logging**: Never expose or log secrets/keys in code
- **SHA Pinning**: All external actions use SHA commits, not tags
- **Input Validation**: Centralized Python validation for all actions

## Naming Conventions

- **Actions**: kebab-case directory names (e.g., `node-setup`, `docker-build`)
- **Files**: kebab-case for action files, snake_case for Python modules
- **Variables**: snake_case in Python, kebab-case in YAML
- **Functions**: snake_case in Python, descriptive names in shell

## Quality Gates

- **Linting**: Zero tolerance - all linting errors are blocking
- **Testing**: Comprehensive test coverage required
- **Documentation**: Auto-generated and maintained
- **Validation**: All inputs validated through centralized system

## Development Patterns

- **Self-Contained Actions**: No cross-dependencies between actions
- **Modular Composition**: Actions achieve functionality through composition
- **Convention-Based**: Automatic rule generation based on input naming patterns
- **Error Handling**: Comprehensive error messages and proper exit codes
