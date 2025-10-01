# ivuorinen/actions/stale

## Stale

### Description

A GitHub Action to close stale issues and pull requests.

### Inputs

| name    | description                            | required | default               |
|---------|----------------------------------------|----------|-----------------------|
| `token` | <p>GitHub token for authentication</p> | `false`  | `${{ github.token }}` |

### Outputs

| name                  | description                             |
|-----------------------|-----------------------------------------|
| `staled_issues_count` | <p>Number of issues marked as stale</p> |
| `closed_issues_count` | <p>Number of issues closed</p>          |

### Runs

This action is a `composite` action.

### Usage

```yaml
- uses: ivuorinen/actions/stale@main
  with:
    token:
    # GitHub token for authentication
    #
    # Required: false
    # Default: ${{ github.token }}
```
