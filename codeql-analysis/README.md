# CodeQL Analysis

<div align="center">
  <img src="https://img.shields.io/badge/icon-shield-blue" alt="shield" />
  <img src="https://img.shields.io/badge/status-stable-brightgreen" alt="Status" />
  <img src="https://img.shields.io/badge/license-MIT-blue" alt="License" />
</div>

## Overview

Run CodeQL security analysis for a single language with configurable query suites

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

      - name: CodeQL Analysis
        uses: ivuorinen/actions/codeql-analysis@vYYYY.MM.DD
        with:
          build-mode: 'your-value-here'
          category: 'your-value-here'
          checkout-ref: 'your-value-here'
          config: 'your-value-here'
          config-file: 'your-value-here'
          language: 'your-value-here'
          output: '../results'
          packs: 'your-value-here'
          queries: 'your-value-here'
          ram: 'your-value-here'
          skip-queries: 'false'
          source-root: 'your-value-here'
          threads: 'your-value-here'
          token: '${{ github.token }}'
          upload-results: 'true'
          working-directory: '.'
```

## Configuration

This action supports various configuration options to customize its behavior according to your needs.

### Input Parameters

| Parameter               | Description                                                                          | Type     | Required | Default Value         |
|-------------------------|--------------------------------------------------------------------------------------|----------|----------|-----------------------|
| **`build-mode`**        | The build mode for compiled languages (none, manual, autobuild)                      | `string` | ❌ No     | _None_                |
| **`category`**          | Analysis category (default: /language:<language>)                                    | `string` | ❌ No     | _None_                |
| **`checkout-ref`**      | Git reference to checkout (default: current ref)                                     | `string` | ❌ No     | _None_                |
| **`config`**            | Configuration passed as a YAML string                                                | `string` | ❌ No     | _None_                |
| **`config-file`**       | Path to CodeQL configuration file                                                    | `string` | ❌ No     | _None_                |
| **`language`**          | Language to analyze (javascript, python, actions, java, csharp, cpp, ruby, go, etc.) | `string` | ✅ Yes    | _None_                |
| **`output`**            | Path to save SARIF results                                                           | `string` | ❌ No     | `../results`          |
| **`packs`**             | Comma-separated list of CodeQL query packs to run                                    | `string` | ❌ No     | _None_                |
| **`queries`**           | Comma-separated list of additional queries to run                                    | `string` | ❌ No     | _None_                |
| **`ram`**               | Amount of memory in MB that can be used by CodeQL                                    | `string` | ❌ No     | _None_                |
| **`skip-queries`**      | Build database but skip running queries                                              | `string` | ❌ No     | `false`               |
| **`source-root`**       | Path of the root source code directory                                               | `string` | ❌ No     | _None_                |
| **`threads`**           | Number of threads that can be used by CodeQL                                         | `string` | ❌ No     | _None_                |
| **`token`**             | GitHub token for API access                                                          | `string` | ❌ No     | `${{ github.token }}` |
| **`upload-results`**    | Upload results to GitHub Security tab                                                | `string` | ❌ No     | `true`                |
| **`working-directory`** | Working directory for the analysis                                                   | `string` | ❌ No     | `.`                   |

#### Parameter Details

##### `build-mode`

The build mode for compiled languages (none, manual, autobuild)

- **Type**: String
- **Required**: No

```yaml
with:
  build-mode: 'your-value-here'
```

##### `category`

Analysis category (default: /language:<language>)

- **Type**: String
- **Required**: No

```yaml
with:
  category: 'your-value-here'
```

##### `checkout-ref`

Git reference to checkout (default: current ref)

- **Type**: String
- **Required**: No

```yaml
with:
  checkout-ref: 'your-value-here'
```

##### `config`

Configuration passed as a YAML string

- **Type**: String
- **Required**: No

```yaml
with:
  config: 'your-value-here'
```

##### `config-file`

Path to CodeQL configuration file

- **Type**: String
- **Required**: No

```yaml
with:
  config-file: 'your-value-here'
```

##### `language`

Language to analyze (javascript, python, actions, java, csharp, cpp, ruby, go, etc.)

- **Type**: String
- **Required**: Yes

```yaml
with:
  language: 'your-value-here'
```

##### `output`

Path to save SARIF results

- **Type**: String
- **Required**: No
- **Default**: `../results`

```yaml
with:
  output: '../results'
```

##### `packs`

Comma-separated list of CodeQL query packs to run

- **Type**: String
- **Required**: No

```yaml
with:
  packs: 'your-value-here'
```

##### `queries`

Comma-separated list of additional queries to run

- **Type**: String
- **Required**: No

```yaml
with:
  queries: 'your-value-here'
