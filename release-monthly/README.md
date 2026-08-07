# Do Monthly Release

<div align="center">
  <img src="https://img.shields.io/badge/icon-calendar-blue" alt="calendar" />
  <img src="https://img.shields.io/badge/status-stable-brightgreen" alt="Status" />
  <img src="https://img.shields.io/badge/license-MIT-blue" alt="License" />
</div>

## Overview

Creates a release for the current month, incrementing patch number if necessary.

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

      - name: Do Monthly Release
        uses: ivuorinen/actions/release-monthly@vYYYY.MM.DD
        with:
          dry-run: 'false'
          prefix: 'your-value-here'
          token: '${{ github.token }}'
```

## Configuration

This action supports various configuration options to customize its behavior according to your needs.

### Input Parameters

| Parameter     | Description                                       | Type     | Required | Default Value         |
|---------------|---------------------------------------------------|----------|----------|-----------------------|
| **`dry-run`** | Run in dry-run mode without creating the release. | `string` | ❌ No     | `false`               |
| **`prefix`**  | Optional prefix for release tags.                 | `string` | ❌ No     | _None_                |
| **`token`**   | GitHub token with permission to create releases.  | `string` | ✅ Yes    | `${{ github.token }}` |

#### Parameter Details

##### `dry-run`

Run in dry-run mode without creating the release.

- **Type**: String
- **Required**: No
- **Default**: `false`

```yaml
with:
  dry-run: 'false'
```

##### `prefix`

Optional prefix for release tags.

- **Type**: String
- **Required**: No

```yaml
with:
  prefix: 'your-value-here'
```

##### `token`

GitHub token with permission to create releases.

- **Type**: String
- **Required**: Yes
- **Default**: `${{ github.token }}`

```yaml
with:
  token: '${{ github.token }}'
```

### Output Parameters

This action provides the following outputs that can be used in subsequent workflow steps:

| Parameter          | Description                    | Usage                                  |
|--------------------|--------------------------------|----------------------------------------|
| **`previous-tag`** | The previous release tag       | `\${{ steps. .outputs.previous-tag }}` |
| **`release-tag`**  | The tag of the created release | `\${{ steps. .outputs.release-tag }}`  |
| **`release-url`**  | The URL of the created release | `\${{ steps. .outputs.release-url }}`  |

#### Using Outputs

```yaml
- name: Do Monthly Release
  id: action-step
  uses: ivuorinen/actions/release-monthly@vYYYY.MM.DD

- name: Use Output
  run: |
    echo "previous-tag: \${{ steps.action-step.outputs.previous-tag }}"
    echo "release-tag: \${{ steps.action-step.outputs.release-tag }}"
    echo "release-url: \${{ steps.action-step.outputs.release-url }}"
```

## 🔐 Required Permissions

This action requires specific GitHub permissions to function correctly. Ensure your workflow includes these permissions:

| Permission | Access Level | Description                   |
|------------|--------------|-------------------------------|
| `contents` | `write`      | Required for action operation |

### How to Set Permissions

```yaml
name: My Workflow
on: [push]

permissions:
  contents: write

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: ivuorinen/actions/release-monthly@vYYYY.MM.DD
```

**Note:** If your workflow doesn't specify permissions, GitHub uses default permissions which may not include all required permissions above.

## Examples

### Basic Usage

```yaml
- name: Basic Do Monthly Release
  uses: ivuorinen/actions/release-monthly@vYYYY.MM.DD
  with:
    dry-run: 'false'
    prefix: 'example-value'
    token: '${{ github.token }}'
```

### Advanced Configuration

```yaml
- name: Advanced Do Monthly Release
  uses: ivuorinen/actions/release-monthly@vYYYY.MM.DD
  with:
    dry-run: "false"
    prefix: "\${{ vars.PREFIX }}"
    token: "${{ github.token }}"
  env:
    GITHUB_TOKEN: \${{ secrets.GITHUB_TOKEN }}
```

### Conditional Usage

```yaml
- name: Conditional Do Monthly Release
  if: github.event_name == 'push'
  uses: ivuorinen/actions/release-monthly@vYYYY.MM.DD
  with:
    dry-run: 'false'
    prefix: 'production-value'
    token: '${{ github.token }}'
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
