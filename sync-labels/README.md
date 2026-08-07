# Sync labels

<div align="center">
  <img src="https://img.shields.io/badge/icon-tag-blue" alt="tag" />
  <img src="https://img.shields.io/badge/status-stable-brightgreen" alt="Status" />
  <img src="https://img.shields.io/badge/license-MIT-blue" alt="License" />
</div>

## Overview

Sync GitHub labels declaratively from a YAML/JSON manifest (no Docker)

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

      - name: Sync labels
        uses: ivuorinen/actions/sync-labels@vYYYY.MM.DD
        with:
          labels: 'your-value-here'
          prune: 'true'
          repository: 'your-value-here'
          token: '${{ github.token }}'
```

## Configuration

This action supports various configuration options to customize its behavior according to your needs.

### Input Parameters

| Parameter        | Description                                                                                                                                                                                                                             | Type     | Required | Default Value         |
|------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------|----------|-----------------------|
| **`labels`**     | Path to the labels manifest (YAML or JSON), relative to the repository root. Defaults to .github/labels.yml when omitted (no longer the action's bundled labels.yml). A missing manifest is a warning + successful no-op, not an error. | `string` | ❌ No     | _None_                |
| **`prune`**      | Delete existing labels that are not listed in the manifest                                                                                                                                                                              | `string` | ❌ No     | `true`                |
| **`repository`** | Newline-separated list of owner/repo targets. Defaults to the current repository. Cross-repo sync requires a PAT in the token input.                                                                                                    | `string` | ❌ No     | _None_                |
| **`token`**      | GitHub token for authentication (use a PAT for cross-repo sync)                                                                                                                                                                         | `string` | ❌ No     | `${{ github.token }}` |

#### Parameter Details

##### `labels`

Path to the labels manifest (YAML or JSON), relative to the repository root. Defaults to .github/labels.yml when omitted (no longer the action's bundled labels.yml). A missing manifest is a warning +
successful no-op, not an error.

- **Type**: String
- **Required**: No

```yaml
with:
  labels: 'your-value-here'
```

##### `prune`

Delete existing labels that are not listed in the manifest

- **Type**: String
- **Required**: No
- **Default**: `true`

```yaml
with:
  prune: 'true'
```

##### `repository`

Newline-separated list of owner/repo targets. Defaults to the current repository. Cross-repo sync requires a PAT in the token input.

- **Type**: String
- **Required**: No

```yaml
with:
  repository: 'your-value-here'
```

##### `token`

GitHub token for authentication (use a PAT for cross-repo sync)

- **Type**: String
- **Required**: No
- **Default**: `${{ github.token }}`

```yaml
with:
  token: '${{ github.token }}'
```

### Output Parameters

This action provides the following outputs that can be used in subsequent workflow steps:

| Parameter          | Description                       | Usage                                  |
|--------------------|-----------------------------------|----------------------------------------|
| **`created`**      | Number of labels created          | `\${{ steps. .outputs.created }}`      |
| **`deleted`**      | Number of labels deleted (pruned) | `\${{ steps. .outputs.deleted }}`      |
| **`repositories`** | Number of repositories synced     | `\${{ steps. .outputs.repositories }}` |
| **`unchanged`**    | Number of labels left unchanged   | `\${{ steps. .outputs.unchanged }}`    |
| **`updated`**      | Number of labels updated          | `\${{ steps. .outputs.updated }}`      |

#### Using Outputs

```yaml
- name: Sync labels
  id: action-step
  uses: ivuorinen/actions/sync-labels@vYYYY.MM.DD

- name: Use Output
  run: |
    echo "created: \${{ steps.action-step.outputs.created }}"
    echo "deleted: \${{ steps.action-step.outputs.deleted }}"
    echo "repositories: \${{ steps.action-step.outputs.repositories }}"
    echo "unchanged: \${{ steps.action-step.outputs.unchanged }}"
    echo "updated: \${{ steps.action-step.outputs.updated }}"
```

## 🔐 Required Permissions

This action requires specific GitHub permissions to function correctly. Ensure your workflow includes these permissions:

| Permission | Access Level | Description                   |
|------------|--------------|-------------------------------|
| `issues`   | `write`      | Required for action operation |

### How to Set Permissions

```yaml
name: My Workflow
on: [push]

permissions:
  issues: write

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: ivuorinen/actions/sync-labels@vYYYY.MM.DD
```

**Note:** If your workflow doesn't specify permissions, GitHub uses default permissions which may not include all required permissions above.

## Examples

### Basic Usage

```yaml
- name: Basic Sync labels
  uses: ivuorinen/actions/sync-labels@vYYYY.MM.DD
  with:
    labels: 'example-value'
    prune: 'true'
    repository: 'example-value'
    token: '${{ github.token }}'
```

### Advanced Configuration

```yaml
- name: Advanced Sync labels
  uses: ivuorinen/actions/sync-labels@vYYYY.MM.DD
  with:
    labels: "\${{ vars.LABELS }}"
    prune: "true"
    repository: "\${{ vars.REPOSITORY }}"
    token: "${{ github.token }}"
  env:
    GITHUB_TOKEN: \${{ secrets.GITHUB_TOKEN }}
```

### Conditional Usage

```yaml
- name: Conditional Sync labels
  if: github.event_name == 'push'
  uses: ivuorinen/actions/sync-labels@vYYYY.MM.DD
  with:
    labels: 'production-value'
    prune: 'true'
    repository: 'production-value'
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
