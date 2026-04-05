---
name: action-health
description: Comprehensive health check for a single action
---

# Action Health Check

Run a full health check on a single action directory.

## Arguments

- `<action-name>` (required): Name of the action directory (e.g., `docker-build`)

## Steps

### 1. Validate action.yml

```bash
action-validator <action-name>/action.yml
```

Report pass/fail.

### 2. Check rules.yml exists and is current

```bash
# Check existence
test -f <action-name>/rules.yml

# Check if rules are current (dry-run regeneration and diff)
make update-validators-dry 2>&1 | grep <action-name> || echo "No changes needed"
```

If `rules.yml` does not exist, report as WARNING (not all actions require one).

### 3. Check CustomValidator.py if needed

If `rules.yml` exists and contains `custom` conventions, verify that `validate-inputs/validators/<action-name>/CustomValidator.py` exists.

### 4. Check README.md is up-to-date

```bash
# Generate fresh docs and check for drift
cp <action-name>/README.md /tmp/readme-backup.md
make docs 2>&1
diff <action-name>/README.md /tmp/readme-backup.md
# Restore original if changed
cp /tmp/readme-backup.md <action-name>/README.md
```

### 5. Check tests exist

Look for test files in `_tests/unit/<action-name>/` or `_tests/` that reference the action. Report MISSING if no tests found.

### 6. Check shell script quality

Scan all `run:` blocks in `<action-name>/action.yml`:

- Verify `set -eu` is present in shell blocks
- Verify `GITHUB_OUTPUT` writes use `printf '%s\n'` format-string separation (not `echo`)
- Report any violations with line numbers

### 7. Check action refs are SHA-pinned

Scan all `uses:` lines in `<action-name>/action.yml`:

- External actions must use 40-character SHA pins (not `@main`, `@v1`, `@latest`)
- Internal actions must use `ivuorinen/actions/<name>@<sha>` format
- Report any violations with line numbers

### 8. Summary

Print a table:

```text
Action: <action-name>
--------------------------------------------------
action-validator    PASS / FAIL
rules.yml           PASS / WARN (missing) / FAIL (outdated)
CustomValidator.py  PASS / WARN (missing) / N/A
README.md           PASS / FAIL (outdated)
Tests               PASS / WARN (missing)
set -eu             PASS / FAIL (N violations)
printf GITHUB_OUT   PASS / FAIL (N violations)
SHA-pinned refs     PASS / FAIL (N violations)
--------------------------------------------------
Overall: PASS / FAIL
```

## Output

A structured pass/fail summary table. Any FAIL item includes the specific file and line number of the violation.
WARN items are advisory but do not cause overall failure. Only FAIL items cause overall FAIL status.
