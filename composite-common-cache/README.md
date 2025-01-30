# ivuorinen/actions/composite-common-cache

## Common Cache

### Description

Adds caching support for workflows with user-defined cache keys and paths.

### Inputs

| name           | description                    | required | default |
|----------------|--------------------------------|----------|---------|
| `path`         | <p>Path to cache.</p>          | `true`   | `""`    |
| `key`          | <p>Primary cache key.</p>      | `true`   | `""`    |
| `restore-keys` | <p>Restore keys for cache.</p> | `false`  | `""`    |

### Runs

This action is a `composite` action.

### Usage

```yaml
- uses: ivuorinen/actions/composite-common-cache@main
  with:
      path:
      # Path to cache.
      #
      # Required: true
      # Default: ""

      key:
      # Primary cache key.
      #
      # Required: true
      # Default: ""

      restore-keys:
      # Restore keys for cache.
      #
      # Required: false
      # Default: ""
```
