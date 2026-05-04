# ivuorinen/actions/docker-publish

## Description

Simple wrapper to publish Docker images to GitHub Packages and/or Docker Hub

## Inputs

| parameter          | description                                                | required | default                 |
|--------------------|------------------------------------------------------------|----------|-------------------------|
| registry           | Registry to publish to (dockerhub, github, or both)        | `false`  | both                    |
| image-name         | Docker image name (defaults to repository name)            | `false`  |                         |
| tags               | Comma-separated list of tags (e.g., latest,v1.0.0)         | `false`  | latest                  |
| platforms          | Platforms to build for (comma-separated)                   | `false`  | linux/amd64,linux/arm64 |
| context            | Build context path                                         | `false`  | .                       |
| dockerfile         | Path to Dockerfile                                         | `false`  | Dockerfile              |
| build-args         | Build arguments (newline-separated KEY=VALUE pairs)        | `false`  |                         |
| push               | Whether to push the image                                  | `false`  | true                    |
| token              | GitHub token for authentication (for GitHub registry)      | `false`  |                         |
| dockerhub-username | Docker Hub username (required if publishing to Docker Hub) | `false`  |                         |
| dockerhub-token    | Docker Hub token (required if publishing to Docker Hub)    | `false`  |                         |

## Outputs

| parameter  | description                   |
|------------|-------------------------------|
| image-name | Full image name with registry |
| tags       | Tags that were published      |
| digest     | Image digest                  |
| metadata   | Build metadata                |

## Runs

This action is a `composite` action.
