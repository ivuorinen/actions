# ivuorinen/actions/docker-publish

## Docker Publish

### Description

Simple wrapper to publish Docker images to GitHub Packages and/or Docker Hub

### Security Considerations

**Trust Model**: This action should only be used in trusted workflows controlled by repository owners.
Do not pass untrusted user input (e.g., PR labels, comments, external webhooks) to the `context`
or `dockerfile` parameters.

**Input Validation**: The action validates `context` and `dockerfile` inputs to prevent code injection attacks:

- **`context`**: Must be a relative path (e.g., `.`, `./app`, `subdir/`). Absolute paths are rejected. Remote URLs trigger a warning and should only be used from trusted sources.
- **`dockerfile`**: Must be a relative path (e.g., `Dockerfile`, `./docker/Dockerfile`). Absolute paths and URLs are rejected.

These validations help prevent malicious actors from:

- Building Docker images from arbitrary file system locations
- Fetching malicious Dockerfiles from untrusted remote sources
- Executing code injection attacks through build context manipulation

**Best Practices**:

1. Only use hard-coded values or trusted workflow variables for `context` and `dockerfile`
2. Never accept these values from PR comments, labels, or external webhooks
3. Review workflow permissions before granting write access to this action
4. Use SHA-pinned action references: `ivuorinen/actions/docker-publish@<commit-sha>`

### Inputs

| name                 | description                                                       | required | default                   |
|----------------------|-------------------------------------------------------------------|----------|---------------------------|
| `registry`           | <p>Registry to publish to (dockerhub, github, or both)</p>        | `false`  | `both`                    |
| `image-name`         | <p>Docker image name (defaults to repository name)</p>            | `false`  | `""`                      |
| `tags`               | <p>Comma-separated list of tags (e.g., latest,v1.0.0)</p>         | `false`  | `latest`                  |
| `platforms`          | <p>Platforms to build for (comma-separated)</p>                   | `false`  | `linux/amd64,linux/arm64` |
| `context`            | <p>Build context path</p>                                         | `false`  | `.`                       |
| `dockerfile`         | <p>Path to Dockerfile</p>                                         | `false`  | `Dockerfile`              |
| `build-args`         | <p>Build arguments (newline-separated KEY=VALUE pairs)</p>        | `false`  | `""`                      |
| `push`               | <p>Whether to push the image</p>                                  | `false`  | `true`                    |
| `token`              | <p>GitHub token for authentication (for GitHub registry)</p>      | `false`  | `""`                      |
| `dockerhub-username` | <p>Docker Hub username (required if publishing to Docker Hub)</p> | `false`  | `""`                      |
| `dockerhub-token`    | <p>Docker Hub token (required if publishing to Docker Hub)</p>    | `false`  | `""`                      |

### Outputs

| name         | description                          |
|--------------|--------------------------------------|
| `image-name` | <p>Full image name with registry</p> |
| `tags`       | <p>Tags that were published</p>      |
| `digest`     | <p>Image digest</p>                  |
| `metadata`   | <p>Build metadata</p>                |

### Runs

This action is a `composite` action.

### Usage

```yaml
- uses: ivuorinen/actions/docker-publish@main
  with:
    registry:
    # Registry to publish to (dockerhub, github, or both)
    #
    # Required: false
    # Default: both

    image-name:
    # Docker image name (defaults to repository name)
    #
    # Required: false
    # Default: ""

    tags:
    # Comma-separated list of tags (e.g., latest,v1.0.0)
    #
    # Required: false
    # Default: latest

    platforms:
    # Platforms to build for (comma-separated)
    #
    # Required: false
    # Default: linux/amd64,linux/arm64

    context:
    # Build context path
    #
    # Required: false
    # Default: .

    dockerfile:
    # Path to Dockerfile
    #
    # Required: false
    # Default: Dockerfile

    build-args:
    # Build arguments (newline-separated KEY=VALUE pairs)
    #
    # Required: false
    # Default: ""

    push:
    # Whether to push the image
    #
    # Required: false
    # Default: true

    token:
    # GitHub token for authentication (for GitHub registry)
    #
    # Required: false
    # Default: ""

    dockerhub-username:
    # Docker Hub username (required if publishing to Docker Hub)
    #
    # Required: false
    # Default: ""

    dockerhub-token:
    # Docker Hub token (required if publishing to Docker Hub)
    #
    # Required: false
    # Default: ""
```
