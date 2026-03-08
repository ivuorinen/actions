---
name: test-action
description: Run tests for a specific GitHub Action by name
disable-model-invocation: true
---

# Test a Specific Action

## 1. Identify the action

Ask the user which action to test if not already specified.
List available actions if needed:

```bash
ls -d */action.yml | sed 's|/action.yml||'
```

## 2. Run tests

```bash
make test-action ACTION=<action-name>
```

## 3. Display results

Show the test output. If tests fail, read the relevant test files in `_tests/unit/<action-name>/` and the action's `action.yml` to help diagnose the issue.

## 4. Coverage (optional)

If the user wants coverage information:

```bash
make test-coverage
```