```

##### `ram`

Amount of memory in MB that can be used by CodeQL

- **Type**: String
- **Required**: No

```yaml
with:
  ram: 'your-value-here'
```

##### `skip-queries`

Build database but skip running queries

- **Type**: String
- **Required**: No
- **Default**: `false`

```yaml
with:
  skip-queries: 'false'
```

##### `source-root`

Path of the root source code directory

- **Type**: String
- **Required**: No

```yaml
with:
  source-root: 'your-value-here'
```

##### `threads`

Number of threads that can be used by CodeQL

- **Type**: String
- **Required**: No

```yaml
with:
  threads: 'your-value-here'
```

##### `token`

GitHub token for API access

- **Type**: String
- **Required**: No
- **Default**: `${{ github.token }}`

```yaml
with:
  token: '${{ github.token }}'
```

##### `upload-results`

Upload results to GitHub Security tab

- **Type**: String
- **Required**: No
- **Default**: `true`

```yaml
with:
  upload-results: 'true'
```

##### `working-directory`

Working directory for the analysis

- **Type**: String
- **Required**: No
- **Default**: `.`

```yaml
with:
  working-directory: '.'
```

### Output Parameters

This action provides the following outputs that can be used in subsequent workflow steps:

| Parameter               | Description                    | Usage                                       |
|-------------------------|--------------------------------|---------------------------------------------|
| **`analysis-category`** | Category used for the analysis | `\${{ steps. .outputs.analysis-category }}` |
| **`language-analyzed`** | Language that was analyzed     | `\${{ steps. .outputs.language-analyzed }}` |
| **`sarif-file`**        | Path to generated SARIF file   | `\${{ steps. .outputs.sarif-file }}`        |

#### Using Outputs

```yaml
- name: CodeQL Analysis
  id: action-step
  uses: ivuorinen/actions/codeql-analysis@vYYYY.MM.DD

- name: Use Output
  run: |
    echo "analysis-category: \${{ steps.action-step.outputs.analysis-category }}"
    echo "language-analyzed: \${{ steps.action-step.outputs.language-analyzed }}"
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
      - uses: ivuorinen/actions/codeql-analysis@vYYYY.MM.DD
```

**Note:** If your workflow doesn't specify permissions, GitHub uses default permissions which may not include all required permissions above.

## Examples

### Basic Usage

```yaml
- name: Basic CodeQL Analysis
  uses: ivuorinen/actions/codeql-analysis@vYYYY.MM.DD
  with:
    build-mode: 'example-value'
    category: 'example-value'
    checkout-ref: 'example-value'
    config: 'example-value'
    config-file: 'example-value'
    language: 'example-value'
    output: '../results'
    packs: 'example-value'
    queries: 'example-value'
    ram: 'example-value'
    skip-queries: 'false'
    source-root: 'example-value'
    threads: 'example-value'
    token: '${{ github.token }}'
    upload-results: 'true'
    working-directory: '.'
```

### Advanced Configuration

```yaml
- name: Advanced CodeQL Analysis
  uses: ivuorinen/actions/codeql-analysis@vYYYY.MM.DD
  with:
    build-mode: "\${{ vars.BUILD-MODE }}"
    category: "\${{ vars.CATEGORY }}"
    checkout-ref: "\${{ vars.CHECKOUT-REF }}"
    config: "\${{ vars.CONFIG }}"
    config-file: "\${{ vars.CONFIG-FILE }}"
    language: "\${{ vars.LANGUAGE }}"
    output: "../results"
    packs: "\${{ vars.PACKS }}"
    queries: "\${{ vars.QUERIES }}"
    ram: "\${{ vars.RAM }}"
    skip-queries: "false"
    source-root: "\${{ vars.SOURCE-ROOT }}"
    threads: "\${{ vars.THREADS }}"
    token: "${{ github.token }}"
    upload-results: "true"
    working-directory: "."
  env:
    GITHUB_TOKEN: \${{ secrets.GITHUB_TOKEN }}
```

### Conditional Usage

```yaml
- name: Conditional CodeQL Analysis
  if: github.event_name == 'push'
  uses: ivuorinen/actions/codeql-analysis@vYYYY.MM.DD
  with:
    build-mode: 'production-value'
    category: 'production-value'
    checkout-ref: 'production-value'
    config: 'production-value'
    config-file: 'production-value'
    language: 'production-value'
    output: '../results'
    packs: 'production-value'
    queries: 'production-value'
    ram: 'production-value'
    skip-queries: 'false'
    source-root: 'production-value'
    threads: 'production-value'
    token: '${{ github.token }}'
    upload-results: 'true'
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
