# Docker Build

<div align="center">
  <img src="https://img.shields.io/badge/icon-package-blue" alt="package" />
  <img src="https://img.shields.io/badge/status-stable-brightgreen" alt="Status" />
  <img src="https://img.shields.io/badge/license-MIT-blue" alt="License" />
</div>

## Overview

Builds a Docker image for multiple architectures with enhanced security and reliability.

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

      - name: Docker Build
        uses: ivuorinen/actions/docker-build@vYYYY.MM.DD
        with:
          architectures: 'linux/amd64,linux/arm64,linux/arm/v7,linux/arm/v6'
          auto-detect-platforms: 'false'
          build-args: 'your-value-here'
          build-contexts: 'your-value-here'
          buildkit-version: 'v0.11.0'
          buildx-version: 'latest'
          cache-export: 'your-value-here'
          cache-from: 'your-value-here'
          cache-import: 'your-value-here'
          cache-mode: 'max'
          context: '.'
          dockerfile: 'Dockerfile'
          dry-run: 'false'
          image-name: 'your-value-here'
          max-retries: '3'
          network: 'default'
          parallel-builds: '0'
          platform-build-args: 'your-value-here'
          platform-fallback: 'true'
          push: 'true'
          sbom-format: 'spdx-json'
          scan-image: 'false'
          secrets: 'your-value-here'
          sign-image: 'false'
          tag: 'your-value-here'
          token: 'your-value-here'
          verbose: 'false'
```

## Configuration

This action supports various configuration options to customize its behavior according to your needs.

### Input Parameters

| Parameter                   | Description                                                                  | Type     | Required | Default Value                                       |
|-----------------------------|------------------------------------------------------------------------------|----------|----------|-----------------------------------------------------|
| **`architectures`**         | Comma-separated list of architectures to build for.                          | `string` | ❌ No     | `linux/amd64,linux/arm64,linux/arm/v7,linux/arm/v6` |
| **`auto-detect-platforms`** | Automatically detect and build for all available platforms                   | `string` | ❌ No     | `false`                                             |
| **`build-args`**            | Build arguments in format KEY=VALUE,KEY2=VALUE2                              | `string` | ❌ No     | _None_                                              |
| **`build-contexts`**        | Additional build contexts in format name=path,name2=path2                    | `string` | ❌ No     | _None_                                              |
| **`buildkit-version`**      | Specific BuildKit version to use                                             | `string` | ❌ No     | `v0.11.0`                                           |
| **`buildx-version`**        | Specific Docker Buildx version to use                                        | `string` | ❌ No     | `latest`                                            |
| **`cache-export`**          | Export cache destination (e.g., type=local,dest=/tmp/cache)                  | `string` | ❌ No     | _None_                                              |
| **`cache-from`**            | External cache sources (e.g., type=registry,ref=user/app:cache)              | `string` | ❌ No     | _None_                                              |
| **`cache-import`**          | Import cache sources (e.g., type=local,src=/tmp/cache)                       | `string` | ❌ No     | _None_                                              |
| **`cache-mode`**            | Cache mode for build layers (min, max, or inline)                            | `string` | ❌ No     | `max`                                               |
| **`context`**               | Docker build context                                                         | `string` | ❌ No     | `.`                                                 |
| **`dockerfile`**            | Path to the Dockerfile                                                       | `string` | ❌ No     | `Dockerfile`                                        |
| **`dry-run`**               | Perform a dry run without actually building                                  | `string` | ❌ No     | `false`                                             |
| **`image-name`**            | The name of the Docker image to build. Defaults to the repository name.      | `string` | ❌ No     | _None_                                              |
| **`max-retries`**           | Maximum number of retry attempts for build and push operations               | `string` | ❌ No     | `3`                                                 |
| **`network`**               | Network mode for build (host, none, or default)                              | `string` | ❌ No     | `default`                                           |
| **`parallel-builds`**       | Number of parallel platform builds (0 for auto)                              | `string` | ❌ No     | `0`                                                 |
| **`platform-build-args`**   | Platform-specific build args in JSON format                                  | `string` | ❌ No     | _None_                                              |
| **`platform-fallback`**     | Continue building other platforms if one fails                               | `string` | ❌ No     | `true`                                              |
| **`push`**                  | Whether to push the image after building                                     | `string` | ❌ No     | `true`                                              |
| **`sbom-format`**           | SBOM format (spdx-json, cyclonedx-json, or syft-json)                        | `string` | ❌ No     | `spdx-json`                                         |
| **`scan-image`**            | Scan built image for vulnerabilities                                         | `string` | ❌ No     | `false`                                             |
| **`secrets`**               | Build secrets in format id=path,id2=path2                                    | `string` | ❌ No     | _None_                                              |
| **`sign-image`**            | Sign the built image with cosign                                             | `string` | ❌ No     | `false`                                             |
| **`tag`**                   | The tag for the Docker image. Must follow semver or valid Docker tag format. | `string` | ✅ Yes    | _None_                                              |
| **`token`**                 | GitHub token for authentication                                              | `string` | ❌ No     | _None_                                              |
| **`verbose`**               | Enable verbose logging with platform-specific output                         | `string` | ❌ No     | `false`                                             |

#### Parameter Details

##### `architectures`

Comma-separated list of architectures to build for.

- **Type**: String
- **Required**: No
- **Default**: `linux/amd64,linux/arm64,linux/arm/v7,linux/arm/v6`

```yaml
with:
  architectures: 'linux/amd64,linux/arm64,linux/arm/v7,linux/arm/v6'
