# ivuorinen/actions/python-version-detect

## Python Version Detect

### Description

Detects Python version from project configuration files or defaults to a specified version.

### Inputs

| name | description | required | default |
| --- | --- | --- | --- |
| `default-version` | <p>Default Python version to use if no version is detected.</p> | `false` | `3.12` |
| `token` | <p>GitHub token for authentication</p> | `false` | `""` |

### Outputs

| name | description |
| --- | --- |
| `python-version` | <p>Detected or default Python version.</p> |

### Runs

This action is a `composite` action.

### Usage

```yaml
- uses: ivuorinen/actions/python-version-detect@main
  with:
    default-version:
    # Default Python version to use if no version is detected.
    #
    # Required: false
    # Default: 3.12

    token:
    # GitHub token for authentication
    #
    # Required: false
    # Default: ""
```
