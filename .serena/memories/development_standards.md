# Development Standards & Workflows

## Quality Standards (ZERO TOLERANCE)

### Production Ready Criteria

- ALL tests pass (100% success rate)
- ALL linting passes (zero issues)
- ALL validation checks pass
- NO warnings or errors

### Communication

- Direct, factual only
- Never claim "production ready" until literally everything passes
- No hype, buzzwords, or excessive enthusiasm

## Required Commands

### Development Cycle

```bash
make all        # Complete: docs, format, lint, test
make dev        # Format + lint (development)
make lint       # All linters (MUST pass 100%)
make test       # All tests (MUST pass 100%)
make format     # Auto-fix formatting
```

### Task Completion Checklist

After ANY coding task:

- [ ] `make lint` - Fix all issues (blocking)
- [ ] `make test` - Ensure 100% pass
- [ ] EditorConfig compliance verified

### Validation System

```bash
make update-validators      # Generate validation rules
make update-validators-dry  # Preview changes
make generate-tests         # Create missing tests
make generate-tests-dry     # Preview test generation
```

## Code Style

### EditorConfig (BLOCKING ERRORS)

- **Indent**: 2 spaces (4 for Python, tabs for Makefile)
- **Charset**: UTF-8
- **Line Endings**: LF
- **Max Line**: 200 chars (120 for Markdown)
- **Final Newline**: Required
- **Trailing Whitespace**: Trimmed

### Shell Scripts (REQUIRED)

```bash
#!/usr/bin/env bash
set -euo pipefail          # MANDATORY
IFS=$' \t\n'
trap cleanup EXIT
trap 'echo "Error at line $LINENO" >&2' ERR
# Always quote: "$variable", basename -- "$path"
# Check tools: command -v jq >/dev/null 2>&1
```

### Python (Ruff)

- **Line Length**: 100 chars
- **Indent**: 4 spaces
- **Quotes**: Double
- **Docstrings**: Google style
- **Type Hints**: Required

### YAML/Actions

- **Indent**: 2 spaces
- **Local Actions**: `uses: ./action-name` (never `../` or `@main`)
- **External Actions**: SHA-pinned (not `@main`/`@v1`)
- **Step IDs**: Required when outputs referenced
- **Permissions**: Minimal scope (contents: read default)
- **Output Sanitization**: Use `printf`, never `echo` for `$GITHUB_OUTPUT`

## Security Requirements

1. **SHA Pinning**: All external actions use commit SHAs
2. **Token Safety**: `${{ github.token }}`, never hardcoded
3. **Input Validation**: All inputs validated via centralized system
4. **Output Sanitization**: `printf '%s\n' "$value" >> $GITHUB_OUTPUT`
5. **Injection Prevention**: Validate for `;`, `&&`, `|`, backticks
6. **Tool Availability**: `command -v tool` checks before use
7. **Variable Quoting**: Always `"$var"` in shell
8. **No Secrets**: Never commit credentials/keys

## Never Do

- Never `git commit` (manual commits not allowed)
- Never use `--no-verify` flags
- Never modify linting config to make tests pass
- Never assume linting issues are acceptable
- Never skip testing after changes
- Never create files unless absolutely necessary
- Never nest `${{ }}` in quoted YAML strings (breaks hashFiles)

## Preferred Patterns

- Edit existing files over creating new ones
- Use centralized validation for all input handling
- Follow existing conventions in codebase
- Actions use composition, not dependencies
- Custom validators in action directories
- Convention-based automatic detection
