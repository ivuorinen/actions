# ivuorinen/actions/python-version-detect-v2

## Python Version Detect v2

### Description

Detects Python version from project configuration files using enhanced detection logic.

### Inputs

| name | description | required | default |
| --- | --- | --- | --- |
| `default-version` | <p>Default Python version to use if no version is detected.</p> | `false` | `3.12` |
| `token` | <p>GitHub token for authentication</p> | `false` | `""` |

### Outputs

| name | description |
| --- | --- |
| `python-version` | <p>Detected or default Python version.</p> |
| `package-manager` | <p>Detected Python package manager (pip, poetry, pipenv).</p> |

### Runs

This action is a `composite` action.

### Usage

```yaml
- uses: ivuorinen/actions/python-version-detect-v2@main
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
