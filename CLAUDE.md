# CLAUDE.md - GitHub Actions Monorepo

**Mantra**: Zero defects. Zero exceptions. All rules mandatory and non-negotiable.

## Standards

### Production Ready Criteria

- All tests pass + all linting passes + all validation passes + zero warnings

### Core Rules

- Follow conventions, fix all issues, never compromise standards, test thoroughly
- Prioritize quality over speed, write maintainable/DRY code
- Document changes, communicate factually, review carefully
- Update existing memory files rather than create new ones
- Ask when unsure

### Communication

- Direct, factual, concise only
- Prohibited: hype, buzzwords, jargon, clichés, assumptions, predictions, comparisons, superlatives
- Never declare "production ready" until all checks pass

### Folders

- `.serena/` – Internal config (do not edit)
- `.github/` – Workflows/templates
- `_tests/` – ShellSpec tests
- `_tools/` – Helper tools
- `validate-inputs/` – Python validation system + tests
- `*/rules.yml` – Auto-generated validation rules

## Repository Structure

Flat structure. Each action self-contained with `action.yml`.

**Actions**: Setup (node-setup, set-git-config, php-version-detect, python-version-detect, python-version-detect-v2, go-version-detect, dotnet-version-detect), Utilities (version-file-parser, version-validator),
Linting (ansible-lint-fix, biome-check, biome-fix, csharp-lint-check, eslint-check, eslint-fix, go-lint, pr-lint, pre-commit, prettier-check, prettier-fix, python-lint-fix, terraform-lint-fix),
Testing (php-tests, php-laravel-phpunit, php-composer), Build (csharp-build, go-build, docker-build),
Publishing (npm-publish, docker-publish, docker-publish-gh, docker-publish-hub, csharp-publish),
Repository (github-release, release-monthly, sync-labels, stale, compress-images, common-cache, common-file-check, common-retry, codeql-analysis)

## Commands

**Main**: `make all` (docs+format+lint+test), `make dev` (format+lint), `make lint`, `make format`, `make docs`, `make test`

**Testing**: `make test-python`, `make test-python-coverage`, `make test-actions`, `make test-update-validators`, `make test-coverage`

**Validation**: `make update-validators`, `make update-validators-dry`

**References**: `make check-local-refs`, `make fix-local-refs`, `make fix-local-refs-dry`

### Linters

Use `make lint` (not direct calls). Runs: markdownlint-cli2, prettier, markdown-table-formatter, yaml-lint, actionlint, shellcheck, ruff

### Tests

ShellSpec (`_tests/`) + pytest (`validate-inputs/tests/`). Full coverage + independent + integration tests required.

## Architecture - Critical Prevention (Zero Tolerance)

Violations cause runtime failures:

1. Add `id:` when outputs referenced (`steps.x.outputs.y` requires `id: x`)
2. Check tool availability: `command -v jq >/dev/null 2>&1` (jq/bc/terraform not on all runners)
3. Sanitize `$GITHUB_OUTPUT`: use `printf '%s\n' "$val"` not `echo "$val"`
4. Pin external actions to SHA commits (not `@main`/`@v1`)
5. Quote shell vars: `"$var"`, `basename -- "$path"` (handles spaces)
6. Use local paths: `./action-name` (not `owner/repo/action@main`)
7. Test regex edge cases (support `1.0.0-rc.1`, `1.0.0+build`)
8. Use `set -euo pipefail` at script start
9. Never nest `${{ }}` in quoted YAML strings (breaks hashFiles)
10. Provide tool fallbacks (macOS/Windows lack Linux tools)

### Core Requirements

- External actions SHA-pinned, use `${{ github.token }}`, `set -euo pipefail`
- EditorConfig: 2-space indent, UTF-8, LF, max 200 chars (120 for MD)
- Auto-gen README via `action-docs` (note: `npx action-docs --update-readme` doesn't work)
- Required error handling

### Action References

✅ `./action-name` | ❌ `../action-name` | ❌ `owner/repo/action@main`

Check: `make check-local-refs`, `make fix-local-refs`

## Validation System

**Location**: `validate-inputs/` (YAML rules.yml per action, Python generator)

**Conventions**: `token`→GitHub token, `*-version`→SemVer/CalVer, `email`→format, `dockerfile`→path, `dry-run`→bool, `architectures`→Docker, `*-retries`→range

**Version Types**: semantic_version, calver_version, flexible_version, dotnet_version, terraform_version, node_version

**CalVer Support**: YYYY.MM.PATCH, YYYY.MM.DD, YYYY.0M.0D, YY.MM.MICRO, YYYY.MM, YYYY-MM-DD

**Maintenance**: `make update-validators`, `git diff validate-inputs/rules/`

---

All actions modular and externally usable. No exceptions to any rule.
