# Docker Publish

<div align="center">
  <img src="https://img.shields.io/badge/icon-upload-cloud-blue" alt="upload-cloud" />
  <img src="https://img.shields.io/badge/status-stable-brightgreen" alt="Status" />
  <img src="https://img.shields.io/badge/license-MIT-blue" alt="License" />
</div>

## Overview

Simple wrapper to publish Docker images to GitHub Packages and/or Docker Hub

This GitHub Action provides a robust solution for your CI/CD pipeline with comprehensive configuration options and detailed output information.

## Table of Contents

- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [Input Parameters](#input-parameters)
- [Output Parameters](#output-parameters)
- [Examples](#examples)

- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

## Quick Start

Add the following step to your GitHub Actions workflow:

```yaml
name: CI/CD Pipeline
on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout Repository
        uses: actions/checkout@v4

      - name: Docker Publish
        uses: ivuorinen/actions/docker-publish@vYYYY.MM.DD
        with:
          build-args: 'your-value-here'
          context: '.'
          dockerfile: 'Dockerfile'
          dockerhub-token: 'your-value-here'
          dockerhub-username: 'your-value-here'
          image-name: 'your-value-here'
          platforms: 'linux/amd64,linux/arm64'
          push: 'true'
          registry: 'both'
          tags: 'latest'
          token: 'your-value-here'
```

## Configuration

This action supports various configuration options to customize its behavior according to your needs.

### Input Parameters

| Parameter                | Description                                                | Type     | Required | Default Value             |
|--------------------------|------------------------------------------------------------|----------|----------|---------------------------|
| **`build-args`**         | Build arguments (newline-separated KEY=VALUE pairs)        | `string` | ❌ No     | _None_                    |
| **`context`**            | Build context path                                         | `string` | ❌ No     | `.`                       |
| **`dockerfile`**         | Path to Dockerfile                                         | `string` | ❌ No     | `Dockerfile`              |
| **`dockerhub-token`**    | Docker Hub token (required if publishing to Docker Hub)    | `string` | ❌ No     | _None_                    |
| **`dockerhub-username`** | Docker Hub username (required if publishing to Docker Hub) | `string` | ❌ No     | _None_                    |
| **`image-name`**         | Docker image name (defaults to repository name)            | `string` | ❌ No     | _None_                    |
| **`platforms`**          | Platforms to build for (comma-separated)                   | `string` | ❌ No     | `linux/amd64,linux/arm64` |
| **`push`**               | Whether to push the image                                  | `string` | ❌ No     | `true`                    |
| **`registry`**           | Registry to publish to (dockerhub, github, or both)        | `string` | ❌ No     | `both`                    |
| **`tags`**               | Comma-separated list of tags (e.g., latest,v1.0.0)         | `string` | ❌ No     | `latest`                  |
| **`token`**              | GitHub token for authentication (for GitHub registry)      | `string` | ❌ No     | _None_                    |

#### Parameter Details

##### `build-args`

Build arguments (newline-separated KEY=VALUE pairs)

- **Type**: String
- **Required**: No

```yaml
with:
  build-args: 'your-value-here'
```

##### `context`

Build context path

- **Type**: String
- **Required**: No
- **Default**: `.`

```yaml
with:
  context: '.'
```

##### `dockerfile`

Path to Dockerfile

- **Type**: String
- **Required**: No
- **Default**: `Dockerfile`

```yaml
with:
  dockerfile: 'Dockerfile'
```

##### `dockerhub-token`

Docker Hub token (required if publishing to Docker Hub)

- **Type**: String
- **Required**: No

```yaml
with:
  dockerhub-token: 'your-value-here'
```

##### `dockerhub-username`

Docker Hub username (required if publishing to Docker Hub)

- **Type**: String
- **Required**: No

```yaml
with:
  dockerhub-username: 'your-value-here'
```

##### `image-name`

Docker image name (defaults to repository name)

- **Type**: String
- **Required**: No

```yaml
with:
  image-name: 'your-value-here'
```

##### `platforms`

Platforms to build for (comma-separated)

- **Type**: String
- **Required**: No
- **Default**: `linux/amd64,linux/arm64`

```yaml
with:
  platforms: 'linux/amd64,linux/arm64'
```

##### `push`

Whether to push the image

- **Type**: String
- **Required**: No
- **Default**: `true`

```yaml
with:
  push: 'true'
```

##### `registry`

Registry to publish to (dockerhub, github, or both)

- **Type**: String
- **Required**: No
- **Default**: `both`

```yaml
with:
  registry: 'both'
```

##### `tags`

Comma-separated list of tags (e.g., latest,v1.0.0)

- **Type**: String
- **Required**: No
- **Default**: `latest`

```yaml
with:
  tags: 'latest'
```

##### `token`

GitHub token for authentication (for GitHub registry)

- **Type**: String
- **Required**: No

```yaml
with:
  token: 'your-value-here'
```

### Output Parameters

This action provides the following outputs that can be used in subsequent workflow steps:

| Parameter        | Description                   | Usage                                |
|------------------|-------------------------------|--------------------------------------|
| **`digest`**     | Image digest                  | `\${{ steps. .outputs.digest }}`     |
| **`image-name`** | Full image name with registry | `\${{ steps. .outputs.image-name }}` |
| **`metadata`**   | Build metadata                | `\${{ steps. .outputs.metadata }}`   |
| **`tags`**       | Tags that were published      | `\${{ steps. .outputs.tags }}`       |

#### Using Outputs

```yaml
- name: Docker Publish
  id: action-step
  uses: ivuorinen/actions/docker-publish@vYYYY.MM.DD

- name: Use Output
  run: |
    echo "digest: \${{ steps.action-step.outputs.digest }}"
    echo "image-name: \${{ steps.action-step.outputs.image-name }}"
    echo "metadata: \${{ steps.action-step.outputs.metadata }}"
    echo "tags: \${{ steps.action-step.outputs.tags }}"
```

## 🔐 Required Permissions

This action requires specific GitHub permissions to function correctly. Ensure your workflow includes these permissions:

| Permission | Access Level | Description                   |
|------------|--------------|-------------------------------|
| `contents` | `read`       | Required for action operation |
| `packages` | `write`      | Required for action operation |

### How to Set Permissions

```yaml
name: My Workflow
on: [push]

permissions:
  contents: read
  packages: write

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: ivuorinen/actions/docker-publish@vYYYY.MM.DD
```

**Note:** If your workflow doesn't specify permissions, GitHub uses default permissions which may not include all required permissions above.

## Examples

### Basic Usage

```yaml
- name: Basic Docker Publish
  uses: ivuorinen/actions/docker-publish@vYYYY.MM.DD
  with:
    build-args: 'example-value'
    context: '.'
    dockerfile: 'Dockerfile'
    dockerhub-token: 'example-value'
    dockerhub-username: 'example-value'
    image-name: 'example-value'
    platforms: 'linux/amd64,linux/arm64'
    push: 'true'
    registry: 'both'
    tags: 'latest'
    token: 'example-value'
```

### Advanced Configuration

```yaml
- name: Advanced Docker Publish
  uses: ivuorinen/actions/docker-publish@vYYYY.MM.DD
  with:
    build-args: "\${{ vars.BUILD-ARGS }}"
    context: "."
    dockerfile: "Dockerfile"
    dockerhub-token: "\${{ vars.DOCKERHUB-TOKEN }}"
    dockerhub-username: "\${{ vars.DOCKERHUB-USERNAME }}"
    image-name: "\${{ vars.IMAGE-NAME }}"
    platforms: "linux/amd64,linux/arm64"
    push: "true"
    registry: "both"
    tags: "latest"
    token: "\${{ vars.TOKEN }}"
  env:
    GITHUB_TOKEN: \${{ secrets.GITHUB_TOKEN }}
```

### Conditional Usage

```yaml
- name: Conditional Docker Publish
  if: github.event_name == 'push'
  uses: ivuorinen/actions/docker-publish@vYYYY.MM.DD
  with:
    build-args: 'production-value'
    context: '.'
    dockerfile: 'Dockerfile'
    dockerhub-token: 'production-value'
    dockerhub-username: 'production-value'
    image-name: 'production-value'
    platforms: 'linux/amd64,linux/arm64'
    push: 'true'
    registry: 'both'
    tags: 'latest'
    token: 'production-value'
```

## Troubleshooting

### Common Issues

1. **Authentication Errors**: Ensure you have set up the required secrets in your repository settings.
2. **Permission Issues**: Check that your GitHub token has the necessary permissions.
3. **Configuration Errors**: Validate your input parameters against the schema.

### Getting Help

- Check the [action.yml](./action.yml) for the complete specification
- Open an issue if you encounter problems

## Contributing

We welcome contributions! Please see our [Contributing Guide](../CONTRIBUTING.md) for details.

### Development Setup

1. Fork this repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License. See the [LICENSE](../LICENSE.md) file for details.

## Support

If you find this action helpful, please consider:

- ⭐ Starring this repository
- 🐛 Reporting issues
- 💡 Suggesting improvements
- 🤝 Contributing code

---

<div align="center">
  <sub>📚 Documentation generated with <a href="https://github.com/ivuorinen/gh-action-readme">gh-action-readme</a></sub>
</div>
