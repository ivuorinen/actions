# ivuorinen/actions/python-lint-fix

## Description

Lints and fixes Python files, commits changes, and uploads SARIF report.

## Inputs

| parameter         | description                                                    | required | default                     |
|-------------------|----------------------------------------------------------------|----------|-----------------------------|
| python-version    | Python version to use                                          | `false`  | 3.11                        |
| flake8-version    | Flake8 version to use                                          | `false`  | 7.0.0                       |
| autopep8-version  | Autopep8 version to use                                        | `false`  | 2.0.4                       |
| max-retries       | Maximum number of retry attempts for installations and linting | `false`  | 3                           |
| working-directory | Directory containing Python files to lint                      | `false`  | .                           |
| fail-on-error     | Whether to fail the action if linting errors are found         | `false`  | true                        |
| token             | GitHub token for authentication                                | `false`  |                             |
| username          | GitHub username for commits                                    | `false`  | github-actions              |
| email             | GitHub email for commits                                       | `false`  | <github-actions@github.com> |

## Outputs

| parameter   | description                                     |
|-------------|-------------------------------------------------|
| lint-result | Result of the linting process (success/failure) |
| fixed-files | Number of files that were fixed                 |
| error-count | Number of errors found                          |

## Runs

This action is a `composite` action.
