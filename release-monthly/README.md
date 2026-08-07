# Do Monthly Release

![calendar](https://img.shields.io/badge/icon-calendar-blue) ![GitHub](https://img.shields.io/badge/GitHub%20Action-%20-blue) ![License](https://img.shields.io/badge/license-MIT-green)

> Creates a release for the current month, incrementing patch number if necessary.

## 🚀 Quick Start

```yaml
name: My Workflow
on:
  schedule:
    - cron: '0 0 1 * *'
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: write
    steps:
      - uses: actions/checkout@11d5960a326750d5838078e36cf38b85af677262 # v4
      - name: Do Monthly Release
        uses: ivuorinen/actions/release-monthly@vYYYY.MM.DD
        with:
          dry-run: 'false'
          prefix: 'v'
          token: '${{ github.token }}'
```

## 📥 Inputs

| Parameter | Description                                       | Required | Default               |
|-----------|---------------------------------------------------|----------|-----------------------|
| `dry-run` | Run in dry-run mode without creating the release. | ❌        | `false`               |
| `prefix`  | Optional prefix for release tags.                 | ❌        | -                     |
| `token`   | GitHub token with permission to create releases.  | ✅        | `${{ github.token }}` |

## 📤 Outputs

| Parameter      | Description                    |
|----------------|--------------------------------|
| `previous-tag` | The previous release tag       |
| `release-tag`  | The tag of the created release |
| `release-url`  | The URL of the created release |

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
- name: Do Monthly Release
  uses: ivuorinen/actions/release-monthly@vYYYY.MM.DD
  with:
    dry-run: 'false'
    prefix: 'v'
    token: '${{ github.token }}'
```

</details>

<details>
<summary>Advanced Configuration</summary>

```yaml
- name: Do Monthly Release with custom settings
  uses: ivuorinen/actions/release-monthly@vYYYY.MM.DD
  with:
    dry-run: 'false'
    prefix: 'v'
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
