# ivuorinen/actions - My Reusable GitHub Actions and Workflows

This repository contains reusable GitHub Actions and Workflows that
I have created for my own use. Feel free to use them in your own projects.

## Actions

These actions are composable and can be used together to create more complex workflows.

### `ivuorinen/actions/php-composer`

This action sets up PHP with specified version and installs Composer dependencies.

#### Inputs

- `php`: PHP version to use (default: `8.3`)
- `args`: Additional arguments to pass to Composer

#### Example

```yaml
on:
  workflow_dispatch:
  workflow_call:
  pull_request:
  paths:
  - 'composer.json'
  - 'composer.lock'
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: ivuorinen/actions/php-composer@main
        with:
          php: '8.3'
          args: '--no-dev'
```

### `ivuorinen/actions/set-git-config`

This action sets up Git configuration for the repository.

#### Inputs

- `name`: Name to use for Git commits (default: `GitHub Actions`)
- `email`: Email to use for Git commits (default: `github-actions@github.com`)
- `token`: GitHub token to use for Git commits (default: `${{ github.token }}`)

#### Example

```yaml
on:
  workflow_dispatch:
  workflow_call:
  pull_request:
  paths:
  - '.gitignore'
jobs:
    build:
        runs-on: ubuntu-latest
        steps:
        - uses: actions/checkout@v4
        - uses: ivuorinen/actions/set-git-config@main
          with:
            name: 'GitHub Actions'
            email: 'github-actions@github.com'
            token: ${{ secrets.GITHUB_TOKEN }}
```

## Workflows

These workflows are complete examples that can be used as-is or as a starting point for your own workflows.

### `ivuorinen/actions/compress-images`

This workflow compresses images in a repository using [calibreapp/image-actions](https://github.com/calibreapp/image-actions).
Defined in the action is a cron job that runs At 23:00 on Sunday and if there are any changes in the repository it creates a pull request with the compressed images.

#### Example

```yaml
# .github/workflows/compress-images.yml
jobs:
  compress-images:
    uses: ivuorinen/actions/compress-images@main
```

### `ivuorinen/actions/release-monthly`

This workflow creates a monthly release with the current date as the tag name.

#### Example

```yaml
# .github/workflows/release-monthly.yml
jobs:
  release-monthly:
    uses: ivuorinen/actions/release-monthly@main
```

### `ivuorinen/actions/php-laravel-phpunit`

This workflow sets up PHP with Composer and runs PHPUnit tests for a Laravel project.

#### Example

```yaml
# .github/workflows/php-laravel-phpunit.yml
jobs:
  laravel:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: ivuorinen/actions/php-composer@main
        with:
          php: '8.3'
          args: '--no-dev'
```

## License

The code in this repository is licensed under the MIT License. See the [LICENSE.md](LICENSE.md) file for details.
