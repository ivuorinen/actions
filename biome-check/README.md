# ivuorinen/actions/biome-check

## Biome Check

### Description

Run Biome check on the repository

### Inputs

| name       | description                            | required | default                     |
|------------|----------------------------------------|----------|-----------------------------|
| `token`    | <p>GitHub token for authentication</p> | `false`  | `${{ github.token }}`       |
| `username` | <p>GitHub username for commits</p>     | `false`  | `github-actions`            |
| `email`    | <p>GitHub email for commits</p>        | `false`  | `github-actions@github.com` |

### Outputs

| name             | description                           |
|------------------|---------------------------------------|
| `check_status`   | <p>Check status (success/failure)</p> |
| `errors_count`   | <p>Number of errors found</p>         |
| `warnings_count` | <p>Number of warnings found</p>       |

### Runs

This action is a `composite` action.

### Usage

```yaml
- uses: ivuorinen/actions/biome-check@main
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
```
