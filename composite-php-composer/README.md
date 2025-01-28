# ivuorinen/actions/composite-php-composer

## Run Composer Install

### Description

Runs Composer install on a repository with caching.

### Inputs

| name   | description                           | required | default                                             |
| ------ | ------------------------------------- | -------- | --------------------------------------------------- |
| `php`  | <p>PHP Version to use.</p>            | `true`   | `8.4`                                               |
| `args` | <p>Arguments to pass to Composer.</p> | `false`  | `--no-progress --prefer-dist --optimize-autoloader` |

### Outputs

| name   | description                                     |
| ------ | ----------------------------------------------- |
| `lock` | <p>composer.lock or composer.json file hash</p> |

### Runs

This action is a `composite` action.

### Usage

```yaml
- uses: ivuorinen/actions/composite-php-composer@main
  with:
      php:
      # PHP Version to use.
      #
      # Required: true
      # Default: 8.4

      args:
      # Arguments to pass to Composer.
      #
      # Required: false
      # Default: --no-progress --prefer-dist --optimize-autoloader
```
