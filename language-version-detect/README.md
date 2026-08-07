# Language Version Detect

<div align="center">
  <img src="https://img.shields.io/badge/icon-code-blue" alt="code" />
  <img src="https://img.shields.io/badge/status-stable-brightgreen" alt="Status" />
  <img src="https://img.shields.io/badge/license-MIT-blue" alt="License" />
</div>

## Overview

DEPRECATED: This action is deprecated. Inline version detection directly in your actions instead. Detects language version from project configuration files with support for PHP, Python, Go, and .NET.

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

      - name: Language Version Detect
        uses: ivuorinen/actions/language-version-detect@vYYYY.MM.DD
        with:
          default-version: 'your-value-here'
          language: 'your-value-here'
          token: 'your-value-here'
```

## Configuration

This action supports various configuration options to customize its behavior according to your needs.

### Input Parameters

| Parameter             | Description                                              | Type     | Required | Default Value |
|-----------------------|----------------------------------------------------------|----------|----------|---------------|
| **`default-version`** | Default version to use if no version is detected         | `string` | ❌ No     | _None_        |
| **`language`**        | Language to detect version for (php, python, go, dotnet) | `string` | ✅ Yes    | _None_        |
| **`token`**           | GitHub token for authentication                          | `string` | ❌ No     | _None_        |

#### Parameter Details

##### `default-version`

Default version to use if no version is detected

- **Type**: String
- **Required**: No

```yaml
with:
  default-version: 'your-value-here'
```

##### `language`

Language to detect version for (php, python, go, dotnet)

- **Type**: String
- **Required**: Yes

```yaml
with:
  language: 'your-value-here'
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

| Parameter              | Description                                                         | Usage                                      |
|------------------------|---------------------------------------------------------------------|--------------------------------------------|
| **`detected-version`** | Detected or default language version                                | `\${{ steps. .outputs.detected-version }}` |
| **`package-manager`**  | Detected package manager (python: pip/poetry/pipenv, php: composer) | `\${{ steps. .outputs.package-manager }}`  |

#### Using Outputs

```yaml
- name: Language Version Detect
  id: action-step
  uses: ivuorinen/actions/language-version-detect@vYYYY.MM.DD

- name: Use Output
  run: |
    echo "detected-version: \${{ steps.action-step.outputs.detected-version }}"
    echo "package-manager: \${{ steps.action-step.outputs.package-manager }}"
```

## 🔐 Required Permissions

This action requires specific GitHub permissions to function correctly. Ensure your workflow includes these permissions:

| Permission | Access Level | Description                   |
|------------|--------------|-------------------------------|
| `contents` | `read`       | Required for action operation |

### How to Set Permissions

```yaml
name: My Workflow
on: [push]

permissions:
  contents: read

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: ivuorinen/actions/language-version-detect@vYYYY.MM.DD
```

**Note:** If your workflow doesn't specify permissions, GitHub uses default permissions which may not include all required permissions above.

## Examples

### Basic Usage

```yaml
- name: Basic Language Version Detect
  uses: ivuorinen/actions/language-version-detect@vYYYY.MM.DD
  with:
    default-version: 'example-value'
    language: 'example-value'
    token: 'example-value'
```

### Advanced Configuration

```yaml
- name: Advanced Language Version Detect
  uses: ivuorinen/actions/language-version-detect@vYYYY.MM.DD
  with:
    default-version: "\${{ vars.DEFAULT-VERSION }}"
    language: "\${{ vars.LANGUAGE }}"
    token: "\${{ vars.TOKEN }}"
  env:
    GITHUB_TOKEN: \${{ secrets.GITHUB_TOKEN }}
```

### Conditional Usage

```yaml
- name: Conditional Language Version Detect
  if: github.event_name == 'push'
  uses: ivuorinen/actions/language-version-detect@vYYYY.MM.DD
  with:
    default-version: 'production-value'
    language: 'production-value'
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
