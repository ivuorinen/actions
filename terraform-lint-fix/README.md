# ivuorinen/actions/terraform-lint-fix

## Terraform Lint and Fix

### Description

Lints and fixes Terraform files with advanced validation and security checks.

### Inputs

| name                | description                                                    | required | default                     |
|---------------------|----------------------------------------------------------------|----------|-----------------------------|
| `terraform-version` | <p>Terraform version to use</p>                                | `false`  | `latest`                    |
| `tflint-version`    | <p>TFLint version to use</p>                                   | `false`  | `latest`                    |
| `working-directory` | <p>Directory containing Terraform files</p>                    | `false`  | `.`                         |
| `config-file`       | <p>Path to TFLint config file</p>                              | `false`  | `.tflint.hcl`               |
| `fail-on-error`     | <p>Fail workflow if issues are found</p>                       | `false`  | `true`                      |
| `auto-fix`          | <p>Automatically fix issues when possible</p>                  | `false`  | `true`                      |
| `max-retries`       | <p>Maximum number of retry attempts</p>                        | `false`  | `3`                         |
| `format`            | <p>Output format (compact, json, checkstyle, junit, sarif)</p> | `false`  | `sarif`                     |
| `token`             | <p>GitHub token for authentication</p>                         | `false`  | `""`                        |
| `username`          | <p>GitHub username for commits</p>                             | `false`  | `github-actions`            |
| `email`             | <p>GitHub email for commits</p>                                | `false`  | `github-actions@github.com` |

### Outputs

| name          | description                      |
|---------------|----------------------------------|
| `error-count` | <p>Number of errors found</p>    |
| `fixed-count` | <p>Number of issues fixed</p>    |
| `sarif-file`  | <p>Path to SARIF report file</p> |

### Runs

This action is a `composite` action.

### Usage

```yaml
- uses: ivuorinen/actions/terraform-lint-fix@main
  with:
    terraform-version:
    # Terraform version to use
    #
    # Required: false
    # Default: latest

    tflint-version:
    # TFLint version to use
    #
    # Required: false
    # Default: latest

    working-directory:
    # Directory containing Terraform files
    #
    # Required: false
    # Default: .

    config-file:
    # Path to TFLint config file
    #
    # Required: false
    # Default: .tflint.hcl

    fail-on-error:
    # Fail workflow if issues are found
    #
    # Required: false
    # Default: true

    auto-fix:
    # Automatically fix issues when possible
    #
    # Required: false
    # Default: true

    max-retries:
    # Maximum number of retry attempts
    #
    # Required: false
    # Default: 3

    format:
    # Output format (compact, json, checkstyle, junit, sarif)
    #
    # Required: false
    # Default: sarif

    token:
    # GitHub token for authentication
    #
    # Required: false
    # Default: ""

    username:
    # GitHub username for commits
    #
    # Required: false
    # Default: github-actions

    email:
    # GitHub email for commits
    #
    # Required: false
    # Default: github-actions@github.com
```
