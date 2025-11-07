# ivuorinen/actions/docker-build

## Docker Build

### Description

Builds a Docker image for multiple architectures with enhanced security and reliability.

### Inputs

| name                    | description                                                                         | required | default                                             |
|-------------------------|-------------------------------------------------------------------------------------|----------|-----------------------------------------------------|
| `image-name`            | <p>The name of the Docker image to build. Defaults to the repository name.</p>      | `false`  | `""`                                                |
| `tag`                   | <p>The tag for the Docker image. Must follow semver or valid Docker tag format.</p> | `true`   | `""`                                                |
| `architectures`         | <p>Comma-separated list of architectures to build for.</p>                          | `false`  | `linux/amd64,linux/arm64,linux/arm/v7,linux/arm/v6` |
| `dockerfile`            | <p>Path to the Dockerfile</p>                                                       | `false`  | `Dockerfile`                                        |
| `context`               | <p>Docker build context</p>                                                         | `false`  | `.`                                                 |
| `build-args`            | <p>Build arguments in format KEY=VALUE,KEY2=VALUE2</p>                              | `false`  | `""`                                                |
| `cache-from`            | <p>External cache sources (e.g., type=registry,ref=user/app:cache)</p>              | `false`  | `""`                                                |
| `push`                  | <p>Whether to push the image after building</p>                                     | `false`  | `true`                                              |
| `max-retries`           | <p>Maximum number of retry attempts for build and push operations</p>               | `false`  | `3`                                                 |
| `token`                 | <p>GitHub token for authentication</p>                                              | `false`  | `""`                                                |
| `buildx-version`        | <p>Specific Docker Buildx version to use</p>                                        | `false`  | `latest`                                            |
| `buildkit-version`      | <p>Specific BuildKit version to use</p>                                             | `false`  | `v0.11.0`                                           |
| `cache-mode`            | <p>Cache mode for build layers (min, max, or inline)</p>                            | `false`  | `max`                                               |
| `build-contexts`        | <p>Additional build contexts in format name=path,name2=path2</p>                    | `false`  | `""`                                                |
| `network`               | <p>Network mode for build (host, none, or default)</p>                              | `false`  | `default`                                           |
| `secrets`               | <p>Build secrets in format id=path,id2=path2</p>                                    | `false`  | `""`                                                |
| `auto-detect-platforms` | <p>Automatically detect and build for all available platforms</p>                   | `false`  | `false`                                             |
| `platform-build-args`   | <p>Platform-specific build args in JSON format</p>                                  | `false`  | `""`                                                |
| `parallel-builds`       | <p>Number of parallel platform builds (0 for auto)</p>                              | `false`  | `0`                                                 |
| `cache-export`          | <p>Export cache destination (e.g., type=local,dest=/tmp/cache)</p>                  | `false`  | `""`                                                |
| `cache-import`          | <p>Import cache sources (e.g., type=local,src=/tmp/cache)</p>                       | `false`  | `""`                                                |
| `dry-run`               | <p>Perform a dry run without actually building</p>                                  | `false`  | `false`                                             |
| `verbose`               | <p>Enable verbose logging with platform-specific output</p>                         | `false`  | `false`                                             |
| `platform-fallback`     | <p>Continue building other platforms if one fails</p>                               | `false`  | `true`                                              |
| `scan-image`            | <p>Scan built image for vulnerabilities</p>                                         | `false`  | `false`                                             |
| `sign-image`            | <p>Sign the built image with cosign</p>                                             | `false`  | `false`                                             |
| `sbom-format`           | <p>SBOM format (spdx-json, cyclonedx-json, or syft-json)</p>                        | `false`  | `spdx-json`                                         |

### Outputs

| name              | description                                           |
|-------------------|-------------------------------------------------------|
| `image-digest`    | <p>The digest of the built image</p>                  |
| `metadata`        | <p>Build metadata in JSON format</p>                  |
| `platforms`       | <p>Successfully built platforms</p>                   |
| `platform-matrix` | <p>Build status per platform in JSON format</p>       |
| `build-time`      | <p>Total build time in seconds</p>                    |
| `scan-results`    | <p>Vulnerability scan results if scanning enabled</p> |
| `signature`       | <p>Image signature if signing enabled</p>             |
| `sbom-location`   | <p>SBOM document location</p>                         |

### Runs

This action is a `composite` action.

### Usage

```yaml
- uses: ivuorinen/actions/docker-build@main
  with:
    image-name:
    # The name of the Docker image to build. Defaults to the repository name.
    #
    # Required: false
    # Default: ""

    tag:
    # The tag for the Docker image. Must follow semver or valid Docker tag format.
    #
    # Required: true
    # Default: ""

    architectures:
    # Comma-separated list of architectures to build for.
    #
    # Required: false
    # Default: linux/amd64,linux/arm64,linux/arm/v7,linux/arm/v6

    dockerfile:
    # Path to the Dockerfile
    #
    # Required: false
    # Default: Dockerfile

    context:
    # Docker build context
    #
    # Required: false
    # Default: .

    build-args:
    # Build arguments in format KEY=VALUE,KEY2=VALUE2
    #
    # Required: false
    # Default: ""

    cache-from:
    # External cache sources (e.g., type=registry,ref=user/app:cache)
    #
    # Required: false
    # Default: ""

    push:
    # Whether to push the image after building
    #
    # Required: false
    # Default: true

    max-retries:
    # Maximum number of retry attempts for build and push operations
    #
    # Required: false
    # Default: 3

    token:
    # GitHub token for authentication
    #
    # Required: false
    # Default: ""

    buildx-version:
    # Specific Docker Buildx version to use
    #
    # Required: false
    # Default: latest

    buildkit-version:
    # Specific BuildKit version to use
    #
    # Required: false
    # Default: v0.11.0

    cache-mode:
    # Cache mode for build layers (min, max, or inline)
    #
    # Required: false
    # Default: max

    build-contexts:
    # Additional build contexts in format name=path,name2=path2
    #
    # Required: false
    # Default: ""

    network:
    # Network mode for build (host, none, or default)
    #
    # Required: false
    # Default: default

    secrets:
    # Build secrets in format id=path,id2=path2
    #
    # Required: false
    # Default: ""

    auto-detect-platforms:
    # Automatically detect and build for all available platforms
    #
    # Required: false
    # Default: false

    platform-build-args:
    # Platform-specific build args in JSON format
    #
    # Required: false
    # Default: ""

    parallel-builds:
    # Number of parallel platform builds (0 for auto)
    #
    # Required: false
    # Default: 0

    cache-export:
    # Export cache destination (e.g., type=local,dest=/tmp/cache)
    #
    # Required: false
    # Default: ""

    cache-import:
    # Import cache sources (e.g., type=local,src=/tmp/cache)
    #
    # Required: false
    # Default: ""

    dry-run:
    # Perform a dry run without actually building
    #
    # Required: false
    # Default: false

    verbose:
    # Enable verbose logging with platform-specific output
    #
    # Required: false
    # Default: false

    platform-fallback:
    # Continue building other platforms if one fails
    #
    # Required: false
    # Default: true

    scan-image:
    # Scan built image for vulnerabilities
    #
    # Required: false
    # Default: false

    sign-image:
    # Sign the built image with cosign
    #
    # Required: false
    # Default: false

    sbom-format:
    # SBOM format (spdx-json, cyclonedx-json, or syft-json)
    #
    # Required: false
    # Default: spdx-json
```
