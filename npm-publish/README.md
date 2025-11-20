# ivuorinen/actions/npm-publish

## Publish to NPM

### Description

Publishes the package to the NPM registry with configurable scope and registry URL.

### Inputs

| name              | description                            | required | default                                |
|-------------------|----------------------------------------|----------|----------------------------------------|
| `npm_token`       | <p>NPM token.</p>                      | `true`   | `""`                                   |
| `registry-url`    | <p>Registry URL for publishing.</p>    | `false`  | `https://registry.npmjs.org/`          |
| `scope`           | <p>Package scope to use.</p>           | `false`  | `@ivuorinen`                           |
| `package-version` | <p>The version to publish.</p>         | `false`  | `${{ github.event.release.tag_name }}` |
| `token`           | <p>GitHub token for authentication</p> | `false`  | `""`                                   |

### Outputs

| name              | description                         |
|-------------------|-------------------------------------|
| `registry-url`    | <p>Registry URL for publishing.</p> |
| `scope`           | <p>Package scope to use.</p>        |
| `package-version` | <p>The version to publish.</p>      |

### Runs

This action is a `composite` action.

### Usage

```yaml
- uses: ivuorinen/actions/npm-publish@main
  with:
    npm_token:
    # NPM token.
    #
    # Required: true
    # Default: ""

    registry-url:
    # Registry URL for publishing.
    #
    # Required: false
    # Default: https://registry.npmjs.org/

    scope:
    # Package scope to use.
    #
    # Required: false
    # Default: @ivuorinen

    package-version:
    # The version to publish.
    #
    # Required: false
    # Default: ${{ github.event.release.tag_name }}

    token:
    # GitHub token for authentication
    #
    # Required: false
    # Default: ""
```
