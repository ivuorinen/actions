# Biome Lint

<div align="center">
  <img src="https://img.shields.io/badge/icon-check-circle-green" alt="check-circle" />
  <img src="https://img.shields.io/badge/status-stable-brightgreen" alt="Status" />
  <img src="https://img.shields.io/badge/license-MIT-blue" alt="License" />
</div>

## Overview

Run Biome linter in check or fix mode

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

      - name: Biome Lint
        uses: ivuorinen/actions/biome-lint@vYYYY.MM.DD
        with:
          email: 'github-actions@github.com'
          fail-on-error: 'true'
          max-retries: '3'
          mode: 'check'
          token: 'your-value-here'
          username: 'github-actions'
```

## Configuration

This action supports various configuration options to customize its behavior according to your needs.

### Input Parameters

| Parameter           | Description                                                              | Type     | Required | Default Value               |
|---------------------|--------------------------------------------------------------------------|----------|----------|-----------------------------|
| **`email`**         | GitHub email for commits (fix mode only)                                 | `string` | ❌ No     | `github-actions@github.com` |
| **`fail-on-error`** | Whether to fail the action if linting errors are found (check mode only) | `string` | ❌ No     | `true`                      |
| **`max-retries`**   | Maximum number of retry attempts for npm install operations              | `string` | ❌ No     | `3`                         |
| **`mode`**          | Mode to run (check or fix)                                               | `string` | ❌ No     | `check`                     |
| **`token`**         | GitHub token for authentication                                          | `string` | ❌ No     | _None_                      |
| **`username`**      | GitHub username for commits (fix mode only)                              | `string` | ❌ No     | `github-actions`            |

#### Parameter Details

##### `email`

GitHub email for commits (fix mode only)

- **Type**: String
- **Required**: No
- **Default**: `github-actions@github.com`

```yaml
with:
  email: 'github-actions@github.com'
```

##### `fail-on-error`

Whether to fail the action if linting errors are found (check mode only)

- **Type**: String
- **Required**: No
- **Default**: `true`

```yaml
with:
  fail-on-error: 'true'
```

##### `max-retries`

Maximum number of retry attempts for npm install operations

- **Type**: String
- **Required**: No
- **Default**: `3`

```yaml
with:
  max-retries: '3'
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

### Output Parameters

This action provides the following outputs that can be used in subsequent workflow steps:

| Parameter            | Description                                | Usage                                    |
|----------------------|--------------------------------------------|------------------------------------------|
| **`errors_count`**   | Number of errors found (check mode only)   | `\${{ steps. .outputs.errors_count }}`   |
| **`files_changed`**  | Number of files changed (fix mode only)    | `\${{ steps. .outputs.files_changed }}`  |
| **`status`**         | Overall status (success/failure)           | `\${{ steps. .outputs.status }}`         |
| **`warnings_count`** | Number of warnings found (check mode only) | `\${{ steps. .outputs.warnings_count }}` |

#### Using Outputs

```yaml
- name: Biome Lint
  id: action-step
  uses: ivuorinen/actions/biome-lint@vYYYY.MM.DD

- name: Use Output
  run: |
    echo "errors_count: \${{ steps.action-step.outputs.errors_count }}"
    echo "files_changed: \${{ steps.action-step.outputs.files_changed }}"
    echo "status: \${{ steps.action-step.outputs.status }}"
    echo "warnings_count: \${{ steps.action-step.outputs.warnings_count }}"
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
      - uses: ivuorinen/actions/biome-lint@vYYYY.MM.DD
```

**Note:** If your workflow doesn't specify permissions, GitHub uses default permissions which may not include all required permissions above.

## Examples

### Basic Usage

```yaml
- name: Basic Biome Lint
  uses: ivuorinen/actions/biome-lint@vYYYY.MM.DD
  with:
    email: 'github-actions@github.com'
    fail-on-error: 'true'
    max-retries: '3'
    mode: 'check'
    token: 'example-value'
    username: 'github-actions'
```

### Advanced Configuration

```yaml
- name: Advanced Biome Lint
  uses: ivuorinen/actions/biome-lint@vYYYY.MM.DD
  with:
    email: "github-actions@github.com"
    fail-on-error: "true"
    max-retries: "3"
    mode: "check"
    token: "\${{ vars.TOKEN }}"
    username: "github-actions"
  env:
    GITHUB_TOKEN: \${{ secrets.GITHUB_TOKEN }}
```

### Conditional Usage

```yaml
- name: Conditional Biome Lint
  if: github.event_name == 'push'
  uses: ivuorinen/actions/biome-lint@vYYYY.MM.DD
  with:
    email: 'github-actions@github.com'
    fail-on-error: 'true'
    max-retries: '3'
    mode: 'check'
    token: 'production-value'
    username: 'github-actions'
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
