# Project Overview - GitHub Actions Monorepo

## Purpose

This repository contains a collection of reusable GitHub Actions designed to streamline CI/CD processes and ensure code quality. Each action is fully self-contained and can be used independently in any GitHub repository.

## Repository Information

- **Branch**: feat/upgrades-and-restructuring
- **Location**: /Users/ivuorinen/Code/ivuorinen/actions
- **External Usage**: `ivuorinen/actions/action-name@main`
- **Last Updated**: January 2025

## Key Features

- **Production-Ready Actions** covering setup, linting, building, testing, and deployment
- **Self-Contained Design** - each action works independently without dependencies
- **Modular Validator Architecture** - specialized validators with convention-based auto-detection
- **Custom Validator Support** - complex actions have dedicated validation logic
- **Test Generation System** - automatic test scaffolding with intelligent pattern detection
- **Multi-Language Support** including Node.js, PHP, Python, Go, C#, Docker, and more
- **Comprehensive Testing** with dual framework (ShellSpec + pytest)
- **Zero Defect Policy** - 100% test pass rate, zero linting issues required

## Architecture Highlights

### Directory Structure

- **Flat Action Layout**: Each action in its own directory with `action.yml`
- **Centralized Validation**: `validate-inputs/` with modular validator system
- **Custom Validators**: Action-specific validators (e.g., `docker-build/CustomValidator.py`)
- **Testing Infrastructure**: `_tests/` for ShellSpec, `validate-inputs/tests/` for pytest
- **Build Tools**: `_tools/` for helper scripts and development utilities
- **Test Generation**: `validate-inputs/scripts/generate-tests.py` for automatic test creation

### Validation System (Modular Architecture)

```
validate-inputs/
├── validator.py              # Main entry point
├── validators/
│   ├── base.py              # Abstract base class
│   ├── registry.py          # Dynamic validator discovery
│   ├── conventions.py       # Convention-based auto-detection
│   └── [9 specialized modules]
├── scripts/
│   ├── update-validators.py # Auto-generates validation rules
│   └── generate-tests.py   # Non-destructive test generation
└── tests/                   # Comprehensive test suite
```

### Testing Framework

- **ShellSpec**: For testing shell scripts and GitHub Actions
- **pytest**: For Python validation system (303 tests, 100% passing)
- **Test Generator**: Automatic test scaffolding for new actions/validators
- **Coverage**: Full test coverage for all validators

## Action Categories

### Setup Actions (7)

- `node-setup`, `set-git-config`, `php-version-detect`, `python-version-detect`,
- `python-version-detect-v2`, `go-version-detect`, `dotnet-version-detect`

### Linting Actions (13)

- `ansible-lint-fix`, `biome-check`, `biome-fix`, `csharp-lint-check`
- `eslint-check`, `eslint-fix`, `go-lint`, `pr-lint`, `pre-commit`
- `prettier-check`, `prettier-fix`, `python-lint-fix`, `terraform-lint-fix`

### Build Actions (3)

- `csharp-build`, `go-build`, `docker-build`

### Publishing Actions (5)

- `npm-publish`, `docker-publish`, `docker-publish-gh`, `docker-publish-hub`, `csharp-publish`

### Testing Actions (3)

- `php-tests`, `php-laravel-phpunit`, `php-composer`

### Repository Management (8+)

- `github-release`, `release-monthly`, `sync-labels`, `stale`
- `compress-images`, `common-cache`, `common-file-check`, `common-retry`
- `codeql-analysis` (security analysis)

### Utilities (2)

- `version-file-parser`, `version-validator`

## Development Workflow

### Core Commands

```bash
make all                    # Generate docs, format, lint, test
make dev                    # Format then lint
make lint                   # Run all linters
make test                   # Run all tests
make update-validators      # Update validation rules
make generate-tests         # Generate missing tests (non-destructive)
make generate-tests-dry     # Preview test generation
```

### Quality Standards

- **ZERO TOLERANCE**: No failing tests, no linting issues
- **Production Ready**: Only when ALL checks pass
- **Convention Priority**: EditorConfig rules are blocking
- **Security First**: No secrets, tokens, or sensitive data in code

## Recent Accomplishments (January 2025)

### Phase 1-4: Modular Validator Architecture ✅

- Transformed monolithic validator into 11 specialized modules
- Implemented convention-based auto-detection (100+ patterns)
- Created 3 custom validators for complex actions
- Achieved 100% test pass rate (292/292 tests)
- Zero linting issues across all code

### Phase 5: Test Generation System ✅

- Created non-destructive test generation (preserves existing tests)
- Intelligent pattern detection for input types
- Template-based scaffolding for different validator types
- ShellSpec test generation for GitHub Actions
- pytest test generation for validators
- Custom validator test support
- 11 comprehensive tests for the generator itself
- Makefile integration with three new commands

### Custom Validators Implemented

1. `docker-build` - Complex build args, platforms, cache validation
2. `codeql-analysis` - Language support, query validation
3. `docker-publish` - Registry, credentials, platform validation

### Technical Improvements

- Full GitHub expression support (`${{ }}`)
- Error propagation between parent/child validators
- Platform-specific validation (Docker architectures)
- Registry validation (Docker Hub, GHCR, etc.)
- Security pattern detection and injection prevention
- Non-destructive test generation system
- Template-based test scaffolding

## Project Status

**Phases Completed**:

- ✅ Phase 1: Base Architecture (100% complete)
- ✅ Phase 2: Core Validators (100% complete)
- ✅ Phase 3: Registry System (100% complete)
- ✅ Phase 4: Custom Validators (100% complete)
- ✅ Phase 5: Test Generation (100% complete)
- ⏳ Phase 6: Integration and Migration (in progress)
- ⏳ Phase 7: Documentation and Tooling (not started)

**Quality Metrics**:

- ✅ 100% test pass rate (303 total tests)
- ✅ Zero linting issues
- ✅ Modular, extensible architecture
- ✅ Custom validator support
- ✅ Convention-based auto-detection
- ✅ Full backward compatibility
- ✅ Comprehensive error handling
- ✅ Security validations
- ✅ Test generation system

## Next Steps

1. Complete Phase 6: Integration and Migration
   - Integrate modular validators with main validator.py
   - Ensure full backward compatibility
   - Test all 50+ actions with integrated system
2. Phase 7: Documentation and Tooling
3. Performance optimization
4. Production deployment

## IDE Configuration Note

For Pyright/Pylance import resolution in IDEs like Zed, VSCode:

- The project uses relative imports within validate-inputs
- Python path includes validate-inputs directory
- Tests use sys.path manipulation for imports
