# Docker Publish

![upload-cloud](https://img.shields.io/badge/icon-upload-cloud-blue) ![GitHub](<https://img.shields.io/badge/GitHub%20Action-> -blue) ![License](https://img.shields.io/badge/license-MIT-green)

> Simple wrapper to publish Docker images to GitHub Packages and/or Docker Hub

## 🚀 Quick Start

```yaml
name: My Workflow
on: [push]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@11d5960a326750d5838078e36cf38b85af677262 # v4
      - name: Docker Publish
        uses: ivuorinen/actions/docker-publish@vYYYY.MM.DD
        with:
          build-args: 'value'
          context: '.'
          dockerfile: 'Dockerfile'
          dockerhub-token: '${{ secrets.DOCKERHUB_TOKEN }}'
          dockerhub-username: 'value'
          image-name: 'value'
          platforms: 'linux/amd64,linux/arm64'
          push: 'true'
          registry: 'both'
          tags: 'latest'
          token: '${{ github.token }}'
```

## 📥 Inputs

| Parameter            | Description                                                | Required | Default                   |
|----------------------|------------------------------------------------------------|----------|---------------------------|
| `build-args`         | Build arguments (newline-separated KEY=VALUE pairs)        | ❌        | -                         |
| `context`            | Build context path                                         | ❌        | `.`                       |
| `dockerfile`         | Path to Dockerfile                                         | ❌        | `Dockerfile`              |
| `dockerhub-token`    | Docker Hub token (required if publishing to Docker Hub)    | ❌        | -                         |
| `dockerhub-username` | Docker Hub username (required if publishing to Docker Hub) | ❌        | -                         |
| `image-name`         | Docker image name (defaults to repository name)            | ❌        | -                         |
| `platforms`          | Platforms to build for (comma-separated)                   | ❌        | `linux/amd64,linux/arm64` |
| `push`               | Whether to push the image                                  | ❌        | `true`                    |
| `registry`           | Registry to publish to (dockerhub, github, or both)        | ❌        | `both`                    |
| `tags`               | Comma-separated list of tags (e.g., latest,v1.0.0)         | ❌        | `latest`                  |
| `token`              | GitHub token for authentication (for GitHub registry)      | ❌        | -                         |

## 📤 Outputs

| Parameter    | Description                   |
|--------------|-------------------------------|
| `digest`     | Image digest                  |
| `image-name` | Full image name with registry |
| `metadata`   | Build metadata                |
| `tags`       | Tags that were published      |

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
- name: Docker Publish
  uses: ivuorinen/actions/docker-publish@vYYYY.MM.DD
  with:
    build-args: 'example-value'
    context: '.'
    dockerfile: 'Dockerfile'
    dockerhub-token: '${{ secrets.DOCKERHUB_TOKEN }}'
    dockerhub-username: 'example-value'
    image-name: 'example-value'
    platforms: 'linux/amd64,linux/arm64'
    push: 'true'
    registry: 'both'
    tags: 'latest'
    token: '${{ github.token }}'
```

</details>

<details>
<summary>Advanced Configuration</summary>

```yaml
- name: Docker Publish with custom settings
  uses: ivuorinen/actions/docker-publish@vYYYY.MM.DD
  with:
    build-args: 'custom-value'
    context: '.'
    dockerfile: 'Dockerfile'
    dockerhub-token: '${{ secrets.DOCKERHUB_TOKEN }}'
    dockerhub-username: 'custom-value'
    image-name: 'custom-value'
    platforms: 'linux/amd64,linux/arm64'
    push: 'true'
    registry: 'both'
    tags: 'latest'
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
