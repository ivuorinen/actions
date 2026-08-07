# C# Build

![code](https://img.shields.io/badge/icon-code-blue) ![GitHub](<https://img.shields.io/badge/GitHub%20Action-> -blue) ![License](https://img.shields.io/badge/license-MIT-green)

> Builds and tests C# projects.

## 🚀 Quick Start

```yaml
name: My Workflow
on: [push]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@11d5960a326750d5838078e36cf38b85af677262 # v4
      - name: C# Build
        uses: ivuorinen/actions/csharp-build@vYYYY.MM.DD
        with:
          dotnet-version: 'value'
          max-retries: '3'
          token: '${{ github.token }}'
```

## 📥 Inputs

| Parameter        | Description                                                    | Required | Default |
|------------------|----------------------------------------------------------------|----------|---------|
| `dotnet-version` | Version of .NET SDK to use.                                    | ❌        | -       |
| `max-retries`    | Maximum number of retry attempts for dotnet restore operations | ❌        | `3`     |
| `token`          | GitHub token for authentication                                | ❌        | -       |

## 📤 Outputs

| Parameter           | Description                                     |
|---------------------|-------------------------------------------------|
| `artifacts_path`    | Path to build artifacts                         |
| `build_status`      | Build completion status (success/failure)       |
| `dotnet_version`    | Version of .NET SDK used                        |
| `test_results_path` | Path to test results                            |
| `test_status`       | Test execution status (success/failure/skipped) |

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
- name: C# Build
  uses: ivuorinen/actions/csharp-build@vYYYY.MM.DD
  with:
    dotnet-version: 'example-value'
    max-retries: '3'
    token: '${{ github.token }}'
```

</details>

<details>
<summary>Advanced Configuration</summary>

```yaml
- name: C# Build with custom settings
  uses: ivuorinen/actions/csharp-build@vYYYY.MM.DD
  with:
    dotnet-version: 'custom-value'
    max-retries: '3'
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
