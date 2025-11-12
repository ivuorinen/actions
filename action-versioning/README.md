# ivuorinen/actions/action-versioning

## Action Versioning

### Description

Automatically update SHA-pinned action references to match latest version tags

### Inputs

| name            | description                                    | required | default |
|-----------------|------------------------------------------------|----------|---------|
| `major-version` | <p>Major version tag to sync (e.g., v2025)</p> | `true`   | `""`    |
| `token`         | <p>GitHub token for authentication</p>         | `false`  | `""`    |

### Outputs

| name                | description                                                |
|---------------------|------------------------------------------------------------|
| `updated`           | <p>Whether action references were updated (true/false)</p> |
| `commit-sha`        | <p>SHA of the commit that was created (if any)</p>         |
| `needs-annual-bump` | <p>Whether annual version bump is needed (true/false)</p>  |

### Runs

This action is a `composite` action.

### Usage

```yaml
- uses: ivuorinen/actions/action-versioning@main
  with:
    major-version:
    # Major version tag to sync (e.g., v2025)
    #
    # Required: true
    # Default: ""

    token:
    # GitHub token for authentication
    #
    # Required: false
    # Default: ""
```
