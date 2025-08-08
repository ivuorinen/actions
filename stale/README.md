# ivuorinen/actions/stale

## Stale

### Description

A GitHub Action to close stale issues and pull requests.

### Inputs

| name    | description                            | required | default               |
|---------|----------------------------------------|----------|-----------------------|
| `token` | <p>GitHub token for authentication</p> | `false`  | `${{ github.token }}` |

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
