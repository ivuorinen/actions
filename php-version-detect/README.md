# ivuorinen/actions/php-version-detect

Detects PHP version from project configuration files or defaults to a specified version.

## Usage

```yaml
- uses: ivuorinen/actions/php-version-detect@main
  with:
    default-version: '8.3'
```

## Inputs

| Name | Description | Required | Default |
|------|-------------|----------|---------|
| `default-version` | Default PHP version to use if no version is detected. | No | `8.3` |

## Outputs

| Name | Description |
|------|-------------|
| `php-version` | Detected or default PHP version. |

## Detection Priority

The action searches for PHP version in this order:

1. `.php-version` file
2. `composer.json` (require.php or platform.php)
3. `.tool-versions` file (asdf format)
4. `phpunit.xml` or `phpunit.xml.dist`
5. `Dockerfile` (FROM php:version)
6. `.devcontainer/devcontainer.json`
7. Default version (fallback)

## Example

```yaml
- name: Detect PHP Version
  id: php-version
  uses: ivuorinen/actions/php-version-detect@main

- name: Setup PHP
  uses: shivammathur/setup-php@v2
  with:
    php-version: ${{ steps.php-version.outputs.php-version }}
```
