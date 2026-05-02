# ivuorinen/actions/php-tests

## Description

Run PHPUnit tests with optional Laravel setup and Composer dependency management

## Inputs

| parameter | description | required | default |
| --- | --- | --- | --- |
| framework | Framework detection mode (auto=detect Laravel via artisan, laravel=force Laravel, generic=no framework) | `false` | auto |
| php-version | PHP Version to use (latest, 8.4, 8.3, etc.) | `false` | latest |
| extensions | PHP extensions to install (comma-separated) | `false` | mbstring, intl, json, pdo_sqlite, sqlite3 |
| coverage | Code-coverage driver (none, xdebug, pcov) | `false` | none |
| composer-args | Arguments to pass to Composer install | `false` | --no-progress --prefer-dist --optimize-autoloader |
| max-retries | Maximum number of retry attempts for Composer commands | `false` | 3 |
| token | GitHub token for authentication | `false` |  |
| username | GitHub username for commits | `false` | github-actions |
| email | GitHub email for commits | `false` | <github-actions@github.com> |

## Outputs

| parameter | description |
| --- | --- |
| framework | Detected framework (laravel or generic) |
| php-version | The PHP version that was setup |
| composer-version | Installed Composer version |
| cache-hit | Indicates if there was a cache hit |
| test-status | Test execution status (success/failure) |
| tests-run | Number of tests executed |
| tests-passed | Number of tests passed |

## Runs

This action is a `composite` action.
