# Go Lint Check

![code](https://img.shields.io/badge/icon-code-blue) ![GitHub](https://img.shields.io/badge/GitHub%20Action-%20-blue) ![License](https://img.shields.io/badge/license-MIT-green)

> Run golangci-lint with advanced configuration, caching, and reporting

## 🚀 Quick Start

```yaml
name: My Workflow
on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      security-events: write
    steps:
      - uses: actions/checkout@11d5960a326750d5838078e36cf38b85af677262 # v4
      - name: Go Lint Check
        uses: ivuorinen/actions/go-lint@vYYYY.MM.DD
        with:
          cache: 'true'
          config-file: '.golangci.yml'
          disable-all: 'false'
          disable-linters: 'gosec,govet'
          enable-linters: 'gosec,govet'
          fail-on-error: 'true'
          go-version: '1.24'
          golangci-lint-version: '2.1.0'
          max-retries: '3'
          only-new-issues: 'true'
          report-format: 'sarif'
          timeout: '5m'
          token: '${{ github.token }}'
          working-directory: '.'
```

## 📥 Inputs

| Parameter               | Description                                                                                                                                                                                                                     | Required | Default         |
| ----------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | --------------- |
| `cache`                 | Enable golangci-lint caching (lowercase true or false)                                                                                                                                                                          | ❌       | `true`          |
| `config-file`           | Path to golangci-lint config file, relative to working-directory. Without the default file, a .golangci.yaml, .golangci.toml or .golangci.json there is used, else a built-in default; a path other than the default must exist | ❌       | `.golangci.yml` |
| `disable-all`           | Disable all linters, useful with --enable-* (lowercase true or false)                                                                                                                                                           | ❌       | `false`         |
| `disable-linters`       | Comma-separated list of linters to disable                                                                                                                                                                                      | ❌       | -               |
| `enable-linters`        | Comma-separated list of linters to enable                                                                                                                                                                                       | ❌       | -               |
| `fail-on-error`         | Fail the workflow when issues are found; a run that could not lint fails either way (lowercase true or false)                                                                                                                   | ❌       | `true`          |
| `go-version`            | Go version to use (empty: the version pinned in this action, "stable": the newest release)                                                                                                                                      | ❌       | -               |
| `golangci-lint-version` | Version of golangci-lint v2 to use (empty: the version pinned in this action, "latest": the newest v2 release)                                                                                                                  | ❌       | -               |
| `max-retries`           | Maximum number of attempts to install golangci-lint (1-10, must not be empty)                                                                                                                                                   | ❌       | `3`             |
| `only-new-issues`       | Report only new issues since main branch (lowercase true or false)                                                                                                                                                              | ❌       | `true`          |
| `report-format`         | Output format: sarif, json or text. github-actions, line-number and colored-line-number, the golangci-lint v1 names, also give text.                                                                                            | ❌       | `sarif`         |
| `timeout`               | Timeout for analysis (e.g., 5m, 1h)                                                                                                                                                                                             | ❌       | `5m`            |
| `token`                 | GitHub token for authentication. Defaults to the workflow token.                                                                                                                                                                | ❌       | -               |
| `working-directory`     | Directory containing Go files                                                                                                                                                                                                   | ❌       | `.`             |

## 📤 Outputs

| Parameter        | Description                        |
| ---------------- | ---------------------------------- |
| `analyzed-files` | Number of files analyzed           |
| `cache-hit`      | Indicates if there was a cache hit |
| `error-count`    | Number of errors found             |
| `sarif-file`     | Path to SARIF report file          |

## 🔐 Permissions

This action requires the following permissions:

| Permission        | Access Level |
| ----------------- | ------------ |
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
    disable-linters: 'gosec,govet'
    enable-linters: 'gosec,govet'
    fail-on-error: 'true'
    go-version: '1.24'
    golangci-lint-version: '2.1.0'
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
    disable-linters: 'gosec,govet'
    enable-linters: 'gosec,govet'
    fail-on-error: 'true'
    go-version: '1.24'
    golangci-lint-version: '2.1.0'
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
