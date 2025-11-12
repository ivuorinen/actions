# ivuorinen/actions/common-cache

## Common Cache

### Description

Standardized caching strategy for all actions

### Inputs

| name           | description                                          | required | default |
|----------------|------------------------------------------------------|----------|---------|
| `type`         | <p>Type of cache (npm, composer, go, pip, etc.)</p>  | `true`   | `""`    |
| `paths`        | <p>Paths to cache (comma-separated)</p>              | `true`   | `""`    |
| `key-prefix`   | <p>Custom prefix for cache key</p>                   | `false`  | `""`    |
| `key-files`    | <p>Files to hash for cache key (comma-separated)</p> | `false`  | `""`    |
| `restore-keys` | <p>Fallback keys for cache restoration</p>           | `false`  | `""`    |
| `env-vars`     | <p>Environment variables to include in cache key</p> | `false`  | `""`    |

### Outputs

| name          | description                 |
|---------------|-----------------------------|
| `cache-hit`   | <p>Cache hit indicator</p>  |
| `cache-key`   | <p>Generated cache key</p>  |
| `cache-paths` | <p>Resolved cache paths</p> |

### Runs

This action is a `composite` action.

### Usage

```yaml
- uses: ivuorinen/actions/common-cache@main
  with:
    type:
    # Type of cache (npm, composer, go, pip, etc.)
    #
    # Required: true
    # Default: ""

    paths:
    # Paths to cache (comma-separated)
    #
    # Required: true
    # Default: ""

    key-prefix:
    # Custom prefix for cache key
    #
    # Required: false
    # Default: ""

    key-files:
    # Files to hash for cache key (comma-separated)
    #
    # Required: false
    # Default: ""

    restore-keys:
    # Fallback keys for cache restoration
    #
    # Required: false
    # Default: ""

    env-vars:
    # Environment variables to include in cache key
    #
    # Required: false
    # Default: ""
```
