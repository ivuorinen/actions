# ivuorinen/actions/npm-semantic-release

## NPM Semantic Release

### Description

Runs semantic-release for automated npm versioning and publishing with OIDC provenance support.

### Inputs

| name            | description                                                       | required | default                                             |
|-----------------|-------------------------------------------------------------------|----------|-----------------------------------------------------|
| `npm_token`     | <p>NPM token for publishing.</p>                                  | `true`   | `""`                                                |
| `github_token`  | <p>GitHub token for creating releases, tags, and PR comments.</p> | `false`  | `${{ github.token }}`                               |
| `scope`         | <p>Package scope to use.</p>                                      | `false`  | `@ivuorinen`                                        |
| `registry-url`  | <p>Registry URL for publishing.</p>                               | `false`  | `https://registry.npmjs.org/`                       |
| `node-version`  | <p>Node.js version to use when .nvmrc is not present.</p>         | `false`  | `24`                                                |
| `extra_plugins` | <p>Extra semantic-release plugins (pipe-separated).</p>           | `false`  | `conventional-changelog-conventionalcommits@^9.3.1` |

### Outputs

| name                    | description                                   |
|-------------------------|-----------------------------------------------|
| `new-release-published` | <p>Whether a new release was published.</p>   |
| `new-release-version`   | <p>The new release version, if published.</p> |

### Runs

This action is a `composite` action.

### Usage

```yaml
- uses: ivuorinen/actions/npm-semantic-release@<sha>
  with:
    npm_token:
    # NPM token for publishing.
    #
    # Required: true
    # Default: ""

    github_token:
    # GitHub token for creating releases, tags, and PR comments.
    #
    # Required: false
    # Default: ${{ github.token }}

    scope:
    # Package scope to use.
    #
    # Required: false
    # Default: @ivuorinen

    registry-url:
    # Registry URL for publishing.
    #
    # Required: false
    # Default: https://registry.npmjs.org/

    node-version:
    # Node.js version to use when .nvmrc is not present.
    #
    # Required: false
    # Default: 24

    extra_plugins:
    # Extra semantic-release plugins (pipe-separated).
    #
    # Required: false
    # Default: conventional-changelog-conventionalcommits@^9.3.1
```
