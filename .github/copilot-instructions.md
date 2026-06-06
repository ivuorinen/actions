# GitHub Actions Monorepo - AI Coding Instructions

## Project Architecture

This is a **flat-structure GitHub Actions monorepo** with over 40 self-contained actions. Each action directory contains:

- `action.yml` - Action definition with inputs/outputs/branding
- `README.md` - Auto-generated documentation
- `validate.py` - Auto-generated, self-contained pure-stdlib input validator (do not edit manually; run via `python3 validate.py`)

**Core principle**: Actions are designed for external consumption with pinned refs like `ivuorinen/actions/action-name@2025-01-15`.

## Essential Workflows

### Development Commands

```bash
make all           # Complete workflow: docs + format + lint + test
make dev           # Quick dev cycle: format + lint only
make test          # Run all tests (ShellSpec + pytest)
make test-action ACTION=node-setup  # Test specific action
```

### Documentation Generation

- `make docs` auto-generates all README.md files from action.yml using action-docs
- `npm run update-catalog` rebuilds the main README.md action listing
- **Never manually edit** generated sections marked with `<!--LISTING-->`

### Validation System

- Each action with inputs has an auto-generated, self-contained `validate.py` (pure stdlib, no third-party deps) that validates `INPUT_*` env vars and fails with `::error::` + exit 1
- `_validation/` holds the generator sources: `kit.py` (canonical check functions — every regex/enum/range),
  `spec.py` (per-action input → check mapping + required inputs), and `generate.py` (inlines checks into each `<action>/validate.py`)
- `make update-validators` regenerates all `validate.py` files; `python3 _validation/generate.py --check` verifies the committed validators are current
- Validator tests live in `_validation/tests/` (pytest)

## Critical Patterns

### Action Structure

```yaml
# All actions follow this schema pattern:
name: Action Name
description: 'Brief description with key features'
branding:
  icon: server # Choose appropriate icon
  color: green # Choose appropriate color

inputs:
  # Required inputs first, then optional with defaults
  some-input:
    description: 'Clear description'
    required: false
    default: 'sensible-default'

outputs:
  # Always include relevant outputs for chaining
  result:
    description: 'What this output contains'
```

### Testing Framework

- **ShellSpec** for action testing in `_tests/unit/`
- **pytest** for Python validation testing
- Use `_tests/shared/` for common test utilities
- Integration tests use `nektos/act` for local GitHub Actions simulation

### Language Detection Actions

Actions like `node-setup`, `php-version-detect` follow auto-detection patterns:

1. Check project files (package.json, composer.json, go.mod, etc.)
2. Fallback to `default-version` input
3. Support `force-version` override
4. Output detected version for downstream actions

### Error Handling

- All actions use structured error messages
- Input validators are generated `validate.py` scripts built from `_validation/kit.py` checks; each check returns `None` on success or a short reason string on failure
- Shell scripts use POSIX `sh` with `set -eu` (not bash; `set -euo pipefail` is bash-only and forbidden)
- Always provide actionable error messages with context

## Development Standards

### Code Quality (Zero Tolerance)

- All linting must pass: markdownlint, yamllint, shellcheck, ruff
- All tests must pass: unit + integration
- No warnings allowed in production
- Use `make all` before committing

### Documentation

- Action descriptions must be concise and feature-focused
- Include examples in README.md (auto-generated from action.yml)
- Update CLAUDE.md for significant architectural changes
- Never edit auto-generated content manually

### Security

- Validate all user-provided input via the action's generated `validate.py` (run it as the first real step); define the rules in `_validation/spec.py` + `_validation/kit.py`
- Pin action versions in workflows with commit SHAs
- Follow least-privilege token permissions
- Implement proper secret handling patterns

## Key Files to Reference

- `CLAUDE.md` - Current architectural decisions and action inventory
- `Makefile` - Complete build system with all targets
- `_validation/kit.py` - Canonical validation check functions (regex/enum/range patterns)
- `_validation/spec.py` - Per-action input → check mapping and required inputs
- `_tests/shared/` - Testing utilities and patterns
- `_tools/fix-local-action-refs.py` - Reference resolution tooling

## Anti-Patterns to Avoid

- **Don't** manually edit generated `validate.py` files (edit `_validation/spec.py`/`_validation/kit.py`, then run `make update-validators`)
- **Don't** edit README.md between `<!--LISTING-->` markers
- **Don't** create actions without proper input validation
- **Don't** skip the `make all` verification step
- **Don't** use relative paths in action references (use `./action-name`)

## Integration Points

Actions are designed for composition:

1. **Setup actions** (node-setup, php-version-detect) prepare environment
2. **Linting actions** (eslint-check, biome-check) validate code quality
3. **Build actions** (docker-build, go-build) create artifacts
4. **Publishing actions** (npm-publish, docker-publish) deploy results

Use outputs from setup actions as inputs to subsequent actions for proper chaining.
