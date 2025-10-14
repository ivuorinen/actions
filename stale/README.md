# ivuorinen/actions/stale

## Stale

### Description

A GitHub Action to close stale issues and pull requests.

### Inputs

| name                | description                                                            | required | default               |
|---------------------|------------------------------------------------------------------------|----------|-----------------------|
| `token`             | <p>GitHub token for authentication</p>                                 | `false`  | `${{ github.token }}` |
| `days-before-stale` | <p>Number of days of inactivity before an issue is marked as stale</p> | `false`  | `30`                  |
| `days-before-close` | <p>Number of days of inactivity before a stale issue is closed</p>     | `false`  | `7`                   |

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

    days-before-stale:
    # Number of days of inactivity before an issue is marked as stale
    #
    # Required: false
    # Default: 30

    days-before-close:
    # Number of days of inactivity before a stale issue is closed
    #
    # Required: false
    # Default: 7
```
