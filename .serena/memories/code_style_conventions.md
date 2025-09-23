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

### **Local Action References**

**CRITICAL**: When referencing actions within the same repository:

- ✅ **CORRECT**: `uses: ./action-name` (relative to workspace root)
- ❌ **INCORRECT**: `uses: ../action-name` (relative paths that assume directory structure)

**Rationale**:

- Uses GitHub workspace root (`$GITHUB_WORKSPACE`) as reference point
- Clear and unambiguous regardless of where action is called from
- Follows GitHub's recommended pattern for same-repository references
- Avoids issues if action checks out repository to different location

**Examples**:

```yaml
# ✅ Correct - relative to workspace root
- uses: ./validate-inputs
- uses: ./common-cache
- uses: ./node-setup

# ❌ Incorrect - relative directory navigation
- uses: ../validate-inputs
- uses: ../common-cache
- uses: ../node-setup
```

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

## Pre-commit and Security Configuration

### Pre-commit Hooks (.pre-commit-config.yaml)

Comprehensive tooling with 11 different integrations:

**Local Integration**:

- `generate-docs-format-lint`: Runs `make all` for comprehensive project maintenance

**Core Quality Checks** (pre-commit-hooks v6.0.0):

- File integrity: trailing whitespace, end-of-file-fixer, mixed line endings
- Syntax validation: check-ast, check-yaml (multiple documents), check-toml, check-xml
- Security: detect-private-key, executable shebangs
- JSON formatting: pretty-format-json with autofix

**Language-Specific Linting**:

- **Markdown**: markdownlint v0.45.0 with auto-fix
- **YAML**: yamllint v1.37.1 for validation
- **Python**: ruff v0.13.0 for linting (with fix) and formatting
- **Shell**: shfmt v3.12.0-2 and shellcheck v0.11.0 (exclude `_tests/`)

**Infrastructure Tools**:

- **GitHub Actions**: actionlint v1.7.7 for workflow validation
- **Renovate**: renovate-config-validator v41.113.3
- **Security**: checkov v3.2.471 (quiet mode), gitleaks v8.28.0

### Gitleaks Configuration (.gitleaks.toml)

**Secret Detection**:

- Uses default gitleaks rules with smart exclusions
- Allowlisted paths: `node_modules`, `.git`, `dist`, lock files, `_tests`
- Dual-layer security with both pre-commit-hooks and gitleaks
- Test exclusion prevents false positives from test fixtures

### Test Compatibility

**ShellSpec Integration**:

- Shell linting tools (shfmt, shellcheck) exclude `_tests/` directory
- Prevents conflicts with ShellSpec test framework syntax
- Maintains code quality while preserving test functionality
