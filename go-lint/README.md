# Go Lint Check

<div align="center">
  <img src="https://img.shields.io/badge/icon-code-blue" alt="code" />
  <img src="https://img.shields.io/badge/status-stable-brightgreen" alt="Status" />
  <img src="https://img.shields.io/badge/license-MIT-blue" alt="License" />
</div>

## Overview

Run golangci-lint with advanced configuration, caching, and reporting

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

      - name: Go Lint Check
        uses: ivuorinen/actions/go-lint@vYYYY.MM.DD
        with:
          cache: 'true'
          config-file: '.golangci.yml'
          disable-all: 'false'
          disable-linters: 'your-value-here'
          enable-linters: 'your-value-here'
          fail-on-error: 'true'
          go-version: 'stable'
          golangci-lint-version: 'latest'
          max-retries: '3'
          only-new-issues: 'true'
          report-format: 'sarif'
          timeout: '5m'
          token: 'your-value-here'
          working-directory: '.'
```

## Configuration

This action supports various configuration options to customize its behavior according to your needs.

### Input Parameters

| Parameter                   | Description                                  | Type     | Required | Default Value   |
|-----------------------------|----------------------------------------------|----------|----------|-----------------|
| **`cache`**                 | Enable golangci-lint caching                 | `string` | ❌ No     | `true`          |
| **`config-file`**           | Path to golangci-lint config file            | `string` | ❌ No     | `.golangci.yml` |
| **`disable-all`**           | Disable all linters (useful with --enable-*) | `string` | ❌ No     | `false`         |
| **`disable-linters`**       | Comma-separated list of linters to disable   | `string` | ❌ No     | _None_          |
| **`enable-linters`**        | Comma-separated list of linters to enable    | `string` | ❌ No     | _None_          |
| **`fail-on-error`**         | Fail workflow if issues are found            | `string` | ❌ No     | `true`          |
| **`go-version`**            | Go version to use                            | `string` | ❌ No     | `stable`        |
| **`golangci-lint-version`** | Version of golangci-lint to use              | `string` | ❌ No     | `latest`        |
| **`max-retries`**           | Maximum number of retry attempts             | `string` | ❌ No     | `3`             |
| **`only-new-issues`**       | Report only new issues since main branch     | `string` | ❌ No     | `true`          |
| **`report-format`**         | Output format (json, sarif, github-actions)  | `string` | ❌ No     | `sarif`         |
| **`timeout`**               | Timeout for analysis (e.g., 5m, 1h)          | `string` | ❌ No     | `5m`            |
| **`token`**                 | GitHub token for authentication              | `string` | ❌ No     | _None_          |
| **`working-directory`**     | Directory containing Go files                | `string` | ❌ No     | `.`             |

#### Parameter Details

##### `cache`

Enable golangci-lint caching

- **Type**: String
- **Required**: No
- **Default**: `true`

```yaml
with:
  cache: 'true'
```

##### `config-file`

Path to golangci-lint config file

- **Type**: String
- **Required**: No
- **Default**: `.golangci.yml`

```yaml
with:
  config-file: '.golangci.yml'
```

##### `disable-all`

Disable all linters (useful with --enable-*)

- **Type**: String
- **Required**: No
- **Default**: `false`

```yaml
with:
  disable-all: 'false'
```

##### `disable-linters`

Comma-separated list of linters to disable

- **Type**: String
- **Required**: No

```yaml
with:
  disable-linters: 'your-value-here'
```

##### `enable-linters`

Comma-separated list of linters to enable

- **Type**: String
- **Required**: No

```yaml
with:
  enable-linters: 'your-value-here'
```

##### `fail-on-error`

Fail workflow if issues are found

- **Type**: String
- **Required**: No
- **Default**: `true`

```yaml
with:
  fail-on-error: 'true'
```

##### `go-version`

Go version to use

- **Type**: String
- **Required**: No
- **Default**: `stable`

```yaml
with:
  go-version: 'stable'
```

##### `golangci-lint-version`

Version of golangci-lint to use

- **Type**: String
- **Required**: No
- **Default**: `latest`

```yaml
with:
  golangci-lint-version: 'latest'
```

##### `max-retries`

Maximum number of retry attempts

- **Type**: String
- **Required**: No
- **Default**: `3`

```yaml
with:
  max-retries: '3'
```

##### `only-new-issues`

Report only new issues since main branch

- **Type**: String
- **Required**: No
- **Default**: `true`

```yaml
with:
  only-new-issues: 'true'
