# ivuorinen/actions/prettier-lint

## Description

Run Prettier in check or fix mode with advanced configuration and reporting

## Inputs

| parameter         | description                                         | required | default                                         |
|-------------------|-----------------------------------------------------|----------|-------------------------------------------------|
| mode              | Mode to run (check or fix)                          | `false`  | check                                           |
| working-directory | Directory containing files to format                | `false`  | .                                               |
| prettier-version  | Prettier version to use                             | `false`  | latest                                          |
| config-file       | Path to Prettier config file                        | `false`  | .prettierrc                                     |
| ignore-file       | Path to Prettier ignore file                        | `false`  | .prettierignore                                 |
| file-pattern      | Files to include (glob pattern)                     | `false`  | \*_/_.{js,jsx,ts,tsx,css,scss,json,md,yaml,yml} |
| cache             | Enable Prettier caching                             | `false`  | true                                            |
| fail-on-error     | Fail workflow if issues are found (check mode only) | `false`  | true                                            |
| report-format     | Output format for check mode (json, sarif)          | `false`  | sarif                                           |
| max-retries       | Maximum number of retry attempts                    | `false`  | 3                                               |
| plugins           | Comma-separated list of Prettier plugins to install | `false`  |                                                 |
| token             | GitHub token for authentication                     | `false`  |                                                 |
| username          | GitHub username for commits (fix mode only)         | `false`  | github-actions                                  |
| email             | GitHub email for commits (fix mode only)            | `false`  | <github-actions@github.com>                     |

## Outputs

| parameter         | description                                              |
|-------------------|----------------------------------------------------------|
| status            | Overall status (success/failure)                         |
| files-checked     | Number of files checked (check mode only)                |
| unformatted-files | Number of files with formatting issues (check mode only) |
| sarif-file        | Path to SARIF report file (check mode only)              |
| files-changed     | Number of files changed (fix mode only)                  |

## Runs

This action is a `composite` action.
