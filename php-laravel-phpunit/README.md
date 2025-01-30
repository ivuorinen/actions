# ivuorinen/actions/php-laravel-phpunit

## Laravel Setup and Composer test

### Inputs

| name               | description                                                                                                           | type     | required | default                                     |
|--------------------|-----------------------------------------------------------------------------------------------------------------------|----------|----------|---------------------------------------------|
| `php-version`      | <p>PHP Version to use, see https://github.com/marketplace/actions/setup-php-action#php-version-optional</p>           | `string` | `false`  | `latest`                                    |
| `php-version-file` | <p>PHP Version file to use, see https://github.com/marketplace/actions/setup-php-action#php-version-file-optional</p> | `string` | `false`  | `.php-version`                              |
| `extensions`       | <p>PHP extensions to install, see https://github.com/marketplace/actions/setup-php-action#extensions-optional</p>     | `string` | `false`  | `mbstring, intl, json, pdo_sqlite, sqlite3` |
| `coverage`         | <p>Specify code-coverage driver, see https://github.com/marketplace/actions/setup-php-action#coverage-optional</p>    | `string` | `false`  | `none`                                      |

### Usage

```yaml
jobs:
    job1:
        uses: ivuorinen/actions/php-laravel-phpunit@main
        with:
            php-version:
            # PHP Version to use, see https://github.com/marketplace/actions/setup-php-action#php-version-optional
            #
            # Type: string
            # Required: false
            # Default: latest

            php-version-file:
            # PHP Version file to use, see https://github.com/marketplace/actions/setup-php-action#php-version-file-optional
            #
            # Type: string
            # Required: false
            # Default: .php-version

            extensions:
            # PHP extensions to install, see https://github.com/marketplace/actions/setup-php-action#extensions-optional
            #
            # Type: string
            # Required: false
            # Default: mbstring, intl, json, pdo_sqlite, sqlite3

            coverage:
            # Specify code-coverage driver, see https://github.com/marketplace/actions/setup-php-action#coverage-optional
            #
            # Type: string
            # Required: false
            # Default: none
```
