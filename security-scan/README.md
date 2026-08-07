# Security Scan

<div align="center">
  <img src="https://img.shields.io/badge/icon-shield-red" alt="shield" />
  <img src="https://img.shields.io/badge/status-stable-brightgreen" alt="Status" />
  <img src="https://img.shields.io/badge/license-MIT-blue" alt="License" />
</div>

## Overview

Comprehensive security scanning for GitHub Actions including actionlint, Gitleaks (optional), and Trivy vulnerability scanning. Requires 'security-events: write' and 'contents: read' permissions in
the workflow.

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

      - name: Security Scan
        uses: ivuorinen/actions/security-scan@vYYYY.MM.DD
        with:
          actionlint-enabled: 'true'
          gitleaks-config: '.gitleaks.toml'
          gitleaks-license: 'your-value-here'
          token: 'your-value-here'
          trivy-scanners: 'vuln,config,secret'
          trivy-severity: 'CRITICAL,HIGH'
          trivy-timeout: '10m'
```

## Configuration

This action supports various configuration options to customize its behavior according to your needs.

### Input Parameters

| Parameter                | Description                                           | Type     | Required | Default Value        |
|--------------------------|-------------------------------------------------------|----------|----------|----------------------|
| **`actionlint-enabled`** | Enable actionlint scanning                            | `string` | ❌ No     | `true`               |
| **`gitleaks-config`**    | Path to Gitleaks config file                          | `string` | ❌ No     | `.gitleaks.toml`     |
| **`gitleaks-license`**   | Gitleaks license key (required for Gitleaks scanning) | `string` | ❌ No     | _None_               |
| **`token`**              | GitHub token for authentication                       | `string` | ❌ No     | _None_               |
| **`trivy-scanners`**     | Types of scanners to run (comma-separated)            | `string` | ❌ No     | `vuln,config,secret` |
| **`trivy-severity`**     | Severity levels to scan for (comma-separated)         | `string` | ❌ No     | `CRITICAL,HIGH`      |
| **`trivy-timeout`**      | Timeout for Trivy scan                                | `string` | ❌ No     | `10m`                |

#### Parameter Details

##### `actionlint-enabled`

Enable actionlint scanning

- **Type**: String
- **Required**: No
- **Default**: `true`

```yaml
with:
  actionlint-enabled: 'true'
```

##### `gitleaks-config`

Path to Gitleaks config file

- **Type**: String
- **Required**: No
- **Default**: `.gitleaks.toml`

```yaml
with:
  gitleaks-config: '.gitleaks.toml'
```

##### `gitleaks-license`

Gitleaks license key (required for Gitleaks scanning)

- **Type**: String
- **Required**: No

```yaml
with:
  gitleaks-license: 'your-value-here'
```

##### `token`

GitHub token for authentication

- **Type**: String
- **Required**: No

```yaml
with:
  token: 'your-value-here'
```

##### `trivy-scanners`

Types of scanners to run (comma-separated)

- **Type**: String
- **Required**: No
- **Default**: `vuln,config,secret`

```yaml
with:
  trivy-scanners: 'vuln,config,secret'
```

##### `trivy-severity`

Severity levels to scan for (comma-separated)

- **Type**: String
- **Required**: No
- **Default**: `CRITICAL,HIGH`

```yaml
with:
  trivy-severity: 'CRITICAL,HIGH'
```

##### `trivy-timeout`

Timeout for Trivy scan

- **Type**: String
- **Required**: No
- **Default**: `10m`

```yaml
with:
  trivy-timeout: '10m'
```

### Output Parameters

This action provides the following outputs that can be used in subsequent workflow steps:

| Parameter                  | Description                                  | Usage                                          |
|----------------------------|----------------------------------------------|------------------------------------------------|
| **`critical_issues`**      | Number of critical security issues found     | `\${{ steps. .outputs.critical_issues }}`      |
| **`has_gitleaks_results`** | Whether Gitleaks scan produced valid results | `\${{ steps. .outputs.has_gitleaks_results }}` |
| **`has_trivy_results`**    | Whether Trivy scan produced valid results    | `\${{ steps. .outputs.has_trivy_results }}`    |
| **`total_issues`**         | Total number of security issues found        | `\${{ steps. .outputs.total_issues }}`         |

#### Using Outputs

```yaml
- name: Security Scan
  id: action-step
  uses: ivuorinen/actions/security-scan@vYYYY.MM.DD

- name: Use Output
  run: |
    echo "critical_issues: \${{ steps.action-step.outputs.critical_issues }}"
    echo "has_gitleaks_results: \${{ steps.action-step.outputs.has_gitleaks_results }}"
    echo "has_trivy_results: \${{ steps.action-step.outputs.has_trivy_results }}"
    echo "total_issues: \${{ steps.action-step.outputs.total_issues }}"
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
      - uses: ivuorinen/actions/security-scan@vYYYY.MM.DD
```

**Note:** If your workflow doesn't specify permissions, GitHub uses default permissions which may not include all required permissions above.

## Examples

### Basic Usage

```yaml
- name: Basic Security Scan
  uses: ivuorinen/actions/security-scan@vYYYY.MM.DD
  with:
    actionlint-enabled: 'true'
    gitleaks-config: '.gitleaks.toml'
    gitleaks-license: 'example-value'
    token: 'example-value'
    trivy-scanners: 'vuln,config,secret'
    trivy-severity: 'CRITICAL,HIGH'
    trivy-timeout: '10m'
```

### Advanced Configuration

```yaml
- name: Advanced Security Scan
  uses: ivuorinen/actions/security-scan@vYYYY.MM.DD
  with:
    actionlint-enabled: "true"
    gitleaks-config: ".gitleaks.toml"
    gitleaks-license: "\${{ vars.GITLEAKS-LICENSE }}"
    token: "\${{ vars.TOKEN }}"
    trivy-scanners: "vuln,config,secret"
    trivy-severity: "CRITICAL,HIGH"
    trivy-timeout: "10m"
  env:
    GITHUB_TOKEN: \${{ secrets.GITHUB_TOKEN }}
```

### Conditional Usage

```yaml
- name: Conditional Security Scan
  if: github.event_name == 'push'
  uses: ivuorinen/actions/security-scan@vYYYY.MM.DD
  with:
    actionlint-enabled: 'true'
    gitleaks-config: '.gitleaks.toml'
    gitleaks-license: 'production-value'
    token: 'production-value'
    trivy-scanners: 'vuln,config,secret'
    trivy-severity: 'CRITICAL,HIGH'
    trivy-timeout: '10m'
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
