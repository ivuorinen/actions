# ivuorinen/actions/composite-docker-publish-hub

## Docker Publish to Docker Hub

### Description

Publishes a Docker image to Docker Hub.

### Inputs

| name         | description                                                                      | required | default |
| ------------ | -------------------------------------------------------------------------------- | -------- | ------- |
| `image-name` | <p>The name of the Docker image to publish. Defaults to the repository name.</p> | `false`  | `""`    |
| `tags`       | <p>Comma-separated list of tags for the Docker image.</p>                        | `true`   | `""`    |

### Runs

This action is a `composite` action.

### Usage

```yaml
- uses: ivuorinen/actions/composite-docker-publish-hub@main
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
```
