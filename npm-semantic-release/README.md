# NPM Semantic Release

![package](https://img.shields.io/badge/icon-package-blue) ![GitHub](https://img.shields.io/badge/GitHub%20Action-%20-blue) ![License](https://img.shields.io/badge/license-MIT-green)

> Runs semantic-release for automated npm versioning and publishing with OIDC provenance support.

## 🚀 Quick Start

```yaml
name: My Workflow
on:
  release:
    types: [published]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@11d5960a326750d5838078e36cf38b85af677262 # v4
      - name: NPM Semantic Release
        uses: ivuorinen/actions/npm-semantic-release@vYYYY.MM.DD
        with:
          extra_plugins: 'conventional-changelog-conventionalcommits@^9.3.1'
          github_token: '${{ github.token }}'
          node-version: '24'
          npm_token: '${{ secrets.NPM_TOKEN }}'
          registry-url: 'https://registry.npmjs.org/'
          scope: '@ivuorinen'
```

## 📥 Inputs

| Parameter       | Description                                                | Required | Default                                             |
|-----------------|------------------------------------------------------------|----------|-----------------------------------------------------|
| `extra_plugins` | Extra semantic-release plugins (pipe-separated).           | ❌        | `conventional-changelog-conventionalcommits@^9.3.1` |
| `github_token`  | GitHub token for creating releases, tags, and PR comments. | ❌        | `${{ github.token }}`                               |
| `node-version`  | Node.js version to use when .nvmrc is not present.         | ❌        | `24`                                                |
| `npm_token`     | NPM token for publishing.                                  | ✅        | -                                                   |
| `registry-url`  | Registry URL for publishing.                               | ❌        | `https://registry.npmjs.org/`                       |
| `scope`         | Package scope to use.                                      | ❌        | `@ivuorinen`                                        |

## 📤 Outputs

| Parameter               | Description                            |
|-------------------------|----------------------------------------|
| `new-release-published` | Whether a new release was published.   |
| `new-release-version`   | The new release version, if published. |

## 🔐 Permissions

This action requires the following permissions:

| Permission      | Access Level |
|-----------------|--------------|
| `contents`      | `write`      |
| `id-token`      | `write`      |
| `issues`        | `write`      |
| `pull-requests` | `write`      |

**Usage in workflow:**

```yaml
permissions:
  contents: write
  id-token: write
  issues: write
  pull-requests: write
```

## 💡 Examples

<details>
<summary>Basic Usage</summary>

```yaml
- name: NPM Semantic Release
  uses: ivuorinen/actions/npm-semantic-release@vYYYY.MM.DD
  with:
    extra_plugins: 'conventional-changelog-conventionalcommits@^9.3.1'
    github_token: '${{ github.token }}'
    node-version: '24'
    npm_token: '${{ secrets.NPM_TOKEN }}'
    registry-url: 'https://registry.npmjs.org/'
    scope: '@ivuorinen'
```

</details>

<details>
<summary>Advanced Configuration</summary>

```yaml
- name: NPM Semantic Release with custom settings
  uses: ivuorinen/actions/npm-semantic-release@vYYYY.MM.DD
  with:
    extra_plugins: 'conventional-changelog-conventionalcommits@^9.3.1'
    github_token: '${{ github.token }}'
    node-version: '24'
    npm_token: '${{ secrets.NPM_TOKEN }}'
    registry-url: 'https://registry.npmjs.org/'
    scope: '@ivuorinen'
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