```

##### `auto-detect-platforms`

Automatically detect and build for all available platforms

- **Type**: String
- **Required**: No
- **Default**: `false`

```yaml
with:
  auto-detect-platforms: 'false'
```

##### `build-args`

Build arguments in format KEY=VALUE,KEY2=VALUE2

- **Type**: String
- **Required**: No

```yaml
with:
  build-args: 'your-value-here'
```

##### `build-contexts`

Additional build contexts in format name=path,name2=path2

- **Type**: String
- **Required**: No

```yaml
with:
  build-contexts: 'your-value-here'
```

##### `buildkit-version`

Specific BuildKit version to use

- **Type**: String
- **Required**: No
- **Default**: `v0.11.0`

```yaml
with:
  buildkit-version: 'v0.11.0'
```

##### `buildx-version`

Specific Docker Buildx version to use

- **Type**: String
- **Required**: No
- **Default**: `latest`

```yaml
with:
  buildx-version: 'latest'
```

##### `cache-export`

Export cache destination (e.g., type=local,dest=/tmp/cache)

- **Type**: String
- **Required**: No

```yaml
with:
  cache-export: 'your-value-here'
```

##### `cache-from`

External cache sources (e.g., type=registry,ref=user/app:cache)

- **Type**: String
- **Required**: No

```yaml
with:
  cache-from: 'your-value-here'
```

##### `cache-import`

Import cache sources (e.g., type=local,src=/tmp/cache)

- **Type**: String
- **Required**: No

```yaml
with:
  cache-import: 'your-value-here'
```

##### `cache-mode`

Cache mode for build layers (min, max, or inline)

- **Type**: String
- **Required**: No
- **Default**: `max`

```yaml
with:
  cache-mode: 'max'
```

##### `context`

Docker build context

- **Type**: String
- **Required**: No
- **Default**: `.`

```yaml
with:
  context: '.'
```

##### `dockerfile`

Path to the Dockerfile

- **Type**: String
- **Required**: No
- **Default**: `Dockerfile`

```yaml
with:
  dockerfile: 'Dockerfile'
```

##### `dry-run`

Perform a dry run without actually building

- **Type**: String
- **Required**: No
- **Default**: `false`

```yaml
with:
  dry-run: 'false'
```

##### `image-name`

The name of the Docker image to build. Defaults to the repository name.

- **Type**: String
- **Required**: No

```yaml
with:
  image-name: 'your-value-here'
