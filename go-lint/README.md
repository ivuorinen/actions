# Go Lint Check

![code](https://img.shields.io/badge/icon-code-blue) ![GitHub](<https://img.shields.io/badge/GitHub%20Action-> -blue) ![License](https://img.shields.io/badge/license-MIT-green)

> Run golangci-lint with advanced configuration, caching, and reporting

## 🚀 Quick Start

```yaml
name: My Workflow
on: [push]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@11d5960a326750d5838078e36cf38b85af677262 # v4
      - name: Go Lint Check
        uses: ivuorinen/actions/go-lint@vYYYY.MM.DD
        with:
          cache: 'true'
          config-file: '.golangci.yml'
          disable-all: 'false'
          disable-linters: 'value'
          enable-linters: 'value'
          fail-on-error: 'true'
          go-version: 'stable'
          golangci-lint-version: 'latest'
          max-retries: '3'
          only-new-issues: 'true'
          report-format: 'sarif'
          timeout: '5m'
          token: '${{ github.token }}'
          working-directory: '.'
```

## 📥 Inputs

| Parameter               | Description                                  | Required | Default         |
|-------------------------|----------------------------------------------|----------|-----------------|
| `cache`                 | Enable golangci-lint caching                 | ❌        | `true`          |
| `config-file`           | Path to golangci-lint config file            | ❌        | `.golangci.yml` |
| `disable-all`           | Disable all linters (useful with --enable-*) | ❌        | `false`         |
| `disable-linters`       | Comma-separated list of linters to disable   | ❌        | -               |
| `enable-linters`        | Comma-separated list of linters to enable    | ❌        | -               |
| `fail-on-error`         | Fail workflow if issues are found            | ❌        | `true`          |
| `go-version`            | Go version to use                            | ❌        | `stable`        |
| `golangci-lint-version` | Version of golangci-lint to use              | ❌        | `latest`        |
| `max-retries`           | Maximum number of retry attempts             | ❌        | `3`             |
| `only-new-issues`       | Report only new issues since main branch     | ❌        | `true`          |
| `report-format`         | Output format (json, sarif, github-actions)  | ❌        | `sarif`         |
| `timeout`               | Timeout for analysis (e.g., 5m, 1h)          | ❌        | `5m`            |
| `token`                 | GitHub token for authentication              | ❌        | -               |
| `working-directory`     | Directory containing Go files                | ❌        | `.`             |

## 📤 Outputs

| Parameter        | Description                        |
|------------------|------------------------------------|
| `analyzed-files` | Number of files analyzed           |
| `cache-hit`      | Indicates if there was a cache hit |
| `error-count`    | Number of errors found             |
| `sarif-file`     | Path to SARIF report file          |

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
- name: Go Lint Check
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
    token: '${{ github.token }}'
    working-directory: '.'
```

</details>

<details>
<summary>Advanced Configuration</summary>

```yaml
- name: Go Lint Check with custom settings
  uses: ivuorinen/actions/go-lint@vYYYY.MM.DD
  with:
    cache: 'true'
    config-file: '.golangci.yml'
    disable-all: 'false'
    disable-linters: 'custom-value'
    enable-linters: 'custom-value'
    fail-on-error: 'true'
    go-version: 'stable'
    golangci-lint-version: 'latest'
    max-retries: '3'
    only-new-issues: 'true'
    report-format: 'sarif'
    timeout: '5m'
    token: '${{ github.token }}'
    working-directory: '.'
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
