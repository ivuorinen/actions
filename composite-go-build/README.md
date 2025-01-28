# ivuorinen/actions/composite-go-build

## Go Build

### Description

Builds the Go project.

### Inputs

| name          | description                         | required | default |
| ------------- | ----------------------------------- | -------- | ------- |
| `go-version`  | <p>Go version to use.</p>           | `false`  | `""`    |
| `destination` | <p>Build destination directory.</p> | `false`  | `./bin` |

### Runs

This action is a `composite` action.

### Usage

```yaml
- uses: ivuorinen/actions/composite-go-build@main
  with:
      go-version:
      # Go version to use.
      #
      # Required: false
      # Default: ""

      destination:
      # Build destination directory.
      #
      # Required: false
      # Default: ./bin
```
