# Terraform Lint and Fix

<div align="center">
  <img src="https://img.shields.io/badge/icon-server-green" alt="server" />
  <img src="https://img.shields.io/badge/status-stable-brightgreen" alt="Status" />
  <img src="https://img.shields.io/badge/license-MIT-blue" alt="License" />
</div>

## Overview

Lints and fixes Terraform files with advanced validation and security checks.

This GitHub Action provides a robust solution for your CI/CD pipeline with comprehensive configuration options and detailed output information.

## Table of Contents

- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [Input Parameters](#input-parameters)
- [Output Parameters](#output-parameters)
- [Examples](#examples)

- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

## Quick Start

Add the following step to your GitHub Actions workflow:

```yaml
name: CI/CD Pipeline
on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout Repository
        uses: actions/checkout@v4

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
          token: 'your-value-here'
          username: 'github-actions'
          working-directory: '.'
```

## Configuration

This action supports various configuration options to customize its behavior according to your needs.

### Input Parameters

| Parameter               | Description                                             | Type     | Required | Default Value               |
|-------------------------|---------------------------------------------------------|----------|----------|-----------------------------|
| **`auto-fix`**          | Automatically fix issues when possible                  | `string` | ❌ No     | `true`                      |
| **`config-file`**       | Path to TFLint config file                              | `string` | ❌ No     | `.tflint.hcl`               |
| **`email`**             | GitHub email for commits                                | `string` | ❌ No     | `github-actions@github.com` |
| **`fail-on-error`**     | Fail workflow if issues are found                       | `string` | ❌ No     | `true`                      |
| **`format`**            | Output format (compact, json, checkstyle, junit, sarif) | `string` | ❌ No     | `sarif`                     |
| **`max-retries`**       | Maximum number of retry attempts                        | `string` | ❌ No     | `3`                         |
| **`terraform-version`** | Terraform version to use                                | `string` | ❌ No     | `latest`                    |
| **`tflint-version`**    | TFLint version to use                                   | `string` | ❌ No     | `latest`                    |
| **`token`**             | GitHub token for authentication                         | `string` | ❌ No     | _None_                      |
| **`username`**          | GitHub username for commits                             | `string` | ❌ No     | `github-actions`            |
| **`working-directory`** | Directory containing Terraform files                    | `string` | ❌ No     | `.`                         |

#### Parameter Details

##### `auto-fix`

Automatically fix issues when possible

- **Type**: String
- **Required**: No
- **Default**: `true`

```yaml
with:
  auto-fix: 'true'
```

##### `config-file`

Path to TFLint config file

- **Type**: String
- **Required**: No
- **Default**: `.tflint.hcl`

```yaml
with:
  config-file: '.tflint.hcl'
```

##### `email`

GitHub email for commits

- **Type**: String
- **Required**: No
- **Default**: `github-actions@github.com`

```yaml
with:
  email: 'github-actions@github.com'
```

##### `fail-on-error`

Fail workflow if issues are found

- **Type**: String
- **Required**: No
- **Default**: `true`

```yaml
with:
  fail-on-error: 'true'
```

##### `format`

Output format (compact, json, checkstyle, junit, sarif)

- **Type**: String
- **Required**: No
- **Default**: `sarif`

```yaml
with:
  format: 'sarif'
```

##### `max-retries`

Maximum number of retry attempts

- **Type**: String
- **Required**: No
- **Default**: `3`

```yaml
with:
  max-retries: '3'
```

##### `terraform-version`

Terraform version to use

- **Type**: String
- **Required**: No
- **Default**: `latest`

```yaml
with:
  terraform-version: 'latest'
```

##### `tflint-version`

TFLint version to use

- **Type**: String
- **Required**: No
- **Default**: `latest`

```yaml
with:
  tflint-version: 'latest'
```

##### `token`

GitHub token for authentication

- **Type**: String
- **Required**: No

```yaml
with:
  token: 'your-value-here'
```

##### `username`

GitHub username for commits

- **Type**: String
- **Required**: No
- **Default**: `github-actions`

```yaml
with:
  username: 'github-actions'
```

##### `working-directory`

Directory containing Terraform files

- **Type**: String
- **Required**: No
- **Default**: `.`

```yaml
with:
  working-directory: '.'
```

### Output Parameters

This action provides the following outputs that can be used in subsequent workflow steps:

| Parameter         | Description               | Usage                                 |
|-------------------|---------------------------|---------------------------------------|
| **`error-count`** | Number of errors found    | `\${{ steps. .outputs.error-count }}` |
| **`fixed-count`** | Number of issues fixed    | `\${{ steps. .outputs.fixed-count }}` |
| **`sarif-file`**  | Path to SARIF report file | `\${{ steps. .outputs.sarif-file }}`  |

#### Using Outputs

```yaml
- name: Terraform Lint and Fix
  id: action-step
  uses: ivuorinen/actions/terraform-lint-fix@vYYYY.MM.DD

- name: Use Output
  run: |
    echo "error-count: \${{ steps.action-step.outputs.error-count }}"
    echo "fixed-count: \${{ steps.action-step.outputs.fixed-count }}"
    echo "sarif-file: \${{ steps.action-step.outputs.sarif-file }}"
```

## 🔐 Required Permissions

This action requires specific GitHub permissions to function correctly. Ensure your workflow includes these permissions:

| Permission        | Access Level | Description                   |
|-------------------|--------------|-------------------------------|
| `contents`        | `write`      | Required for action operation |
| `security-events` | `write`      | Required for action operation |

### How to Set Permissions

```yaml
name: My Workflow
on: [push]

permissions:
  contents: write
  security-events: write

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: ivuorinen/actions/terraform-lint-fix@vYYYY.MM.DD
```

**Note:** If your workflow doesn't specify permissions, GitHub uses default permissions which may not include all required permissions above.

## Examples

### Basic Usage

```yaml
- name: Basic Terraform Lint and Fix
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
    token: 'example-value'
    username: 'github-actions'
    working-directory: '.'
```

### Advanced Configuration

```yaml
- name: Advanced Terraform Lint and Fix
  uses: ivuorinen/actions/terraform-lint-fix@vYYYY.MM.DD
  with:
    auto-fix: "true"
    config-file: ".tflint.hcl"
    email: "github-actions@github.com"
    fail-on-error: "true"
    format: "sarif"
    max-retries: "3"
    terraform-version: "latest"
    tflint-version: "latest"
    token: "\${{ vars.TOKEN }}"
    username: "github-actions"
    working-directory: "."
  env:
    GITHUB_TOKEN: \${{ secrets.GITHUB_TOKEN }}
```

### Conditional Usage

```yaml
- name: Conditional Terraform Lint and Fix
  if: github.event_name == 'push'
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
    token: 'production-value'
    username: 'github-actions'
    working-directory: '.'
```

## Troubleshooting

### Common Issues

1. **Authentication Errors**: Ensure you have set up the required secrets in your repository settings.
2. **Permission Issues**: Check that your GitHub token has the necessary permissions.
3. **Configuration Errors**: Validate your input parameters against the schema.

### Getting Help

- Check the [action.yml](./action.yml) for the complete specification
- Open an issue if you encounter problems

## Contributing

We welcome contributions! Please see our [Contributing Guide](../CONTRIBUTING.md) for details.

### Development Setup

1. Fork this repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License. See the [LICENSE](../LICENSE.md) file for details.

## Support

If you find this action helpful, please consider:

- ⭐ Starring this repository
- 🐛 Reporting issues
- 💡 Suggesting improvements
- 🤝 Contributing code

---

<div align="center">
  <sub>📚 Documentation generated with <a href="https://github.com/ivuorinen/gh-action-readme">gh-action-readme</a></sub>
</div>
