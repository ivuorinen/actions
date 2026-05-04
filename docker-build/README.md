# ivuorinen/actions/docker-build

## Description

Builds a Docker image for multiple architectures with enhanced security and reliability.

## Inputs

| parameter             | description                                                                  | required | default                                           |
|-----------------------|------------------------------------------------------------------------------|----------|---------------------------------------------------|
| image-name            | The name of the Docker image to build. Defaults to the repository name.      | `false`  |                                                   |
| tag                   | The tag for the Docker image. Must follow semver or valid Docker tag format. | `true`   |                                                   |
| architectures         | Comma-separated list of architectures to build for.                          | `false`  | linux/amd64,linux/arm64,linux/arm/v7,linux/arm/v6 |
| dockerfile            | Path to the Dockerfile                                                       | `false`  | Dockerfile                                        |
| context               | Docker build context                                                         | `false`  | .                                                 |
| build-args            | Build arguments in format KEY=VALUE,KEY2=VALUE2                              | `false`  |                                                   |
| cache-from            | External cache sources (e.g., type=registry,ref=user/app:cache)              | `false`  |                                                   |
| push                  | Whether to push the image after building                                     | `false`  | true                                              |
| max-retries           | Maximum number of retry attempts for build and push operations               | `false`  | 3                                                 |
| token                 | GitHub token for authentication                                              | `false`  |                                                   |
| buildx-version        | Specific Docker Buildx version to use                                        | `false`  | latest                                            |
| buildkit-version      | Specific BuildKit version to use                                             | `false`  | v0.11.0                                           |
| cache-mode            | Cache mode for build layers (min, max, or inline)                            | `false`  | max                                               |
| build-contexts        | Additional build contexts in format name=path,name2=path2                    | `false`  |                                                   |
| network               | Network mode for build (host, none, or default)                              | `false`  | default                                           |
| secrets               | Build secrets in format id=path,id2=path2                                    | `false`  |                                                   |
| auto-detect-platforms | Automatically detect and build for all available platforms                   | `false`  | false                                             |
| platform-build-args   | Platform-specific build args in JSON format                                  | `false`  |                                                   |
| parallel-builds       | Number of parallel platform builds (0 for auto)                              | `false`  | 0                                                 |
| cache-export          | Export cache destination (e.g., type=local,dest=/tmp/cache)                  | `false`  |                                                   |
| cache-import          | Import cache sources (e.g., type=local,src=/tmp/cache)                       | `false`  |                                                   |
| dry-run               | Perform a dry run without actually building                                  | `false`  | false                                             |
| verbose               | Enable verbose logging with platform-specific output                         | `false`  | false                                             |
| platform-fallback     | Continue building other platforms if one fails                               | `false`  | true                                              |
| scan-image            | Scan built image for vulnerabilities                                         | `false`  | false                                             |
| sign-image            | Sign the built image with cosign                                             | `false`  | false                                             |
| sbom-format           | SBOM format (spdx-json, cyclonedx-json, or syft-json)                        | `false`  | spdx-json                                         |

## Outputs

| parameter       | description                                    |
|-----------------|------------------------------------------------|
| image-digest    | The digest of the built image                  |
| metadata        | Build metadata in JSON format                  |
| platforms       | Successfully built platforms                   |
| platform-matrix | Build status per platform in JSON format       |
| build-time      | Total build time in seconds                    |
| scan-results    | Vulnerability scan results if scanning enabled |
| signature       | Image signature if signing enabled             |
| sbom-location   | SBOM document location                         |

## Runs

This action is a `composite` action.
