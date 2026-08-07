# ESLint Lint

<div align="center">
  <img src="https://img.shields.io/badge/icon-check-circle-blue" alt="check-circle" />
  <img src="https://img.shields.io/badge/status-stable-brightgreen" alt="Status" />
  <img src="https://img.shields.io/badge/license-MIT-blue" alt="License" />
</div>

## Overview

Run ESLint in check or fix mode with advanced configuration and reporting

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

      - name: ESLint Lint
        uses: ivuorinen/actions/eslint-lint@vYYYY.MM.DD
        with:
          cache: 'true'
          config-file: '.eslintrc'
          email: 'github-actions@github.com'
          eslint-version: 'latest'
          fail-on-error: 'true'
          file-extensions: '.js,.jsx,.ts,.tsx'
          ignore-file: '.eslintignore'
          max-retries: '3'
          max-warnings: '0'
          mode: 'check'
          report-format: 'sarif'
          token: 'your-value-here'
          username: 'github-actions'
          working-directory: '.'
```

## Configuration

This action supports various configuration options to customize its behavior according to your needs.

### Input Parameters

| Parameter               | Description                                          | Type     | Required | Default Value               |
|-------------------------|------------------------------------------------------|----------|----------|-----------------------------|
| **`cache`**             | Enable ESLint caching                                | `string` | ❌ No     | `true`                      |
| **`config-file`**       | Path to ESLint config file                           | `string` | ❌ No     | `.eslintrc`                 |
| **`email`**             | GitHub email for commits (fix mode only)             | `string` | ❌ No     | `github-actions@github.com` |
| **`eslint-version`**    | ESLint version to use                                | `string` | ❌ No     | `latest`                    |
| **`fail-on-error`**     | Fail workflow if issues are found (check mode only)  | `string` | ❌ No     | `true`                      |
| **`file-extensions`**   | File extensions to lint (comma-separated)            | `string` | ❌ No     | `.js,.jsx,.ts,.tsx`         |
| **`ignore-file`**       | Path to ESLint ignore file                           | `string` | ❌ No     | `.eslintignore`             |
| **`max-retries`**       | Maximum number of retry attempts                     | `string` | ❌ No     | `3`                         |
| **`max-warnings`**      | Maximum number of warnings allowed (check mode only) | `string` | ❌ No     | `0`                         |
| **`mode`**              | Mode to run (check or fix)                           | `string` | ❌ No     | `check`                     |
| **`report-format`**     | Output format for check mode (stylish, json, sarif)  | `string` | ❌ No     | `sarif`                     |
| **`token`**             | GitHub token for authentication                      | `string` | ❌ No     | _None_                      |
| **`username`**          | GitHub username for commits (fix mode only)          | `string` | ❌ No     | `github-actions`            |
| **`working-directory`** | Directory containing files to lint                   | `string` | ❌ No     | `.`                         |

#### Parameter Details

##### `cache`

Enable ESLint caching

- **Type**: String
- **Required**: No
- **Default**: `true`

```yaml
with:
  cache: 'true'
```

##### `config-file`

Path to ESLint config file

- **Type**: String
- **Required**: No
- **Default**: `.eslintrc`

```yaml
with:
  config-file: '.eslintrc'
```

##### `email`

GitHub email for commits (fix mode only)

- **Type**: String
- **Required**: No
- **Default**: `github-actions@github.com`

```yaml
with:
  email: 'github-actions@github.com'
```

##### `eslint-version`

ESLint version to use

- **Type**: String
- **Required**: No
- **Default**: `latest`

```yaml
with:
  eslint-version: 'latest'
```

##### `fail-on-error`

Fail workflow if issues are found (check mode only)

- **Type**: String
- **Required**: No
- **Default**: `true`

```yaml
with:
  fail-on-error: 'true'
```

##### `file-extensions`

File extensions to lint (comma-separated)

- **Type**: String
- **Required**: No
- **Default**: `.js,.jsx,.ts,.tsx`

```yaml
with:
  file-extensions: '.js,.jsx,.ts,.tsx'
```

##### `ignore-file`

Path to ESLint ignore file

- **Type**: String
- **Required**: No
- **Default**: `.eslintignore`

```yaml
with:
  ignore-file: '.eslintignore'
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

##### `max-warnings`

Maximum number of warnings allowed (check mode only)

- **Type**: String
- **Required**: No
- **Default**: `0`

```yaml
with:
  max-warnings: '0'
```

##### `mode`

Mode to run (check or fix)

- **Type**: String
- **Required**: No
- **Default**: `check`

