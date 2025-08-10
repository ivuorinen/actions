# ivuorinen/actions/php-laravel-phpunit

## Laravel Setup and Composer test

### Description

Setup PHP, install dependencies, generate key, create database and run composer test

### Inputs

| name               | description                                                                                                           | required | default                                     |
|--------------------|-----------------------------------------------------------------------------------------------------------------------|----------|---------------------------------------------|
| `php-version`      | <p>PHP Version to use, see https://github.com/marketplace/actions/setup-php-action#php-version-optional</p>           | `false`  | `latest`                                    |
| `php-version-file` | <p>PHP Version file to use, see https://github.com/marketplace/actions/setup-php-action#php-version-file-optional</p> | `false`  | `.php-version`                              |
| `extensions`       | <p>PHP extensions to install, see https://github.com/marketplace/actions/setup-php-action#extensions-optional</p>     | `false`  | `mbstring, intl, json, pdo_sqlite, sqlite3` |
| `coverage`         | <p>Specify code-coverage driver, see https://github.com/marketplace/actions/setup-php-action#coverage-optional</p>    | `false`  | `none`                                      |
| `token`            | <p>GitHub token for authentication</p>                                                                                | `false`  | `${{ github.token }}`                       |

### Outputs

| name               | description                                    |
|--------------------|------------------------------------------------|
| `php-version`      | <p>The PHP version that was setup</p>          |
| `php-version-file` | <p>The PHP version file that was used</p>      |
| `extensions`       | <p>The PHP extensions that were installed</p>  |
| `coverage`         | <p>The code-coverage driver that was setup</p> |

### Runs

This action is a `composite` action.

### Usage

```yaml
- uses: ivuorinen/actions/php-laravel-phpunit@main
  with:
    php-version:
    # PHP Version to use, see https://github.com/marketplace/actions/setup-php-action#php-version-optional
    #
    # Required: false
    # Default: latest

    php-version-file:
    # PHP Version file to use, see https://github.com/marketplace/actions/setup-php-action#php-version-file-optional
    #
    # Required: false
    # Default: .php-version

    extensions:
    # PHP extensions to install, see https://github.com/marketplace/actions/setup-php-action#extensions-optional
    #
    # Required: false
    # Default: mbstring, intl, json, pdo_sqlite, sqlite3

    coverage:
    # Specify code-coverage driver, see https://github.com/marketplace/actions/setup-php-action#coverage-optional
    #
    # Required: false
    # Default: none

    token:
    # GitHub token for authentication
    #
    # Required: false
    # Default: ${{ github.token }}
```
