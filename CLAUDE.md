# CLAUDE.md - GitHub Actions Monorepo

Guidance for Claude Code (claude.ai/code) when working with this repository.

## 🚨 CRITICAL: Self-Contained Actions

All 40 actions MUST work independently as `ivuorinen/actions/action-name@main`. No relative paths or shared dependencies allowed.

## Repository Overview

**40 GitHub Actions** in flat directory structure, each self-contained with `action.yml`.

### Actions by Category

**Setup (7)**: `node-setup`, `set-git-config`, `php-version-detect`, `python-version-detect`, `python-version-detect-v2`, `go-version-detect`, `dotnet-version-detect`

**Utilities (2)**: `version-file-parser`, `version-validator`

**Linting (13)**: `ansible-lint-fix`, `biome-check`, `biome-fix`, `csharp-lint-check`, `eslint-check`, `eslint-fix`, `go-lint`,
`pr-lint`, `pre-commit`, `prettier-check`, `prettier-fix`, `python-lint-fix`, `terraform-lint-fix`

**Testing (3)**: `php-tests`, `php-laravel-phpunit`, `php-composer`

**Build (3)**: `csharp-build`, `go-build`, `docker-build`

**Publishing (5)**: `npm-publish`, `docker-publish`, `docker-publish-gh`, `docker-publish-hub`, `csharp-publish`

**Repository (7)**: `github-release`, `release-monthly`, `sync-labels`, `stale`, `compress-images`, `common-cache`, `common-file-check`

## Development

### Commands

```bash
make all     # Generate docs, format, lint
make dev     # Format then lint
make lint    # Run all linters
make format  # Format all files
make docs    # Generate documentation
```

### Linting Sequence

```bash
npx markdownlint-cli2 --fix "**/*.md"
npx prettier --write "**/*.md" "**/*.yml" "**/*.yaml" "**/*.json"
npx markdown-table-formatter "**/*.md"
npx yaml-lint "**/*.yml" "**/*.yaml"
actionlint
shellcheck **/*.sh
```

## Architecture Rules

### Composition Pattern

- ✅ Use full paths: `ivuorinen/actions/action-name@main`
- ❌ Never use: `./action-name` or `../shared/`
- ✅ Utility actions: `version-file-parser`, `version-validator`

### Security

- All external actions SHA-pinned
- Token authentication with `${{ github.token }}` fallback
- Shell scripts use `set -euo pipefail`

### Quality Standards

- EditorConfig: 2-space indent, UTF-8, LF
- Max line: 200 chars (120 for Markdown)
- README.md auto-generated via `action-docs`
- Comprehensive error handling required

## Testing Requirements

- Actions must work externally as `ivuorinen/actions/action-name@main`
- Test utility actions independently
- Validate modular composition patterns

---

**Note**: All actions achieve 100% external usability via modular composition.
