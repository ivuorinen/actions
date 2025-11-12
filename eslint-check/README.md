# ivuorinen/actions/eslint-check

## ESLint Check

### Description

Run ESLint check on the repository with advanced configuration and reporting

### Inputs

| name                | description                                      | required | default             |
|---------------------|--------------------------------------------------|----------|---------------------|
| `working-directory` | <p>Directory containing files to lint</p>        | `false`  | `.`                 |
| `eslint-version`    | <p>ESLint version to use</p>                     | `false`  | `latest`            |
| `config-file`       | <p>Path to ESLint config file</p>                | `false`  | `.eslintrc`         |
| `ignore-file`       | <p>Path to ESLint ignore file</p>                | `false`  | `.eslintignore`     |
| `file-extensions`   | <p>File extensions to lint (comma-separated)</p> | `false`  | `.js,.jsx,.ts,.tsx` |
| `cache`             | <p>Enable ESLint caching</p>                     | `false`  | `true`              |
| `max-warnings`      | <p>Maximum number of warnings allowed</p>        | `false`  | `0`                 |
| `fail-on-error`     | <p>Fail workflow if issues are found</p>         | `false`  | `true`              |
| `report-format`     | <p>Output format (stylish, json, sarif)</p>      | `false`  | `sarif`             |
| `max-retries`       | <p>Maximum number of retry attempts</p>          | `false`  | `3`                 |
| `token`             | <p>GitHub token for authentication</p>           | `false`  | `""`                |

### Outputs

| name            | description                      |
|-----------------|----------------------------------|
| `error-count`   | <p>Number of errors found</p>    |
| `warning-count` | <p>Number of warnings found</p>  |
| `sarif-file`    | <p>Path to SARIF report file</p> |
| `files-checked` | <p>Number of files checked</p>   |

### Runs

This action is a `composite` action.

### Usage

```yaml
- uses: ivuorinen/actions/eslint-check@main
  with:
    working-directory:
    # Directory containing files to lint
    #
    # Required: false
    # Default: .

    eslint-version:
    # ESLint version to use
    #
    # Required: false
    # Default: latest

    config-file:
    # Path to ESLint config file
    #
    # Required: false
    # Default: .eslintrc

    ignore-file:
    # Path to ESLint ignore file
    #
    # Required: false
    # Default: .eslintignore

    file-extensions:
    # File extensions to lint (comma-separated)
    #
    # Required: false
    # Default: .js,.jsx,.ts,.tsx

    cache:
    # Enable ESLint caching
    #
    # Required: false
    # Default: true

    max-warnings:
    # Maximum number of warnings allowed
    #
    # Required: false
    # Default: 0

    fail-on-error:
    # Fail workflow if issues are found
    #
    # Required: false
    # Default: true

    report-format:
    # Output format (stylish, json, sarif)
    #
    # Required: false
    # Default: sarif

    max-retries:
    # Maximum number of retry attempts
    #
    # Required: false
    # Default: 3

    token:
    # GitHub token for authentication
    #
    # Required: false
    # Default: ""
```
