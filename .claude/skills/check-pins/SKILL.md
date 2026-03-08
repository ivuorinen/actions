---
name: check-pins
description: Verify all action references are properly SHA-pinned
disable-model-invocation: true
---

# Check SHA-Pinned Action References

## 1. Check version references

```bash
make check-version-refs
```

This verifies that all `ivuorinen/actions/*` references in `action.yml` files use SHA-pinned commits.

## 2. Check local references

```bash
make check-local-refs
```

This verifies that test workflows use `./action-name` format (local references are allowed in tests).

## 3. Interpret results

**Violations to fix:**

- `@main` or `@v*` references in `action.yml` files must be replaced with full SHA commits
- `./action-name` in `action.yml` (non-test) files must use `ivuorinen/actions/action-name@<SHA>`
- External actions must be pinned to SHA commits, not version tags

**How to get the SHA for pinning:**

```bash
# After pushing, get the SHA of the latest commit on the remote
git rev-parse origin/main
```

Use a SHA that exists on the remote. Local-only commits won't resolve when the action is used externally.
