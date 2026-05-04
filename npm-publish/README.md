# ivuorinen/actions/npm-publish

## Description

Publishes the package to the NPM registry with configurable scope and registry URL.

## Inputs

| parameter | description | required | default |
| --- | --- | --- | --- |
| npm_token | NPM token. | `true` |  |
| registry-url | Registry URL for publishing. | `false` | <https://registry.npmjs.org/> |
| scope | Package scope to use. | `false` | @ivuorinen |
| package-version | The version to publish. | `false` | ${{ github.event.release.tag_name }} |
| token | GitHub token for authentication | `false` |  |

## Outputs

| parameter | description |
| --- | --- |
| registry-url | Registry URL for publishing. |
| scope | Package scope to use. |
| package-version | The version to publish. |

## Runs

This action is a `composite` action.
