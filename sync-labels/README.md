# ivuorinen/actions/sync-labels

## Description

Sync labels from a YAML file to a GitHub repository

## Inputs

| name     | description                            | required | default               |
|----------|----------------------------------------|----------|-----------------------|
| `labels` | <p>Path to the labels YAML file</p>    | `false`  | `""`                  |
| `token`  | <p>GitHub token for authentication</p> | `false`  | `${{ github.token }}` |

## Outputs

| name     | description                         |
|----------|-------------------------------------|
| `labels` | <p>Path to the labels YAML file</p> |

## Runs

This action is a `composite` action.

## Usage

```yaml
- uses: ivuorinen/actions/sync-labels@vYYYY.MM.DD
  with:
    labels:
    # Path to the labels YAML file
    #
    # Required: false
    # Default: ""

    token:
    # GitHub token for authentication
    #
    # Required: false
    # Default: ${{ github.token }}
```
