# TODO: GitHub Actions Monorepo Roadmap

This document outlines planned improvements and tasks for this GitHub Actions monorepo.

**Repository**: 40 self-contained GitHub Actions  
**Architecture**: Modular composition with utility actions  
**External Usage**: All actions work as `ivuorinen/actions/action-name@main` ✅

## 🔥 High Priority

### Quality & Testing

- [ ] **Create Action Testing Framework** `[Quality]` `[Large Effort]`
  - Implement automated testing for all actions
  - Test external usage patterns to ensure self-containment
  - Add integration tests for critical workflows
  - **Impact**: Prevents regressions, validates functionality

- [ ] **Complete Input Validation Standardization** `[Quality]` `[Medium Effort]`
  - Currently 14/40 actions have validation (35% complete)
  - Extend validation to remaining 26 actions
  - Apply security validation patterns consistently
  - **Impact**: Prevents runtime errors, improves security

- [ ] **Add Comprehensive Output Handling** `[Quality]` `[Medium Effort]`
  - Standardize outputs across actions for better composability
  - Add missing outputs useful for downstream actions
  - Ensure consistent output naming conventions
  - **Impact**: Better action interoperability

### Performance

- [ ] **Implement Shared Cache Strategy** `[Performance]` `[Large Effort]`
  - Expand `common-cache` action usage across language-specific actions
  - Create consistent caching patterns
  - **Impact**: Faster CI/CD workflows, reduced resource usage

### Documentation

- [ ] **Create Action Catalog/Index** `[Documentation]` `[Small Effort]`
  - Add comprehensive action listing in README
  - Create quick reference table with descriptions
  - **Impact**: Better discoverability

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
- **Bash Error Handling**: Implemented in all shell-based actions ✅
- **Input Validation**: 14/40 actions (35% complete)
- **Test Coverage**: Not yet measured
- **Performance**: Baseline established

### Target Metrics

- **Test Coverage**: 80%+ for all actions
- **Input Validation**: 100% of actions
- **Cache Hit Rate**: >70% for dependency caches
- **Action Execution Time**: 20% improvement through optimization
- **Documentation Coverage**: 100% with usage examples

---

**Last Updated**: August 7, 2025  
**Next Review**: September 2025
