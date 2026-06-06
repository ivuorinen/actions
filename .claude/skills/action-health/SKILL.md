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

### 2. Check validate.py exists and is current

```bash
# Check existence (every action with inputs has a generated validator)
test -f <action-name>/validate.py

# Check the committed validator is current (regenerates in memory and compares)
python3 _validation/generate.py --check --action <action-name>
```

If the action declares inputs but `validate.py` does not exist, report as FAIL.
If the action has no inputs, `validate.py` is not required — report as N/A.
Never hand-edit `validate.py`; it is generated from `_validation/spec.py` +
`_validation/kit.py` via `make update-validators`.

### 3. Check README.md is up-to-date

```bash
# Generate fresh docs and check for drift
cp <action-name>/README.md /tmp/readme-backup.md
make docs 2>&1
diff <action-name>/README.md /tmp/readme-backup.md
# Restore original if changed
cp /tmp/readme-backup.md <action-name>/README.md
```

### 4. Check tests exist

Look for test files in `_tests/unit/<action-name>/` or `_tests/` that reference the action. Report MISSING if no tests found.

### 5. Check shell script quality

Scan all `run:` blocks in `<action-name>/action.yml`:

- Verify `set -eu` is present in shell blocks
- Verify `GITHUB_OUTPUT` writes use `printf 'key=%s\n' "$value"` format (not `echo` or `printf '%s\n' "key=$value"`)
- Report any violations with line numbers

### 6. Check action refs are SHA-pinned

Scan all `uses:` lines in `<action-name>/action.yml`:

- External actions must use 40-character SHA pins (not `@main`, `@v1`, `@latest`)
- Internal actions must use `ivuorinen/actions/<name>@<sha>` format
- Report any violations with line numbers

### 7. Summary

Print a table:

```text
Action: <action-name>
--------------------------------------------------
action-validator    PASS / FAIL
validate.py         PASS / FAIL (missing/outdated) / N/A (no inputs)
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
