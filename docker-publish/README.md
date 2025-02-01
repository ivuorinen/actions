# ivuorinen/actions/docker-publish

## Docker Publish

### Description

Publish a Docker image to GitHub Packages and Docker Hub.

### Inputs

| name       | description                                                 | required | default |
| ---------- | ----------------------------------------------------------- | -------- | ------- |
| `registry` | <p>Registry to publish to (dockerhub, github, or both).</p> | `true`   | `both`  |
| `nightly`  | <p>Is this a nightly build?</p>                             | `false`  | `""`    |

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
    # Is this a nightly build?
    #
    # Required: false
    # Default: ""
```
