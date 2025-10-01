# ShellSpec Test Fixes Tracking

## Status

**Branch**: feat/upgrades-and-restructuring  
**Date**: 2025-09-17
**Progress**: Fixed critical test failures

## Summary

- Initial failing tests: 27 actions
- **Fixed completely**: 3 actions (codeql-analysis, common-cache, common-file-check)
- **Partially fixed**: Several others have reduced failures
- **Key achievement**: Established patterns for fixing remaining tests

## ✅ Completed Fixes (3 actions)

### 1. codeql-analysis

- Created comprehensive CustomValidator
- Fixed all language, token, path, and query validations
- Result: **65 examples, 0 failures**

### 2. common-cache

- Created CustomValidator for comma-separated paths
- Added cache type, paths, keys, env-vars validation
- Result: **29 examples, 0 failures** (23 warnings)

### 3. common-file-check

- Created CustomValidator for glob patterns
- Supports \*, ?, \*\*, {}, [] in file patterns
- Result: **17 examples, 0 failures** (12 warnings)

## 🎯 Key Patterns Established

### CustomValidator Template

```python
class CustomValidator(BaseValidator):
    def validate_inputs(self, inputs: dict[str, str]) -> bool:
        # Handle required inputs first
        # Use specific validation methods
        # Check for GitHub expressions: if "${{" in value
        # Validate security patterns
        return valid
```

### Common Validation Patterns

1. **Token Validation**
   - ghp\_ tokens: 40-44 chars
   - github*pat* tokens: 82-95 chars
   - ghs\_ tokens: 40-44 chars

2. **Path Validation**
   - Reject absolute paths: `/path`
   - Reject traversal: `..`
   - Allow comma-separated: split and validate each

3. **Error Messages**
   - "Required input 'X' is missing"
   - "Absolute path not allowed"
   - "Path traversal detected"
   - "Command injection detected"

4. **Test Output**
   - Python logger outputs to stderr
   - Tests checking stdout need updating to stderr
   - Warnings about unexpected output are non-critical

## 📋 Remaining Work

### Quick Fixes (Similar patterns)

- common-retry: Add backoff-strategy, shell validation
- compress-images: File pattern validation
- eslint-check, prettier-fix: Token validation

### Docker Actions (Need CustomValidators)

- docker-build, docker-publish, docker-publish-gh, docker-publish-hub
- Common issues: image-name, registry, platforms validation

### Version Detection Actions

- go-version-detect, python-version-detect, php-version-detect
- Need version format validation

### Complex Actions (Need detailed CustomValidators)

- node-setup: Package manager, caching logic
- pre-commit: Hook configuration
- terraform-lint-fix: HCL-specific validation

## 🚀 Next Steps

To complete all fixes:

1. Create CustomValidators for remaining actions with failures
2. Use established patterns for quick wins
3. Test each action individually before full suite
4. Update tests expecting stdout to check stderr where needed

## 📊 Success Criteria

- All ShellSpec tests pass (0 failures)
- Warnings are acceptable (output format issues)
- Maintain backward compatibility
- Follow established validation patterns
