# pre-commit

![check-square](https://img.shields.io/badge/icon-check-square-green) ![GitHub](https://img.shields.io/badge/GitHub%20Action-%20-blue) ![License](https://img.shields.io/badge/license-MIT-green)

> Runs pre-commit on the repository and pushes the fixes back to the repository

## 🚀 Quick Start

```yaml
name: My Workflow
on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@11d5960a326750d5838078e36cf38b85af677262 # v4
      - name: pre-commit
        uses: ivuorinen/actions/pre-commit@vYYYY.MM.DD
        with:
          base-branch: 'value'
          commit_email: 'github-actions@github.com'
          commit_user: 'GitHub Actions'
          pre-commit-config: '.pre-commit-config.yaml'
          token: '${{ github.token }}'
```

## 📥 Inputs

| Parameter           | Description                     | Required | Default                     |
|---------------------|---------------------------------|----------|-----------------------------|
| `base-branch`       | Base branch to compare against  | ❌        | -                           |
| `commit_email`      | Commit email                    | ❌        | `github-actions@github.com` |
| `commit_user`       | Commit user                     | ❌        | `GitHub Actions`            |
| `pre-commit-config` | pre-commit configuration file   | ❌        | `.pre-commit-config.yaml`   |
| `token`             | GitHub token for authentication | ❌        | -                           |

## 📤 Outputs

| Parameter       | Description                                        |
|-----------------|----------------------------------------------------|
| `files_changed` | Whether any files were changed by pre-commit hooks |
| `hooks_passed`  | Whether all pre-commit hooks passed (true/false)   |

## 🔐 Permissions

This action requires the following permissions:

| Permission | Access Level |
|------------|--------------|
| `contents` | `write`      |

**Usage in workflow:**

```yaml
permissions:
  contents: write
```

## 💡 Examples

<details>
<summary>Basic Usage</summary>

```yaml
- name: pre-commit
  uses: ivuorinen/actions/pre-commit@vYYYY.MM.DD
  with:
    base-branch: 'example-value'
    commit_email: 'github-actions@github.com'
    commit_user: 'GitHub Actions'
    pre-commit-config: '.pre-commit-config.yaml'
    token: '${{ github.token }}'
```

</details>

<details>
<summary>Advanced Configuration</summary>

```yaml
- name: pre-commit with custom settings
  uses: ivuorinen/actions/pre-commit@vYYYY.MM.DD
  with:
    base-branch: 'custom-value'
    commit_email: 'github-actions@github.com'
    commit_user: 'GitHub Actions'
    pre-commit-config: '.pre-commit-config.yaml'
    token: '${{ github.token }}'
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
