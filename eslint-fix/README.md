# ivuorinen/actions/eslint-fix

## ESLint Fix

### Description

Fixes ESLint violations in a project.

### Inputs

| name          | description                                                        | required | default                     |
| ------------- | ------------------------------------------------------------------ | -------- | --------------------------- |
| `token`       | <p>GitHub token for authentication</p>                             | `false`  | `${{ github.token }}`       |
| `username`    | <p>GitHub username for commits</p>                                 | `false`  | `github-actions`            |
| `email`       | <p>GitHub email for commits</p>                                    | `false`  | `github-actions@github.com` |
| `max-retries` | <p>Maximum number of retry attempts for npm install operations</p> | `false`  | `3`                         |

### Outputs

| name            | description                              |
| --------------- | ---------------------------------------- |
| `files_changed` | <p>Number of files changed by ESLint</p> |
| `lint_status`   | <p>Linting status (success/failure)</p>  |
| `errors_fixed`  | <p>Number of errors fixed</p>            |

### Runs

This action is a `composite` action.

### Usage

```yaml
- uses: ivuorinen/actions/eslint-fix@main
  with:
    token:
    # GitHub token for authentication
    #
    # Required: false
    # Default: ${{ github.token }}

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

    max-retries:
    # Maximum number of retry attempts for npm install operations
    #
    # Required: false
    # Default: 3
```
