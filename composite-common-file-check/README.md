# ivuorinen/actions/composite-common-file-check

## Common File Check

### Description

A reusable action to check if a specific file or type of files exists in the repository.
Emits an output 'found' which is true or false.

### Inputs

| name           | description                             | required | default |
|----------------|-----------------------------------------|----------|---------|
| `file-pattern` | <p>Glob pattern for files to check.</p> | `true`   | `""`    |

### Outputs

| name    | description                                                    |
|---------|----------------------------------------------------------------|
| `found` | <p>Indicates if the files matching the pattern were found.</p> |

### Runs

This action is a `composite` action.

### Usage

```yaml
- uses: ivuorinen/actions/composite-common-file-check@main
  with:
      file-pattern:
      # Glob pattern for files to check.
      #
      # Required: true
      # Default: ""
```
