# ivuorinen/actions/prettier-lint

## Prettier Lint

### Description

Run Prettier in check or fix mode with advanced configuration and reporting

### Inputs

| name | description | required | default |
| --- | --- | --- | --- |
| `mode` | <p>Mode to run (check or fix)</p> | `false` | `check` |
| `working-directory` | <p>Directory containing files to format</p> | `false` | `.` |
| `prettier-version` | <p>Prettier version to use</p> | `false` | `latest` |
| `config-file` | <p>Path to Prettier config file</p> | `false` | `.prettierrc` |
| `ignore-file` | <p>Path to Prettier ignore file</p> | `false` | `.prettierignore` |
| `file-pattern` | <p>Files to include (glob pattern)</p> | `false` | `**/*.{js,jsx,ts,tsx,css,scss,json,md,yaml,yml}` |
| `cache` | <p>Enable Prettier caching</p> | `false` | `true` |
| `fail-on-error` | <p>Fail workflow if issues are found (check mode only)</p> | `false` | `true` |
| `report-format` | <p>Output format for check mode (json, sarif)</p> | `false` | `sarif` |
| `max-retries` | <p>Maximum number of retry attempts</p> | `false` | `3` |
| `plugins` | <p>Comma-separated list of Prettier plugins to install</p> | `false` | `""` |
| `token` | <p>GitHub token for authentication</p> | `false` | `""` |
| `username` | <p>GitHub username for commits (fix mode only)</p> | `false` | `github-actions` |
| `email` | <p>GitHub email for commits (fix mode only)</p> | `false` | `github-actions@github.com` |

### Outputs

| name | description |
| --- | --- |
| `status` | <p>Overall status (success/failure)</p> |
| `files-checked` | <p>Number of files checked (check mode only)</p> |
| `unformatted-files` | <p>Number of files with formatting issues (check mode only)</p> |
| `sarif-file` | <p>Path to SARIF report file (check mode only)</p> |
| `files-changed` | <p>Number of files changed (fix mode only)</p> |

### Runs

This action is a `composite` action.

### Usage

```yaml
- uses: ivuorinen/actions/prettier-lint@main
  with:
    mode:
    # Mode to run (check or fix)
    #
    # Required: false
    # Default: check

    working-directory:
    # Directory containing files to format
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
    # Fail workflow if issues are found (check mode only)
    #
    # Required: false
    # Default: true

    report-format:
    # Output format for check mode (json, sarif)
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
