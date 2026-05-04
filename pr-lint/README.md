# ivuorinen/actions/pr-lint

## Description

Runs MegaLinter against pull requests

## Inputs

| parameter | description                     | required | default                     |
|-----------|---------------------------------|----------|-----------------------------|
| token     | GitHub token for authentication | `false`  |                             |
| username  | GitHub username for commits     | `false`  | github-actions              |
| email     | GitHub email for commits        | `false`  | <github-actions@github.com> |

## Outputs

| parameter         | description                                 |
|-------------------|---------------------------------------------|
| validation_status | Overall validation status (success/failure) |
| errors_found      | Number of linting errors found              |

## Runs

This action is a `composite` action.
