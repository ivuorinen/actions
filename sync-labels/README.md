# ivuorinen/actions/sync-labels

## Description

Sync labels from a YAML file to a GitHub repository

## Inputs

| parameter | description | required | default |
| --- | --- | --- | --- |
| labels | Path to the labels YAML file | `false` |  |
| token | GitHub token for authentication | `false` | ${{ github.token }} |

## Outputs

| parameter | description |
| --- | --- |
| labels | Path to the labels YAML file |

## Runs

This action is a `composite` action.
