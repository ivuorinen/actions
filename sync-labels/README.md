# ivuorinen/actions/sync-labels

## Sync labels

### Description

Sync labels from a YAML file to a GitHub repository

### Inputs

| name     | description                         | required | default      |
|----------|-------------------------------------|----------|--------------|
| `labels` | <p>Path to the labels YAML file</p> | `true`   | `labels.yml` |

### Outputs

| name     | description                         |
|----------|-------------------------------------|
| `labels` | <p>Path to the labels YAML file</p> |

### Runs

This action is a `composite` action.

### Usage

```yaml
- uses: ivuorinen/actions/sync-labels@main
  with:
    labels:
    # Path to the labels YAML file
    #
    # Required: true
    # Default: labels.yml
```
