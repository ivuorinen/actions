# ivuorinen/actions/version-file-parser

## Version File Parser

### Description

Universal parser for common version detection files (.tool-versions, Dockerfile, devcontainer.json, etc.)

### Inputs

| name                | description                                                                  | required | default                       |
| ------------------- | ---------------------------------------------------------------------------- | -------- | ----------------------------- |
| `language`          | <p>Programming language name (node, python, php, go, dotnet)</p>             | `true`   | `""`                          |
| `tool-versions-key` | <p>Key name in .tool-versions file (nodejs, python, php, golang, dotnet)</p> | `true`   | `""`                          |
| `dockerfile-image`  | <p>Docker image name pattern (node, python, php, golang, dotnet)</p>         | `true`   | `""`                          |
| `version-file`      | <p>Language-specific version file (.nvmrc, .python-version, etc.)</p>        | `false`  | `""`                          |
| `validation-regex`  | <p>Version validation regex pattern</p>                                      | `false`  | `^[0-9]+\.[0-9]+(\.[0-9]+)?$` |
| `default-version`   | <p>Default version to use if no version is detected</p>                      | `false`  | `""`                          |

### Outputs

| name                    | description                                                                       |
| ----------------------- | --------------------------------------------------------------------------------- |
| `tool-versions-version` | <p>Version found in .tool-versions</p>                                            |
| `dockerfile-version`    | <p>Version found in Dockerfile</p>                                                |
| `devcontainer-version`  | <p>Version found in devcontainer.json</p>                                         |
| `version-file-version`  | <p>Version found in language-specific version file</p>                            |
| `config-file-version`   | <p>Version found in language config files (package.json, composer.json, etc.)</p> |
| `detected-version`      | <p>Final detected version (first found or default)</p>                            |
| `package-manager`       | <p>Detected package manager (npm, yarn, pnpm, composer, pip, poetry, etc.)</p>    |

### Runs

This action is a `composite` action.

### Usage

```yaml
- uses: ivuorinen/actions/version-file-parser@main
  with:
    language:
    # Programming language name (node, python, php, go, dotnet)
    #
    # Required: true
    # Default: ""

    tool-versions-key:
    # Key name in .tool-versions file (nodejs, python, php, golang, dotnet)
    #
    # Required: true
    # Default: ""

    dockerfile-image:
    # Docker image name pattern (node, python, php, golang, dotnet)
    #
    # Required: true
    # Default: ""

    version-file:
    # Language-specific version file (.nvmrc, .python-version, etc.)
    #
    # Required: false
    # Default: ""

    validation-regex:
    # Version validation regex pattern
    #
    # Required: false
    # Default: ^[0-9]+\.[0-9]+(\.[0-9]+)?$

    default-version:
    # Default version to use if no version is detected
    #
    # Required: false
    # Default: ""
```
