# ivuorinen/actions/composite-docker-build

## Docker Build

### Description

Builds a Docker image for multiple architectures.

### Inputs

| name            | description                                                                          | required | default                                             |
| --------------- | ------------------------------------------------------------------------------------ | -------- | --------------------------------------------------- |
| `image-name`    | <p>The name of the Docker image to build. Defaults to the repository name.</p>       | `false`  | `""`                                                |
| `tag`           | <p>The tag for the Docker image.</p>                                                 | `true`   | `""`                                                |
| `architectures` | <p>List of architectures to build for. Defaults to amd64, arm64, arm/v7, arm/v6.</p> | `false`  | `linux/amd64,linux/arm64,linux/arm/v7,linux/arm/v6` |

### Runs

This action is a `composite` action.

### Usage

```yaml
- uses: ivuorinen/actions/composite-docker-build@main
  with:
      image-name:
      # The name of the Docker image to build. Defaults to the repository name.
      #
      # Required: false
      # Default: ""

      tag:
      # The tag for the Docker image.
      #
      # Required: true
      # Default: ""

      architectures:
      # List of architectures to build for. Defaults to amd64, arm64, arm/v7, arm/v6.
      #
      # Required: false
      # Default: linux/amd64,linux/arm64,linux/arm/v7,linux/arm/v6
```
