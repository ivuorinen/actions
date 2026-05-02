# ivuorinen/actions/eslint-lint

## Description

Run ESLint in check or fix mode with advanced configuration and reporting

## Inputs

| parameter | description | required | default |
| --- | --- | --- | --- |
| mode | Mode to run (check or fix) | `false` | check |
| working-directory | Directory containing files to lint | `false` | . |
| eslint-version | ESLint version to use | `false` | latest |
| config-file | Path to ESLint config file | `false` | .eslintrc |
| ignore-file | Path to ESLint ignore file | `false` | .eslintignore |
| file-extensions | File extensions to lint (comma-separated) | `false` | .js,.jsx,.ts,.tsx |
| cache | Enable ESLint caching | `false` | true |
| max-warnings | Maximum number of warnings allowed (check mode only) | `false` | 0 |
| fail-on-error | Fail workflow if issues are found (check mode only) | `false` | true |
| report-format | Output format for check mode (stylish, json, sarif) | `false` | sarif |
| max-retries | Maximum number of retry attempts | `false` | 3 |
| token | GitHub token for authentication | `false` |  |
| username | GitHub username for commits (fix mode only) | `false` | github-actions |
| email | GitHub email for commits (fix mode only) | `false` | <github-actions@github.com> |

## Outputs

| parameter | description |
| --- | --- |
| status | Overall status (success/failure) |
| error-count | Number of errors found (check mode only) |
| warning-count | Number of warnings found (check mode only) |
| sarif-file | Path to SARIF report file (check mode only) |
| files-checked | Number of files checked (check mode only) |
| files-changed | Number of files changed (fix mode only) |
| errors-fixed | Number of errors fixed (fix mode only) |

## Runs

This action is a `composite` action.
