# pre-commit

<div align="center">
  <img src="https://img.shields.io/badge/icon-check-square-green" alt="check-square" />
  <img src="https://img.shields.io/badge/status-stable-brightgreen" alt="Status" />
  <img src="https://img.shields.io/badge/license-MIT-blue" alt="License" />
</div>

## Overview

Runs pre-commit on the repository and pushes the fixes back to the repository

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

      - name: pre-commit
        uses: ivuorinen/actions/pre-commit@vYYYY.MM.DD
        with:
          base-branch: 'your-value-here'
          commit_email: 'github-actions@github.com'
          commit_user: 'GitHub Actions'
          pre-commit-config: '.pre-commit-config.yaml'
          token: 'your-value-here'
```

## Configuration

This action supports various configuration options to customize its behavior according to your needs.

### Input Parameters

| Parameter               | Description                     | Type     | Required | Default Value               |
|-------------------------|---------------------------------|----------|----------|-----------------------------|
| **`base-branch`**       | Base branch to compare against  | `string` | ❌ No     | _None_                      |
| **`commit_email`**      | Commit email                    | `string` | ❌ No     | `github-actions@github.com` |
| **`commit_user`**       | Commit user                     | `string` | ❌ No     | `GitHub Actions`            |
| **`pre-commit-config`** | pre-commit configuration file   | `string` | ❌ No     | `.pre-commit-config.yaml`   |
| **`token`**             | GitHub token for authentication | `string` | ❌ No     | _None_                      |

#### Parameter Details

##### `base-branch`

Base branch to compare against

- **Type**: String
- **Required**: No

```yaml
with:
  base-branch: 'your-value-here'
```

##### `commit_email`

Commit email

- **Type**: String
- **Required**: No
- **Default**: `github-actions@github.com`

```yaml
with:
  commit_email: 'github-actions@github.com'
```

##### `commit_user`

Commit user

- **Type**: String
- **Required**: No
- **Default**: `GitHub Actions`

```yaml
with:
  commit_user: 'GitHub Actions'
```

##### `pre-commit-config`

pre-commit configuration file

- **Type**: String
- **Required**: No
- **Default**: `.pre-commit-config.yaml`

```yaml
with:
  pre-commit-config: '.pre-commit-config.yaml'
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

| Parameter           | Description                                        | Usage                                   |
|---------------------|----------------------------------------------------|-----------------------------------------|
| **`files_changed`** | Whether any files were changed by pre-commit hooks | `\${{ steps. .outputs.files_changed }}` |
| **`hooks_passed`**  | Whether all pre-commit hooks passed (true/false)   | `\${{ steps. .outputs.hooks_passed }}`  |

#### Using Outputs

```yaml
- name: pre-commit
  id: action-step
  uses: ivuorinen/actions/pre-commit@vYYYY.MM.DD

- name: Use Output
  run: |
    echo "files_changed: \${{ steps.action-step.outputs.files_changed }}"
    echo "hooks_passed: \${{ steps.action-step.outputs.hooks_passed }}"
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
      - uses: ivuorinen/actions/pre-commit@vYYYY.MM.DD
```

**Note:** If your workflow doesn't specify permissions, GitHub uses default permissions which may not include all required permissions above.

## Examples

### Basic Usage

```yaml
- name: Basic pre-commit
  uses: ivuorinen/actions/pre-commit@vYYYY.MM.DD
  with:
    base-branch: 'example-value'
    commit_email: 'github-actions@github.com'
    commit_user: 'GitHub Actions'
    pre-commit-config: '.pre-commit-config.yaml'
    token: 'example-value'
```

### Advanced Configuration

```yaml
- name: Advanced pre-commit
  uses: ivuorinen/actions/pre-commit@vYYYY.MM.DD
  with:
    base-branch: "\${{ vars.BASE-BRANCH }}"
    commit_email: "github-actions@github.com"
    commit_user: "GitHub Actions"
    pre-commit-config: ".pre-commit-config.yaml"
    token: "\${{ vars.TOKEN }}"
  env:
    GITHUB_TOKEN: \${{ secrets.GITHUB_TOKEN }}
```

### Conditional Usage

```yaml
- name: Conditional pre-commit
  if: github.event_name == 'push'
  uses: ivuorinen/actions/pre-commit@vYYYY.MM.DD
  with:
    base-branch: 'production-value'
    commit_email: 'github-actions@github.com'
    commit_user: 'GitHub Actions'
    pre-commit-config: '.pre-commit-config.yaml'
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
