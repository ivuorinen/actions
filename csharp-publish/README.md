# C# Publish

<div align="center">
  <img src="https://img.shields.io/badge/icon-package-blue" alt="package" />
  <img src="https://img.shields.io/badge/status-stable-brightgreen" alt="Status" />
  <img src="https://img.shields.io/badge/license-MIT-blue" alt="License" />
</div>

## Overview

Publishes a C# project to GitHub Packages.

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

      - name: C# Publish
        uses: ivuorinen/actions/csharp-publish@vYYYY.MM.DD
        with:
          dotnet-version: 'your-value-here'
          max-retries: '3'
          namespace: 'ivuorinen'
          token: 'your-value-here'
```

## Configuration

This action supports various configuration options to customize its behavior according to your needs.

### Input Parameters

| Parameter            | Description                                                 | Type     | Required | Default Value |
|----------------------|-------------------------------------------------------------|----------|----------|---------------|
| **`dotnet-version`** | Version of .NET SDK to use.                                 | `string` | ❌ No     | _None_        |
| **`max-retries`**    | Maximum number of retry attempts for dependency restoration | `string` | ❌ No     | `3`           |
| **`namespace`**      | GitHub namespace for the package.                           | `string` | ✅ Yes    | `ivuorinen`   |
| **`token`**          | GitHub token with package write permissions                 | `string` | ❌ No     | _None_        |

#### Parameter Details

##### `dotnet-version`

Version of .NET SDK to use.

- **Type**: String
- **Required**: No

```yaml
with:
  dotnet-version: 'your-value-here'
```

##### `max-retries`

Maximum number of retry attempts for dependency restoration

- **Type**: String
- **Required**: No
- **Default**: `3`

```yaml
with:
  max-retries: '3'
```

##### `namespace`

GitHub namespace for the package.

- **Type**: String
- **Required**: Yes
- **Default**: `ivuorinen`

```yaml
with:
  namespace: 'ivuorinen'
```

##### `token`

GitHub token with package write permissions

- **Type**: String
- **Required**: No

```yaml
with:
  token: 'your-value-here'
```

### Output Parameters

This action provides the following outputs that can be used in subsequent workflow steps:

| Parameter             | Description                              | Usage                                     |
|-----------------------|------------------------------------------|-------------------------------------------|
| **`package_url`**     | URL of the published package             | `\${{ steps. .outputs.package_url }}`     |
| **`package_version`** | Version of the published package         | `\${{ steps. .outputs.package_version }}` |
| **`publish_status`**  | Overall publish status (success/failure) | `\${{ steps. .outputs.publish_status }}`  |

#### Using Outputs

```yaml
- name: C# Publish
  id: action-step
  uses: ivuorinen/actions/csharp-publish@vYYYY.MM.DD

- name: Use Output
  run: |
    echo "package_url: \${{ steps.action-step.outputs.package_url }}"
    echo "package_version: \${{ steps.action-step.outputs.package_version }}"
    echo "publish_status: \${{ steps.action-step.outputs.publish_status }}"
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
      - uses: ivuorinen/actions/csharp-publish@vYYYY.MM.DD
```

**Note:** If your workflow doesn't specify permissions, GitHub uses default permissions which may not include all required permissions above.

## Examples

### Basic Usage

```yaml
- name: Basic C# Publish
  uses: ivuorinen/actions/csharp-publish@vYYYY.MM.DD
  with:
    dotnet-version: 'example-value'
    max-retries: '3'
    namespace: 'ivuorinen'
    token: 'example-value'
```

### Advanced Configuration

```yaml
- name: Advanced C# Publish
  uses: ivuorinen/actions/csharp-publish@vYYYY.MM.DD
  with:
    dotnet-version: "\${{ vars.DOTNET-VERSION }}"
    max-retries: "3"
    namespace: "ivuorinen"
    token: "\${{ vars.TOKEN }}"
  env:
    GITHUB_TOKEN: \${{ secrets.GITHUB_TOKEN }}
```

### Conditional Usage

```yaml
- name: Conditional C# Publish
  if: github.event_name == 'push'
  uses: ivuorinen/actions/csharp-publish@vYYYY.MM.DD
  with:
    dotnet-version: 'production-value'
    max-retries: '3'
    namespace: 'ivuorinen'
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
