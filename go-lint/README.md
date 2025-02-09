# ivuorinen/actions/go-lint

## Go Lint Check

### Description

Run golangci-lint with advanced configuration, caching, and reporting

### Inputs

| name                    | description                                          | required | default         |
|-------------------------|------------------------------------------------------|----------|-----------------|
| `working-directory`     | <p>Directory containing Go files</p>                 | `false`  | `.`             |
| `golangci-lint-version` | <p>Version of golangci-lint to use</p>               | `false`  | `latest`        |
| `go-version`            | <p>Go version to use</p>                             | `false`  | `stable`        |
| `config-file`           | <p>Path to golangci-lint config file</p>             | `false`  | `.golangci.yml` |
| `timeout`               | <p>Timeout for analysis (e.g., 5m, 1h)</p>           | `false`  | `5m`            |
| `cache`                 | <p>Enable golangci-lint caching</p>                  | `false`  | `true`          |
| `fail-on-error`         | <p>Fail workflow if issues are found</p>             | `false`  | `true`          |
| `report-format`         | <p>Output format (json, sarif, github-actions)</p>   | `false`  | `sarif`         |
| `max-retries`           | <p>Maximum number of retry attempts</p>              | `false`  | `3`             |
| `only-new-issues`       | <p>Report only new issues since main branch</p>      | `false`  | `true`          |
| `disable-all`           | <p>Disable all linters (useful with --enable-\*)</p> | `false`  | `false`         |
| `enable-linters`        | <p>Comma-separated list of linters to enable</p>     | `false`  | `""`            |
| `disable-linters`       | <p>Comma-separated list of linters to disable</p>    | `false`  | `""`            |

### Outputs

| name             | description                               |
|------------------|-------------------------------------------|
| `error-count`    | <p>Number of errors found</p>             |
| `sarif-file`     | <p>Path to SARIF report file</p>          |
| `cache-hit`      | <p>Indicates if there was a cache hit</p> |
| `analyzed-files` | <p>Number of files analyzed</p>           |

### Runs

This action is a `composite` action.

### Usage

```yaml
- uses: ivuorinen/actions/go-lint@main
  with:
    working-directory:
    # Directory containing Go files
    #
    # Required: false
    # Default: .

    golangci-lint-version:
    # Version of golangci-lint to use
    #
    # Required: false
    # Default: latest

    go-version:
    # Go version to use
    #
    # Required: false
    # Default: stable

    config-file:
    # Path to golangci-lint config file
    #
    # Required: false
    # Default: .golangci.yml

    timeout:
    # Timeout for analysis (e.g., 5m, 1h)
    #
    # Required: false
    # Default: 5m

    cache:
    # Enable golangci-lint caching
    #
    # Required: false
    # Default: true

    fail-on-error:
    # Fail workflow if issues are found
    #
    # Required: false
    # Default: true

    report-format:
    # Output format (json, sarif, github-actions)
    #
    # Required: false
    # Default: sarif

    max-retries:
    # Maximum number of retry attempts
    #
    # Required: false
    # Default: 3

    only-new-issues:
    # Report only new issues since main branch
    #
    # Required: false
    # Default: true

    disable-all:
    # Disable all linters (useful with --enable-*)
    #
    # Required: false
    # Default: false

    enable-linters:
    # Comma-separated list of linters to enable
    #
    # Required: false
    # Default: ""

    disable-linters:
    # Comma-separated list of linters to disable
    #
    # Required: false
    # Default: ""
```
