# ivuorinen/actions/eslint-lint

## ESLint Lint

### Description

Run ESLint in check or fix mode with advanced configuration and reporting

### Inputs

| name                | description                                                 | required | default                     |
|---------------------|-------------------------------------------------------------|----------|-----------------------------|
| `mode`              | <p>Mode to run (check or fix)</p>                           | `false`  | `check`                     |
| `working-directory` | <p>Directory containing files to lint</p>                   | `false`  | `.`                         |
| `eslint-version`    | <p>ESLint version to use</p>                                | `false`  | `latest`                    |
| `config-file`       | <p>Path to ESLint config file</p>                           | `false`  | `.eslintrc`                 |
| `ignore-file`       | <p>Path to ESLint ignore file</p>                           | `false`  | `.eslintignore`             |
| `file-extensions`   | <p>File extensions to lint (comma-separated)</p>            | `false`  | `.js,.jsx,.ts,.tsx`         |
| `cache`             | <p>Enable ESLint caching</p>                                | `false`  | `true`                      |
| `max-warnings`      | <p>Maximum number of warnings allowed (check mode only)</p> | `false`  | `0`                         |
| `fail-on-error`     | <p>Fail workflow if issues are found (check mode only)</p>  | `false`  | `true`                      |
| `report-format`     | <p>Output format for check mode (stylish, json, sarif)</p>  | `false`  | `sarif`                     |
| `max-retries`       | <p>Maximum number of retry attempts</p>                     | `false`  | `3`                         |
| `token`             | <p>GitHub token for authentication</p>                      | `false`  | `""`                        |
| `username`          | <p>GitHub username for commits (fix mode only)</p>          | `false`  | `github-actions`            |
| `email`             | <p>GitHub email for commits (fix mode only)</p>             | `false`  | `github-actions@github.com` |

### Outputs

| name            | description                                        |
|-----------------|----------------------------------------------------|
| `status`        | <p>Overall status (success/failure)</p>            |
| `error-count`   | <p>Number of errors found (check mode only)</p>    |
| `warning-count` | <p>Number of warnings found (check mode only)</p>  |
| `sarif-file`    | <p>Path to SARIF report file (check mode only)</p> |
| `files-checked` | <p>Number of files checked (check mode only)</p>   |
| `files-changed` | <p>Number of files changed (fix mode only)</p>     |
| `errors-fixed`  | <p>Number of errors fixed (fix mode only)</p>      |

### Runs

This action is a `composite` action.

### Usage

```yaml
- uses: ivuorinen/actions/eslint-lint@main
  with:
    mode:
    # Mode to run (check or fix)
    #
    # Required: false
    # Default: check

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
    # Maximum number of warnings allowed (check mode only)
    #
    # Required: false
    # Default: 0

    fail-on-error:
    # Fail workflow if issues are found (check mode only)
    #
    # Required: false
    # Default: true

    report-format:
    # Output format for check mode (stylish, json, sarif)
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

    username:
    # GitHub username for commits (fix mode only)
    #
    # Required: false
    # Default: github-actions

    email:
    # GitHub email for commits (fix mode only)
    #
    # Required: false
    # Default: github-actions@github.com
```
