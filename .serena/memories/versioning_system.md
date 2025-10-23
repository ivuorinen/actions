# Version System Architecture

## Overview

This repository uses a CalVer-based SHA-pinned versioning system for all internal action references.

## Version Format

### CalVer: vYYYY.MM.DD

- **Major**: `v2025` (year, updated annually)
- **Minor**: `v2025.10` (year.month)
- **Patch**: `v2025.10.18` (year.month.day)

Example: Release `v2025.10.18` creates three tags pointing to the same commit:

- `v2025.10.18` (patch - specific release)
- `v2025.10` (minor - latest October 2025 release)
- `v2025` (major - latest 2025 release)

## Internal vs External References

### Internal (action.yml files)

- **Format**: `ivuorinen/actions/validate-inputs@<40-char-SHA>`
- **Purpose**: Security, reproducibility, precise control
- **Example**: `ivuorinen/actions/validate-inputs@7061aafd35a2f21b57653e34f2b634b2a19334a9`

### External (user consumption)

- **Format**: `ivuorinen/actions/validate-inputs@v2025`
- **Purpose**: Convenience, always gets latest release
- **Options**: `@v2025`, `@v2025.10`, or `@v2025.10.18`

### Test Workflows

- **Format**: `uses: ./action-name` (local reference)
- **Location**: `_tests/integration/workflows/*.yml`
- **Reason**: Tests run within the actions repo context

### Internal Workflows

- **Format**: `uses: ./sync-labels` (local reference)
- **Location**: `.github/workflows/sync-labels.yml`
- **Reason**: Runs within the actions repo, local is sufficient

## Release Process

### Creating a Release

```bash
# 1. Create release with version tags
make release VERSION=v2025.10.18

# This automatically:
#   - Updates all action.yml SHA refs to current HEAD
#   - Commits the changes
#   - Creates tags: v2025.10.18, v2025.10, v2025
#   - All tags point to the same commit SHA

# 2. Push to remote
git push origin main --tags --force-with-lease
```

### After Each Release

Tags are force-pushed to ensure `v2025` and `v2025.10` always point to latest:

```bash
git push origin v2025 --force
git push origin v2025.10 --force
git push origin v2025.10.18
```

Or use `--tags --force-with-lease` to push all at once.

## Makefile Targets

### `make release VERSION=v2025.10.18`

Creates new release with version tags and updates all action references.

### `make update-version-refs MAJOR=v2025`

Updates all action.yml files to reference the SHA of the specified major version tag.

### `make bump-major-version OLD=v2025 NEW=v2026`

Annual version bump - replaces all references from one major version to another.

### `make check-version-refs`

Lists all current SHA-pinned references grouped by SHA. Useful for verification.

## Helper Scripts (\_tools/)

### release.sh

Main release script - validates version, updates refs, creates tags.

### validate-version.sh

Validates CalVer format (vYYYY.MM.DD, vYYYY.MM, vYYYY).

### update-action-refs.sh

Updates all action references to a specific SHA or version tag.

### bump-major-version.sh

Handles annual version bumps with commit creation.

### check-version-refs.sh

Displays current SHA-pinned references with tag information.

### get-action-sha.sh

Retrieves SHA for a specific version tag.

## Action Versioning Action

**Location**: `action-versioning/action.yml`

Automatically checks if major version tag has moved and updates all action references.

**Usage in CI**:

```yaml
- uses: ./action-versioning
  with:
    major-version: v2025
```

**Outputs**:

- `updated`: true/false
- `commit-sha`: SHA of created commit (if any)
- `needs-annual-bump`: true/false (year mismatch)

## CI Workflow

**File**: `.github/workflows/version-maintenance.yml`

**Triggers**:

- Weekly (Monday 9 AM UTC)
- Manual (workflow_dispatch)

**Actions**:

1. Checks if `v2025` tag has moved
2. Updates action references if needed
3. Creates PR with changes
4. Creates issue if annual bump needed

## Annual Version Bump

**When**: Start of each new year

**Process**:

```bash
# 1. Create new major version tag
git tag -a v2026 -m "Major version v2026"
git push origin v2026

# 2. Bump all references
make bump-major-version OLD=v2025 NEW=v2026

# 3. Update documentation
make docs

# 4. Push changes
git push origin main
```

## Verification

### Check Current Refs

```bash
make check-version-refs
```

### Verify All Refs Match

All action references should point to the same SHA after a release.

### Test External Usage

Create a test repo and use:

```yaml
uses: ivuorinen/actions/pr-lint@v2025
```

## Migration from @main

All action.yml files have been migrated from:

- `uses: ./action-name`
- `uses: ivuorinen/actions/action-name@main`

To:

- `uses: ivuorinen/actions/action-name@<SHA>`

Test workflows still use `./action-name` for local testing.

## Security Considerations

**SHA Pinning**: Prevents supply chain attacks by ensuring exact commit is used.

**Version Tags**: Provide user-friendly references while maintaining security internally.

**Tag Verification**: Always verify tags point to expected commits before force-pushing.

**Annual Review**: Each year requires conscious version bump, preventing accidental drift.
