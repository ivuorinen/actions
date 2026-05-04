# ivuorinen/actions/terraform-lint-fix

## Description

Lints and fixes Terraform files with advanced validation and security checks.

## Inputs

| parameter         | description                                             | required | default                     |
|-------------------|---------------------------------------------------------|----------|-----------------------------|
| terraform-version | Terraform version to use                                | `false`  | latest                      |
| tflint-version    | TFLint version to use                                   | `false`  | latest                      |
| working-directory | Directory containing Terraform files                    | `false`  | .                           |
| config-file       | Path to TFLint config file                              | `false`  | .tflint.hcl                 |
| fail-on-error     | Fail workflow if issues are found                       | `false`  | true                        |
| auto-fix          | Automatically fix issues when possible                  | `false`  | true                        |
| max-retries       | Maximum number of retry attempts                        | `false`  | 3                           |
| format            | Output format (compact, json, checkstyle, junit, sarif) | `false`  | sarif                       |
| token             | GitHub token for authentication                         | `false`  |                             |
| username          | GitHub username for commits                             | `false`  | github-actions              |
| email             | GitHub email for commits                                | `false`  | <github-actions@github.com> |

## Outputs

| parameter   | description               |
|-------------|---------------------------|
| error-count | Number of errors found    |
| fixed-count | Number of issues fixed    |
| sarif-file  | Path to SARIF report file |

## Runs

This action is a `composite` action.
