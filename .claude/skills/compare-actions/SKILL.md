---
name: compare-actions
description: Compare two actions for pattern consistency
---

# Compare Actions

Compare two actions side-by-side for pattern consistency. Useful when one action was modeled after another and you want to ensure they follow the same conventions.

## Arguments

- `<action1>` (required): First action directory name (e.g., `npm-publish`)
- `<action2>` (required): Second action directory name (e.g., `npm-semantic-release`)

## Steps

### 1. Verify both actions exist

Check that both `<action1>/action.yml` and `<action2>/action.yml` exist. Abort with an error if either is missing.

### 2. Compare checkout action versions

Extract all `actions/checkout@` references from both action.yml files. Flag if they use different SHAs.

### 3. Compare setup action versions

Extract all `actions/setup-node@`, `actions/setup-python@`, `actions/setup-go@`, and similar setup action references.
Compare versions/SHAs between the two actions. Only compare setup actions that appear in both.

### 4. Compare cache patterns

Look for `actions/cache@` usage or built-in caching (`cache:` keys in setup actions). Compare cache key patterns and restore-keys strategies.

### 5. Compare error handling patterns

Check both actions for:

- `set -eu` usage in shell blocks
- `if: failure()` or `if: always()` steps
- `continue-on-error` usage
- Error message formatting patterns

Flag differences.

### 6. Compare secret masking

Check both actions for:

- `::add-mask::` usage
- Token/secret handling patterns
- Whether sensitive inputs are masked before use

Flag if one action masks secrets and the other does not.

### 7. Compare structural patterns

- Number of steps
- Input/output naming conventions
- Shell language used (sh vs bash)
- Branding (icon, color)
- Whether they use composite vs docker vs node

### 8. Summary

Print a comparison report:

```text
Comparing: <action1> vs <action2>
--------------------------------------------------
Checkout version     MATCH / MISMATCH (details)
Setup actions        MATCH / MISMATCH / N/A
Cache patterns       MATCH / MISMATCH / N/A
Error handling       MATCH / MISMATCH (details)
Secret masking       MATCH / MISMATCH (details)
Structure            (summary of differences)
--------------------------------------------------
Inconsistencies found: N
```

## Output

A structured comparison report. Each check shows MATCH, MISMATCH (with details), or N/A (if the check does not apply to both actions).
Inconsistencies are flagged with specific recommendations for which action should be updated to match.
