# Python Lint and Fix

![code](https://img.shields.io/badge/icon-code-yellow) ![GitHub](https://img.shields.io/badge/GitHub%20Action-%20-blue) ![License](https://img.shields.io/badge/license-MIT-green)

> Lints and fixes Python files, commits changes, and uploads SARIF report.

## 🚀 Quick Start

```yaml
name: My Workflow
on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: write
      security-events: write
    steps:
      - uses: actions/checkout@11d5960a326750d5838078e36cf38b85af677262 # v4
      - name: Python Lint and Fix
        uses: ivuorinen/actions/python-lint-fix@vYYYY.MM.DD
        with:
          autopep8-version: '2.0.4'
          email: 'github-actions@github.com'
          fail-on-error: 'true'
          flake8-version: '7.0.0'
          max-retries: '3'
          python-version: '3.11'
          token: '${{ github.token }}'
          username: 'github-actions'
          working-directory: '.'
```

## 📥 Inputs

| Parameter           | Description                                                    | Required | Default                     |
|---------------------|----------------------------------------------------------------|----------|-----------------------------|
| `autopep8-version`  | Autopep8 version to use                                        | ❌        | `2.0.4`                     |
| `email`             | GitHub email for commits                                       | ❌        | `github-actions@github.com` |
| `fail-on-error`     | Whether to fail the action if linting errors are found         | ❌        | `true`                      |
| `flake8-version`    | Flake8 version to use                                          | ❌        | `7.0.0`                     |
| `max-retries`       | Maximum number of retry attempts for installations and linting | ❌        | `3`                         |
| `python-version`    | Python version to use                                          | ❌        | `3.11`                      |
| `token`             | GitHub token for authentication                                | ❌        | -                           |
| `username`          | GitHub username for commits                                    | ❌        | `github-actions`            |
| `working-directory` | Directory containing Python files to lint                      | ❌        | `.`                         |

## 📤 Outputs

| Parameter     | Description                                     |
|---------------|-------------------------------------------------|
| `error-count` | Number of errors found                          |
| `fixed-files` | Number of files that were fixed                 |
| `lint-result` | Result of the linting process (success/failure) |

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
- name: Python Lint and Fix
  uses: ivuorinen/actions/python-lint-fix@vYYYY.MM.DD
  with:
    autopep8-version: '2.0.4'
    email: 'github-actions@github.com'
    fail-on-error: 'true'
    flake8-version: '7.0.0'
    max-retries: '3'
    python-version: '3.11'
    token: '${{ github.token }}'
    username: 'github-actions'
    working-directory: '.'
```

</details>

<details>
<summary>Advanced Configuration</summary>

```yaml
- name: Python Lint and Fix with custom settings
  uses: ivuorinen/actions/python-lint-fix@vYYYY.MM.DD
  with:
    autopep8-version: '2.0.4'
    email: 'github-actions@github.com'
    fail-on-error: 'true'
    flake8-version: '7.0.0'
    max-retries: '3'
    python-version: '3.11'
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
