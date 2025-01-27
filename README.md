# ivuorinen/actions - My Reusable GitHub Actions and Workflows

## Overview

This project contains a collection of workflows and composable actions to
streamline CI/CD processes and ensure code quality. Below is a categorized
list of all workflows, grouped by their types.

## Testing Workflows

- [PHP Tests][php-tests]: Runs PHPUnit tests to ensure PHP code correctness.

## Linting and Formatting Workflows

- [Ansible Lint and Fix][ansible-lint-fix]: Lints and fixes Ansible playbooks
  and roles.
- [Biome Check][biome-check]: Runs Biome to lint multiple languages and formats.
- [Biome Fix][biome-fix]: Automatically fixes issues detected by Biome.
- [C# Lint Check][csharp-lint-check]: Lints C# code using tools like
  `dotnet-format`.
- [ESLint Check][eslint-check]: Runs ESLint to check for code style violations.
- [ESLint Fix][eslint-fix]: Automatically fixes code style issues with ESLint.
- [Go Lint Check][go-lint]: Lints Go code using `golangci-lint`.
- [Prettier Check][prettier-check]: Checks code formatting using Prettier.
- [Prettier Fix][prettier-fix]: Automatically fixes code formatting with
  Prettier.
- [Python Lint and Fix][python-lint-fix]: Lints and fixes Python code using
  `flake8` and `black`.
- [Terraform Lint and Fix][terraform-lint-fix]: Lints and fixes Terraform
  configurations.

## Build Workflows

- [C# Build][csharp-build]: Builds C# projects using the .NET SDK.
- [Docker Build][docker-build]: Builds Docker images using a Dockerfile.
- [Go Build][go-build]: Builds Go projects using the `go build` command.

## Deployment Workflows

- [C# Publish][csharp-publish]: Publishes .NET projects to an output directory.
- [Docker Publish to Docker Hub][docker-publish-hub]: Publishes Docker images to
  Docker Hub.
- [Docker Publish to GitHub Packages][docker-publish-gh]: Publishes Docker
  images to GitHub's Container Registry.
- [Publish to NPM][npm-publish]: Publishes packages to the NPM registry.

## Release Workflows

- [GitHub Release][github-release]: Automates GitHub release creation with
  custom tags and notes.
- [Release Monthly][release-monthly]: Creates a monthly GitHub release with
  autogenerated notes.

## Utility Workflows

- [Common File Check][common-file-check]: Checks for the presence of specific
  files based on a glob pattern.
- [Compress Images][compress-images]: Optimizes and creates a pull request with
  compressed images.
- [Dotnet Version Detect][dotnet-v-detect]: Detects the required .NET version
  from `global.json`.
- [Go Version Detect][go-version-detect]: Detects the required Go version from
  configuration files.
- [Node Setup][node-setup]: Sets up a Node.js environment for workflows.
- [PHP Composer][php-composer]: Installs PHP dependencies using Composer.
- [Pre-Commit][pre-commit]: Runs `pre-commit` hooks to enforce code quality
  standards.
- [Set Git Config][set-git-config]: Configures Git user information for
  automated commits.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE.md)
file for details.

[ansible-lint-fix]: composite-ansible-lint-fix/README.md
[common-file-check]: ./composite/common-file-check/README.md
[csharp-build]: composite-csharp-build/README.md
[csharp-lint-check]: composite-csharp-lint-check/README.md
[csharp-publish]: ./csharp-publish/README.md
[docker-build]: composite-docker-build/README.md
[docker-publish-gh]: composite-docker-publish-gh/README.md
[docker-publish-hub]: composite-docker-publish-hub/README.md
[dotnet-v-detect]: composite-dotnet-version-detect/README.md
[github-release]: composite-github-release/README.md
[go-build]: composite-go-build/README.md
[go-lint]: ./go-lint/README.md
[python-lint-fix]: ./python-lint-fix/README.md
[biome-check]: ./biome-check/README.md
[biome-fix]: ./biome-fix/README.md
[eslint-check]: ./eslint-check/README.md
[eslint-fix]: ./eslint-fix/README.md
[php-tests]: ./php-tests/README.md
[prettier-check]: ./prettier-check/README.md
[prettier-fix]: ./prettier-fix/README.md
[release-monthly]: ./release-monthly/README.md
[terraform-lint-fix]: composite-terraform-lint-fix/README.md

[compress-images]: ./compress-images/README.md
[go-version-detect]: composite-go-version-detect/README.md
[node-setup]: composite-node-setup/README.md
[npm-publish]: composite-npm-publish/README.md
[php-composer]: composite-php-composer/README.md
[pre-commit]: composite-pre-commit/README.md
[set-git-config]: composite-set-git-config/README.md
