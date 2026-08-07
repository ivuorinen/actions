# Stale

![clock](https://img.shields.io/badge/icon-clock-yellow) ![GitHub](https://img.shields.io/badge/GitHub%20Action-%20-blue) ![License](https://img.shields.io/badge/license-MIT-green)

> A GitHub Action to close stale issues and pull requests.

## 🚀 Quick Start

```yaml
name: My Workflow
on:
  schedule:
    - cron: '0 0 * * *'
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      issues: write
      pull-requests: write
    steps:
      - uses: actions/checkout@11d5960a326750d5838078e36cf38b85af677262 # v4
      - name: Stale
        uses: ivuorinen/actions/stale@vYYYY.MM.DD
        with:
          days-before-close: '7'
          days-before-stale: '30'
          token: '${{ github.token }}'
```

## 📥 Inputs

| Parameter           | Description                                                     | Required | Default |
|---------------------|-----------------------------------------------------------------|----------|---------|
| `days-before-close` | Number of days of inactivity before a stale issue is closed     | ❌        | `7`     |
| `days-before-stale` | Number of days of inactivity before an issue is marked as stale | ❌        | `30`    |
| `token`             | GitHub token for authentication                                 | ❌        | -       |

## 📤 Outputs

| Parameter             | Description                      |
|-----------------------|----------------------------------|
| `closed_issues_count` | Number of issues closed          |
| `staled_issues_count` | Number of issues marked as stale |

## 🔐 Permissions

This action requires the following permissions:

| Permission      | Access Level |
|-----------------|--------------|
| `issues`        | `write`      |
| `pull-requests` | `write`      |

**Usage in workflow:**

```yaml
permissions:
  issues: write
  pull-requests: write
```

## 💡 Examples

<details>
<summary>Basic Usage</summary>

```yaml
- name: Stale
  uses: ivuorinen/actions/stale@vYYYY.MM.DD
  with:
    days-before-close: '7'
    days-before-stale: '30'
    token: '${{ github.token }}'
```

</details>

<details>
<summary>Advanced Configuration</summary>

```yaml
- name: Stale with custom settings
  uses: ivuorinen/actions/stale@vYYYY.MM.DD
  with:
    days-before-close: '7'
    days-before-stale: '30'
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
