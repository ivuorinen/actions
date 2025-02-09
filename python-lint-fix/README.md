# ivuorinen/actions/python-lint-fix

## Python Lint and Fix

### Description

Lints and fixes Python files, commits changes, and uploads SARIF report.

### Inputs

| name                | description                                                           | required | default |
|---------------------|-----------------------------------------------------------------------|----------|---------|
| `python-version`    | <p>Python version to use</p>                                          | `false`  | `3.11`  |
| `flake8-version`    | <p>Flake8 version to use</p>                                          | `false`  | `7.0.0` |
| `autopep8-version`  | <p>Autopep8 version to use</p>                                        | `false`  | `2.0.4` |
| `max-retries`       | <p>Maximum number of retry attempts for installations and linting</p> | `false`  | `3`     |
| `working-directory` | <p>Directory containing Python files to lint</p>                      | `false`  | `.`     |
| `fail-on-error`     | <p>Whether to fail the action if linting errors are found</p>         | `false`  | `true`  |

### Outputs

| name          | description                                            |
|---------------|--------------------------------------------------------|
| `lint-result` | <p>Result of the linting process (success/failure)</p> |
| `fixed-files` | <p>Number of files that were fixed</p>                 |
| `error-count` | <p>Number of errors found</p>                          |

### Runs

This action is a `composite` action.

### Usage

```yaml
- uses: ivuorinen/actions/python-lint-fix@main
  with:
    python-version:
    # Python version to use
    #
    # Required: false
    # Default: 3.11

    flake8-version:
    # Flake8 version to use
    #
    # Required: false
    # Default: 7.0.0

    autopep8-version:
    # Autopep8 version to use
    #
    # Required: false
    # Default: 2.0.4

    max-retries:
    # Maximum number of retry attempts for installations and linting
    #
    # Required: false
    # Default: 3

    working-directory:
    # Directory containing Python files to lint
    #
    # Required: false
    # Default: .

    fail-on-error:
    # Whether to fail the action if linting errors are found
    #
    # Required: false
    # Default: true
```
