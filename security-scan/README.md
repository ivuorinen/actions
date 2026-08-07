# Security Scan

![shield](https://img.shields.io/badge/icon-shield-red) ![GitHub](<https://img.shields.io/badge/GitHub%20Action-> -blue) ![License](https://img.shields.io/badge/license-MIT-green)

> Comprehensive security scanning for GitHub Actions including actionlint, Gitleaks (optional), and Trivy vulnerability scanning. Requires 'security-events: write' and 'contents: read' permissions in
> the workflow.

## 🚀 Quick Start

```yaml
name: My Workflow
on: [push]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@11d5960a326750d5838078e36cf38b85af677262 # v4
      - name: Security Scan
        uses: ivuorinen/actions/security-scan@vYYYY.MM.DD
        with:
          actionlint-enabled: 'true'
          gitleaks-config: '.gitleaks.toml'
          gitleaks-license: '${{ secrets.GITLEAKS_LICENSE }}'
          token: '${{ github.token }}'
          trivy-scanners: 'vuln,config,secret'
          trivy-severity: 'CRITICAL,HIGH'
          trivy-timeout: '10m'
```

## 📥 Inputs

| Parameter            | Description                                           | Required | Default              |
|----------------------|-------------------------------------------------------|----------|----------------------|
| `actionlint-enabled` | Enable actionlint scanning                            | ❌        | `true`               |
| `gitleaks-config`    | Path to Gitleaks config file                          | ❌        | `.gitleaks.toml`     |
| `gitleaks-license`   | Gitleaks license key (required for Gitleaks scanning) | ❌        | -                    |
| `token`              | GitHub token for authentication                       | ❌        | -                    |
| `trivy-scanners`     | Types of scanners to run (comma-separated)            | ❌        | `vuln,config,secret` |
| `trivy-severity`     | Severity levels to scan for (comma-separated)         | ❌        | `CRITICAL,HIGH`      |
| `trivy-timeout`      | Timeout for Trivy scan                                | ❌        | `10m`                |

## 📤 Outputs

| Parameter              | Description                                  |
|------------------------|----------------------------------------------|
| `critical_issues`      | Number of critical security issues found     |
| `has_gitleaks_results` | Whether Gitleaks scan produced valid results |
| `has_trivy_results`    | Whether Trivy scan produced valid results    |
| `total_issues`         | Total number of security issues found        |

## 🔐 Permissions

This action requires the following permissions:

| Permission        | Access Level |
|-------------------|--------------|
| `contents`        | `read`       |
| `security-events` | `write`      |

**Usage in workflow:**

```yaml
permissions:
  contents: read
  security-events: write
```

## 💡 Examples

<details>
<summary>Basic Usage</summary>

```yaml
- name: Security Scan
  uses: ivuorinen/actions/security-scan@vYYYY.MM.DD
  with:
    actionlint-enabled: 'true'
    gitleaks-config: '.gitleaks.toml'
    gitleaks-license: '${{ secrets.GITLEAKS_LICENSE }}'
    token: '${{ github.token }}'
    trivy-scanners: 'vuln,config,secret'
    trivy-severity: 'CRITICAL,HIGH'
    trivy-timeout: '10m'
```

</details>

<details>
<summary>Advanced Configuration</summary>

```yaml
- name: Security Scan with custom settings
  uses: ivuorinen/actions/security-scan@vYYYY.MM.DD
  with:
    actionlint-enabled: 'true'
    gitleaks-config: '.gitleaks.toml'
    gitleaks-license: '${{ secrets.GITLEAKS_LICENSE }}'
    token: '${{ github.token }}'
    trivy-scanners: 'vuln,config,secret'
    trivy-severity: 'CRITICAL,HIGH'
    trivy-timeout: '10m'
```

</details>

## 🔧 Development

See the [action.yml](./action.yml) for the complete action specification.

## 📄 License

This action is distributed under the MIT License. See [LICENSE](../LICENSE.md) for more information.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

---

<div align="center">
  <sub>🚀 Generated with <a href="https://github.com/ivuorinen/gh-action-readme">gh-action-readme</a></sub>
</div>
