# ivuorinen/actions/docker-build

## Docker Build

### Description

Builds a Docker image for multiple architectures with enhanced security and reliability.

### Inputs

| name            | description                                                                         | required | default                                             |
| --------------- | ----------------------------------------------------------------------------------- | -------- | --------------------------------------------------- |
| `image-name`    | <p>The name of the Docker image to build. Defaults to the repository name.</p>      | `false`  | `""`                                                |
| `tag`           | <p>The tag for the Docker image. Must follow semver or valid Docker tag format.</p> | `true`   | `""`                                                |
| `architectures` | <p>Comma-separated list of architectures to build for.</p>                          | `false`  | `linux/amd64,linux/arm64,linux/arm/v7,linux/arm/v6` |
| `dockerfile`    | <p>Path to the Dockerfile</p>                                                       | `false`  | `Dockerfile`                                        |
| `context`       | <p>Docker build context</p>                                                         | `false`  | `.`                                                 |
| `build-args`    | <p>Build arguments in format KEY=VALUE,KEY2=VALUE2</p>                              | `false`  | `""`                                                |
| `cache-from`    | <p>External cache sources (e.g., type=registry,ref=user/app:cache)</p>              | `false`  | `""`                                                |
| `push`          | <p>Whether to push the image after building</p>                                     | `false`  | `true`                                              |
| `max-retries`   | <p>Maximum number of retry attempts for build and push operations</p>               | `false`  | `3`                                                 |

### Outputs

| name           | description                          |
| -------------- | ------------------------------------ |
| `image-digest` | <p>The digest of the built image</p> |
| `metadata`     | <p>Build metadata in JSON format</p> |
| `platforms`    | <p>Successfully built platforms</p>  |

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
```
