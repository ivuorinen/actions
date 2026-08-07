# Docker Build

![package](https://img.shields.io/badge/icon-package-blue) ![GitHub](<https://img.shields.io/badge/GitHub%20Action-> -blue) ![License](https://img.shields.io/badge/license-MIT-green)

> Builds a Docker image for multiple architectures with enhanced security and reliability.

## 🚀 Quick Start

```yaml
name: My Workflow
on: [push]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@11d5960a326750d5838078e36cf38b85af677262 # v4
      - name: Docker Build
        uses: ivuorinen/actions/docker-build@vYYYY.MM.DD
        with:
          architectures: 'linux/amd64,linux/arm64,linux/arm/v7,linux/arm/v6'
          auto-detect-platforms: 'false'
          build-args: 'value'
          build-contexts: 'value'
          buildkit-version: 'v0.11.0'
          buildx-version: 'latest'
          cache-export: 'value'
          cache-from: 'value'
          cache-import: 'value'
          cache-mode: 'max'
          context: '.'
          dockerfile: 'Dockerfile'
          dry-run: 'false'
          image-name: 'value'
          max-retries: '3'
          network: 'default'
          parallel-builds: '0'
          platform-build-args: 'value'
          platform-fallback: 'true'
          push: 'true'
          sbom-format: 'spdx-json'
          scan-image: 'false'
          secrets: 'value'
          sign-image: 'false'
          tag: 'value'
          token: '${{ github.token }}'
          verbose: 'false'
```

## 📥 Inputs

| Parameter               | Description                                                                  | Required | Default                                             |
|-------------------------|------------------------------------------------------------------------------|----------|-----------------------------------------------------|
| `architectures`         | Comma-separated list of architectures to build for.                          | ❌        | `linux/amd64,linux/arm64,linux/arm/v7,linux/arm/v6` |
| `auto-detect-platforms` | Automatically detect and build for all available platforms                   | ❌        | `false`                                             |
| `build-args`            | Build arguments in format KEY=VALUE,KEY2=VALUE2                              | ❌        | -                                                   |
| `build-contexts`        | Additional build contexts in format name=path,name2=path2                    | ❌        | -                                                   |
| `buildkit-version`      | Specific BuildKit version to use                                             | ❌        | `v0.11.0`                                           |
| `buildx-version`        | Specific Docker Buildx version to use                                        | ❌        | `latest`                                            |
| `cache-export`          | Export cache destination (e.g., type=local,dest=/tmp/cache)                  | ❌        | -                                                   |
| `cache-from`            | External cache sources (e.g., type=registry,ref=user/app:cache)              | ❌        | -                                                   |
| `cache-import`          | Import cache sources (e.g., type=local,src=/tmp/cache)                       | ❌        | -                                                   |
| `cache-mode`            | Cache mode for build layers (min, max, or inline)                            | ❌        | `max`                                               |
| `context`               | Docker build context                                                         | ❌        | `.`                                                 |
| `dockerfile`            | Path to the Dockerfile                                                       | ❌        | `Dockerfile`                                        |
| `dry-run`               | Perform a dry run without actually building                                  | ❌        | `false`                                             |
| `image-name`            | The name of the Docker image to build. Defaults to the repository name.      | ❌        | -                                                   |
| `max-retries`           | Maximum number of retry attempts for build and push operations               | ❌        | `3`                                                 |
| `network`               | Network mode for build (host, none, or default)                              | ❌        | `default`                                           |
| `parallel-builds`       | Number of parallel platform builds (0 for auto)                              | ❌        | `0`                                                 |
| `platform-build-args`   | Platform-specific build args in JSON format                                  | ❌        | -                                                   |
| `platform-fallback`     | Continue building other platforms if one fails                               | ❌        | `true`                                              |
| `push`                  | Whether to push the image after building                                     | ❌        | `true`                                              |
| `sbom-format`           | SBOM format (spdx-json, cyclonedx-json, or syft-json)                        | ❌        | `spdx-json`                                         |
| `scan-image`            | Scan built image for vulnerabilities                                         | ❌        | `false`                                             |
| `secrets`               | Build secrets in format id=path,id2=path2                                    | ❌        | -                                                   |
| `sign-image`            | Sign the built image with cosign                                             | ❌        | `false`                                             |
| `tag`                   | The tag for the Docker image. Must follow semver or valid Docker tag format. | ✅        | -                                                   |
| `token`                 | GitHub token for authentication                                              | ❌        | -                                                   |
| `verbose`               | Enable verbose logging with platform-specific output                         | ❌        | `false`                                             |

## 📤 Outputs

| Parameter         | Description                                    |
|-------------------|------------------------------------------------|
| `build-time`      | Total build time in seconds                    |
| `image-digest`    | The digest of the built image                  |
| `metadata`        | Build metadata in JSON format                  |
| `platform-matrix` | Build status per platform in JSON format       |
| `platforms`       | Successfully built platforms                   |
| `sbom-location`   | SBOM document location                         |
| `scan-results`    | Vulnerability scan results if scanning enabled |
| `signature`       | Image signature if signing enabled             |

## 💡 Examples

<details>
<summary>Basic Usage</summary>

```yaml
- name: Docker Build
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
    token: '${{ github.token }}'
    verbose: 'false'
```

</details>

<details>
<summary>Advanced Configuration</summary>

```yaml
- name: Docker Build with custom settings
  uses: ivuorinen/actions/docker-build@vYYYY.MM.DD
  with:
    architectures: 'linux/amd64,linux/arm64,linux/arm/v7,linux/arm/v6'
    auto-detect-platforms: 'false'
    build-args: 'custom-value'
    build-contexts: 'custom-value'
    buildkit-version: 'v0.11.0'
    buildx-version: 'latest'
    cache-export: 'custom-value'
    cache-from: 'custom-value'
    cache-import: 'custom-value'
    cache-mode: 'max'
    context: '.'
    dockerfile: 'Dockerfile'
    dry-run: 'false'
    image-name: 'custom-value'
    max-retries: '3'
    network: 'default'
    parallel-builds: '0'
    platform-build-args: 'custom-value'
    platform-fallback: 'true'
    push: 'true'
    sbom-format: 'spdx-json'
    scan-image: 'false'
    secrets: 'custom-value'
    sign-image: 'false'
    tag: 'custom-value'
    token: '${{ github.token }}'
    verbose: 'false'
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