```

##### `max-retries`

Maximum number of retry attempts for build and push operations

- **Type**: String
- **Required**: No
- **Default**: `3`

```yaml
with:
  max-retries: '3'
```

##### `network`

Network mode for build (host, none, or default)

- **Type**: String
- **Required**: No
- **Default**: `default`

```yaml
with:
  network: 'default'
```

##### `parallel-builds`

Number of parallel platform builds (0 for auto)

- **Type**: String
- **Required**: No
- **Default**: `0`

```yaml
with:
  parallel-builds: '0'
```

##### `platform-build-args`

Platform-specific build args in JSON format

- **Type**: String
- **Required**: No

```yaml
with:
  platform-build-args: 'your-value-here'
```

##### `platform-fallback`

Continue building other platforms if one fails

- **Type**: String
- **Required**: No
- **Default**: `true`

```yaml
with:
  platform-fallback: 'true'
```

##### `push`

Whether to push the image after building

- **Type**: String
- **Required**: No
- **Default**: `true`

```yaml
with:
  push: 'true'
```

##### `sbom-format`

SBOM format (spdx-json, cyclonedx-json, or syft-json)

- **Type**: String
- **Required**: No
- **Default**: `spdx-json`

```yaml
with:
  sbom-format: 'spdx-json'
```

##### `scan-image`

Scan built image for vulnerabilities

- **Type**: String
- **Required**: No
- **Default**: `false`

```yaml
with:
  scan-image: 'false'
```

##### `secrets`

Build secrets in format id=path,id2=path2

- **Type**: String
- **Required**: No

```yaml
with:
  secrets: 'your-value-here'
```

##### `sign-image`

Sign the built image with cosign

- **Type**: String
- **Required**: No
- **Default**: `false`

```yaml
with:
  sign-image: 'false'
```

##### `tag`

The tag for the Docker image. Must follow semver or valid Docker tag format.

- **Type**: String
- **Required**: Yes

```yaml
with:
  tag: 'your-value-here'
```

##### `token`

GitHub token for authentication

- **Type**: String
- **Required**: No

```yaml
with:
  token: 'your-value-here'
```

##### `verbose`

Enable verbose logging with platform-specific output

- **Type**: String
- **Required**: No
- **Default**: `false`

```yaml
with:
  verbose: 'false'
```

### Output Parameters

This action provides the following outputs that can be used in subsequent workflow steps:

| Parameter             | Description                                    | Usage                                     |
|-----------------------|------------------------------------------------|-------------------------------------------|
| **`build-time`**      | Total build time in seconds                    | `\${{ steps. .outputs.build-time }}`      |
| **`image-digest`**    | The digest of the built image                  | `\${{ steps. .outputs.image-digest }}`    |
| **`metadata`**        | Build metadata in JSON format                  | `\${{ steps. .outputs.metadata }}`        |
| **`platform-matrix`** | Build status per platform in JSON format       | `\${{ steps. .outputs.platform-matrix }}` |
| **`platforms`**       | Successfully built platforms                   | `\${{ steps. .outputs.platforms }}`       |
| **`sbom-location`**   | SBOM document location                         | `\${{ steps. .outputs.sbom-location }}`   |
| **`scan-results`**    | Vulnerability scan results if scanning enabled | `\${{ steps. .outputs.scan-results }}`    |
| **`signature`**       | Image signature if signing enabled             | `\${{ steps. .outputs.signature }}`       |

#### Using Outputs

```yaml
- name: Docker Build
  id: action-step
  uses: ivuorinen/actions/docker-build@vYYYY.MM.DD

- name: Use Output
  run: |
    echo "build-time: \${{ steps.action-step.outputs.build-time }}"
    echo "image-digest: \${{ steps.action-step.outputs.image-digest }}"
    echo "metadata: \${{ steps.action-step.outputs.metadata }}"
    echo "platform-matrix: \${{ steps.action-step.outputs.platform-matrix }}"
    echo "platforms: \${{ steps.action-step.outputs.platforms }}"
    echo "sbom-location: \${{ steps.action-step.outputs.sbom-location }}"
    echo "scan-results: \${{ steps.action-step.outputs.scan-results }}"
    echo "signature: \${{ steps.action-step.outputs.signature }}"
