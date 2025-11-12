# ivuorinen/actions/php-composer

## Run Composer Install

### Description

Runs Composer install on a repository with advanced caching and configuration.

### Inputs

| name                | description                                                   | required | default                                             |
| ------------------- | ------------------------------------------------------------- | -------- | --------------------------------------------------- |
| `php`               | <p>PHP Version to use.</p>                                    | `true`   | `8.4`                                               |
| `extensions`        | <p>Comma-separated list of PHP extensions to install</p>      | `false`  | `mbstring, xml, zip, curl, json`                    |
| `tools`             | <p>Comma-separated list of Composer tools to install</p>      | `false`  | `composer:v2`                                       |
| `args`              | <p>Arguments to pass to Composer.</p>                         | `false`  | `--no-progress --prefer-dist --optimize-autoloader` |
| `composer-version`  | <p>Composer version to use (1 or 2)</p>                       | `false`  | `2`                                                 |
| `stability`         | <p>Minimum stability (stable, RC, beta, alpha, dev)</p>       | `false`  | `stable`                                            |
| `cache-directories` | <p>Additional directories to cache (comma-separated)</p>      | `false`  | `""`                                                |
| `token`             | <p>GitHub token for private repository access</p>             | `false`  | `""`                                                |
| `max-retries`       | <p>Maximum number of retry attempts for Composer commands</p> | `false`  | `3`                                                 |

### Outputs

| name               | description                                     |
| ------------------ | ----------------------------------------------- |
| `lock`             | <p>composer.lock or composer.json file hash</p> |
| `php-version`      | <p>Installed PHP version</p>                    |
| `composer-version` | <p>Installed Composer version</p>               |
| `cache-hit`        | <p>Indicates if there was a cache hit</p>       |

### Runs

This action is a `composite` action.

### Usage

```yaml
- uses: ivuorinen/actions/php-composer@main
  with:
    php:
    # PHP Version to use.
    #
    # Required: true
    # Default: 8.4

    extensions:
    # Comma-separated list of PHP extensions to install
    #
    # Required: false
    # Default: mbstring, xml, zip, curl, json

    tools:
    # Comma-separated list of Composer tools to install
    #
    # Required: false
    # Default: composer:v2

    args:
    # Arguments to pass to Composer.
    #
    # Required: false
    # Default: --no-progress --prefer-dist --optimize-autoloader

    composer-version:
    # Composer version to use (1 or 2)
    #
    # Required: false
    # Default: 2

    stability:
    # Minimum stability (stable, RC, beta, alpha, dev)
    #
    # Required: false
    # Default: stable

    cache-directories:
    # Additional directories to cache (comma-separated)
    #
    # Required: false
    # Default: ""

    token:
    # GitHub token for private repository access
    #
    # Required: false
    # Default: ""

    max-retries:
    # Maximum number of retry attempts for Composer commands
    #
    # Required: false
    # Default: 3
```
