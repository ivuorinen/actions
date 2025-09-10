# Task Completion Requirements

## Mandatory Steps After Completing Any Task

### 1. Linting (BLOCKING REQUIREMENT)

```bash
make lint                    # Run all linters - must pass 100%
```

**Critical Rules:**

- EditorConfig violations are BLOCKING errors - fix always
- All linting issues are NOT ACCEPTABLE and must be resolved
- Never simplify linting configuration to make tests pass
- Linting tools decisions are final and must be obeyed
- Consider ALL linting errors as blocking errors

**Specific Linting Steps:**

```bash
make lint-markdown          # Fix markdown issues
make lint-yaml             # Fix YAML issues
make lint-shell            # Fix shell script issues
make lint-python           # Fix Python code issues
```

### 2. Testing (VERIFICATION REQUIREMENT)

```bash
make test                   # Run all tests - must pass 100%
```

**Test Categories:**

- Python validation tests (pytest)
- GitHub Actions tests (ShellSpec)
- Integration tests
- Coverage reporting

### 3. Formatting (AUTO-FIX REQUIREMENT)

```bash
make format                 # Auto-fix all formatting issues
```

**Always use autofixers before running linters:**

- Markdown formatting and table formatting
- YAML/JSON formatting with prettier
- Python formatting with ruff
- Line ending and whitespace fixes

## Verification Checklist

### Before Considering Task Complete

- [ ] `make lint` passes with zero issues
- [ ] `make test` passes with 100% success
- [ ] EditorConfig rules followed (2-space indent, LF endings, UTF-8)
- [ ] No trailing whitespace or missing final newlines
- [ ] Shell scripts pass shellcheck
- [ ] Python code passes ruff with comprehensive rules
- [ ] YAML files pass yaml-lint and actionlint
- [ ] Markdown passes markdownlint-cli2

### Security and Quality Gates

- [ ] No secrets or credentials committed
- [ ] No hardcoded tokens or API keys
- [ ] Proper error handling with `set -euo pipefail`
- [ ] External actions are SHA-pinned
- [ ] Input validation through centralized system

## Error Resolution Strategy

### When Linting Fails

1. **Read the error message carefully** - don't ignore details
2. **Read the linting tool schema** - understand the rules
3. **Compare against schema** - schema is the truth
4. **Fix the actual issue** - don't disable rules
5. **Use autofix first** - `make format` before manual fixes

### When Tests Fail

1. **Fix all errors and warnings** - no exceptions
2. **Ensure proper test coverage** - comprehensive testing required
3. **Verify integration points** - actions must work together
4. **Check validation logic** - centralized validation must pass

### Common Issues and Solutions

- **EditorConfig**: Use exactly 2 spaces, LF endings, UTF-8
- **Python**: Follow Google docstring style, 100 char lines
- **Shell**: Use shellcheck-compliant patterns
- **YAML**: Proper indentation, no trailing spaces
- **Markdown**: Tables formatted, links valid, consistent style

## Never Do These

- Never use `git commit` without explicit user request
- Never use `--no-verify` flags
- Never modify linting configuration to make tests pass
- Never assume linting issues are acceptable
- Never skip testing after code changes
- Never create files unless absolutely necessary

## File Modification Preferences

- **Always prefer editing existing files** over creating new ones
- **Never proactively create documentation** unless requested
- **Read project patterns** before making changes
- **Follow existing conventions** in the codebase
- **Use centralized validation** for all input handling

## Final Verification

After ALL tasks are complete, run the full development cycle:

```bash
make all                    # Complete workflow: docs, format, lint, test
```

This ensures the project maintains its excellent state and all quality gates pass.
