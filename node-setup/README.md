# ivuorinen/actions/node-setup

## Node Setup

### Description

Sets up Node.js environment with advanced version management, caching, and tooling.

### Inputs

| name              | description                                                              | required | default                      |
|-------------------|--------------------------------------------------------------------------|----------|------------------------------|
| `default-version` | <p>Default Node.js version to use if no configuration file is found.</p> | `false`  | `22`                         |
| `package-manager` | <p>Node.js package manager to use (npm, yarn, pnpm)</p>                  | `false`  | `npm`                        |
| `registry-url`    | <p>Custom NPM registry URL</p>                                           | `false`  | `https://registry.npmjs.org` |
| `token`           | <p>Auth token for private registry</p>                                   | `false`  | `""`                         |
| `cache`           | <p>Enable dependency caching</p>                                         | `false`  | `true`                       |
| `install`         | <p>Automatically install dependencies</p>                                | `false`  | `true`                       |
| `node-mirror`     | <p>Custom Node.js binary mirror</p>                                      | `false`  | `""`                         |
| `force-version`   | <p>Force specific Node.js version regardless of config files</p>         | `false`  | `""`                         |

### Outputs

| name              | description                               |
|-------------------|-------------------------------------------|
| `node-version`    | <p>Installed Node.js version</p>          |
| `package-manager` | <p>Selected package manager</p>           |
| `cache-hit`       | <p>Indicates if there was a cache hit</p> |
| `node-path`       | <p>Path to Node.js installation</p>       |

### Runs

This action is a `composite` action.

### Usage

```yaml
- uses: ivuorinen/actions/node-setup@main
  with:
    default-version:
    # Default Node.js version to use if no configuration file is found.
    #
    # Required: false
    # Default: 22

    package-manager:
    # Node.js package manager to use (npm, yarn, pnpm)
    #
    # Required: false
    # Default: npm

    registry-url:
    # Custom NPM registry URL
    #
    # Required: false
    # Default: https://registry.npmjs.org

    token:
    # Auth token for private registry
    #
    # Required: false
    # Default: ""

    cache:
    # Enable dependency caching
    #
    # Required: false
    # Default: true

    install:
    # Automatically install dependencies
    #
    # Required: false
    # Default: true

    node-mirror:
    # Custom Node.js binary mirror
    #
    # Required: false
    # Default: ""

    force-version:
    # Force specific Node.js version regardless of config files
    #
    # Required: false
    # Default: ""
```
