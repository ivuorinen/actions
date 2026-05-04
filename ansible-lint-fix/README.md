# ivuorinen/actions/ansible-lint-fix

## Description

Lints and fixes Ansible playbooks, commits changes, and uploads SARIF report.

## Inputs

| parameter | description | required | default |
| --- | --- | --- | --- |
| token | GitHub token for authentication | `false` |  |
| username | GitHub username for commits | `false` | github-actions |
| email | GitHub email for commits | `false` | <github-actions@github.com> |
| max-retries | Maximum number of retry attempts for pip install operations | `false` | 3 |

## Outputs

| parameter | description |
| --- | --- |
| files_changed | Number of files changed by linting |
| lint_status | Linting status (success/failure) |
| sarif_path | Path to SARIF report file |

## Runs

This action is a `composite` action.
