---
name: pin-check
description: Verify all action references are properly SHA-pinned
---

# Pin Check

Verify that all action references across the repository are properly SHA-pinned. This is the skill-based replacement for `make check-version-refs`.

## Arguments

None. This skill always runs across the entire repository.

## Steps

### 1. Scan action.yml files (production actions)

Find all `action.yml` files in action directories (exclude `.github/workflows/` and `_tests/`):

```bash
find . -maxdepth 2 \( -name 'action.yml' -o -name 'action.yaml' \) -not -path './.github/*' -not -path './_tests/*'
```

### 2. Check external action references

For each `action.yml` found, extract all `uses:` lines. For external references (not starting with `ivuorinen/actions/` or `./`):

- Verify the ref after `@` is a 40-character hex SHA
- Flag any `@main`, `@master`, `@v1`, `@v2`, `@latest`, or short tag references
- Report violations as `file:line: <uses-value>`

### 3. Check internal action references

For each `action.yml` found, extract `uses:` lines referencing `ivuorinen/actions/`:

- Verify format is `ivuorinen/actions/<action-name>@<40-char-sha>`
- Flag any `@main`, `@v*`, or non-SHA references
- Flag any `./` relative references in production action.yml files
- Report violations as `file:line: <uses-value>`

### 4. Scan test workflows

Find all workflow files in `.github/workflows/`:

```bash
find .github/workflows \( -name '*.yml' -o -name '*.yaml' \)
```

For internal action references in test workflows:

- Verify they use `./action-name` format (local references)
- Flag any SHA-pinned or `@main` references to internal actions in test workflows
- Report violations as `file:line: <uses-value>`

External action references in test workflows should still be SHA-pinned.

### 5. Group by SHA for consistency

Collect all SHA references and group them. If the same action is pinned to different SHAs in different files, flag as INCONSISTENT. This helps catch partial updates.

```text
actions/checkout:
  abc123...def456  (used in 15 files)  <-- consistent
actions/setup-node:
  abc123...def456  (used in 3 files)
  789012...345678  (used in 1 file)    <-- INCONSISTENT
```

### 6. Summary

Print a report:

```text
Pin Check Report
--------------------------------------------------
Production action.yml files scanned: N
Test workflow files scanned: N

External refs:  N total, M violations
Internal refs:  N total, M violations
Test refs:      N total, M violations

SHA Consistency:
  <action>@<sha> used in N files (CONSISTENT / INCONSISTENT)

Violations:
  <file>:<line>: <uses-value> -- <reason>
--------------------------------------------------
Overall: PASS / FAIL (N violations)
```

## Output

A structured report showing all pinning violations with file:line references, SHA consistency analysis, and an overall pass/fail status. Zero violations means PASS.
