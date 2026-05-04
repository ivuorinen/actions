# ivuorinen/actions/npm-semantic-release

## Description

Runs semantic-release for automated npm versioning and publishing with OIDC provenance support.

## Inputs

| parameter     | description                                                | required | default                                           |
|---------------|------------------------------------------------------------|----------|---------------------------------------------------|
| npm_token     | NPM token for publishing.                                  | `true`   |                                                   |
| github_token  | GitHub token for creating releases, tags, and PR comments. | `false`  | ${{ github.token }}                               |
| scope         | Package scope to use.                                      | `false`  | @ivuorinen                                        |
| registry-url  | Registry URL for publishing.                               | `false`  | <https://registry.npmjs.org/>                     |
| node-version  | Node.js version to use when .nvmrc is not present.         | `false`  | 24                                                |
| extra_plugins | Extra semantic-release plugins (pipe-separated).           | `false`  | conventional-changelog-conventionalcommits@^9.3.1 |

## Outputs

| parameter             | description                            |
|-----------------------|----------------------------------------|
| new-release-published | Whether a new release was published.   |
| new-release-version   | The new release version, if published. |

## Runs

This action is a `composite` action.
