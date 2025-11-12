# ivuorinen/actions/github-release

## GitHub Release

### Description

Creates a GitHub release with a version and changelog.

### Inputs

| name        | description                                          | required | default |
|-------------|------------------------------------------------------|----------|---------|
| `version`   | <p>The version for the release.</p>                  | `true`   | `""`    |
| `changelog` | <p>The changelog or description for the release.</p> | `false`  | `""`    |

### Outputs

| name          | description                                             |
|---------------|---------------------------------------------------------|
| `release_url` | <p>URL of the created GitHub release</p>                |
| `release_id`  | <p>ID of the created GitHub release</p>                 |
| `upload_url`  | <p>Upload URL for the created GitHub release assets</p> |

### Runs

This action is a `composite` action.

### Usage

```yaml
- uses: ivuorinen/actions/github-release@main
  with:
    version:
    # The version for the release.
    #
    # Required: true
    # Default: ""

    changelog:
    # The changelog or description for the release.
    #
    # Required: false
    # Default: ""
```
