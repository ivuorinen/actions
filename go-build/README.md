# ivuorinen/actions/go-build

## Go Build

### Description

Builds the Go project.

### Inputs

| name          | description                                                            | required | default |
| ------------- | ---------------------------------------------------------------------- | -------- | ------- |
| `go-version`  | <p>Go version to use.</p>                                              | `false`  | `""`    |
| `destination` | <p>Build destination directory.</p>                                    | `false`  | `./bin` |
| `max-retries` | <p>Maximum number of retry attempts for go mod download operations</p> | `false`  | `3`     |
| `token`       | <p>GitHub token for authentication</p>                                 | `false`  | `""`    |

### Outputs

| name            | description                                            |
| --------------- | ------------------------------------------------------ |
| `build_status`  | <p>Build completion status (success/failure)</p>       |
| `test_status`   | <p>Test execution status (success/failure/skipped)</p> |
| `go_version`    | <p>Version of Go used</p>                              |
| `binary_path`   | <p>Path to built binaries</p>                          |
| `coverage_path` | <p>Path to coverage report</p>                         |

### Runs

This action is a `composite` action.

### Usage

```yaml
- uses: ivuorinen/actions/go-build@main
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

    max-retries:
    # Maximum number of retry attempts for go mod download operations
    #
    # Required: false
    # Default: 3

    token:
    # GitHub token for authentication
    #
    # Required: false
    # Default: ""
```
