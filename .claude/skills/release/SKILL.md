---
name: release
description: Create a new CalVer release with validation checks
disable-model-invocation: true
---

# Release Workflow

Follow these steps to create a new CalVer release:

## 1. Pre-flight checks

Run the full validation pipeline:

```bash
make all
```

If any step fails, fix the issues before proceeding.

## 2. Check version references

Verify all action references are properly pinned:

```bash
make check-version-refs
make check-local-refs
```

## 3. Prepare the release

Run release preparation (updates version references):

```bash
make release-prep
```

Review the changes with `git diff`.

## 4. Confirm with user

Ask the user to confirm:

- The version number (defaults to `vYYYY.MM.DD` based on today's date)
- That all changes look correct

## 5. Create the release

```bash
make release VERSION=vYYYY.MM.DD
```

Replace `vYYYY.MM.DD` with the confirmed version.

## 6. Verify

Show the user the created tag and any output from the release process.
