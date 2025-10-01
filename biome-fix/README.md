# ivuorinen/actions/biome-fix

## Biome Fix

### Description

Run Biome fix on the repository

### Inputs

| name          | description                                                        | required | default                     |
|---------------|--------------------------------------------------------------------|----------|-----------------------------|
| `token`       | <p>GitHub token for authentication</p>                             | `false`  | `${{ github.token }}`       |
| `username`    | <p>GitHub username for commits</p>                                 | `false`  | `github-actions`            |
| `email`       | <p>GitHub email for commits</p>                                    | `false`  | `github-actions@github.com` |
| `max-retries` | <p>Maximum number of retry attempts for npm install operations</p> | `false`  | `3`                         |

### Outputs

| name            | description                                  |
|-----------------|----------------------------------------------|
| `files_changed` | <p>Number of files changed by formatting</p> |
| `fix_status`    | <p>Fix status (success/failure)</p>          |

### Runs

This action is a `composite` action.

### Usage

```yaml
- uses: ivuorinen/actions/biome-fix@main
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
