# NPM Semantic Release

<div align="center">
  <img src="https://img.shields.io/badge/icon-package-blue" alt="package" />
  <img src="https://img.shields.io/badge/status-stable-brightgreen" alt="Status" />
  <img src="https://img.shields.io/badge/license-MIT-blue" alt="License" />
</div>

## Overview

Runs semantic-release for automated npm versioning and publishing with OIDC provenance support.

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

      - name: NPM Semantic Release
        uses: ivuorinen/actions/npm-semantic-release@vYYYY.MM.DD
        with:
          extra_plugins: 'conventional-changelog-conventionalcommits@^9.3.1'
          github_token: '${{ github.token }}'
          node-version: '24'
          npm_token: 'your-value-here'
          registry-url: 'https://registry.npmjs.org/'
          scope: '@ivuorinen'
```

## Configuration

This action supports various configuration options to customize its behavior according to your needs.

### Input Parameters

| Parameter           | Description                                                | Type     | Required | Default Value                                       |
|---------------------|------------------------------------------------------------|----------|----------|-----------------------------------------------------|
| **`extra_plugins`** | Extra semantic-release plugins (pipe-separated).           | `string` | ❌ No     | `conventional-changelog-conventionalcommits@^9.3.1` |
| **`github_token`**  | GitHub token for creating releases, tags, and PR comments. | `string` | ❌ No     | `${{ github.token }}`                               |
| **`node-version`**  | Node.js version to use when .nvmrc is not present.         | `string` | ❌ No     | `24`                                                |
| **`npm_token`**     | NPM token for publishing.                                  | `string` | ✅ Yes    | _None_                                              |
| **`registry-url`**  | Registry URL for publishing.                               | `string` | ❌ No     | `https://registry.npmjs.org/`                       |
| **`scope`**         | Package scope to use.                                      | `string` | ❌ No     | `@ivuorinen`                                        |

#### Parameter Details

##### `extra_plugins`

Extra semantic-release plugins (pipe-separated).

- **Type**: String
- **Required**: No
- **Default**: `conventional-changelog-conventionalcommits@^9.3.1`

```yaml
with:
  extra_plugins: 'conventional-changelog-conventionalcommits@^9.3.1'
```

##### `github_token`

GitHub token for creating releases, tags, and PR comments.

- **Type**: String
- **Required**: No
- **Default**: `${{ github.token }}`

```yaml
with:
  github_token: '${{ github.token }}'
```

##### `node-version`

Node.js version to use when .nvmrc is not present.

- **Type**: String
- **Required**: No
- **Default**: `24`

```yaml
with:
  node-version: '24'
```

##### `npm_token`

NPM token for publishing.

- **Type**: String
- **Required**: Yes

```yaml
with:
  npm_token: 'your-value-here'
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

### Output Parameters

This action provides the following outputs that can be used in subsequent workflow steps:

| Parameter                   | Description                            | Usage                                           |
|-----------------------------|----------------------------------------|-------------------------------------------------|
| **`new-release-published`** | Whether a new release was published.   | `\${{ steps. .outputs.new-release-published }}` |
| **`new-release-version`**   | The new release version, if published. | `\${{ steps. .outputs.new-release-version }}`   |

#### Using Outputs

```yaml
- name: NPM Semantic Release
  id: action-step
  uses: ivuorinen/actions/npm-semantic-release@vYYYY.MM.DD

- name: Use Output
  run: |
    echo "new-release-published: \${{ steps.action-step.outputs.new-release-published }}"
    echo "new-release-version: \${{ steps.action-step.outputs.new-release-version }}"
```

## 🔐 Required Permissions

This action requires specific GitHub permissions to function correctly. Ensure your workflow includes these permissions:

| Permission      | Access Level | Description                   |
|-----------------|--------------|-------------------------------|
| `contents`      | `write`      | Required for action operation |
| `id-token`      | `write`      | Required for action operation |
| `issues`        | `write`      | Required for action operation |
| `pull-requests` | `write`      | Required for action operation |

### How to Set Permissions

```yaml
name: My Workflow
on: [push]

permissions:
  contents: write
  id-token: write
  issues: write
  pull-requests: write

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: ivuorinen/actions/npm-semantic-release@vYYYY.MM.DD
```

**Note:** If your workflow doesn't specify permissions, GitHub uses default permissions which may not include all required permissions above.

## Examples

### Basic Usage

```yaml
- name: Basic NPM Semantic Release
  uses: ivuorinen/actions/npm-semantic-release@vYYYY.MM.DD
  with:
    extra_plugins: 'conventional-changelog-conventionalcommits@^9.3.1'
    github_token: '${{ github.token }}'
    node-version: '24'
    npm_token: 'example-value'
    registry-url: 'https://registry.npmjs.org/'
    scope: '@ivuorinen'
```

### Advanced Configuration

```yaml
- name: Advanced NPM Semantic Release
  uses: ivuorinen/actions/npm-semantic-release@vYYYY.MM.DD
  with:
    extra_plugins: "conventional-changelog-conventionalcommits@^9.3.1"
    github_token: "${{ github.token }}"
    node-version: "24"
    npm_token: "\${{ vars.NPM_TOKEN }}"
    registry-url: "https://registry.npmjs.org/"
    scope: "@ivuorinen"
  env:
    GITHUB_TOKEN: \${{ secrets.GITHUB_TOKEN }}
```

### Conditional Usage

```yaml
- name: Conditional NPM Semantic Release
  if: github.event_name == 'push'
  uses: ivuorinen/actions/npm-semantic-release@vYYYY.MM.DD
  with:
    extra_plugins: 'conventional-changelog-conventionalcommits@^9.3.1'
    github_token: '${{ github.token }}'
    node-version: '24'
    npm_token: 'production-value'
    registry-url: 'https://registry.npmjs.org/'
    scope: '@ivuorinen'
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
