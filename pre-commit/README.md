# ivuorinen/actions/pre-commit

## Description

Runs pre-commit on the repository and pushes the fixes back to the repository

## Inputs

| parameter         | description                     | required | default                     |
|-------------------|---------------------------------|----------|-----------------------------|
| pre-commit-config | pre-commit configuration file   | `false`  | .pre-commit-config.yaml     |
| base-branch       | Base branch to compare against  | `false`  |                             |
| token             | GitHub token for authentication | `false`  |                             |
| commit_user       | Commit user                     | `false`  | GitHub Actions              |
| commit_email      | Commit email                    | `false`  | <github-actions@github.com> |

## Outputs

| parameter     | description                                        |
|---------------|----------------------------------------------------|
| hooks_passed  | Whether all pre-commit hooks passed (true/false)   |
| files_changed | Whether any files were changed by pre-commit hooks |

## Runs

This action is a `composite` action.
