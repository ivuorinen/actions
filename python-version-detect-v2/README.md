# ivuorinen/actions/python-version-detect-v2

## Python Version Detect V2

### Description

Detects Python version from project configuration files using shared utilities.

### Inputs

| name              | description                                                     | required | default |
|-------------------|-----------------------------------------------------------------|----------|---------|
| `default-version` | <p>Default Python version to use if no version is detected.</p> | `false`  | `3.12`  |

### Outputs

| name              | description                                                   |
|-------------------|---------------------------------------------------------------|
| `python-version`  | <p>Detected or default Python version.</p>                    |
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
```
