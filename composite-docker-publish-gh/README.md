# ivuorinen/actions/composite-docker-publish-gh

## Docker Publish to GitHub Packages

### Description

Publishes a Docker image to GitHub Packages.

### Inputs

| name         | description                                                                      | required | default |
| ------------ | -------------------------------------------------------------------------------- | -------- | ------- |
| `image-name` | <p>The name of the Docker image to publish. Defaults to the repository name.</p> | `false`  | `""`    |
| `tags`       | <p>Comma-separated list of tags for the Docker image.</p>                        | `true`   | `""`    |

### Runs

This action is a `composite` action.

### Usage

```yaml
- uses: ivuorinen/actions/composite-docker-publish-gh@main
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
