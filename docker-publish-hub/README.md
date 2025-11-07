# ivuorinen/actions/docker-publish-hub

## Docker Publish to Docker Hub

### Description

Publishes a Docker image to Docker Hub with enhanced security and reliability features.

### Inputs

| name                     | description                                                                      | required | default                   |
| ------------------------ | -------------------------------------------------------------------------------- | -------- | ------------------------- |
| `image-name`             | <p>The name of the Docker image to publish. Defaults to the repository name.</p> | `false`  | `""`                      |
| `tags`                   | <p>Comma-separated list of tags for the Docker image.</p>                        | `true`   | `""`                      |
| `platforms`              | <p>Platforms to publish (comma-separated). Defaults to amd64 and arm64.</p>      | `false`  | `linux/amd64,linux/arm64` |
| `username`               | <p>Docker Hub username</p>                                                       | `true`   | `""`                      |
| `password`               | <p>Docker Hub password or access token</p>                                       | `true`   | `""`                      |
| `repository-description` | <p>Update Docker Hub repository description</p>                                  | `false`  | `""`                      |
| `readme-file`            | <p>Path to README file to update on Docker Hub</p>                               | `false`  | `README.md`               |
| `provenance`             | <p>Enable SLSA provenance generation</p>                                         | `false`  | `true`                    |
| `sbom`                   | <p>Generate Software Bill of Materials</p>                                       | `false`  | `true`                    |
| `max-retries`            | <p>Maximum number of retry attempts for publishing</p>                           | `false`  | `3`                       |
| `retry-delay`            | <p>Delay in seconds between retries</p>                                          | `false`  | `10`                      |
| `buildx-version`         | <p>Specific Docker Buildx version to use</p>                                     | `false`  | `latest`                  |
| `cache-mode`             | <p>Cache mode for build layers (min, max, or inline)</p>                         | `false`  | `max`                     |
| `auto-detect-platforms`  | <p>Automatically detect and build for all available platforms</p>                | `false`  | `false`                   |
| `scan-image`             | <p>Scan published image for vulnerabilities</p>                                  | `false`  | `true`                    |
| `sign-image`             | <p>Sign the published image with cosign</p>                                      | `false`  | `false`                   |
| `verbose`                | <p>Enable verbose logging</p>                                                    | `false`  | `false`                   |

### Outputs

| name              | description                               |
| ----------------- | ----------------------------------------- |
| `image-name`      | <p>Full image name including registry</p> |
| `digest`          | <p>The digest of the published image</p>  |
| `tags`            | <p>List of published tags</p>             |
| `repo-url`        | <p>Docker Hub repository URL</p>          |
| `scan-results`    | <p>Vulnerability scan results</p>         |
| `platform-matrix` | <p>Build status per platform</p>          |
| `build-time`      | <p>Total build time in seconds</p>        |
| `signature`       | <p>Image signature if signing enabled</p> |

### Runs

This action is a `composite` action.

### Usage

```yaml
- uses: ivuorinen/actions/docker-publish-hub@main
  with:
    image-name:
    # The name of the Docker image to publish. Defaults to the repository name.
    #
    # Required: false
    # Default: ""

    tags:
    # Comma-separated list of tags for the Docker image.
    #
    # Required: true
    # Default: ""

    platforms:
    # Platforms to publish (comma-separated). Defaults to amd64 and arm64.
    #
    # Required: false
    # Default: linux/amd64,linux/arm64

    username:
    # Docker Hub username
    #
    # Required: true
    # Default: ""

    password:
    # Docker Hub password or access token
    #
    # Required: true
    # Default: ""

    repository-description:
    # Update Docker Hub repository description
    #
    # Required: false
    # Default: ""

    readme-file:
    # Path to README file to update on Docker Hub
    #
    # Required: false
    # Default: README.md

    provenance:
    # Enable SLSA provenance generation
    #
    # Required: false
    # Default: true

    sbom:
    # Generate Software Bill of Materials
    #
    # Required: false
    # Default: true

    max-retries:
    # Maximum number of retry attempts for publishing
    #
    # Required: false
    # Default: 3

    retry-delay:
    # Delay in seconds between retries
    #
    # Required: false
    # Default: 10

    buildx-version:
    # Specific Docker Buildx version to use
    #
    # Required: false
    # Default: latest

    cache-mode:
    # Cache mode for build layers (min, max, or inline)
    #
    # Required: false
    # Default: max

    auto-detect-platforms:
    # Automatically detect and build for all available platforms
    #
    # Required: false
    # Default: false

    scan-image:
    # Scan published image for vulnerabilities
    #
    # Required: false
    # Default: true

    sign-image:
    # Sign the published image with cosign
    #
    # Required: false
    # Default: false

    verbose:
    # Enable verbose logging
    #
    # Required: false
    # Default: false
```
