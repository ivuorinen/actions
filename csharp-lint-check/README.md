# C# Lint Check

![code](https://img.shields.io/badge/icon-code-blue) ![GitHub](<https://img.shields.io/badge/GitHub%20Action-> -blue) ![License](https://img.shields.io/badge/license-MIT-green)

> Runs linters like StyleCop or dotnet-format for C# code style checks.

## 🚀 Quick Start

```yaml
name: My Workflow
on: [push]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@11d5960a326750d5838078e36cf38b85af677262 # v4
      - name: C# Lint Check
        uses: ivuorinen/actions/csharp-lint-check@vYYYY.MM.DD
        with:
          dotnet-version: 'value'
          token: '${{ github.token }}'
```

## 📥 Inputs

| Parameter        | Description                     | Required | Default |
|------------------|---------------------------------|----------|---------|
| `dotnet-version` | Version of .NET SDK to use.     | ❌        | -       |
| `token`          | GitHub token for authentication | ❌        | -       |

## 📤 Outputs

| Parameter        | Description                           |
|------------------|---------------------------------------|
| `errors_count`   | Number of formatting errors found     |
| `lint_status`    | Overall lint status (success/failure) |
| `warnings_count` | Number of formatting warnings found   |

## 🔐 Permissions

This action requires the following permissions:

| Permission        | Access Level |
|-------------------|--------------|
| `contents`        | `read`       |
| `security-events` | `write`      |

**Usage in workflow:**

```yaml
permissions:
  contents: read
  security-events: write
```

## 💡 Examples

<details>
<summary>Basic Usage</summary>

```yaml
- name: C# Lint Check
  uses: ivuorinen/actions/csharp-lint-check@vYYYY.MM.DD
  with:
    dotnet-version: 'example-value'
    token: '${{ github.token }}'
```

</details>

<details>
<summary>Advanced Configuration</summary>

```yaml
- name: C# Lint Check with custom settings
  uses: ivuorinen/actions/csharp-lint-check@vYYYY.MM.DD
  with:
    dotnet-version: 'custom-value'
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
