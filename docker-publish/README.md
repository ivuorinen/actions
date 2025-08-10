# ivuorinen/actions/docker-publish

## Docker Publish

### Description

Publish a Docker image to GitHub Packages and Docker Hub.

### Inputs

| name                    | description                                                       | required | default                                |
|-------------------------|-------------------------------------------------------------------|----------|----------------------------------------|
| `registry`              | <p>Registry to publish to (dockerhub, github, or both).</p>       | `true`   | `both`                                 |
| `nightly`               | <p>Is this a nightly build? (true or false)</p>                   | `false`  | `false`                                |
| `platforms`             | <p>Platforms to build for (comma-separated)</p>                   | `false`  | `linux/amd64,linux/arm64,linux/arm/v7` |
| `auto-detect-platforms` | <p>Automatically detect and build for all available platforms</p> | `false`  | `false`                                |
| `scan-image`            | <p>Scan images for vulnerabilities</p>                            | `false`  | `true`                                 |
| `sign-image`            | <p>Sign images with cosign</p>                                    | `false`  | `false`                                |
| `cache-mode`            | <p>Cache mode for build layers (min, max, or inline)</p>          | `false`  | `max`                                  |
| `buildx-version`        | <p>Specific Docker Buildx version to use</p>                      | `false`  | `latest`                               |
| `verbose`               | <p>Enable verbose logging</p>                                     | `false`  | `false`                                |

### Outputs

| name              | description                                           |
|-------------------|-------------------------------------------------------|
| `registry`        | <p>Registry where image was published</p>             |
| `tags`            | <p>Tags that were published</p>                       |
| `build-time`      | <p>Total build time in seconds</p>                    |
| `platform-matrix` | <p>Build status per platform</p>                      |
| `scan-results`    | <p>Vulnerability scan results if scanning enabled</p> |

### Runs

This action is a `composite` action.

### Usage

```yaml
- uses: ivuorinen/actions/docker-publish@main
  with:
    registry:
    # Registry to publish to (dockerhub, github, or both).
    #
    # Required: true
    # Default: both

    nightly:
    # Is this a nightly build? (true or false)
    #
    # Required: false
    # Default: false

    platforms:
    # Platforms to build for (comma-separated)
    #
    # Required: false
    # Default: linux/amd64,linux/arm64,linux/arm/v7

    auto-detect-platforms:
    # Automatically detect and build for all available platforms
    #
    # Required: false
    # Default: false

    scan-image:
    # Scan images for vulnerabilities
    #
    # Required: false
    # Default: true

    sign-image:
    # Sign images with cosign
    #
    # Required: false
    # Default: false

    cache-mode:
    # Cache mode for build layers (min, max, or inline)
    #
    # Required: false
    # Default: max

    buildx-version:
    # Specific Docker Buildx version to use
    #
    # Required: false
    # Default: latest

    verbose:
    # Enable verbose logging
    #
    # Required: false
    # Default: false
```