```

##### `report-format`

Output format (json, sarif, github-actions)

- **Type**: String
- **Required**: No
- **Default**: `sarif`

```yaml
with:
  report-format: 'sarif'
```

##### `timeout`

Timeout for analysis (e.g., 5m, 1h)

- **Type**: String
- **Required**: No
- **Default**: `5m`

```yaml
with:
  timeout: '5m'
```

##### `token`

GitHub token for authentication

- **Type**: String
- **Required**: No

```yaml
with:
  token: 'your-value-here'
```

##### `working-directory`

Directory containing Go files

- **Type**: String
- **Required**: No
- **Default**: `.`

```yaml
with:
  working-directory: '.'
```

### Output Parameters

This action provides the following outputs that can be used in subsequent workflow steps:

| Parameter            | Description                        | Usage                                    |
|----------------------|------------------------------------|------------------------------------------|
| **`analyzed-files`** | Number of files analyzed           | `\${{ steps. .outputs.analyzed-files }}` |
| **`cache-hit`**      | Indicates if there was a cache hit | `\${{ steps. .outputs.cache-hit }}`      |
| **`error-count`**    | Number of errors found             | `\${{ steps. .outputs.error-count }}`    |
| **`sarif-file`**     | Path to SARIF report file          | `\${{ steps. .outputs.sarif-file }}`     |

#### Using Outputs

```yaml
- name: Go Lint Check
  id: action-step
  uses: ivuorinen/actions/go-lint@vYYYY.MM.DD

- name: Use Output
  run: |
    echo "analyzed-files: \${{ steps.action-step.outputs.analyzed-files }}"
    echo "cache-hit: \${{ steps.action-step.outputs.cache-hit }}"
    echo "error-count: \${{ steps.action-step.outputs.error-count }}"
    echo "sarif-file: \${{ steps.action-step.outputs.sarif-file }}"
```

## 🔐 Required Permissions

This action requires specific GitHub permissions to function correctly. Ensure your workflow includes these permissions:

| Permission        | Access Level | Description                   |
|-------------------|--------------|-------------------------------|
| `contents`        | `read`       | Required for action operation |
| `security-events` | `write`      | Required for action operation |

### How to Set Permissions

```yaml
name: My Workflow
on: [push]

permissions:
  contents: read
  security-events: write

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: ivuorinen/actions/go-lint@vYYYY.MM.DD
```

**Note:** If your workflow doesn't specify permissions, GitHub uses default permissions which may not include all required permissions above.

## Examples

### Basic Usage

```yaml
- name: Basic Go Lint Check
  uses: ivuorinen/actions/go-lint@vYYYY.MM.DD
  with:
    cache: 'true'
    config-file: '.golangci.yml'
    disable-all: 'false'
    disable-linters: 'example-value'
    enable-linters: 'example-value'
    fail-on-error: 'true'
    go-version: 'stable'
    golangci-lint-version: 'latest'
    max-retries: '3'
    only-new-issues: 'true'
    report-format: 'sarif'
    timeout: '5m'
    token: 'example-value'
    working-directory: '.'
```

### Advanced Configuration

```yaml
- name: Advanced Go Lint Check
  uses: ivuorinen/actions/go-lint@vYYYY.MM.DD
  with:
    cache: "true"
    config-file: ".golangci.yml"
    disable-all: "false"
    disable-linters: "\${{ vars.DISABLE-LINTERS }}"
    enable-linters: "\${{ vars.ENABLE-LINTERS }}"
    fail-on-error: "true"
    go-version: "stable"
    golangci-lint-version: "latest"
    max-retries: "3"
    only-new-issues: "true"
    report-format: "sarif"
    timeout: "5m"
    token: "\${{ vars.TOKEN }}"
    working-directory: "."
  env:
    GITHUB_TOKEN: \${{ secrets.GITHUB_TOKEN }}
```

### Conditional Usage

```yaml
- name: Conditional Go Lint Check
  if: github.event_name == 'push'
  uses: ivuorinen/actions/go-lint@vYYYY.MM.DD
  with:
    cache: 'true'
    config-file: '.golangci.yml'
    disable-all: 'false'
    disable-linters: 'production-value'
    enable-linters: 'production-value'
    fail-on-error: 'true'
    go-version: 'stable'
    golangci-lint-version: 'latest'
    max-retries: '3'
    only-new-issues: 'true'
    report-format: 'sarif'
    timeout: '5m'
    token: 'production-value'
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
