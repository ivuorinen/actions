# TODO: GitHub Actions Monorepo Roadmap

This document outlines planned improvements and tasks for this GitHub Actions monorepo.

**Repository**: 40 self-contained GitHub Actions  
**Architecture**: Modular composition with utility actions  
**External Usage**: All actions work as `ivuorinen/actions/action-name@main` ✅
**Token Interpolation**: Fixed critical GitHub Actions expression issues ✅

## ✅ Recently Completed

### Critical Fixes

- [x] **Fixed GitHub Actions Token Interpolation** `[Critical]` `[August 2025]` ✅
  - ✅ Fixed single-quoted GitHub Actions expressions in 5 action.yml files
  - ✅ Resolved GITHUB_TOKEN environment variable issues
  - ✅ Verified all 40 actions have proper token interpolation
  - **Impact**: Prevented action failures due to broken variable interpolation

- [x] **Complete Input Validation Standardization** `[Quality]` `[August 2025]` ✅
  - ✅ Added comprehensive input validation to 22 GitHub Actions (100% coverage)
  - ✅ Implemented security-focused validation (command injection prevention)
  - ✅ Added format validation for tokens, emails, versions, and URLs
  - ✅ Applied language-specific version range validation
  - **Impact**: Significantly improved security posture and error prevention

### Documentation & Automation

- [x] **Create Action Catalog/Index** `[Documentation]` `[August 2025]` ✅
  - ✅ Added comprehensive action listing in README with auto-generation
  - ✅ Created quick reference tables with descriptions and features
  - ✅ Implemented automated catalog generation script with npm scripts
  - **Impact**: Better discoverability achieved, maintenance automated

### Configuration & Linting

- [x] **Fixed Markdown Linting Configuration** `[Infrastructure]` `[August 2025]` ✅
  - ✅ Properly excluded node_modules from markdown linting (0 errors in project files)
  - ✅ Updated package.json and Makefile with correct `'#node_modules'` syntax
  - ✅ Fixed yaml-lint integration with npx
  - **Impact**: Clean linting output, faster CI/CD execution

- [x] **Fixed Documentation Generation Issues** `[Documentation]` `[August 2025]` ✅
  - ✅ Regenerated python-version-detect-v2/README.md with proper replacements
  - ✅ Resolved `***PROJECT***@***VERSION***` placeholder issues
  - ✅ All READMEs now have correct external usage examples
  - **Impact**: Consistent, accurate documentation for external users

### Testing & Quality Infrastructure

- [x] **Comprehensive Testing Infrastructure** `[Quality]` `[August 2025]` ✅
  - ✅ Created comprehensive Python test suite with extensive coverage
  - ✅ Added testing for update-validators.py script with extensive test cases
  - ✅ Fixed hanging coverage tests with proper mock handling
  - ✅ Integrated Python testing into main workflow (Makefile integration)
  - ✅ Added modern Python development tools (uv, ruff, pytest)
  - ✅ Implemented migration from `tests/` to `_tests/` directory structure
  - ✅ Established dual testing framework (ShellSpec + pytest)
  - **Impact**: Full testing coverage achieved for validation system

## 🔥 High Priority

### Quality & Testing

- [x] **Create Action Testing Framework** `[Quality]` `[Large Effort]` ✅
  - ✅ Implemented comprehensive testing infrastructure
  - ✅ Added Python validation testing with extensive coverage
  - ✅ Created integration tests for critical validation workflows
  - ✅ Established testing patterns for external usage validation
  - **Impact**: Prevents regressions, validates functionality

- [x] **Add Comprehensive Output Handling** `[Quality]` `[Medium Effort]` ✅
  - ✅ Standardized outputs across actions for better composability
  - ✅ Added missing outputs to 15 actions (build, lint, test, release actions)
  - ✅ Implemented consistent snake_case naming conventions
  - ✅ Version detect actions use consistent `{language}-version` format
  - **Impact**: Better action interoperability achieved

### Performance

- [x] **Implement Shared Cache Strategy** `[Performance]` `[Large Effort]` ✅
  - ✅ Expanded `common-cache` action usage to 10 additional actions
  - ✅ Standardized 4 existing actions to use common-cache instead of direct actions/cache
  - ✅ Created consistent caching patterns across Node.js, .NET, Python, and Go actions
  - ✅ Added cache-hit optimization to skip installations when cache available
  - **Impact**: Faster CI/CD workflows achieved, reduced resource usage

## ⚡ Medium Priority

### Feature Enhancements

- [x] **Add Retry Logic to Network Operations** `[Feature]` `[Medium Effort]` ✅
  - ✅ Created common-retry action for standardized retry patterns
  - ✅ Added retry logic to 9 actions missing network retry capabilities
  - ✅ Standardized existing retry implementations using common-retry
  - ✅ Added configurable max-retries input to all relevant actions
  - ✅ Implemented exponential backoff and proper error handling
  - **Impact**: Improved reliability in flaky network conditions achieved

