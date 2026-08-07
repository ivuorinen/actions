# C# Publish

![package](https://img.shields.io/badge/icon-package-blue) ![GitHub](https://img.shields.io/badge/GitHub%20Action-%20-blue) ![License](https://img.shields.io/badge/license-MIT-green)

> Publishes a C# project to GitHub Packages.

## 🚀 Quick Start

```yaml
name: My Workflow
on: [push]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@11d5960a326750d5838078e36cf38b85af677262 # v4
      - name: C# Publish
        uses: ivuorinen/actions/csharp-publish@vYYYY.MM.DD
        with:
          dotnet-version: 'value'
          max-retries: '3'
          namespace: 'ivuorinen'
          token: '${{ github.token }}'
```

## 📥 Inputs

| Parameter        | Description                                                 | Required | Default     |
|------------------|-------------------------------------------------------------|----------|-------------|
| `dotnet-version` | Version of .NET SDK to use.                                 | ❌        | -           |
| `max-retries`    | Maximum number of retry attempts for dependency restoration | ❌        | `3`         |
| `namespace`      | GitHub namespace for the package.                           | ✅        | `ivuorinen` |
| `token`          | GitHub token with package write permissions                 | ❌        | -           |

## 📤 Outputs

| Parameter         | Description                              |
|-------------------|------------------------------------------|
| `package_url`     | URL of the published package             |
| `package_version` | Version of the published package         |
| `publish_status`  | Overall publish status (success/failure) |

## 🔐 Permissions

This action requires the following permissions:

| Permission | Access Level |
|------------|--------------|
| `contents` | `read`       |
| `packages` | `write`      |

**Usage in workflow:**

```yaml
permissions:
  contents: read
  packages: write
```

## 💡 Examples

<details>
<summary>Basic Usage</summary>

```yaml
- name: C# Publish
  uses: ivuorinen/actions/csharp-publish@vYYYY.MM.DD
  with:
    dotnet-version: 'example-value'
    max-retries: '3'
    namespace: 'ivuorinen'
    token: '${{ github.token }}'
```

</details>

<details>
<summary>Advanced Configuration</summary>

```yaml
- name: C# Publish with custom settings
  uses: ivuorinen/actions/csharp-publish@vYYYY.MM.DD
  with:
    dotnet-version: 'custom-value'
    max-retries: '3'
    namespace: 'ivuorinen'
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
