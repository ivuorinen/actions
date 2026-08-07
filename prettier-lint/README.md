# Prettier Lint

![check-circle](https://img.shields.io/badge/icon-check-circle-green) ![GitHub](https://img.shields.io/badge/GitHub%20Action-%20-blue) ![License](https://img.shields.io/badge/license-MIT-green)

> Run Prettier in check or fix mode with advanced configuration and reporting

## 🚀 Quick Start

```yaml
name: My Workflow
on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@11d5960a326750d5838078e36cf38b85af677262 # v4
      - name: Prettier Lint
        uses: ivuorinen/actions/prettier-lint@vYYYY.MM.DD
        with:
          cache: 'true'
          config-file: '.prettierrc'
          email: 'github-actions@github.com'
          fail-on-error: 'true'
          file-pattern: '**/*.{js,jsx,ts,tsx,css,scss,json,md,yaml,yml}'
          ignore-file: '.prettierignore'
          max-retries: '3'
          mode: 'check'
          plugins: 'value'
          prettier-version: 'latest'
          report-format: 'sarif'
          token: '${{ github.token }}'
          username: 'github-actions'
          working-directory: '.'
```

## 📥 Inputs

| Parameter           | Description                                         | Required | Default                                          |
|---------------------|-----------------------------------------------------|----------|--------------------------------------------------|
| `cache`             | Enable Prettier caching                             | ❌        | `true`                                           |
| `config-file`       | Path to Prettier config file                        | ❌        | `.prettierrc`                                    |
| `email`             | GitHub email for commits (fix mode only)            | ❌        | `github-actions@github.com`                      |
| `fail-on-error`     | Fail workflow if issues are found (check mode only) | ❌        | `true`                                           |
| `file-pattern`      | Files to include (glob pattern)                     | ❌        | `**/*.{js,jsx,ts,tsx,css,scss,json,md,yaml,yml}` |
| `ignore-file`       | Path to Prettier ignore file                        | ❌        | `.prettierignore`                                |
| `max-retries`       | Maximum number of retry attempts                    | ❌        | `3`                                              |
| `mode`              | Mode to run (check or fix)                          | ❌        | `check`                                          |
| `plugins`           | Comma-separated list of Prettier plugins to install | ❌        | -                                                |
| `prettier-version`  | Prettier version to use                             | ❌        | `latest`                                         |
| `report-format`     | Output format for check mode (json, sarif)          | ❌        | `sarif`                                          |
| `token`             | GitHub token for authentication                     | ❌        | -                                                |
| `username`          | GitHub username for commits (fix mode only)         | ❌        | `github-actions`                                 |
| `working-directory` | Directory containing files to format                | ❌        | `.`                                              |

## 📤 Outputs

| Parameter           | Description                                              |
|---------------------|----------------------------------------------------------|
| `files-changed`     | Number of files changed (fix mode only)                  |
| `files-checked`     | Number of files checked (check mode only)                |
| `sarif-file`        | Path to SARIF report file (check mode only)              |
| `status`            | Overall status (success/failure)                         |
| `unformatted-files` | Number of files with formatting issues (check mode only) |

## 🔐 Permissions

This action requires the following permissions:

| Permission        | Access Level |
|-------------------|--------------|
| `contents`        | `write`      |
| `security-events` | `write`      |

**Usage in workflow:**

```yaml
permissions:
  contents: write
  security-events: write
```

## 💡 Examples

<details>
<summary>Basic Usage</summary>

```yaml
- name: Prettier Lint
  uses: ivuorinen/actions/prettier-lint@vYYYY.MM.DD
  with:
    cache: 'true'
    config-file: '.prettierrc'
    email: 'github-actions@github.com'
    fail-on-error: 'true'
    file-pattern: '**/*.{js,jsx,ts,tsx,css,scss,json,md,yaml,yml}'
    ignore-file: '.prettierignore'
    max-retries: '3'
    mode: 'check'
    plugins: 'example-value'
    prettier-version: 'latest'
    report-format: 'sarif'
    token: '${{ github.token }}'
    username: 'github-actions'
    working-directory: '.'
```

</details>

<details>
<summary>Advanced Configuration</summary>

```yaml
- name: Prettier Lint with custom settings
  uses: ivuorinen/actions/prettier-lint@vYYYY.MM.DD
  with:
    cache: 'true'
    config-file: '.prettierrc'
    email: 'github-actions@github.com'
    fail-on-error: 'true'
    file-pattern: '**/*.{js,jsx,ts,tsx,css,scss,json,md,yaml,yml}'
    ignore-file: '.prettierignore'
    max-retries: '3'
    mode: 'check'
    plugins: 'custom-value'
    prettier-version: 'latest'
    report-format: 'sarif'
    token: '${{ github.token }}'
    username: 'github-actions'
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
