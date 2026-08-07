# Compress Images

<div align="center">
  <img src="https://img.shields.io/badge/icon-image-blue" alt="image" />
  <img src="https://img.shields.io/badge/status-stable-brightgreen" alt="Status" />
  <img src="https://img.shields.io/badge/license-MIT-blue" alt="License" />
</div>

## Overview

Compress images on demand (workflow_dispatch), and at 11pm every Sunday (schedule).

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

      - name: Compress Images
        uses: ivuorinen/actions/compress-images@vYYYY.MM.DD
        with:
          email: 'github-actions@github.com'
          ignore-paths: 'node_modules/**,dist/**,build/**'
          image-quality: '85'
          png-quality: '95'
          token: '${{ github.token }}'
          username: 'github-actions'
          working-directory: '.'
```

## Configuration

This action supports various configuration options to customize its behavior according to your needs.

### Input Parameters

| Parameter               | Description                                        | Type     | Required | Default Value                      |
|-------------------------|----------------------------------------------------|----------|----------|------------------------------------|
| **`email`**             | GitHub email for commits                           | `string` | ❌ No     | `github-actions@github.com`        |
| **`ignore-paths`**      | Paths to ignore during compression (glob patterns) | `string` | ❌ No     | `node_modules/**,dist/**,build/**` |
| **`image-quality`**     | JPEG compression quality (0-100)                   | `string` | ❌ No     | `85`                               |
| **`png-quality`**       | PNG compression quality (0-100)                    | `string` | ❌ No     | `95`                               |
| **`token`**             | GitHub token for authentication                    | `string` | ❌ No     | `${{ github.token }}`              |
| **`username`**          | GitHub username for commits                        | `string` | ❌ No     | `github-actions`                   |
| **`working-directory`** | Directory containing images to compress            | `string` | ❌ No     | `.`                                |

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

##### `ignore-paths`

Paths to ignore during compression (glob patterns)

- **Type**: String
- **Required**: No
- **Default**: `node_modules/**,dist/**,build/**`

```yaml
with:
  ignore-paths: 'node_modules/**,dist/**,build/**'
```

##### `image-quality`

JPEG compression quality (0-100)

- **Type**: String
- **Required**: No
- **Default**: `85`

```yaml
with:
  image-quality: '85'
```

##### `png-quality`

PNG compression quality (0-100)

- **Type**: String
- **Required**: No
- **Default**: `95`

```yaml
with:
  png-quality: '95'
```

##### `token`

GitHub token for authentication

- **Type**: String
- **Required**: No
- **Default**: `${{ github.token }}`

```yaml
with:
  token: '${{ github.token }}'
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

Directory containing images to compress

- **Type**: String
- **Required**: No
- **Default**: `.`

```yaml
with:
  working-directory: '.'
```

### Output Parameters

This action provides the following outputs that can be used in subsequent workflow steps:

| Parameter                | Description                                  | Usage                                        |
|--------------------------|----------------------------------------------|----------------------------------------------|
| **`compression_report`** | Markdown report of compression results       | `\${{ steps. .outputs.compression_report }}` |
| **`images_compressed`**  | Whether any images were compressed (boolean) | `\${{ steps. .outputs.images_compressed }}`  |

#### Using Outputs

```yaml
- name: Compress Images
  id: action-step
  uses: ivuorinen/actions/compress-images@vYYYY.MM.DD

- name: Use Output
  run: |
    echo "compression_report: \${{ steps.action-step.outputs.compression_report }}"
    echo "images_compressed: \${{ steps.action-step.outputs.images_compressed }}"
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
      - uses: ivuorinen/actions/compress-images@vYYYY.MM.DD
```

**Note:** If your workflow doesn't specify permissions, GitHub uses default permissions which may not include all required permissions above.

## Examples

### Basic Usage

```yaml
- name: Basic Compress Images
  uses: ivuorinen/actions/compress-images@vYYYY.MM.DD
  with:
    email: 'github-actions@github.com'
    ignore-paths: 'node_modules/**,dist/**,build/**'
    image-quality: '85'
    png-quality: '95'
    token: '${{ github.token }}'
    username: 'github-actions'
    working-directory: '.'
```

### Advanced Configuration

```yaml
- name: Advanced Compress Images
  uses: ivuorinen/actions/compress-images@vYYYY.MM.DD
  with:
    email: 'github-actions@github.com'
    ignore-paths: 'node_modules/**,dist/**,build/**'
    image-quality: '85'
    png-quality: '95'
    token: '${{ github.token }}'
    username: 'github-actions'
    working-directory: '.'
  env:
    GITHUB_TOKEN: \${{ secrets.GITHUB_TOKEN }}
```

### Conditional Usage

```yaml
- name: Conditional Compress Images
  if: github.event_name == 'push'
  uses: ivuorinen/actions/compress-images@vYYYY.MM.DD
  with:
    email: 'github-actions@github.com'
    ignore-paths: 'node_modules/**,dist/**,build/**'
    image-quality: '85'
    png-quality: '95'
    token: '${{ github.token }}'
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
