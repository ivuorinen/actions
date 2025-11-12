# ivuorinen/actions/pr-lint

## PR Lint

### Description

Runs MegaLinter against pull requests

### Inputs

| name       | description                            | required | default                     |
|------------|----------------------------------------|----------|-----------------------------|
| `token`    | <p>GitHub token for authentication</p> | `false`  | `""`                        |
| `username` | <p>GitHub username for commits</p>     | `false`  | `github-actions`            |
| `email`    | <p>GitHub email for commits</p>        | `false`  | `github-actions@github.com` |

### Outputs

| name                | description                                        |
|---------------------|----------------------------------------------------|
| `validation_status` | <p>Overall validation status (success/failure)</p> |
| `errors_found`      | <p>Number of linting errors found</p>              |

### Runs

This action is a `composite` action.

### Usage

```yaml
- uses: ivuorinen/actions/pr-lint@main
  with:
    token:
    # GitHub token for authentication
    #
    # Required: false
    # Default: ""

    username:
    # GitHub username for commits
    #
    # Required: false
    # Default: github-actions

    email:
    # GitHub email for commits
    #
    # Required: false
    # Default: github-actions@github.com
```

### Required Permissions

This action requires the following permissions when running in a workflow, especially in private repositories where MegaLinter needs to push changes:

```yaml
permissions:
  actions: write # Required for uploading MegaLinter artifacts
  contents: write # Required for checkout and committing linter fixes
  issues: write # Required for MegaLinter to comment on issues
  pull-requests: write # Required for creating pull requests with fixes
  security-events: write # Required for uploading SARIF reports (if enabled)
  statuses: write # Required for creating status checks
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
