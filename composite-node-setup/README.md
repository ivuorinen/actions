# ivuorinen/actions/composite-node-setup

## Node Setup

### Description

Sets up the Node.js environment based on .nvmrc, .tool-versions, or a default version.

### Inputs

| name              | description                                                              | required | default |
| ----------------- | ------------------------------------------------------------------------ | -------- | ------- |
| `default-version` | <p>Default Node.js version to use if no configuration file is found.</p> | `false`  | `20`    |

### Runs

This action is a `composite` action.

### Usage

```yaml
- uses: ivuorinen/actions/composite-node-setup@main
  with:
      default-version:
      # Default Node.js version to use if no configuration file is found.
      #
      # Required: false
      # Default: 20
```
