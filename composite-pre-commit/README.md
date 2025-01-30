# ivuorinen/actions/composite-pre-commit

## pre-commit

### Description

Runs pre-commit on the repository and pushes the fixes back to the repository

### Inputs

| name                | description                           | required | default                     |
|---------------------|---------------------------------------|----------|-----------------------------|
| `pre-commit-config` | <p>pre-commit configuration file</p>  | `false`  | `.pre-commit-config.yaml`   |
| `base-branch`       | <p>Base branch to compare against</p> | `false`  | `""`                        |
| `token`             | <p>GitHub Token</p>                   | `false`  | `${{ github.token }}`       |
| `commit_user`       | <p>Commit user</p>                    | `false`  | `GitHub Actions`            |
| `commit_email`      | <p>Commit email</p>                   | `false`  | `github-actions@github.com` |

### Runs

This action is a `composite` action.

### Usage

```yaml
- uses: ivuorinen/actions/composite-pre-commit@main
  with:
      pre-commit-config:
      # pre-commit configuration file
      #
      # Required: false
      # Default: .pre-commit-config.yaml

      base-branch:
      # Base branch to compare against
      #
      # Required: false
      # Default: ""

      token:
      # GitHub Token
      #
      # Required: false
      # Default: ${{ github.token }}

      commit_user:
      # Commit user
      #
      # Required: false
      # Default: GitHub Actions

      commit_email:
      # Commit email
      #
      # Required: false
      # Default: github-actions@github.com
```
