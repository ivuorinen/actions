# ivuorinen/actions/prettier-check

## Prettier Check

### Description

Run Prettier check on the repository with advanced configuration and reporting

### Inputs

| name                | description                                                | required | default                                          |
| ------------------- | ---------------------------------------------------------- | -------- | ------------------------------------------------ |
| `working-directory` | <p>Directory containing files to check</p>                 | `false`  | `.`                                              |
| `prettier-version`  | <p>Prettier version to use</p>                             | `false`  | `latest`                                         |
| `config-file`       | <p>Path to Prettier config file</p>                        | `false`  | `.prettierrc`                                    |
| `ignore-file`       | <p>Path to Prettier ignore file</p>                        | `false`  | `.prettierignore`                                |
| `file-pattern`      | <p>Files to include (glob pattern)</p>                     | `false`  | `**/*.{js,jsx,ts,tsx,css,scss,json,md,yaml,yml}` |
| `cache`             | <p>Enable Prettier caching</p>                             | `false`  | `true`                                           |
| `fail-on-error`     | <p>Fail workflow if issues are found</p>                   | `false`  | `true`                                           |
| `report-format`     | <p>Output format (json, sarif)</p>                         | `false`  | `sarif`                                          |
| `max-retries`       | <p>Maximum number of retry attempts</p>                    | `false`  | `3`                                              |
| `plugins`           | <p>Comma-separated list of Prettier plugins to install</p> | `false`  | `""`                                             |
| `check-only`        | <p>Only check for formatting issues without fixing</p>     | `false`  | `true`                                           |

### Outputs

| name                | description                                   |
| ------------------- | --------------------------------------------- |
| `files-checked`     | <p>Number of files checked</p>                |
| `unformatted-files` | <p>Number of files with formatting issues</p> |
| `sarif-file`        | <p>Path to SARIF report file</p>              |
| `cache-hit`         | <p>Indicates if there was a cache hit</p>     |

### Runs

This action is a `composite` action.

### Usage

```yaml
- uses: ivuorinen/actions/prettier-check@main
  with:
    working-directory:
    # Directory containing files to check
    #
    # Required: false
    # Default: .

    prettier-version:
    # Prettier version to use
    #
    # Required: false
    # Default: latest

    config-file:
    # Path to Prettier config file
    #
    # Required: false
    # Default: .prettierrc

    ignore-file:
    # Path to Prettier ignore file
    #
    # Required: false
    # Default: .prettierignore

    file-pattern:
    # Files to include (glob pattern)
    #
    # Required: false
    # Default: **/*.{js,jsx,ts,tsx,css,scss,json,md,yaml,yml}

    cache:
    # Enable Prettier caching
    #
    # Required: false
    # Default: true

    fail-on-error:
    # Fail workflow if issues are found
    #
    # Required: false
    # Default: true

    report-format:
    # Output format (json, sarif)
    #
    # Required: false
    # Default: sarif

    max-retries:
    # Maximum number of retry attempts
    #
    # Required: false
    # Default: 3

    plugins:
    # Comma-separated list of Prettier plugins to install
    #
    # Required: false
    # Default: ""

    check-only:
    # Only check for formatting issues without fixing
    #
    # Required: false
    # Default: true
```
