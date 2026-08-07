# PR Lint

<div align="center">
  <img src="https://img.shields.io/badge/icon-check-circle-green" alt="check-circle" />
  <img src="https://img.shields.io/badge/status-stable-brightgreen" alt="Status" />
  <img src="https://img.shields.io/badge/license-MIT-blue" alt="License" />
</div>

## Overview

Runs MegaLinter against pull requests

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

      - name: PR Lint
        uses: ivuorinen/actions/pr-lint@vYYYY.MM.DD
        with:
          email: 'github-actions@github.com'
          token: 'your-value-here'
          username: 'github-actions'
```

## Configuration

This action supports various configuration options to customize its behavior according to your needs.

### Input Parameters

| Parameter      | Description                     | Type     | Required | Default Value               |
|----------------|---------------------------------|----------|----------|-----------------------------|
| **`email`**    | GitHub email for commits        | `string` | ❌ No     | `github-actions@github.com` |
| **`token`**    | GitHub token for authentication | `string` | ❌ No     | _None_                      |
| **`username`** | GitHub username for commits     | `string` | ❌ No     | `github-actions`            |

#### Parameter Details

##### `email`

GitHub email for commits

- **Type**: String
- **Required**: No
- **Default**: `github-actions@github.com`

```yaml
with:
  email: 'github-actions@github.com'
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

### Output Parameters

This action provides the following outputs that can be used in subsequent workflow steps:

| Parameter               | Description                                 | Usage                                       |
|-------------------------|---------------------------------------------|---------------------------------------------|
| **`errors_found`**      | Number of linting errors found              | `\${{ steps. .outputs.errors_found }}`      |
| **`validation_status`** | Overall validation status (success/failure) | `\${{ steps. .outputs.validation_status }}` |

#### Using Outputs

```yaml
- name: PR Lint
  id: action-step
  uses: ivuorinen/actions/pr-lint@vYYYY.MM.DD

- name: Use Output
  run: |
    echo "errors_found: \${{ steps.action-step.outputs.errors_found }}"
    echo "validation_status: \${{ steps.action-step.outputs.validation_status }}"
```

## 🔐 Required Permissions

This action requires specific GitHub permissions to function correctly. Ensure your workflow includes these permissions:

| Permission      | Access Level | Description                   |
|-----------------|--------------|-------------------------------|
| `contents`      | `write`      | Required for action operation |
| `pull-requests` | `write`      | Required for action operation |

### How to Set Permissions

```yaml
name: My Workflow
on: [push]

permissions:
  contents: write
  pull-requests: write

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: ivuorinen/actions/pr-lint@vYYYY.MM.DD
```

**Note:** If your workflow doesn't specify permissions, GitHub uses default permissions which may not include all required permissions above.

## Examples

### Basic Usage

```yaml
- name: Basic PR Lint
  uses: ivuorinen/actions/pr-lint@vYYYY.MM.DD
  with:
    email: 'github-actions@github.com'
    token: 'example-value'
    username: 'github-actions'
```

### Advanced Configuration

```yaml
- name: Advanced PR Lint
  uses: ivuorinen/actions/pr-lint@vYYYY.MM.DD
  with:
    email: "github-actions@github.com"
    token: "\${{ vars.TOKEN }}"
    username: "github-actions"
  env:
    GITHUB_TOKEN: \${{ secrets.GITHUB_TOKEN }}
```

### Conditional Usage

```yaml
- name: Conditional PR Lint
  if: github.event_name == 'push'
  uses: ivuorinen/actions/pr-lint@vYYYY.MM.DD
  with:
    email: 'github-actions@github.com'
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
