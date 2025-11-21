# ivuorinen/actions/php-tests

## PHP Tests

### Description

Run PHPUnit tests with optional Laravel setup and Composer dependency management

### Inputs

| name            | description                                                                                                    | required | default                                             |
|-----------------|----------------------------------------------------------------------------------------------------------------|----------|-----------------------------------------------------|
| `framework`     | <p>Framework detection mode (auto=detect Laravel via artisan, laravel=force Laravel, generic=no framework)</p> | `false`  | `auto`                                              |
| `php-version`   | <p>PHP Version to use (latest, 8.4, 8.3, etc.)</p>                                                             | `false`  | `latest`                                            |
| `extensions`    | <p>PHP extensions to install (comma-separated)</p>                                                             | `false`  | `mbstring, intl, json, pdo_sqlite, sqlite3`         |
| `coverage`      | <p>Code-coverage driver (none, xdebug, pcov)</p>                                                               | `false`  | `none`                                              |
| `composer-args` | <p>Arguments to pass to Composer install</p>                                                                   | `false`  | `--no-progress --prefer-dist --optimize-autoloader` |
| `max-retries`   | <p>Maximum number of retry attempts for Composer commands</p>                                                  | `false`  | `3`                                                 |
| `token`         | <p>GitHub token for authentication</p>                                                                         | `false`  | `""`                                                |
| `username`      | <p>GitHub username for commits</p>                                                                             | `false`  | `github-actions`                                    |
| `email`         | <p>GitHub email for commits</p>                                                                                | `false`  | `github-actions@github.com`                         |

### Outputs

| name               | description                                    |
|--------------------|------------------------------------------------|
| `framework`        | <p>Detected framework (laravel or generic)</p> |
| `php-version`      | <p>The PHP version that was setup</p>          |
| `composer-version` | <p>Installed Composer version</p>              |
| `cache-hit`        | <p>Indicates if there was a cache hit</p>      |
| `test-status`      | <p>Test execution status (success/failure)</p> |
| `tests-run`        | <p>Number of tests executed</p>                |
| `tests-passed`     | <p>Number of tests passed</p>                  |

### Runs

This action is a `composite` action.

### Usage

```yaml
- uses: ivuorinen/actions/php-tests@main
  with:
    framework:
    # Framework detection mode (auto=detect Laravel via artisan, laravel=force Laravel, generic=no framework)
    #
    # Required: false
    # Default: auto

    php-version:
    # PHP Version to use (latest, 8.4, 8.3, etc.)
    #
    # Required: false
    # Default: latest

    extensions:
    # PHP extensions to install (comma-separated)
    #
    # Required: false
    # Default: mbstring, intl, json, pdo_sqlite, sqlite3

    coverage:
    # Code-coverage driver (none, xdebug, pcov)
    #
    # Required: false
    # Default: none

    composer-args:
    # Arguments to pass to Composer install
    #
    # Required: false
    # Default: --no-progress --prefer-dist --optimize-autoloader

    max-retries:
    # Maximum number of retry attempts for Composer commands
    #
    # Required: false
    # Default: 3

    token:
    # GitHub token for authentication
    #
    # Required: false
    # Default: ""

    username:
    # GitHub username for commits
    #
    # Required: false
    # Default: github-actions

    email:
    # GitHub email for commits
    #
    # Required: false
    # Default: github-actions@github.com
```