```

## Examples

### Basic Usage

```yaml
- name: Basic Docker Build
  uses: ivuorinen/actions/docker-build@vYYYY.MM.DD
  with:
    architectures: 'linux/amd64,linux/arm64,linux/arm/v7,linux/arm/v6'
    auto-detect-platforms: 'false'
    build-args: 'example-value'
    build-contexts: 'example-value'
    buildkit-version: 'v0.11.0'
    buildx-version: 'latest'
    cache-export: 'example-value'
    cache-from: 'example-value'
    cache-import: 'example-value'
    cache-mode: 'max'
    context: '.'
    dockerfile: 'Dockerfile'
    dry-run: 'false'
    image-name: 'example-value'
    max-retries: '3'
    network: 'default'
    parallel-builds: '0'
    platform-build-args: 'example-value'
    platform-fallback: 'true'
    push: 'true'
    sbom-format: 'spdx-json'
    scan-image: 'false'
    secrets: 'example-value'
    sign-image: 'false'
    tag: 'example-value'
    token: 'example-value'
    verbose: 'false'
```

### Advanced Configuration

```yaml
- name: Advanced Docker Build
  uses: ivuorinen/actions/docker-build@vYYYY.MM.DD
  with:
    architectures: "linux/amd64,linux/arm64,linux/arm/v7,linux/arm/v6"
    auto-detect-platforms: "false"
    build-args: "\${{ vars.BUILD-ARGS }}"
    build-contexts: "\${{ vars.BUILD-CONTEXTS }}"
    buildkit-version: "v0.11.0"
    buildx-version: "latest"
    cache-export: "\${{ vars.CACHE-EXPORT }}"
    cache-from: "\${{ vars.CACHE-FROM }}"
    cache-import: "\${{ vars.CACHE-IMPORT }}"
    cache-mode: "max"
    context: "."
    dockerfile: "Dockerfile"
    dry-run: "false"
    image-name: "\${{ vars.IMAGE-NAME }}"
    max-retries: "3"
    network: "default"
    parallel-builds: "0"
    platform-build-args: "\${{ vars.PLATFORM-BUILD-ARGS }}"
    platform-fallback: "true"
    push: "true"
    sbom-format: "spdx-json"
    scan-image: "false"
    secrets: "\${{ vars.SECRETS }}"
    sign-image: "false"
    tag: "\${{ vars.TAG }}"
    token: "\${{ vars.TOKEN }}"
    verbose: "false"
  env:
    GITHUB_TOKEN: \${{ secrets.GITHUB_TOKEN }}
```

### Conditional Usage

```yaml
- name: Conditional Docker Build
  if: github.event_name == 'push'
  uses: ivuorinen/actions/docker-build@vYYYY.MM.DD
  with:
    architectures: 'linux/amd64,linux/arm64,linux/arm/v7,linux/arm/v6'
    auto-detect-platforms: 'false'
    build-args: 'production-value'
    build-contexts: 'production-value'
    buildkit-version: 'v0.11.0'
    buildx-version: 'latest'
    cache-export: 'production-value'
    cache-from: 'production-value'
    cache-import: 'production-value'
    cache-mode: 'max'
    context: '.'
    dockerfile: 'Dockerfile'
    dry-run: 'false'
    image-name: 'production-value'
    max-retries: '3'
    network: 'default'
    parallel-builds: '0'
    platform-build-args: 'production-value'
    platform-fallback: 'true'
    push: 'true'
    sbom-format: 'spdx-json'
    scan-image: 'false'
    secrets: 'production-value'
    sign-image: 'false'
    tag: 'production-value'
    token: 'production-value'
    verbose: 'false'
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
