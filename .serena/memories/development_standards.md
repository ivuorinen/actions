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

### Version Management

```bash
make release [VERSION=vYYYY.MM.DD]  # Create new release (auto-generates version from date if omitted)
make update-version-refs MAJOR=vYYYY # Update refs to version
make bump-major-version OLD=vYYYY NEW=vYYYY  # Annual bump
make check-version-refs              # Verify current refs
```

See `versioning_system` memory for complete details.

## Code Style

### EditorConfig (BLOCKING ERRORS)

- **Indent**: 2 spaces (4 for Python, tabs for Makefile)
- **Charset**: UTF-8
- **Line Endings**: LF
- **Max Line**: 200 chars (120 for Markdown)
- **Final Newline**: Required
- **Trailing Whitespace**: Trimmed

### Shell Scripts (POSIX REQUIRED)

**ALL scripts use POSIX shell** (`#!/bin/sh`) for maximum portability:

```bash
#!/bin/sh
set -eu                    # MANDATORY (no pipefail - not POSIX)
# Quote everything: "$variable", basename -- "$path"
# Check tools: command -v jq >/dev/null 2>&1
# Use printf instead of echo -e for portability
```

**Why POSIX:**

- Works on Alpine Linux, busybox, minimal containers
- Faster than bash
- Maximum compatibility (sh, dash, ash, bash, zsh)
- CI-friendly, minimal dependencies

**Key Differences from Bash:**

- Use `#!/bin/sh` not `#!/usr/bin/env bash`
- Use `set -eu` not `set -euo pipefail` (pipefail not POSIX)
- Use `[ ]` not `[[ ]]`
- Use `printf` not `echo -e`
- Use `. file` not `source file`
- Use `cut`/`grep` for parsing, not here-strings `<<<`
- Use temp files instead of associative arrays
- Use `$0` not `$BASH_SOURCE`

### Python (Ruff)

- **Line Length**: 100 chars
- **Indent**: 4 spaces
- **Quotes**: Double
- **Docstrings**: Google style
- **Type Hints**: Required

### YAML/Actions

- **Indent**: 2 spaces
- **Internal Actions (action.yml)**: `ivuorinen/actions/action-name@<SHA>` (SHA-pinned, security)
- **Test Workflows**: `./action-name` (local reference, runs within repo)
- **Internal Workflows**: `./action-name` (local reference for sync-labels.yml etc)
- **External Actions**: SHA-pinned (not `@main`/`@v1`)
- **Step IDs**: Required when outputs referenced
- **Permissions**: Minimal scope (contents: read default)
- **Output Sanitization**: Use `printf`, never `echo` for `$GITHUB_OUTPUT`

## Versioning System

### Internal References (SHA-Pinned)

All `*/action.yml` files use SHA-pinned references for security and reproducibility:

```yaml
uses: ivuorinen/actions/validate-inputs@7061aafd35a2f21b57653e34f2b634b2a19334a9
```

**Why SHA-pinned internally:**

- Security: immutable, auditable references
- Reproducibility: exact version control
- Portability: works when actions used externally
- Prevention: no accidental version drift

### Test Workflows (Local References)

Test workflows in `_tests/` use local references:

```yaml
uses: ./validate-inputs
```

**Why local in tests:** Tests run within the repo, faster, simpler

### External User References

Users reference with version tags:

```yaml
uses: ivuorinen/actions/validate-inputs@v2025
```

### Version Format (CalVer)

- Major: `v2025` (year)
- Minor: `v2025.10` (year.month)
- Patch: `v2025.10.18` (year.month.day)

All three tags point to the same commit SHA.

### Creating Releases

```bash
make release                     # Auto-generates vYYYY.MM.DD from today's date
make release VERSION=v2025.10.18 # Specific version
git push origin main --tags --force-with-lease
```

## Security Requirements

1. **SHA Pinning**: All action references use commit SHAs (not moving tags)
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
- Never use `@main` for internal action references (use SHA-pinned)
- Never use bash-specific features (scripts must be POSIX sh)

## Preferred Patterns

- POSIX shell for all scripts (not bash)
- SHA-pinned internal action references (security)
- Edit existing files over creating new ones
- Use centralized validation for all input handling
- Follow existing conventions in codebase
- Actions use composition, not dependencies
- Custom validators in action directories
- Convention-based automatic detection
