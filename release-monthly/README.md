# ivuorinen/actions/release-monthly

## Do Monthly Release

### Description

Creates a release for the current month, incrementing patch number if necessary.

### Inputs

| name      | description                                              | required | default               |
| --------- | -------------------------------------------------------- | -------- | --------------------- |
| `token`   | <p>GitHub token with permission to create releases.</p>  | `true`   | `${{ github.token }}` |
| `dry-run` | <p>Run in dry-run mode without creating the release.</p> | `false`  | `false`               |
| `prefix`  | <p>Optional prefix for release tags.</p>                 | `false`  | `""`                  |

### Outputs

| name           | description                           |
| -------------- | ------------------------------------- |
| `release-tag`  | <p>The tag of the created release</p> |
| `release-url`  | <p>The URL of the created release</p> |
| `previous-tag` | <p>The previous release tag</p>       |

### Runs

This action is a `composite` action.

### Usage

```yaml
- uses: ivuorinen/actions/release-monthly@main
  with:
    token:
    # GitHub token with permission to create releases.
    #
    # Required: true
    # Default: ${{ github.token }}

    dry-run:
    # Run in dry-run mode without creating the release.
    #
    # Required: false
    # Default: false

    prefix:
    # Optional prefix for release tags.
    #
    # Required: false
    # Default: ""
```