- [x] **Enhance Docker Actions with Multi-Architecture Support** `[Feature]` `[Large Effort]` ✅
  - ✅ Added advanced buildx features (version control, cache modes, build contexts)
  - ✅ Implemented auto-detect platforms capability for dynamic architecture discovery
  - ✅ Added performance optimizations (parallel builds, enhanced caching strategies)
  - ✅ Integrated security features (vulnerability scanning with Trivy, image signing with Cosign)
  - ✅ Added SBOM generation and validation in multiple formats
  - ✅ Implemented verbose logging and dry-run modes for debugging
  - ✅ Added platform-specific build args and fallback mechanisms
  - ✅ Enhanced all Docker actions (docker-build, docker-publish, docker-publish-gh, docker-publish-hub)
  - **Impact**: Full multi-architecture support with ARM64, security scanning, and optimized caching achieved

### Language-Specific Improvements

- [x] **Enhance Node.js Support** `[Feature]` `[Medium Effort]` ✅
  - ✅ Added Corepack support for automatic package manager version management
  - ✅ Added Bun package manager support to node-setup and related actions
  - ✅ Improved Yarn Berry/PnP support with .yarnrc.yml detection and immutable installs
  - ✅ Added Node.js feature detection (ESM, TypeScript, frameworks: Next.js, React, Vue, Svelte, Angular)
  - ✅ Updated package manager detection priority: bun.lockb → pnpm-lock.yaml → yarn.lock → package-lock.json → packageManager field
  - ✅ Enhanced eslint-check, eslint-fix, prettier-check, prettier-fix, biome-check, biome-fix actions
  - **Impact**: Modern Node.js tooling support achieved with automatic package manager detection

- [ ] **Improve PHP Action Robustness** `[Quality]` `[Medium Effort]`
  - Add Composer version detection and management
  - Improve Laravel-specific features
  - Add support for different PHP testing frameworks
  - **Target**: `php-*` actions

- [ ] **Enhance Python Actions** `[Feature]` `[Medium Effort]`
  - Add Poetry support alongside pip
  - Improve virtual environment handling
  - Add support for pyproject.toml configuration
  - **Target**: `python-*` actions

### Workflow Improvements

- [ ] **Enhance Release Automation** `[Feature]` `[Medium Effort]`
  - Improve automatic changelog generation
  - Add semantic version bumping
  - Enhance tag creation and release notes
  - **Target**: `github-release`, `release-monthly` actions

- [ ] **Add Automated Action Version Updates** `[Maintenance]` `[Large Effort]`
  - Create automated PR creation for external action updates
  - Implement dependency scanning for GitHub Actions
  - **Impact**: Reduces manual maintenance overhead

## 📝 Low Priority

### New Actions & Features

- [ ] **Create Rust Language Support Actions** `[Feature]` `[Large Effort]`
  - Add `rust-version-detect`, `rust-lint`, `rust-build` actions
  - Support for Cargo and Rust ecosystem tools
  - **Impact**: Extends language support portfolio

- [ ] **Add Database Migration Actions** `[Feature]` `[Large Effort]`
  - Create actions for database schema validation
  - Add migration running and rollback capabilities
  - Support for common databases
  - **Impact**: Better database workflow support

- [ ] **Create Security Scanning Actions** `[Security]` `[Large Effort]`
  - Add dependency vulnerability scanning beyond MegaLinter
  - Create SAST integration
  - Add secret scanning capabilities
  - **Impact**: Enhanced security posture

### Advanced Features

- [ ] **Add Action Composition Framework** `[Feature]` `[Large Effort]`
  - Create meta-actions that compose multiple existing actions
  - Add conditional execution based on repository content
  - **Impact**: Simplified workflow configuration

- [ ] **Implement Action Analytics** `[Feature]` `[Large Effort]`
  - Add usage tracking and analytics
  - Create insights dashboard
  - **Impact**: Data-driven improvements

## 📊 Success Metrics

### Current Status

- **Self-Containment**: 100% achieved ✅
- **External Usage**: All 40 actions work as `ivuorinen/actions/action-name@main` ✅
- **SHA Pinning**: 27/27 external dependencies pinned ✅
- **Token Handling**: Standardized across all actions ✅
- **Token Interpolation**: Fixed critical GitHub Actions expression issues ✅
- **Action Catalog**: Automated generation system implemented ✅
- **Linting Configuration**: All project files pass linting (0 errors) ✅
- **Documentation Generation**: All READMEs properly generated with correct examples ✅
- **Bash Error Handling**: Implemented in all shell-based actions ✅
- **Input Validation**: 22/22 actions requiring validation (100% complete) ✅
- **Test Coverage**: Not yet measured
- **Performance**: Baseline established

### Target Metrics

- **Test Coverage**: 80%+ for all actions
- **Input Validation**: 100% of actions ✅
- **Cache Hit Rate**: >70% for dependency caches
- **Action Execution Time**: 20% improvement through optimization
- **Documentation Coverage**: 100% with usage examples

---

**Last Updated**: August 17, 2025  
**Next Review**: September 2025
