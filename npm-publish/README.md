# Publish to NPM

![package](https://img.shields.io/badge/icon-package-green) ![GitHub](https://img.shields.io/badge/GitHub%20Action-%20-blue) ![License](https://img.shields.io/badge/license-MIT-green)

> Publishes the package to the NPM registry with configurable scope and registry URL.

## 🚀 Quick Start

```yaml
name: My Workflow
on: [push]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@11d5960a326750d5838078e36cf38b85af677262 # v4
      - name: Publish to NPM
        uses: ivuorinen/actions/npm-publish@vYYYY.MM.DD
        with:
          npm_token: '${{ secrets.NPM_TOKEN }}'
          package-version: '${{ github.event.release.tag_name }}'
          registry-url: 'https://registry.npmjs.org/'
          scope: '@ivuorinen'
          token: '${{ github.token }}'
```

## 📥 Inputs

| Parameter         | Description                     | Required | Default                                |
|-------------------|---------------------------------|----------|----------------------------------------|
| `npm_token`       | NPM token.                      | ✅        | -                                      |
| `package-version` | The version to publish.         | ❌        | `${{ github.event.release.tag_name }}` |
| `registry-url`    | Registry URL for publishing.    | ❌        | `https://registry.npmjs.org/`          |
| `scope`           | Package scope to use.           | ❌        | `@ivuorinen`                           |
| `token`           | GitHub token for authentication | ❌        | -                                      |

## 📤 Outputs

| Parameter         | Description                  |
|-------------------|------------------------------|
| `package-version` | The version to publish.      |
| `registry-url`    | Registry URL for publishing. |
| `scope`           | Package scope to use.        |

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
- name: Publish to NPM
  uses: ivuorinen/actions/npm-publish@vYYYY.MM.DD
  with:
    npm_token: '${{ secrets.NPM_TOKEN }}'
    package-version: '${{ github.event.release.tag_name }}'
    registry-url: 'https://registry.npmjs.org/'
    scope: '@ivuorinen'
    token: '${{ github.token }}'
```

</details>

<details>
<summary>Advanced Configuration</summary>

```yaml
- name: Publish to NPM with custom settings
  uses: ivuorinen/actions/npm-publish@vYYYY.MM.DD
  with:
    npm_token: '${{ secrets.NPM_TOKEN }}'
    package-version: '${{ github.event.release.tag_name }}'
    registry-url: 'https://registry.npmjs.org/'
    scope: '@ivuorinen'
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
