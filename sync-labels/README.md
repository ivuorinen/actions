# Sync labels

![tag](https://img.shields.io/badge/icon-tag-blue) ![GitHub](https://img.shields.io/badge/GitHub%20Action-%20-blue) ![License](https://img.shields.io/badge/license-MIT-green)

> Sync GitHub labels declaratively from a YAML/JSON manifest (no Docker)

## 🚀 Quick Start

```yaml
name: My Workflow
on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      issues: write
    steps:
      - uses: actions/checkout@11d5960a326750d5838078e36cf38b85af677262 # v4
      - name: Sync labels
        uses: ivuorinen/actions/sync-labels@vYYYY.MM.DD
        with:
          labels: 'config/settings.yml'
          prune: 'true'
          repository: 'my-org/my-repo'
          token: '${{ github.token }}'
```

## 📥 Inputs

| Parameter    | Description                                                                                                                                                                                                                             | Required | Default               |
|--------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------|-----------------------|
| `labels`     | Path to the labels manifest (YAML or JSON), relative to the repository root. Defaults to .github/labels.yml when omitted (no longer the action's bundled labels.yml). A missing manifest is a warning + successful no-op, not an error. | ❌        | -                     |
| `prune`      | Delete existing labels that are not listed in the manifest                                                                                                                                                                              | ❌        | `true`                |
| `repository` | Newline-separated list of owner/repo targets. Defaults to the current repository. Cross-repo sync requires a PAT in the token input.                                                                                                    | ❌        | -                     |
| `token`      | GitHub token for authentication (use a PAT for cross-repo sync)                                                                                                                                                                         | ❌        | `${{ github.token }}` |

## 📤 Outputs

| Parameter      | Description                       |
|----------------|-----------------------------------|
| `created`      | Number of labels created          |
| `deleted`      | Number of labels deleted (pruned) |
| `repositories` | Number of repositories synced     |
| `unchanged`    | Number of labels left unchanged   |
| `updated`      | Number of labels updated          |

## 🔐 Permissions

This action requires the following permissions:

| Permission | Access Level |
|------------|--------------|
| `issues`   | `write`      |

**Usage in workflow:**

```yaml
permissions:
  issues: write
```

## 💡 Examples

<details>
<summary>Basic Usage</summary>

```yaml
- name: Sync labels
  uses: ivuorinen/actions/sync-labels@vYYYY.MM.DD
  with:
    labels: 'config/settings.yml'
    prune: 'true'
    repository: 'my-org/my-repo'
    token: '${{ github.token }}'
```

</details>

<details>
<summary>Advanced Configuration</summary>

```yaml
- name: Sync labels with custom settings
  uses: ivuorinen/actions/sync-labels@vYYYY.MM.DD
  with:
    labels: 'config/settings.yml'
    prune: 'true'
    repository: 'my-org/my-repo'
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
