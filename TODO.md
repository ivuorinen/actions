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

## 🔥 High Priority

### Quality & Testing

- [ ] **Create Action Testing Framework** `[Quality]` `[Large Effort]`
  - Implement automated testing for all actions
  - Test external usage patterns to ensure self-containment
  - Add integration tests for critical workflows
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

- [ ] **Add Retry Logic to Network Operations** `[Feature]` `[Medium Effort]`
  - Implement shared retry utilities for Docker operations
  - Add retries for package installations and API calls
  - **Impact**: Improved reliability in flaky network conditions

- [ ] **Enhance Docker Actions with Multi-Architecture Support** `[Feature]` `[Large Effort]`
  - Improve `docker-build`, `docker-publish` actions
  - Better multi-arch support and buildx optimization
  - **Impact**: Enables ARM64 and other architecture support

- [ ] **Add Performance Monitoring** `[Feature]` `[Medium Effort]`
  - Add timing outputs to long-running actions
  - Create performance dashboards
  - **Impact**: Better visibility into action performance

### Language-Specific Improvements

- [ ] **Enhance Node.js Support** `[Feature]` `[Medium Effort]`
  - Add support for Bun package manager
  - Improve Yarn Berry/PnP support
  - Add Node.js feature detection (ESM, TypeScript)
  - **Target**: `node-setup`, `eslint-*`, `prettier-*` actions

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

**Last Updated**: August 7, 2025  
**Next Review**: September 2025
