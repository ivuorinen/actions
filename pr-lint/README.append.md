
### Required Permissions

This action requires the following permissions when running in a workflow, especially in private repositories where MegaLinter needs to push changes:

```yaml
permissions:
  actions: write          # Required for uploading MegaLinter artifacts
  contents: write         # Required for checkout and committing linter fixes
  issues: write           # Required for MegaLinter to comment on issues
  pull-requests: write    # Required for creating pull requests with fixes
  security-events: write  # Required for uploading SARIF reports (if enabled)
  statuses: write         # Required for creating status checks
```

**Note:** These permissions must be set at the job level in your workflow file. Example:

```yaml
jobs:
  lint:
    runs-on: ubuntu-latest
    permissions:
      actions: write
      contents: write
      issues: write
      pull-requests: write
      security-events: write
      statuses: write
    steps:
      - uses: ivuorinen/actions/pr-lint@main
```
