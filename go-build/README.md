# Go Build

![package](https://img.shields.io/badge/icon-package-blue) ![GitHub](https://img.shields.io/badge/GitHub%20Action-%20-blue) ![License](https://img.shields.io/badge/license-MIT-green)

> Builds the Go project.

## 🚀 Quick Start

```yaml
name: My Workflow
on: [push]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@11d5960a326750d5838078e36cf38b85af677262 # v4
      - name: Go Build
        uses: ivuorinen/actions/go-build@vYYYY.MM.DD
        with:
          destination: './bin'
          go-version: 'value'
          max-retries: '3'
          token: '${{ github.token }}'
```

## 📥 Inputs

| Parameter     | Description                                                     | Required | Default |
|---------------|-----------------------------------------------------------------|----------|---------|
| `destination` | Build destination directory.                                    | ❌        | `./bin` |
| `go-version`  | Go version to use.                                              | ❌        | -       |
| `max-retries` | Maximum number of retry attempts for go mod download operations | ❌        | `3`     |
| `token`       | GitHub token for authentication                                 | ❌        | -       |

## 📤 Outputs

| Parameter       | Description                                     |
|-----------------|-------------------------------------------------|
| `binary_path`   | Path to built binaries                          |
| `build_status`  | Build completion status (success/failure)       |
| `coverage_path` | Path to coverage report                         |
| `go_version`    | Version of Go used                              |
| `test_status`   | Test execution status (success/failure/skipped) |

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
- name: Go Build
  uses: ivuorinen/actions/go-build@vYYYY.MM.DD
  with:
    destination: './bin'
    go-version: 'example-value'
    max-retries: '3'
    token: '${{ github.token }}'
```

</details>

<details>
<summary>Advanced Configuration</summary>

```yaml
- name: Go Build with custom settings
  uses: ivuorinen/actions/go-build@vYYYY.MM.DD
  with:
    destination: './bin'
    go-version: 'custom-value'
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
