# Biome Lint

![check-circle](https://img.shields.io/badge/icon-check-circle-green) ![GitHub](https://img.shields.io/badge/GitHub%20Action-%20-blue) ![License](https://img.shields.io/badge/license-MIT-green)

> Run Biome linter in check or fix mode

## 🚀 Quick Start

```yaml
name: My Workflow
on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@11d5960a326750d5838078e36cf38b85af677262 # v4
      - name: Biome Lint
        uses: ivuorinen/actions/biome-lint@vYYYY.MM.DD
        with:
          email: 'github-actions@github.com'
          fail-on-error: 'true'
          max-retries: '3'
          mode: 'check'
          token: '${{ github.token }}'
          username: 'github-actions'
```

## 📥 Inputs

| Parameter       | Description                                                              | Required | Default                     |
|-----------------|--------------------------------------------------------------------------|----------|-----------------------------|
| `email`         | GitHub email for commits (fix mode only)                                 | ❌        | `github-actions@github.com` |
| `fail-on-error` | Whether to fail the action if linting errors are found (check mode only) | ❌        | `true`                      |
| `max-retries`   | Maximum number of retry attempts for npm install operations              | ❌        | `3`                         |
| `mode`          | Mode to run (check or fix)                                               | ❌        | `check`                     |
| `token`         | GitHub token for authentication                                          | ❌        | -                           |
| `username`      | GitHub username for commits (fix mode only)                              | ❌        | `github-actions`            |

## 📤 Outputs

| Parameter        | Description                                |
|------------------|--------------------------------------------|
| `errors_count`   | Number of errors found (check mode only)   |
| `files_changed`  | Number of files changed (fix mode only)    |
| `status`         | Overall status (success/failure)           |
| `warnings_count` | Number of warnings found (check mode only) |

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
- name: Biome Lint
  uses: ivuorinen/actions/biome-lint@vYYYY.MM.DD
  with:
    email: 'github-actions@github.com'
    fail-on-error: 'true'
    max-retries: '3'
    mode: 'check'
    token: '${{ github.token }}'
    username: 'github-actions'
```

</details>

<details>
<summary>Advanced Configuration</summary>

```yaml
- name: Biome Lint with custom settings
  uses: ivuorinen/actions/biome-lint@vYYYY.MM.DD
  with:
    email: 'github-actions@github.com'
    fail-on-error: 'true'
    max-retries: '3'
    mode: 'check'
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
