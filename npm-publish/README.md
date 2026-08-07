# Publish to NPM

<div align="center">
  <img src="https://img.shields.io/badge/icon-package-green" alt="package" />
  <img src="https://img.shields.io/badge/status-stable-brightgreen" alt="Status" />
  <img src="https://img.shields.io/badge/license-MIT-blue" alt="License" />
</div>

## Overview

Publishes the package to the NPM registry with configurable scope and registry URL.

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

      - name: Publish to NPM
        uses: ivuorinen/actions/npm-publish@vYYYY.MM.DD
        with:
          npm_token: 'your-value-here'
          package-version: '${{ github.event.release.tag_name }}'
          registry-url: 'https://registry.npmjs.org/'
          scope: '@ivuorinen'
          token: 'your-value-here'
```

## Configuration

This action supports various configuration options to customize its behavior according to your needs.

### Input Parameters

| Parameter             | Description                     | Type     | Required | Default Value                          |
|-----------------------|---------------------------------|----------|----------|----------------------------------------|
| **`npm_token`**       | NPM token.                      | `string` | ✅ Yes    | _None_                                 |
| **`package-version`** | The version to publish.         | `string` | ❌ No     | `${{ github.event.release.tag_name }}` |
| **`registry-url`**    | Registry URL for publishing.    | `string` | ❌ No     | `https://registry.npmjs.org/`          |
| **`scope`**           | Package scope to use.           | `string` | ❌ No     | `@ivuorinen`                           |
| **`token`**           | GitHub token for authentication | `string` | ❌ No     | _None_                                 |

#### Parameter Details

##### `npm_token`

NPM token.

- **Type**: String
- **Required**: Yes

```yaml
with:
  npm_token: 'your-value-here'
```

##### `package-version`

The version to publish.

- **Type**: String
- **Required**: No
- **Default**: `${{ github.event.release.tag_name }}`

```yaml
with:
  package-version: '${{ github.event.release.tag_name }}'
```

##### `registry-url`

Registry URL for publishing.

- **Type**: String
- **Required**: No
- **Default**: `https://registry.npmjs.org/`

```yaml
with:
  registry-url: 'https://registry.npmjs.org/'
```

##### `scope`

Package scope to use.

- **Type**: String
- **Required**: No
- **Default**: `@ivuorinen`

```yaml
with:
  scope: '@ivuorinen'
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

| Parameter             | Description                  | Usage                                     |
|-----------------------|------------------------------|-------------------------------------------|
| **`package-version`** | The version to publish.      | `\${{ steps. .outputs.package-version }}` |
| **`registry-url`**    | Registry URL for publishing. | `\${{ steps. .outputs.registry-url }}`    |
| **`scope`**           | Package scope to use.        | `\${{ steps. .outputs.scope }}`           |

#### Using Outputs

```yaml
- name: Publish to NPM
  id: action-step
  uses: ivuorinen/actions/npm-publish@vYYYY.MM.DD

- name: Use Output
  run: |
    echo "package-version: \${{ steps.action-step.outputs.package-version }}"
    echo "registry-url: \${{ steps.action-step.outputs.registry-url }}"
    echo "scope: \${{ steps.action-step.outputs.scope }}"
```

## 🔐 Required Permissions

This action requires specific GitHub permissions to function correctly. Ensure your workflow includes these permissions:

| Permission | Access Level | Description                   |
|------------|--------------|-------------------------------|
| `contents` | `read`       | Required for action operation |
| `packages` | `write`      | Required for action operation |

### How to Set Permissions

```yaml
name: My Workflow
on: [push]

permissions:
  contents: read
  packages: write

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: ivuorinen/actions/npm-publish@vYYYY.MM.DD
```

**Note:** If your workflow doesn't specify permissions, GitHub uses default permissions which may not include all required permissions above.

## Examples

### Basic Usage

```yaml
- name: Basic Publish to NPM
  uses: ivuorinen/actions/npm-publish@vYYYY.MM.DD
  with:
    npm_token: 'example-value'
    package-version: '${{ github.event.release.tag_name }}'
    registry-url: 'https://registry.npmjs.org/'
    scope: '@ivuorinen'
    token: 'example-value'
```

### Advanced Configuration

```yaml
- name: Advanced Publish to NPM
  uses: ivuorinen/actions/npm-publish@vYYYY.MM.DD
  with:
    npm_token: "\${{ vars.NPM_TOKEN }}"
    package-version: "${{ github.event.release.tag_name }}"
    registry-url: "https://registry.npmjs.org/"
    scope: "@ivuorinen"
    token: "\${{ vars.TOKEN }}"
  env:
    GITHUB_TOKEN: \${{ secrets.GITHUB_TOKEN }}
```

### Conditional Usage

```yaml
- name: Conditional Publish to NPM
  if: github.event_name == 'push'
  uses: ivuorinen/actions/npm-publish@vYYYY.MM.DD
  with:
    npm_token: 'production-value'
    package-version: '${{ github.event.release.tag_name }}'
    registry-url: 'https://registry.npmjs.org/'
    scope: '@ivuorinen'
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
