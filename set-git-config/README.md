# ivuorinen/actions/set-git-config

## Set Git Config

### Description

Sets Git configuration for actions.

### Inputs

| name         | description                            | required | default                     |
| ------------ | -------------------------------------- | -------- | --------------------------- |
| `token`      | <p>GitHub token for authentication</p> | `false`  | `${{ github.token }}`       |
| `username`   | <p>GitHub username for commits.</p>    | `false`  | `github-actions`            |
| `email`      | <p>GitHub email for commits.</p>       | `false`  | `github-actions@github.com` |
| `is_fiximus` | <p>Whether to use the Fiximus bot.</p> | `false`  | `false`                     |

### Outputs

| name         | description                            |
| ------------ | -------------------------------------- |
| `token`      | <p>GitHub token.</p>                   |
| `username`   | <p>GitHub username for commits.</p>    |
| `email`      | <p>GitHub email for commits.</p>       |
| `is_fiximus` | <p>Whether to use the Fiximus bot.</p> |

### Runs

This action is a `composite` action.

### Usage

```yaml
- uses: ivuorinen/actions/set-git-config@main
  with:
    token:
    # GitHub token for authentication
    #
    # Required: false
    # Default: ${{ github.token }}

    username:
    # GitHub username for commits.
    #
    # Required: false
    # Default: github-actions

    email:
    # GitHub email for commits.
    #
    # Required: false
    # Default: github-actions@github.com

    is_fiximus:
    # Whether to use the Fiximus bot.
    #
    # Required: false
    # Default: false
```
