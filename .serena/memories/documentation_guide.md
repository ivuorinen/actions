# Documentation Guide

## Documentation Locations

### Validation System Docs (`validate-inputs/docs/`)

Read when working with validators or validation logic:

**API.md** - Complete API reference

- BaseValidator methods and properties
- Core validators (Boolean, Version, Token, Numeric, Docker, File, Network, Security, CodeQL)
- Registry system usage
- Custom validator patterns
- Convention system

**DEVELOPER_GUIDE.md** - Creating new validators

- Quick start guide
- Creating core validators (in validators/ directory)
- Creating custom validators (in action directories)
- Adding convention patterns
- Writing tests, debugging, common patterns

**ACTION_MAINTAINER.md** - Using validation in actions

- How validation works (automatic integration)
- Validation flow (input collection, validator selection, execution, error reporting)
- Using automatic validation via conventions
- Custom validation for complex scenarios
- Testing validation, common scenarios, troubleshooting

**README_ARCHITECTURE.md** - System architecture

- Feature overview
- Quick start examples
- Architecture details
- Modular validator structure
- Convention-based detection
- Custom validator support

### Testing Framework (`_tests/README.md`)

Read when writing or debugging tests:

- ShellSpec framework overview
- Multi-level testing strategy (unit, integration, external usage)
- Directory structure explanation
- Test writing patterns
- Running tests (`make test`, `make test-unit`, `make test-action ACTION=name`)
- Coverage reporting
- Mocking and fixtures
- CI integration

### Docker Testing Tools (`_tools/docker-testing-tools/README.md`)

Read when working with CI or testing infrastructure:

- Pre-built Docker image with all testing tools
- Pre-installed tools (ShellSpec, nektos/act, TruffleHog, actionlint, etc.)
- Building locally (build.sh, test.sh)
- Performance benefits (saves ~3 minutes per run)
- Multi-stage build process
- Usage in workflows

### Top-Level Documentation

**README.md** - Main project readme (auto-generated)

- Actions catalog
- Usage examples
- Quick reference

**SECURITY.md** - Security policy

- Reporting vulnerabilities
- Security practices

**LICENSE.md** - MIT license

**CLAUDE.md** - Project instructions (covered in development_standards memory)

## When to Read What

**Starting new validator work**: Read `DEVELOPER_GUIDE.md`, then `API.md` for reference

**Using validation in action**: Read `ACTION_MAINTAINER.md`

**Understanding architecture**: Read `README_ARCHITECTURE.md`

**Writing tests**: Read `_tests/README.md`

**Setting up CI/testing**: Read `_tools/docker-testing-tools/README.md`

**API reference lookup**: Read `API.md` (has method tables, validator details)

## Documentation is Auto-Generated

- Action READMEs generated via `action-docs` (don't edit manually)
- Validation system README auto-generated
- Keep CLAUDE.md and docs/ files updated manually
