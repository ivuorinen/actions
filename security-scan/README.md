# Security Scan

![shield](https://img.shields.io/badge/icon-shield-red) ![GitHub](https://img.shields.io/badge/GitHub%20Action-%20-blue) ![License](https://img.shields.io/badge/license-MIT-green)

> Security scanning for repositories with GitHub Actions: actionlint, Gitleaks and Trivy, with the results uploaded to code scanning. Requires 'contents: read' and 'security-events: write', and on a
> pull request 'pull-requests: write' for its comment. All three scanners run from release binaries checked against SHA-256 digests pinned in this action, on Linux and macOS (x64 and ARM64) and
> Windows x64. Gitleaks scans the commits a pull request, merge group or push adds, two-parent merge commits included, and the whole history on other events and on a push whose earlier commit the
> clone lacks, such as the push that creates a branch, where an older commit can fail the scan. On a pull request or merge group, Gitleaks and Trivy run from an export of the base commit, so their
> configs, ignore files and git attributes come from the base branch, and actionlint reads the base branch's config. Inline gitleaks:allow comments, and Trivy's trivy:ignore comments, in the changed
> files still apply; a pull request's scan lists the gitleaks:allow comments it adds in a comment when the base branch keeps a Gitleaks config or ignore file.

## 🚀 Quick Start

```yaml
name: My Workflow
on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      pull-requests: write
      security-events: write
    steps:
      - uses: actions/checkout@11d5960a326750d5838078e36cf38b85af677262 # v4
      - name: Security Scan
        uses: ivuorinen/actions/security-scan@vYYYY.MM.DD
        with:
          actionlint-enabled: 'true'
          gitleaks-config: '.gitleaks.toml'
          token: '${{ github.token }}'
          trivy-scanners: 'vuln,misconfig,secret'
          trivy-severity: 'CRITICAL,HIGH'
          trivy-timeout: '10m'
```

## 📥 Inputs

| Parameter            | Description                                                                                                                                                                                              | Required | Default                 |
| -------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ----------------------- |
| `actionlint-enabled` | Enable actionlint scanning (lowercase true or false)                                                                                                                                                     | ❌       | `true`                  |
| `gitleaks-config`    | Path to the Gitleaks config file. If it does not exist, Gitleaks uses a root .gitleaks.toml or its default rules. On a pull request or merge group the file is read from the base commit.                | ❌       | `.gitleaks.toml`        |
| `gitleaks-license`   | Deprecated: has no effect, because Gitleaks runs from its own release binary, which needs no license. A value set here must still contain no whitespace or control characters, and is masked in the log. | ❌       | -                       |
| `token`              | GitHub token for checking out the repository and, on a pull request, for the inline gitleaks:allow comment. Defaults to the workflow token                                                               | ❌       | -                       |
| `trivy-scanners`     | Trivy scanners to run (comma-separated): vuln, misconfig, secret, license. config is Trivy's older, deprecated name for misconfig                                                                        | ❌       | `vuln,misconfig,secret` |
| `trivy-severity`     | Severity levels to scan for (comma-separated). Also limits the SARIF report                                                                                                                              | ❌       | `CRITICAL,HIGH`         |
| `trivy-timeout`      | Timeout for Trivy scan                                                                                                                                                                                   | ❌       | `10m`                   |

## 📤 Outputs

| Parameter              | Description                                                                                            |
| ---------------------- | ------------------------------------------------------------------------------------------------------ |
| `critical_issues`      | Number of critical security issues found; empty when a scanner that was to run left no report to count |
| `has_gitleaks_results` | Whether Gitleaks scan produced valid results                                                           |
| `has_trivy_results`    | Whether Trivy scan produced valid results                                                              |
| `total_issues`         | Total number of security issues found; empty when a scanner that was to run left no report to count    |

## 🔐 Permissions

This action requires the following permissions:

| Permission        | Access Level |
| ----------------- | ------------ |
| `contents`        | `read`       |
| `pull-requests`   | `write`      |
| `security-events` | `write`      |

**Usage in workflow:**

```yaml
permissions:
  contents: read
  pull-requests: write
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
    token: '${{ github.token }}'
    trivy-scanners: 'vuln,misconfig,secret'
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
    token: '${{ github.token }}'
    trivy-scanners: 'vuln,misconfig,secret'
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
