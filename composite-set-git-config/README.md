# ivuorinen/actions/composite-set-git-config

## Set Git Config

### Description

Sets Git configuration for actions.

### Inputs

| name       | description                         | required | default                       |
|------------|-------------------------------------|----------|-------------------------------|
| `token`    | <p>GitHub token.</p>                | `false`  | `${{ secrets.GITHUB_TOKEN }}` |
| `username` | <p>GitHub username for commits.</p> | `false`  | `github-actions`              |
| `email`    | <p>GitHub email for commits.</p>    | `false`  | `github-actions@github.com`   |

### Outputs

| name       | description                         |
|------------|-------------------------------------|
| `token`    | <p>GitHub token.</p>                |
| `username` | <p>GitHub username for commits.</p> |
| `email`    | <p>GitHub email for commits.</p>    |

### Runs

This action is a `composite` action.

### Usage

```yaml
- uses: ivuorinen/actions/composite-set-git-config@main
  with:
      token:
      # GitHub token.
      #
      # Required: false
      # Default: ${{ secrets.GITHUB_TOKEN }}

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
```
