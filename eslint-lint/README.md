# ESLint Lint

![check-circle](https://img.shields.io/badge/icon-check-circle-blue) ![GitHub](https://img.shields.io/badge/GitHub%20Action-%20-blue) ![License](https://img.shields.io/badge/license-MIT-green)

> Run ESLint in check or fix mode with advanced configuration and reporting

## 🚀 Quick Start

```yaml
name: My Workflow
on: [push]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@11d5960a326750d5838078e36cf38b85af677262 # v4
      - name: ESLint Lint
        uses: ivuorinen/actions/eslint-lint@vYYYY.MM.DD
        with:
          cache: 'true'
          config-file: '.eslintrc'
          email: 'github-actions@github.com'
          eslint-version: 'latest'
          fail-on-error: 'true'
          file-extensions: '.js,.jsx,.ts,.tsx'
          ignore-file: '.eslintignore'
          max-retries: '3'
          max-warnings: '0'
          mode: 'check'
          report-format: 'sarif'
          token: '${{ github.token }}'
          username: 'github-actions'
          working-directory: '.'
```

## 📥 Inputs

| Parameter           | Description                                          | Required | Default                     |
|---------------------|------------------------------------------------------|----------|-----------------------------|
| `cache`             | Enable ESLint caching                                | ❌        | `true`                      |
| `config-file`       | Path to ESLint config file                           | ❌        | `.eslintrc`                 |
| `email`             | GitHub email for commits (fix mode only)             | ❌        | `github-actions@github.com` |
| `eslint-version`    | ESLint version to use                                | ❌        | `latest`                    |
| `fail-on-error`     | Fail workflow if issues are found (check mode only)  | ❌        | `true`                      |
| `file-extensions`   | File extensions to lint (comma-separated)            | ❌        | `.js,.jsx,.ts,.tsx`         |
| `ignore-file`       | Path to ESLint ignore file                           | ❌        | `.eslintignore`             |
| `max-retries`       | Maximum number of retry attempts                     | ❌        | `3`                         |
| `max-warnings`      | Maximum number of warnings allowed (check mode only) | ❌        | `0`                         |
| `mode`              | Mode to run (check or fix)                           | ❌        | `check`                     |
| `report-format`     | Output format for check mode (stylish, json, sarif)  | ❌        | `sarif`                     |
| `token`             | GitHub token for authentication                      | ❌        | -                           |
| `username`          | GitHub username for commits (fix mode only)          | ❌        | `github-actions`            |
| `working-directory` | Directory containing files to lint                   | ❌        | `.`                         |

## 📤 Outputs

| Parameter       | Description                                 |
|-----------------|---------------------------------------------|
| `error-count`   | Number of errors found (check mode only)    |
| `errors-fixed`  | Number of errors fixed (fix mode only)      |
| `files-changed` | Number of files changed (fix mode only)     |
| `files-checked` | Number of files checked (check mode only)   |
| `sarif-file`    | Path to SARIF report file (check mode only) |
| `status`        | Overall status (success/failure)            |
| `warning-count` | Number of warnings found (check mode only)  |

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
- name: ESLint Lint
  uses: ivuorinen/actions/eslint-lint@vYYYY.MM.DD
  with:
    cache: 'true'
    config-file: '.eslintrc'
    email: 'github-actions@github.com'
    eslint-version: 'latest'
    fail-on-error: 'true'
    file-extensions: '.js,.jsx,.ts,.tsx'
    ignore-file: '.eslintignore'
    max-retries: '3'
    max-warnings: '0'
    mode: 'check'
    report-format: 'sarif'
    token: '${{ github.token }}'
    username: 'github-actions'
    working-directory: '.'
```

</details>

<details>
<summary>Advanced Configuration</summary>

```yaml
- name: ESLint Lint with custom settings
  uses: ivuorinen/actions/eslint-lint@vYYYY.MM.DD
  with:
    cache: 'true'
    config-file: '.eslintrc'
    email: 'github-actions@github.com'
    eslint-version: 'latest'
    fail-on-error: 'true'
    file-extensions: '.js,.jsx,.ts,.tsx'
    ignore-file: '.eslintignore'
    max-retries: '3'
    max-warnings: '0'
    mode: 'check'
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
