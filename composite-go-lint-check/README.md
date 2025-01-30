# ivuorinen/actions/composite-go-lint-check

## Go Lint Check

### Description

Runs golangci-lint to check for code style violations in Go projects.

### Inputs

| name         | description               | required | default |
|--------------|---------------------------|----------|---------|
| `go-version` | <p>Go version to use.</p> | `false`  | `""`    |

### Outputs

| name         | description                |
|--------------|----------------------------|
| `go-version` | <p>Detected go version</p> |

### Runs

This action is a `composite` action.

### Usage

```yaml
- uses: ivuorinen/actions/composite-go-lint-check@main
  with:
      go-version:
      # Go version to use.
      #
      # Required: false
      # Default: ""
```
