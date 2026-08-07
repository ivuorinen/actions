# PR Lint

![check-circle](https://img.shields.io/badge/icon-check-circle-green) ![GitHub](https://img.shields.io/badge/GitHub%20Action-%20-blue) ![License](https://img.shields.io/badge/license-MIT-green)

> Runs MegaLinter against pull requests

## 🚀 Quick Start

```yaml
name: My Workflow
on: [push]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@11d5960a326750d5838078e36cf38b85af677262 # v4
      - name: PR Lint
        uses: ivuorinen/actions/pr-lint@vYYYY.MM.DD
        with:
          email: 'github-actions@github.com'
          token: '${{ github.token }}'
          username: 'github-actions'
```

## 📥 Inputs

| Parameter  | Description                     | Required | Default                     |
|------------|---------------------------------|----------|-----------------------------|
| `email`    | GitHub email for commits        | ❌        | `github-actions@github.com` |
| `token`    | GitHub token for authentication | ❌        | -                           |
| `username` | GitHub username for commits     | ❌        | `github-actions`            |

## 📤 Outputs

| Parameter           | Description                                 |
|---------------------|---------------------------------------------|
| `errors_found`      | Number of linting errors found              |
| `validation_status` | Overall validation status (success/failure) |

## 🔐 Permissions

This action requires the following permissions:

| Permission      | Access Level |
|-----------------|--------------|
| `contents`      | `write`      |
| `pull-requests` | `write`      |

**Usage in workflow:**

```yaml
permissions:
  contents: write
  pull-requests: write
```

## 💡 Examples

<details>
<summary>Basic Usage</summary>

```yaml
- name: PR Lint
  uses: ivuorinen/actions/pr-lint@vYYYY.MM.DD
  with:
    email: 'github-actions@github.com'
    token: '${{ github.token }}'
    username: 'github-actions'
```

</details>

<details>
<summary>Advanced Configuration</summary>

```yaml
- name: PR Lint with custom settings
  uses: ivuorinen/actions/pr-lint@vYYYY.MM.DD
  with:
    email: 'github-actions@github.com'
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
