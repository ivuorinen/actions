---
name: changelog
description: Generate a changelog for a specific action or the whole repo
---

# Changelog

Generate a changelog from git history, either for a specific action or across the entire repository.

## Arguments

- `<action-name>` (optional): Name of a specific action directory. If omitted, shows recent activity across all actions.

## Steps

### 1. Determine scope and gather commits

**If `<action-name>` is provided:**

```bash
# Verify the action exists
test -d <action-name>

# Get commits touching this action's directory
git log --oneline --format='%h %as %s' -- <action-name>/
```

**If no argument:**

```bash
# Get recent commits across the whole repo (last 50)
git log --oneline --format='%h %as %s' -50
```

### 2. Parse and classify commits

Classify each commit by its conventional commit prefix:

- **feat**: New features or capabilities
- **fix**: Bug fixes
- **chore**: Maintenance, dependency updates, CI changes
- **docs**: Documentation changes
- **refactor**: Code restructuring without behavior change
- **test**: Test additions or modifications
- **style**: Formatting, whitespace, linting fixes
- **perf**: Performance improvements
- **ci**: CI/CD pipeline changes
- **build**: Build system changes

Commits without a conventional prefix go under **other**.

### 3. Compute date range and stats

```bash
# First and last commit dates in scope
git log --format='%as' -- <path>/ | sort | head -1  # earliest
git log --format='%as' -- <path>/ | sort | tail -1  # latest

# Total commit count
git log --oneline -- <path>/ | wc -l
```

### 4. For whole-repo mode, show per-action activity

When no action is specified, also show which actions had the most activity:

```bash
# Count commits per action directory (top 10)
# Get the date cutoff from the 50th most recent repo commit
CUTOFF_DATE=$(git log -n50 --format=%ci | tail -1)
for dir in */action.yml; do
  [ -e "$dir" ] || continue
  action=$(dirname "$dir")
  count=$(git log --oneline --since="$CUTOFF_DATE" -- "$action/" | wc -l)
  [ "$count" -gt 0 ] && printf '%s %s\n' "$count" "$action"
done | sort -rn | head -10
```

### 5. Format the changelog

**For a specific action:**

```text
Changelog: <action-name>
Date range: YYYY-MM-DD to YYYY-MM-DD
Total commits: N
--------------------------------------------------

### Features
- <hash> <description> (<date>)

### Fixes
- <hash> <description> (<date>)

### Maintenance
- <hash> <description> (<date>)

### Documentation
- <hash> <description> (<date>)

### Other
- <hash> <description> (<date>)
```

**For the whole repo:**

```text
Repository Changelog (last 50 commits)
Date range: YYYY-MM-DD to YYYY-MM-DD
--------------------------------------------------

Most active actions:
  <action-name>: N commits
  <action-name>: N commits

### Features
- <hash> <description> (<date>)

### Fixes
- <hash> <description> (<date>)

[...remaining groups...]
```

## Output

A formatted changelog grouped by commit type. Empty groups are omitted. Each entry shows the short SHA, description, and date. Useful before releases or when answering "what changed in this action?"
