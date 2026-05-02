# ivuorinen/actions/biome-lint

## Description

Run Biome linter in check or fix mode

## Inputs

| parameter | description | required | default |
| --- | --- | --- | --- |
| mode | Mode to run (check or fix) | `false` | check |
| token | GitHub token for authentication | `false` |  |
| username | GitHub username for commits (fix mode only) | `false` | github-actions |
| email | GitHub email for commits (fix mode only) | `false` | <github-actions@github.com> |
| max-retries | Maximum number of retry attempts for npm install operations | `false` | 3 |
| fail-on-error | Whether to fail the action if linting errors are found (check mode only) | `false` | true |

## Outputs

| parameter | description |
| --- | --- |
| status | Overall status (success/failure) |
| errors_count | Number of errors found (check mode only) |
| warnings_count | Number of warnings found (check mode only) |
| files_changed | Number of files changed (fix mode only) |

## Runs

This action is a `composite` action.
