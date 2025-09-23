# CLAUDE.md - GitHub Actions Monorepo

**Mantra**: Zero defects. Zero exceptions.

Authoritative guidance for Claude Code (claude.ai/code). All rules are mandatory and non-negotiable.

## Absolute Standards

### Zero Tolerance

- Any failing tests or linting issues = not production ready
- No exceptions

### Production Ready

A project is production ready only when:

- All tests pass
- All linting passes
- All validation checks pass
- No warnings or errors

### Rules

- Follow conventions and best practices
- Fix and understand all issues before completion
- Never compromise standards
- Test thoroughly
- Prioritize quality over speed
- Write maintainable, simple, DRY code
- Document all changes
- Communicate factually
- Review carefully
- Use memory files wisely, update rather than add
- Ask when unsure

### Communication

- Be direct, factual, concise
- Prohibited: hype, buzzwords, jargon, clichés, assumptions, predictions, comparisons, superlatives, promotional or subjective terms
- Do not declare success or "production ready" until all rules pass

### Folder Rules

- `.serena/` – Internal config, do not edit
- `.github/` – Workflows and templates
- `_tests/` – ShellSpec tests
- `_tools/` – Helper tools
- `validate-inputs/` – Python validation system
- `validate-inputs/rules/` – Auto-generated, do not edit
- `validate-inputs/tests/` – pytest tests

## Repository

Flat structure. Each action self-contained with `action.yml`.

### Actions

**Setup**: `node-setup`, `set-git-config`, `php-version-detect`, `python-version-detect`, `python-version-detect-v2`, `go-version-detect`, `dotnet-version-detect`
**Utilities**: `version-file-parser`, `version-validator`
**Linting**: `ansible-lint-fix`, `biome-check`, `biome-fix`, `csharp-lint-check`, `eslint-check`, `eslint-fix`, `go-lint`, `pr-lint`, `pre-commit`, `prettier-check`, `prettier-fix`, `python-lint-fix`, `terraform-lint-fix`
**Testing**: `php-tests`, `php-laravel-phpunit`, `php-composer`
**Build**: `csharp-build`, `go-build`, `docker-build`
**Publishing**: `npm-publish`, `docker-publish`, `docker-publish-gh`, `docker-publish-hub`, `csharp-publish`
**Repository**: `github-release`, `release-monthly`, `sync-labels`, `stale`, `compress-images`, `common-cache`, `common-file-check`, `common-retry`

## Development & Testing

### Commands

- `make all` – Generate docs, format, lint, test
- `make dev` – Format then lint
- `make lint` – Run all linters
- `make format` – Format files
- `make docs` – Generate docs
- `make test` – Run all tests
- `make test-python` – Run Python tests
- `make test-python-coverage` – Python coverage
- `make test-actions` – Run shell tests
- `make test-update-validators` – Validator tests
- `make test-coverage` – All with coverage
- `make update-validators` – Update validation rules
- `make update-validators-dry` – Preview validator changes
- `make check-local-refs` – Check for `../` references
- `make fix-local-refs` – Fix `../` references
- `make fix-local-refs-dry` – Preview ref fixes

### Linting

Run `make lint` or `make lint-*`. Avoid direct linter calls unless required.

- `npx markdownlint-cli2 --fix "**/*.md"`
- `npx prettier --write "**/*.md" "**/*.yml" "**/*.yaml" "**/*.json"`
- `npx markdown-table-formatter "**/*.md"`
- `npx yaml-lint "**/*.yml" "**/*.yaml"`
- `actionlint`
- `find . -name "*.sh" -not -path "./_tests/*" -exec shellcheck -x {} +`
- `uv run ruff check --fix validate-inputs/`
- `uv run ruff format validate-inputs/`

### Test Rules

- ShellSpec for Actions (`_tests/`)
- pytest for validation (`validate-inputs/tests/`)
- Full coverage required
- Independent action tests
- Integration tests required

## Architecture Rules

- All external actions SHA-pinned
- Use `${{ github.token }}` for auth
- Shell scripts: `set -euo pipefail`
- EditorConfig: 2-space indent, UTF-8, LF
- Max line length: 200 (120 for Markdown)
- `README.md` auto-generated via `action-docs`
- Error handling required

### Local Action References

- ✅ `uses: ./action-name`
- ❌ `uses: ../action-name`

Check with: `make check-local-refs`, `make fix-local-refs`

## Validation System

### Centralized

- Location: `validate-inputs/`
- Rules: YAML in `validate-inputs/rules/`
- Security: regex, injection protection
- Generator: Python script

### Convention Rules

- `token` → GitHub token, `*-version` → SemVer/CalVer/flexible, `email` → email format, `dockerfile` → file path, `dry-run` → boolean, `architectures` → Docker architectures, `*-retries` → numeric range

### Version Types

- `semantic_version`, `calver_version`, `flexible_version`, `dotnet_version`, `terraform_version`, `node_version`

**Supported CalVer**: YYYY.MM.PATCH (2024.3.1), YYYY.MM.DD (2024.3.15), YYYY.0M.0D (2024.03.05), YY.MM.MICRO (24.3.1), YYYY.MM (2024.3), YYYY-MM-DD (2024-03-15)

### Maintenance

- `make update-validators`
- `git diff validate-inputs/rules/`

---

**Summary**: Every rule here is absolute. No exceptions. All code, tests, and communication must meet these standards. All actions are modular and externally usable.

- `npx action-docs --update-readme` does not update readmes.
