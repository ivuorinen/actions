# Stale

<div align="center">
  <img src="https://img.shields.io/badge/icon-clock-yellow" alt="clock" />
  <img src="https://img.shields.io/badge/status-stable-brightgreen" alt="Status" />
  <img src="https://img.shields.io/badge/license-MIT-blue" alt="License" />
</div>

## Overview

A GitHub Action to close stale issues and pull requests.

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

      - name: Stale
        uses: ivuorinen/actions/stale@vYYYY.MM.DD
        with:
          days-before-close: '7'
          days-before-stale: '30'
          token: 'your-value-here'
```

## Configuration

This action supports various configuration options to customize its behavior according to your needs.

### Input Parameters

| Parameter               | Description                                                     | Type     | Required | Default Value |
|-------------------------|-----------------------------------------------------------------|----------|----------|---------------|
| **`days-before-close`** | Number of days of inactivity before a stale issue is closed     | `string` | ❌ No     | `7`           |
| **`days-before-stale`** | Number of days of inactivity before an issue is marked as stale | `string` | ❌ No     | `30`          |
| **`token`**             | GitHub token for authentication                                 | `string` | ❌ No     | _None_        |

#### Parameter Details

##### `days-before-close`

Number of days of inactivity before a stale issue is closed

- **Type**: String
- **Required**: No
- **Default**: `7`

```yaml
with:
  days-before-close: '7'
```

##### `days-before-stale`

Number of days of inactivity before an issue is marked as stale

- **Type**: String
- **Required**: No
- **Default**: `30`

```yaml
with:
  days-before-stale: '30'
```

##### `token`

GitHub token for authentication

- **Type**: String
- **Required**: No

```yaml
with:
  token: 'your-value-here'
```

### Output Parameters

This action provides the following outputs that can be used in subsequent workflow steps:

| Parameter                 | Description                      | Usage                                         |
|---------------------------|----------------------------------|-----------------------------------------------|
| **`closed_issues_count`** | Number of issues closed          | `\${{ steps. .outputs.closed_issues_count }}` |
| **`staled_issues_count`** | Number of issues marked as stale | `\${{ steps. .outputs.staled_issues_count }}` |

#### Using Outputs

```yaml
- name: Stale
  id: action-step
  uses: ivuorinen/actions/stale@vYYYY.MM.DD

- name: Use Output
  run: |
    echo "closed_issues_count: \${{ steps.action-step.outputs.closed_issues_count }}"
    echo "staled_issues_count: \${{ steps.action-step.outputs.staled_issues_count }}"
```

## 🔐 Required Permissions

This action requires specific GitHub permissions to function correctly. Ensure your workflow includes these permissions:

| Permission      | Access Level | Description                   |
|-----------------|--------------|-------------------------------|
| `issues`        | `write`      | Required for action operation |
| `pull-requests` | `write`      | Required for action operation |

### How to Set Permissions

```yaml
name: My Workflow
on: [push]

permissions:
  issues: write
  pull-requests: write

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: ivuorinen/actions/stale@vYYYY.MM.DD
```

**Note:** If your workflow doesn't specify permissions, GitHub uses default permissions which may not include all required permissions above.

## Examples

### Basic Usage

```yaml
- name: Basic Stale
  uses: ivuorinen/actions/stale@vYYYY.MM.DD
  with:
    days-before-close: '7'
    days-before-stale: '30'
    token: 'example-value'
```

### Advanced Configuration

```yaml
- name: Advanced Stale
  uses: ivuorinen/actions/stale@vYYYY.MM.DD
  with:
    days-before-close: "7"
    days-before-stale: "30"
    token: "\${{ vars.TOKEN }}"
  env:
    GITHUB_TOKEN: \${{ secrets.GITHUB_TOKEN }}
```

### Conditional Usage

```yaml
- name: Conditional Stale
  if: github.event_name == 'push'
  uses: ivuorinen/actions/stale@vYYYY.MM.DD
  with:
    days-before-close: '7'
    days-before-stale: '30'
    token: 'production-value'
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
