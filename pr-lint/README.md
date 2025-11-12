# ivuorinen/actions/pr-lint

## PR Lint

### Description

Runs MegaLinter against pull requests

### Inputs

| name       | description                            | required | default                     |
| ---------- | -------------------------------------- | -------- | --------------------------- |
| `token`    | <p>GitHub token for authentication</p> | `false`  | `""`                        |
| `username` | <p>GitHub username for commits</p>     | `false`  | `github-actions`            |
| `email`    | <p>GitHub email for commits</p>        | `false`  | `github-actions@github.com` |

### Outputs

| name                | description                                        |
| ------------------- | -------------------------------------------------- |
| `validation_status` | <p>Overall validation status (success/failure)</p> |
| `errors_found`      | <p>Number of linting errors found</p>              |

### Runs

This action is a `composite` action.

### Usage

```yaml
- uses: ivuorinen/actions/pr-lint@main
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
```
