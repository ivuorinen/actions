# Code Style and Conventions

## Critical Prevention Guidelines

1. **ALWAYS** add `id:` when step outputs will be referenced
   - Missing IDs cause `steps.*.outputs.*` to be undefined at runtime
   - Example: `id: detect-version` required before `steps.detect-version.outputs.version`

2. **ALWAYS** check tool availability before use
   - Not all tools (jq, bc, terraform) are available on all runner types
   - Pattern: `if command -v jq >/dev/null 2>&1; then ... else fallback; fi`

3. **ALWAYS** sanitize user input before writing to `$GITHUB_OUTPUT`
   - Malicious inputs with newlines can inject additional outputs
   - Use `printf '%s\n' "$value"` or heredoc instead of `echo "$value"`

4. **ALWAYS** pin external actions to commit SHAs, not branches
   - `@main` or `@v1` tags can change, breaking reproducibility
   - Use full SHA: `actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683`

5. **ALWAYS** quote shell variables to handle spaces
   - Unquoted variables cause word splitting and globbing
   - Example: `"$variable"` not `$variable`, `basename -- "$path"` not `basename $path`

6. **ALWAYS** use local paths (`./action-name`) for intra-repo actions
   - Avoids external dependencies and version drift
   - Pattern: `uses: ./common-cache` not `uses: ivuorinen/actions/common-cache@main`

7. **ALWAYS** test regex patterns against edge cases
   - Include prerelease tags (`1.0.0-rc.1`), build metadata (`1.0.0+build.123`)
   - Version validation should support full semver/calver formats

8. **ALWAYS** use `set -euo pipefail` at script start
   - `-e`: Exit on error, `-u`: Exit on undefined variable, `-o pipefail`: Exit on pipe failures
   - Critical for fail-fast behavior in composite actions

9. **NEVER** interpolate expressions inside quoted strings in YAML
   - `"${{ inputs.value }}"` in hashFiles breaks cache key generation
   - Use unquoted or extract to separate variable first

10. **NEVER** assume tools are available across all runner types
    - macOS/Windows runners may lack Linux tools (jq, bc, specific GNU utils)
    - Always provide fallbacks or explicit installation steps

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
- **Variable Quoting**: Always quote to prevent word splitting: `"$var"`, `basename -- "$path"`
- **Tool Availability**: Check before use: `command -v tool >/dev/null 2>&1`

## YAML/GitHub Actions Style

- **Indentation**: 2 spaces consistent with EditorConfig
- **Token Security**: Proper GitHub expression syntax (unquoted when needed)
- **Validation**: actionlint and yaml-lint compliance
- **Documentation**: Auto-generated README.md via action-docs
- **Expression Safety**: Never nest `${{ }}` inside quoted strings

### **Local Action References**

**CRITICAL**: When referencing actions within the same repository:

- ✅ **CORRECT**: `uses: ./action-name` (relative to workspace root)
- ❌ **INCORRECT**: `uses: ../action-name` (relative paths that assume directory structure)
- ❌ **INCORRECT**: `uses: owner/repo/action-name@main` (floating branch reference)

**Rationale**:

- Uses GitHub workspace root (`$GITHUB_WORKSPACE`) as reference point
- Clear and unambiguous regardless of where action is called from
- Follows GitHub's recommended pattern for same-repository references
- Avoids issues if action checks out repository to different location
- Eliminates external dependencies and supply chain risks

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

# ❌ Incorrect - external reference to same repo
- uses: ivuorinen/actions/validate-inputs@main
- uses: ivuorinen/actions/common-cache@v1
```

### **Step Output References**

**CRITICAL**: Steps must have `id:` to reference their outputs:

```yaml
# ❌ INCORRECT - missing id
- name: Detect Version
  uses: ./version-detect

- name: Setup
  with:
    version: ${{ steps.detect-version.outputs.version }} # UNDEFINED!

# ✅ CORRECT - id present
- name: Detect Version
  id: detect-version # Required for output reference
  uses: ./version-detect

- name: Setup
  with:
    version: ${{ steps.detect-version.outputs.version }} # Works
```

## Security Standards

- **No Secrets**: Never commit secrets or keys to repository
- **No Logging**: Never expose or log secrets/keys in code
- **SHA Pinning**: All external actions use SHA commits, not tags
- **Input Validation**: Centralized Python validation for all actions
- **Output Sanitization**: Use `printf` or heredoc for `$GITHUB_OUTPUT` writes
- **Injection Prevention**: Validate inputs for command injection patterns (`;`, `&&`, `|`, backticks)

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
- **Defensive Programming**: Check tool availability, validate inputs, handle edge cases

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
