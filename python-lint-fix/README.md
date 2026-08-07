# Python Lint and Fix

<div align="center">
  <img src="https://img.shields.io/badge/icon-code-yellow" alt="code" />
  <img src="https://img.shields.io/badge/status-stable-brightgreen" alt="Status" />
  <img src="https://img.shields.io/badge/license-MIT-blue" alt="License" />
</div>

## Overview

Lints and fixes Python files, commits changes, and uploads SARIF report.

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

      - name: Python Lint and Fix
        uses: ivuorinen/actions/python-lint-fix@vYYYY.MM.DD
        with:
          autopep8-version: '2.0.4'
          email: 'github-actions@github.com'
          fail-on-error: 'true'
          flake8-version: '7.0.0'
          max-retries: '3'
          python-version: '3.11'
          token: 'your-value-here'
          username: 'github-actions'
          working-directory: '.'
```

## Configuration

This action supports various configuration options to customize its behavior according to your needs.

### Input Parameters

| Parameter               | Description                                                    | Type     | Required | Default Value               |
|-------------------------|----------------------------------------------------------------|----------|----------|-----------------------------|
| **`autopep8-version`**  | Autopep8 version to use                                        | `string` | ❌ No     | `2.0.4`                     |
| **`email`**             | GitHub email for commits                                       | `string` | ❌ No     | `github-actions@github.com` |
| **`fail-on-error`**     | Whether to fail the action if linting errors are found         | `string` | ❌ No     | `true`                      |
| **`flake8-version`**    | Flake8 version to use                                          | `string` | ❌ No     | `7.0.0`                     |
| **`max-retries`**       | Maximum number of retry attempts for installations and linting | `string` | ❌ No     | `3`                         |
| **`python-version`**    | Python version to use                                          | `string` | ❌ No     | `3.11`                      |
| **`token`**             | GitHub token for authentication                                | `string` | ❌ No     | _None_                      |
| **`username`**          | GitHub username for commits                                    | `string` | ❌ No     | `github-actions`            |
| **`working-directory`** | Directory containing Python files to lint                      | `string` | ❌ No     | `.`                         |

#### Parameter Details

##### `autopep8-version`

Autopep8 version to use

- **Type**: String
- **Required**: No
- **Default**: `2.0.4`

```yaml
with:
  autopep8-version: '2.0.4'
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

Whether to fail the action if linting errors are found

- **Type**: String
- **Required**: No
- **Default**: `true`

```yaml
with:
  fail-on-error: 'true'
```

##### `flake8-version`

Flake8 version to use

- **Type**: String
- **Required**: No
- **Default**: `7.0.0`

```yaml
with:
  flake8-version: '7.0.0'
```

##### `max-retries`

Maximum number of retry attempts for installations and linting

- **Type**: String
- **Required**: No
- **Default**: `3`

```yaml
with:
  max-retries: '3'
```

##### `python-version`

Python version to use

- **Type**: String
- **Required**: No
- **Default**: `3.11`

```yaml
with:
  python-version: '3.11'
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

Directory containing Python files to lint

- **Type**: String
- **Required**: No
- **Default**: `.`

```yaml
with:
  working-directory: '.'
```

### Output Parameters

This action provides the following outputs that can be used in subsequent workflow steps:

| Parameter         | Description                                     | Usage                                 |
|-------------------|-------------------------------------------------|---------------------------------------|
| **`error-count`** | Number of errors found                          | `\${{ steps. .outputs.error-count }}` |
| **`fixed-files`** | Number of files that were fixed                 | `\${{ steps. .outputs.fixed-files }}` |
| **`lint-result`** | Result of the linting process (success/failure) | `\${{ steps. .outputs.lint-result }}` |

#### Using Outputs

```yaml
- name: Python Lint and Fix
  id: action-step
  uses: ivuorinen/actions/python-lint-fix@vYYYY.MM.DD

- name: Use Output
  run: |
    echo "error-count: \${{ steps.action-step.outputs.error-count }}"
    echo "fixed-files: \${{ steps.action-step.outputs.fixed-files }}"
    echo "lint-result: \${{ steps.action-step.outputs.lint-result }}"
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
      - uses: ivuorinen/actions/python-lint-fix@vYYYY.MM.DD
```

**Note:** If your workflow doesn't specify permissions, GitHub uses default permissions which may not include all required permissions above.

## Examples

### Basic Usage

```yaml
- name: Basic Python Lint and Fix
  uses: ivuorinen/actions/python-lint-fix@vYYYY.MM.DD
  with:
    autopep8-version: '2.0.4'
    email: 'github-actions@github.com'
    fail-on-error: 'true'
    flake8-version: '7.0.0'
    max-retries: '3'
    python-version: '3.11'
    token: 'example-value'
    username: 'github-actions'
    working-directory: '.'
```

### Advanced Configuration

```yaml
- name: Advanced Python Lint and Fix
  uses: ivuorinen/actions/python-lint-fix@vYYYY.MM.DD
  with:
    autopep8-version: "2.0.4"
    email: "github-actions@github.com"
    fail-on-error: "true"
    flake8-version: "7.0.0"
    max-retries: "3"
    python-version: "3.11"
    token: "\${{ vars.TOKEN }}"
    username: "github-actions"
    working-directory: "."
  env:
    GITHUB_TOKEN: \${{ secrets.GITHUB_TOKEN }}
```

### Conditional Usage

```yaml
- name: Conditional Python Lint and Fix
  if: github.event_name == 'push'
  uses: ivuorinen/actions/python-lint-fix@vYYYY.MM.DD
  with:
    autopep8-version: '2.0.4'
    email: 'github-actions@github.com'
    fail-on-error: 'true'
    flake8-version: '7.0.0'
    max-retries: '3'
    python-version: '3.11'
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
