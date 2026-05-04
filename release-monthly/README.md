# ivuorinen/actions/release-monthly

## Description

Creates a release for the current month, incrementing patch number if necessary.

## Inputs

| parameter | description                                       | required | default             |
|-----------|---------------------------------------------------|----------|---------------------|
| token     | GitHub token with permission to create releases.  | `true`   | ${{ github.token }} |
| dry-run   | Run in dry-run mode without creating the release. | `false`  | false               |
| prefix    | Optional prefix for release tags.                 | `false`  |                     |

## Outputs

| parameter    | description                    |
|--------------|--------------------------------|
| release-tag  | The tag of the created release |
| release-url  | The URL of the created release |
| previous-tag | The previous release tag       |

## Runs

This action is a `composite` action.
