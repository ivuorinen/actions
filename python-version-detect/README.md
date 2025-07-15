# ivuorinen/actions/python-version-detect

Detects Python version from project configuration files or defaults to a specified version.

## Usage

```yaml
- uses: ivuorinen/actions/python-version-detect@main
  with:
    default-version: '3.12'
```

## Inputs

| Name | Description | Required | Default |
|------|-------------|----------|---------|
| `default-version` | Default Python version to use if no version is detected. | No | `3.12` |

## Outputs

| Name | Description |
|------|-------------|
| `python-version` | Detected or default Python version. |

## Detection Priority

The action searches for Python version in this order:

1. `.python-version` file
2. `pyproject.toml` (requires-python)
3. `setup.py` (python_requires)
4. `runtime.txt` (Heroku style)
5. `Pipfile` (python_version)
6. `.tool-versions` file (asdf format)
7. `tox.ini` (basepython)
8. `Dockerfile` (FROM python:version)
9. `.devcontainer/devcontainer.json`
10. Default version (fallback)

## Example

```yaml
- name: Detect Python Version
  id: python-version
  uses: ivuorinen/actions/python-version-detect@main

- name: Setup Python
  uses: actions/setup-python@v4
  with:
    python-version: ${{ steps.python-version.outputs.python-version }}
```
