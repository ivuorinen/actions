# Language Version Detect

![code](https://img.shields.io/badge/icon-code-blue) ![GitHub](https://img.shields.io/badge/GitHub%20Action-%20-blue) ![License](https://img.shields.io/badge/license-MIT-green)

> DEPRECATED: This action is deprecated. Inline version detection directly in your actions instead. Detects language version from project configuration files with support for PHP, Python, Go, and
> .NET.

## 🚀 Quick Start

```yaml
name: My Workflow
on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: read
    steps:
      - uses: actions/checkout@11d5960a326750d5838078e36cf38b85af677262 # v4
      - name: Language Version Detect
        uses: ivuorinen/actions/language-version-detect@vYYYY.MM.DD
        with:
          default-version: '1.2.3'
          language: 'python'
          token: '${{ github.token }}'
```

## 📥 Inputs

| Parameter         | Description                                              | Required | Default |
|-------------------|----------------------------------------------------------|----------|---------|
| `default-version` | Default version to use if no version is detected         | ❌        | -       |
| `language`        | Language to detect version for (php, python, go, dotnet) | ✅        | -       |
| `token`           | GitHub token for authentication                          | ❌        | -       |

## 📤 Outputs

| Parameter          | Description                                                         |
|--------------------|---------------------------------------------------------------------|
| `detected-version` | Detected or default language version                                |
| `package-manager`  | Detected package manager (python: pip/poetry/pipenv, php: composer) |

## 🔐 Permissions

This action requires the following permissions:

| Permission | Access Level |
|------------|--------------|
| `contents` | `read`       |

**Usage in workflow:**

```yaml
permissions:
  contents: read
```

## 💡 Examples

<details>
<summary>Basic Usage</summary>

```yaml
- name: Language Version Detect
  uses: ivuorinen/actions/language-version-detect@vYYYY.MM.DD
  with:
    default-version: '1.2.3'
    language: 'python'
    token: '${{ github.token }}'
```

</details>

<details>
<summary>Advanced Configuration</summary>

```yaml
- name: Language Version Detect with custom settings
  uses: ivuorinen/actions/language-version-detect@vYYYY.MM.DD
  with:
    default-version: '1.2.3'
    language: 'python'
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
