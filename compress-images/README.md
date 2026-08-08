# Compress Images

![image](https://img.shields.io/badge/icon-image-blue) ![GitHub](https://img.shields.io/badge/GitHub%20Action-%20-blue) ![License](https://img.shields.io/badge/license-MIT-green)

> Compress images on demand (workflow_dispatch), and at 11pm every Sunday (schedule).

## 🚀 Quick Start

```yaml
name: My Workflow
on:
  schedule:
    - cron: '0 0 * * 0'
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: write
      pull-requests: write
    steps:
      - uses: actions/checkout@11d5960a326750d5838078e36cf38b85af677262 # v4
      - name: Compress Images
        uses: ivuorinen/actions/compress-images@vYYYY.MM.DD
        with:
          email: 'github-actions@github.com'
          ignore-paths: 'node_modules/**,dist/**,build/**'
          image-quality: '85'
          png-quality: '95'
          token: '${{ github.token }}'
          username: 'github-actions'
          working-directory: '.'
```

## 📥 Inputs

| Parameter           | Description                                        | Required | Default                            |
|---------------------|----------------------------------------------------|----------|------------------------------------|
| `email`             | GitHub email for commits                           | ❌        | `github-actions@github.com`        |
| `ignore-paths`      | Paths to ignore during compression (glob patterns) | ❌        | `node_modules/**,dist/**,build/**` |
| `image-quality`     | JPEG compression quality (0-100)                   | ❌        | `85`                               |
| `png-quality`       | PNG compression quality (0-100)                    | ❌        | `95`                               |
| `token`             | GitHub token for authentication                    | ❌        | `${{ github.token }}`              |
| `username`          | GitHub username for commits                        | ❌        | `github-actions`                   |
| `working-directory` | Directory containing images to compress            | ❌        | `.`                                |

## 📤 Outputs

| Parameter            | Description                                  |
|----------------------|----------------------------------------------|
| `compression_report` | Markdown report of compression results       |
| `images_compressed`  | Whether any images were compressed (boolean) |

## 🔐 Permissions

This action requires the following permissions:

| Permission      | Access Level |
|-----------------|--------------|
| `contents`      | `write`      |
| `pull-requests` | `write`      |

**Usage in workflow:**

```yaml
permissions:
  contents: write
  pull-requests: write
```

## 💡 Examples

<details>
<summary>Basic Usage</summary>

```yaml
- name: Compress Images
  uses: ivuorinen/actions/compress-images@vYYYY.MM.DD
  with:
    email: 'github-actions@github.com'
    ignore-paths: 'node_modules/**,dist/**,build/**'
    image-quality: '85'
    png-quality: '95'
    token: '${{ github.token }}'
    username: 'github-actions'
    working-directory: '.'
```

</details>

<details>
<summary>Advanced Configuration</summary>

```yaml
- name: Compress Images with custom settings
  uses: ivuorinen/actions/compress-images@vYYYY.MM.DD
  with:
    email: 'github-actions@github.com'
    ignore-paths: 'node_modules/**,dist/**,build/**'
    image-quality: '85'
    png-quality: '95'
    token: '${{ github.token }}'
    username: 'github-actions'
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
