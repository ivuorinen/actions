# ivuorinen/actions/composite-npm-publish

## Publish to NPM

### Description

Publishes the package to the NPM registry with configurable scope and registry URL.

### Inputs

| name              | description                         | required | default                                |
|-------------------|-------------------------------------|----------|----------------------------------------|
| `registry-url`    | <p>Registry URL for publishing.</p> | `false`  | `https://registry.npmjs.org/`          |
| `scope`           | <p>Package scope to use.</p>        | `false`  | `@ivuorinen`                           |
| `package-version` | <p>The version to publish.</p>      | `false`  | `${{ github.event.release.tag_name }}` |

### Runs

This action is a `composite` action.

### Usage

```yaml
- uses: ivuorinen/actions/composite-npm-publish@main
  with:
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
```
