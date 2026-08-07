# CodeQL Analysis

![shield](https://img.shields.io/badge/icon-shield-blue) ![GitHub](<https://img.shields.io/badge/GitHub%20Action-> -blue) ![License](https://img.shields.io/badge/license-MIT-green)

> Run CodeQL security analysis for a single language with configurable query suites

## 🚀 Quick Start

```yaml
name: My Workflow
on: [push]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@11d5960a326750d5838078e36cf38b85af677262 # v4
      - name: CodeQL Analysis
        uses: ivuorinen/actions/codeql-analysis@vYYYY.MM.DD
        with:
          build-mode: 'value'
          category: 'value'
          checkout-ref: 'value'
          config: 'value'
          config-file: 'value'
          language: 'value'
          output: '../results'
          packs: 'value'
          queries: 'value'
          ram: 'value'
          skip-queries: 'false'
          source-root: 'value'
          threads: 'value'
          token: '${{ github.token }}'
          upload-results: 'true'
          working-directory: '.'
```

## 📥 Inputs

| Parameter           | Description                                                                          | Required | Default               |
|---------------------|--------------------------------------------------------------------------------------|----------|-----------------------|
| `build-mode`        | The build mode for compiled languages (none, manual, autobuild)                      | ❌        | -                     |
| `category`          | Analysis category (default: /language:<language>)                                    | ❌        | -                     |
| `checkout-ref`      | Git reference to checkout (default: current ref)                                     | ❌        | -                     |
| `config`            | Configuration passed as a YAML string                                                | ❌        | -                     |
| `config-file`       | Path to CodeQL configuration file                                                    | ❌        | -                     |
| `language`          | Language to analyze (javascript, python, actions, java, csharp, cpp, ruby, go, etc.) | ✅        | -                     |
| `output`            | Path to save SARIF results                                                           | ❌        | `../results`          |
| `packs`             | Comma-separated list of CodeQL query packs to run                                    | ❌        | -                     |
| `queries`           | Comma-separated list of additional queries to run                                    | ❌        | -                     |
| `ram`               | Amount of memory in MB that can be used by CodeQL                                    | ❌        | -                     |
| `skip-queries`      | Build database but skip running queries                                              | ❌        | `false`               |
| `source-root`       | Path of the root source code directory                                               | ❌        | -                     |
| `threads`           | Number of threads that can be used by CodeQL                                         | ❌        | -                     |
| `token`             | GitHub token for API access                                                          | ❌        | `${{ github.token }}` |
| `upload-results`    | Upload results to GitHub Security tab                                                | ❌        | `true`                |
| `working-directory` | Working directory for the analysis                                                   | ❌        | `.`                   |

## 📤 Outputs

| Parameter           | Description                    |
|---------------------|--------------------------------|
| `analysis-category` | Category used for the analysis |
| `language-analyzed` | Language that was analyzed     |
| `sarif-file`        | Path to generated SARIF file   |

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
- name: CodeQL Analysis
  uses: ivuorinen/actions/codeql-analysis@vYYYY.MM.DD
  with:
    build-mode: 'example-value'
    category: 'example-value'
    checkout-ref: 'example-value'
    config: 'example-value'
    config-file: 'example-value'
    language: 'example-value'
    output: '../results'
    packs: 'example-value'
    queries: 'example-value'
    ram: 'example-value'
    skip-queries: 'false'
    source-root: 'example-value'
    threads: 'example-value'
    token: '${{ github.token }}'
    upload-results: 'true'
    working-directory: '.'
```

</details>

<details>
<summary>Advanced Configuration</summary>

```yaml
- name: CodeQL Analysis with custom settings
  uses: ivuorinen/actions/codeql-analysis@vYYYY.MM.DD
  with:
    build-mode: 'custom-value'
    category: 'custom-value'
    checkout-ref: 'custom-value'
    config: 'custom-value'
    config-file: 'custom-value'
    language: 'custom-value'
    output: '../results'
    packs: 'custom-value'
    queries: 'custom-value'
    ram: 'custom-value'
    skip-queries: 'false'
    source-root: 'custom-value'
    threads: 'custom-value'
    token: '${{ github.token }}'
    upload-results: 'true'
    working-directory: '.'
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