```yaml
with:
  mode: 'check'
```

##### `report-format`

Output format for check mode (stylish, json, sarif)

- **Type**: String
- **Required**: No
- **Default**: `sarif`

```yaml
with:
  report-format: 'sarif'
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

GitHub username for commits (fix mode only)

- **Type**: String
- **Required**: No
- **Default**: `github-actions`

```yaml
with:
  username: 'github-actions'
```

##### `working-directory`

Directory containing files to lint

- **Type**: String
- **Required**: No
- **Default**: `.`

```yaml
with:
  working-directory: '.'
```

### Output Parameters

This action provides the following outputs that can be used in subsequent workflow steps:

| Parameter           | Description                                 | Usage                                   |
|---------------------|---------------------------------------------|-----------------------------------------|
| **`error-count`**   | Number of errors found (check mode only)    | `\${{ steps. .outputs.error-count }}`   |
| **`errors-fixed`**  | Number of errors fixed (fix mode only)      | `\${{ steps. .outputs.errors-fixed }}`  |
| **`files-changed`** | Number of files changed (fix mode only)     | `\${{ steps. .outputs.files-changed }}` |
| **`files-checked`** | Number of files checked (check mode only)   | `\${{ steps. .outputs.files-checked }}` |
| **`sarif-file`**    | Path to SARIF report file (check mode only) | `\${{ steps. .outputs.sarif-file }}`    |
| **`status`**        | Overall status (success/failure)            | `\${{ steps. .outputs.status }}`        |
| **`warning-count`** | Number of warnings found (check mode only)  | `\${{ steps. .outputs.warning-count }}` |

#### Using Outputs

```yaml
- name: ESLint Lint
  id: action-step
  uses: ivuorinen/actions/eslint-lint@vYYYY.MM.DD

- name: Use Output
  run: |
    echo "error-count: \${{ steps.action-step.outputs.error-count }}"
    echo "errors-fixed: \${{ steps.action-step.outputs.errors-fixed }}"
    echo "files-changed: \${{ steps.action-step.outputs.files-changed }}"
    echo "files-checked: \${{ steps.action-step.outputs.files-checked }}"
    echo "sarif-file: \${{ steps.action-step.outputs.sarif-file }}"
    echo "status: \${{ steps.action-step.outputs.status }}"
    echo "warning-count: \${{ steps.action-step.outputs.warning-count }}"
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
      - uses: ivuorinen/actions/eslint-lint@vYYYY.MM.DD
```

**Note:** If your workflow doesn't specify permissions, GitHub uses default permissions which may not include all required permissions above.

## Examples

### Basic Usage

```yaml
- name: Basic ESLint Lint
  uses: ivuorinen/actions/eslint-lint@vYYYY.MM.DD
  with:
    cache: 'true'
    config-file: '.eslintrc'
    email: 'github-actions@github.com'
    eslint-version: 'latest'
    fail-on-error: 'true'
    file-extensions: '.js,.jsx,.ts,.tsx'
    ignore-file: '.eslintignore'
    max-retries: '3'
    max-warnings: '0'
    mode: 'check'
    report-format: 'sarif'
    token: 'example-value'
    username: 'github-actions'
    working-directory: '.'
```

### Advanced Configuration

```yaml
- name: Advanced ESLint Lint
  uses: ivuorinen/actions/eslint-lint@vYYYY.MM.DD
  with:
    cache: "true"
    config-file: ".eslintrc"
    email: "github-actions@github.com"
    eslint-version: "latest"
    fail-on-error: "true"
    file-extensions: ".js,.jsx,.ts,.tsx"
    ignore-file: ".eslintignore"
    max-retries: "3"
    max-warnings: "0"
    mode: "check"
    report-format: "sarif"
    token: "\${{ vars.TOKEN }}"
    username: "github-actions"
    working-directory: "."
  env:
    GITHUB_TOKEN: \${{ secrets.GITHUB_TOKEN }}
```

### Conditional Usage

```yaml
- name: Conditional ESLint Lint
  if: github.event_name == 'push'
  uses: ivuorinen/actions/eslint-lint@vYYYY.MM.DD
  with:
    cache: 'true'
    config-file: '.eslintrc'
    email: 'github-actions@github.com'
    eslint-version: 'latest'
    fail-on-error: 'true'
    file-extensions: '.js,.jsx,.ts,.tsx'
    ignore-file: '.eslintignore'
    max-retries: '3'
    max-warnings: '0'
    mode: 'check'
    report-format: 'sarif'
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
