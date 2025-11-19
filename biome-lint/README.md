# ivuorinen/actions/biome-lint

## Biome Lint

### Description

Run Biome linter in check or fix mode

### Inputs

| name            | description                                                                     | required | default                     |
|-----------------|---------------------------------------------------------------------------------|----------|-----------------------------|
| `mode`          | <p>Mode to run (check or fix)</p>                                               | `false`  | `check`                     |
| `token`         | <p>GitHub token for authentication</p>                                          | `false`  | `""`                        |
| `username`      | <p>GitHub username for commits (fix mode only)</p>                              | `false`  | `github-actions`            |
| `email`         | <p>GitHub email for commits (fix mode only)</p>                                 | `false`  | `github-actions@github.com` |
| `max-retries`   | <p>Maximum number of retry attempts for npm install operations</p>              | `false`  | `3`                         |
| `fail-on-error` | <p>Whether to fail the action if linting errors are found (check mode only)</p> | `false`  | `true`                      |

### Outputs

| name             | description                                       |
|------------------|---------------------------------------------------|
| `status`         | <p>Overall status (success/failure)</p>           |
| `errors_count`   | <p>Number of errors found (check mode only)</p>   |
| `warnings_count` | <p>Number of warnings found (check mode only)</p> |
| `files_changed`  | <p>Number of files changed (fix mode only)</p>    |

### Runs

This action is a `composite` action.

### Usage

```yaml
- uses: ivuorinen/actions/biome-lint@main
  with:
    mode:
    # Mode to run (check or fix)
    #
    # Required: false
    # Default: check

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

    max-retries:
    # Maximum number of retry attempts for npm install operations
    #
    # Required: false
    # Default: 3

    fail-on-error:
    # Whether to fail the action if linting errors are found (check mode only)
    #
    # Required: false
    # Default: true
```
