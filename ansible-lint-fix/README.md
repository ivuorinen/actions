# Ansible Lint and Fix

![play](https://img.shields.io/badge/icon-play-green) ![GitHub](https://img.shields.io/badge/GitHub%20Action-%20-blue) ![License](https://img.shields.io/badge/license-MIT-green)

> Lints and fixes Ansible playbooks, commits changes, and uploads SARIF report.

## 🚀 Quick Start

```yaml
name: My Workflow
on: [push]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@11d5960a326750d5838078e36cf38b85af677262 # v4
      - name: Ansible Lint and Fix
        uses: ivuorinen/actions/ansible-lint-fix@vYYYY.MM.DD
        with:
          email: 'github-actions@github.com'
          max-retries: '3'
          token: '${{ github.token }}'
          username: 'github-actions'
```

## 📥 Inputs

| Parameter     | Description                                                 | Required | Default                     |
|---------------|-------------------------------------------------------------|----------|-----------------------------|
| `email`       | GitHub email for commits                                    | ❌        | `github-actions@github.com` |
| `max-retries` | Maximum number of retry attempts for pip install operations | ❌        | `3`                         |
| `token`       | GitHub token for authentication                             | ❌        | -                           |
| `username`    | GitHub username for commits                                 | ❌        | `github-actions`            |

## 📤 Outputs

| Parameter       | Description                        |
|-----------------|------------------------------------|
| `files_changed` | Number of files changed by linting |
| `lint_status`   | Linting status (success/failure)   |
| `sarif_path`    | Path to SARIF report file          |

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
- name: Ansible Lint and Fix
  uses: ivuorinen/actions/ansible-lint-fix@vYYYY.MM.DD
  with:
    email: 'github-actions@github.com'
    max-retries: '3'
    token: '${{ github.token }}'
    username: 'github-actions'
```

</details>

<details>
<summary>Advanced Configuration</summary>

```yaml
- name: Ansible Lint and Fix with custom settings
  uses: ivuorinen/actions/ansible-lint-fix@vYYYY.MM.DD
  with:
    email: 'github-actions@github.com'
    max-retries: '3'
    token: '${{ github.token }}'
    username: 'github-actions'
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
