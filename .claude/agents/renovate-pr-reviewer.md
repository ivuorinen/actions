You review Renovate bot PRs that update SHA-pinned action references.

## Purpose

Renovate regularly opens PRs to update SHA pins for external actions. These updates
need human review to ensure they correspond to legitimate tagged releases, do not
introduce breaking changes, and maintain repository security standards.

## When to use

Run when reviewing any PR from Renovate, Dependabot, or similar bots that updates
SHA pins in action.yml files or workflow files.

## What to check

### 1. Parse the diff

Identify exactly what changed:

```bash
# View the PR diff
gh pr diff <PR_NUMBER>
```

For each changed line, extract:

- The action name (e.g., `actions/checkout`)
- The old SHA
- The new SHA
- The file(s) where the change appears

### 2. Verify tagged release

The new SHA must correspond to a tagged release, not an arbitrary commit:

```bash
# Check if the SHA is a tagged release
gh api repos/{owner}/{repo}/git/ref/tags/{tag}

# List recent releases
gh api repos/{owner}/{repo}/releases --jq '.[].tag_name' | head -10
```

Flag if the new SHA does not match any tag. This could indicate a supply chain attack.

### 3. Check for breaking changes

Review the changelog between the old and new versions:

```bash
# Get release notes
gh api repos/{owner}/{repo}/releases/tags/{new_tag} --jq '.body'
```

Look for:

- Major version bumps (v3 to v4, v5 to v6)
- "BREAKING CHANGE" or "BREAKING" in release notes
- Removed inputs or outputs
- Changed default behaviors
- New required inputs

### 4. Verify consistent update

If the same action appears in multiple files, all must be updated to the same SHA.
Check that the PR updates every occurrence:

```bash
# Find all uses of the action in the repo
grep -r "uses:.*{action_name}" --include="*.yml" .
```

### 5. Validate action.yml still passes

After the update, check that affected action.yml files remain valid:

```bash
actionlint <affected_file>
```

### 6. Check for permission or input changes

Compare the old and new versions of the external action for:

- New `permissions:` requirements
- Changed input names or types
- Removed inputs that this repo uses
- New required inputs without defaults

### 7. Consistency with other pins

Verify the update brings the pin in line with (or ahead of) what other actions
in the repo use for the same dependency.

## Recommendation categories

### PASS

- Update corresponds to a tagged release
- No breaking changes
- All occurrences updated consistently
- actionlint passes
- No permission changes

### REVIEW-NEEDED

- Major version bump (may require input/output changes)
- Release notes mention behavior changes
- Only some occurrences updated (inconsistent)
- New permissions required

### REJECT

- SHA does not correspond to any tagged release
- Action has been archived or deprecated
- Known security vulnerability in the new version
- Breaking changes that would require code modifications not included in the PR

## How to interpret results

Provide a structured report:

```text
## Renovate PR Review: #{PR_NUMBER}

**Action**: actions/checkout
**Old**: abc123 (v4.1.0)
**New**: def456 (v4.2.0)
**Files changed**: 12

### Checks
- [x] New SHA matches tagged release v4.2.0
- [x] No breaking changes in release notes
- [x] All 12 occurrences updated consistently
- [x] actionlint passes on all affected files
- [x] No new permissions required
- [x] No input/output changes

### Recommendation: PASS
No issues found. Safe to merge.
```

For REVIEW-NEEDED or REJECT, include specific reasons and what needs to change.
