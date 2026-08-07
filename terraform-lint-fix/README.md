# Terraform Lint and Fix

![server](https://img.shields.io/badge/icon-server-green) ![GitHub](<https://img.shields.io/badge/GitHub%20Action-> -blue) ![License](https://img.shields.io/badge/license-MIT-green)

> Lints and fixes Terraform files with advanced validation and security checks.

## 🚀 Quick Start

```yaml
name: My Workflow
on: [push]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@11d5960a326750d5838078e36cf38b85af677262 # v4
      - name: Terraform Lint and Fix
        uses: ivuorinen/actions/terraform-lint-fix@vYYYY.MM.DD
        with:
          auto-fix: 'true'
          config-file: '.tflint.hcl'
          email: 'github-actions@github.com'
          fail-on-error: 'true'
          format: 'sarif'
          max-retries: '3'
          terraform-version: 'latest'
          tflint-version: 'latest'
          token: '${{ github.token }}'
          username: 'github-actions'
          working-directory: '.'
```

## 📥 Inputs

| Parameter           | Description                                             | Required | Default                     |
|---------------------|---------------------------------------------------------|----------|-----------------------------|
| `auto-fix`          | Automatically fix issues when possible                  | ❌        | `true`                      |
| `config-file`       | Path to TFLint config file                              | ❌        | `.tflint.hcl`               |
| `email`             | GitHub email for commits                                | ❌        | `github-actions@github.com` |
| `fail-on-error`     | Fail workflow if issues are found                       | ❌        | `true`                      |
| `format`            | Output format (compact, json, checkstyle, junit, sarif) | ❌        | `sarif`                     |
| `max-retries`       | Maximum number of retry attempts                        | ❌        | `3`                         |
| `terraform-version` | Terraform version to use                                | ❌        | `latest`                    |
| `tflint-version`    | TFLint version to use                                   | ❌        | `latest`                    |
| `token`             | GitHub token for authentication                         | ❌        | -                           |
| `username`          | GitHub username for commits                             | ❌        | `github-actions`            |
| `working-directory` | Directory containing Terraform files                    | ❌        | `.`                         |

## 📤 Outputs

| Parameter     | Description               |
|---------------|---------------------------|
| `error-count` | Number of errors found    |
| `fixed-count` | Number of issues fixed    |
| `sarif-file`  | Path to SARIF report file |

## 🔐 Permissions

This action requires the following permissions:

| Permission        | Access Level |
|-------------------|--------------|
| `contents`        | `write`      |
| `security-events` | `write`      |

**Usage in workflow:**

```yaml
permissions:
  contents: write
  security-events: write
```

## 💡 Examples

<details>
<summary>Basic Usage</summary>

```yaml
- name: Terraform Lint and Fix
  uses: ivuorinen/actions/terraform-lint-fix@vYYYY.MM.DD
  with:
    auto-fix: 'true'
    config-file: '.tflint.hcl'
    email: 'github-actions@github.com'
    fail-on-error: 'true'
    format: 'sarif'
    max-retries: '3'
    terraform-version: 'latest'
    tflint-version: 'latest'
    token: '${{ github.token }}'
    username: 'github-actions'
    working-directory: '.'
```

</details>

<details>
<summary>Advanced Configuration</summary>

```yaml
- name: Terraform Lint and Fix with custom settings
  uses: ivuorinen/actions/terraform-lint-fix@vYYYY.MM.DD
  with:
    auto-fix: 'true'
    config-file: '.tflint.hcl'
    email: 'github-actions@github.com'
    fail-on-error: 'true'
    format: 'sarif'
    max-retries: '3'
    terraform-version: 'latest'
    tflint-version: 'latest'
    token: '${{ github.token }}'
    username: 'github-actions'
    working-directory: '.'
```

</details>

## 🔧 Development

See the [action.yml](./action.yml) for the complete action specification.

## 📄 License

This action is distributed under the MIT License. See [LICENSE](../LICENSE.md) for more information.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

---

<div align="center">
  <sub>🚀 Generated with <a href="https://github.com/ivuorinen/gh-action-readme">gh-action-readme</a></sub>
</div>
