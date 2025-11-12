# ivuorinen/actions/go-version-detect

## Go Version Detect

### Description

Detects the Go version from the project's go.mod file or defaults to a specified version.

### Inputs

| name | description | required | default |
| --- | --- | --- | --- |
| `default-version` | <p>Default Go version to use if go.mod is not found.</p> | `false` | `1.25` |
| `token` | <p>GitHub token for authentication</p> | `false` | `""` |

### Outputs

| name | description |
| --- | --- |
| `go-version` | <p>Detected or default Go version.</p> |

### Runs

This action is a `composite` action.

### Usage

```yaml
- uses: ivuorinen/actions/go-version-detect@main
  with:
    default-version:
    # Default Go version to use if go.mod is not found.
    #
    # Required: false
    # Default: 1.25

    token:
    # GitHub token for authentication
    #
    # Required: false
    # Default: ""
```
