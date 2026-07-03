# ivuorinen/actions/sync-labels

## Description

Sync GitHub labels declaratively from a YAML/JSON manifest (no Docker)

## Inputs

| name         | description                                                                                                                                                                                                                                    | required | default               |
|--------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------|-----------------------|
| `labels`     | <p>Path to the labels manifest (YAML or JSON), relative to the repository root. Defaults to .github/labels.yml when omitted (no longer the action's bundled labels.yml). A missing manifest is a warning + successful no-op, not an error.</p> | `false`  | `""`                  |
| `repository` | <p>Newline-separated list of owner/repo targets. Defaults to the current repository. Cross-repo sync requires a PAT in the token input.</p>                                                                                                    | `false`  | `""`                  |
| `prune`      | <p>Delete existing labels that are not listed in the manifest</p>                                                                                                                                                                              | `false`  | `true`                |
| `token`      | <p>GitHub token for authentication (use a PAT for cross-repo sync)</p>                                                                                                                                                                         | `false`  | `${{ github.token }}` |

## Outputs

| name           | description                              |
|----------------|------------------------------------------|
| `created`      | <p>Number of labels created</p>          |
| `updated`      | <p>Number of labels updated</p>          |
| `deleted`      | <p>Number of labels deleted (pruned)</p> |
| `unchanged`    | <p>Number of labels left unchanged</p>   |
| `repositories` | <p>Number of repositories synced</p>     |

## Runs

This action is a `composite` action.

## Usage

```yaml
- uses: ivuorinen/actions/sync-labels@vYYYY.MM.DD
  with:
    labels:
    # Path to the labels manifest (YAML or JSON), relative to the repository root. Defaults to .github/labels.yml when omitted (no longer the action's bundled labels.yml). A missing manifest is a warning + successful no-op, not an error.
    #
    # Required: false
    # Default: ""

    repository:
    # Newline-separated list of owner/repo targets. Defaults to the current repository. Cross-repo sync requires a PAT in the token input.
    #
    # Required: false
    # Default: ""

    prune:
    # Delete existing labels that are not listed in the manifest
    #
    # Required: false
    # Default: true

    token:
    # GitHub token for authentication (use a PAT for cross-repo sync)
    #
    # Required: false
    # Default: ${{ github.token }}
```
