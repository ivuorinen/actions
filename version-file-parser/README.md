# ivuorinen/actions/version-file-parser

Universal parser for common version detection files (.tool-versions, Dockerfile, devcontainer.json, etc.)

## Usage

```yaml
- uses: ivuorinen/actions/version-file-parser@main
  with:
    language: 'python'
    tool-versions-key: 'python'
    dockerfile-image: 'python'
    version-file: '.python-version'
```

## Inputs

| Name                | Description                                                           | Required | Default                       |
|---------------------|-----------------------------------------------------------------------|----------|-------------------------------|
| `language`          | Programming language name (node, python, php, go, dotnet)             | Yes      |                               |
| `tool-versions-key` | Key name in .tool-versions file (nodejs, python, php, golang, dotnet) | Yes      |                               |
| `dockerfile-image`  | Docker image name pattern (node, python, php, golang, dotnet)         | Yes      |                               |
| `version-file`      | Language-specific version file (.nvmrc, .python-version, etc.)        | No       |                               |
| `validation-regex`  | Version validation regex pattern                                      | No       | `^[0-9]+\.[0-9]+(\.[0-9]+)?$` |

## Outputs

| Name                    | Description                                     |
|-------------------------|-------------------------------------------------|
| `tool-versions-version` | Version found in .tool-versions                 |
| `dockerfile-version`    | Version found in Dockerfile                     |
| `devcontainer-version`  | Version found in devcontainer.json              |
| `version-file-version`  | Version found in language-specific version file |

## Supported Files

- **`.tool-versions`** - asdf version manager format
- **`Dockerfile`** - FROM image:version patterns
- **`.devcontainer/devcontainer.json`** - VS Code devcontainer configuration
- **Language-specific files** - .nvmrc, .python-version, .php-version, .go-version

## Example Usage

```yaml
- name: Parse Python Version Files
  id: parse
  uses: ivuorinen/actions/version-file-parser@main
  with:
    language: 'python'
    tool-versions-key: 'python'
    dockerfile-image: 'python'
    version-file: '.python-version'

- name: Use detected versions
  run: |
    echo "Tool versions: ${{ steps.parse.outputs.tool-versions-version }}"
    echo "Dockerfile: ${{ steps.parse.outputs.dockerfile-version }}"
    echo "DevContainer: ${{ steps.parse.outputs.devcontainer-version }}"
    echo "Version file: ${{ steps.parse.outputs.version-file-version }}"
```
