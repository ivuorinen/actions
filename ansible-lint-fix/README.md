# ivuorinen/actions/ansible-lint-fix

## Ansible Lint and Fix

### Description

Lints and fixes Ansible playbooks, commits changes, and uploads SARIF report.

### Inputs

| name          | description                                                        | required | default                     |
|---------------|--------------------------------------------------------------------|----------|-----------------------------|
| `token`       | <p>GitHub token for authentication</p>                             | `false`  | `""`                        |
| `username`    | <p>GitHub username for commits</p>                                 | `false`  | `github-actions`            |
| `email`       | <p>GitHub email for commits</p>                                    | `false`  | `github-actions@github.com` |
| `max-retries` | <p>Maximum number of retry attempts for pip install operations</p> | `false`  | `3`                         |

### Outputs

| name            | description                               |
|-----------------|-------------------------------------------|
| `files_changed` | <p>Number of files changed by linting</p> |
| `lint_status`   | <p>Linting status (success/failure)</p>   |
| `sarif_path`    | <p>Path to SARIF report file</p>          |

### Runs

This action is a `composite` action.

### Usage

```yaml
- uses: ivuorinen/actions/ansible-lint-fix@main
  with:
    token:
    # GitHub token for authentication
    #
    # Required: false
    # Default: ""

    username:
    # GitHub username for commits
    #
    # Required: false
    # Default: github-actions

    email:
    # GitHub email for commits
    #
    # Required: false
    # Default: github-actions@github.com

    max-retries:
    # Maximum number of retry attempts for pip install operations
    #
    # Required: false
    # Default: 3
```
