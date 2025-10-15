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

### Memory System

**Location**: `.serena/memories/` (9 consolidated memories for context)

**When to Use**: Read memories at session start or when needed for specific context. Be token-efficient - read only relevant memories for the task.

**Core Memories** (read first for project understanding):

- `repository_overview` – 43 actions, categories, structure, status
- `validator_system` – Validation architecture, components, usage patterns
- `development_standards` – Quality rules, workflows, security, completion checklist

**Reference Guides** (read when working on specific areas):

- `code_style_conventions` – EditorConfig, Shell/Python/YAML style, 10 critical prevention rules
- `suggested_commands` – Make targets, testing commands, tool usage
- `tech_stack` – Python/Node.js/Shell tools, paths, versions

**GitHub Actions Reference** (read when working with workflows):

- `github-workflow-expressions` – Expression syntax, contexts, operators, common patterns
- `github-workflow-commands` – Workflow commands (outputs, env, logging, masking)
- `github-workflow-secure-use` – Security best practices, secrets, injection prevention

**Memory Maintenance**: Update existing memories rather than create new ones. Keep content token-efficient and factual.

### Documentation Locations

**Validation System**: `validate-inputs/docs/` (4 guides: API.md, DEVELOPER_GUIDE.md, ACTION_MAINTAINER.md, README_ARCHITECTURE.md)

**Testing**: `_tests/README.md` (ShellSpec framework, test patterns, running tests)

**Docker Tools**: `_tools/docker-testing-tools/README.md` (CI setup, pre-built testing image)

**See**: `documentation_guide` memory for detailed descriptions and when to read each

## Repository Structure

Flat structure. Each action self-contained with `action.yml`.

**43 Actions**: Setup (node-setup, set-git-config, php-version-detect, python-version-detect, python-version-detect-v2, go-version-detect, dotnet-version-detect), Utilities (version-file-parser, version-validator),
Linting (ansible-lint-fix, biome-check, biome-fix, csharp-lint-check, eslint-check, eslint-fix, go-lint, pr-lint, pre-commit, prettier-check, prettier-fix, python-lint-fix, terraform-lint-fix),
Testing (php-tests, php-laravel-phpunit, php-composer), Build (csharp-build, go-build, docker-build),
Publishing (npm-publish, docker-publish, docker-publish-gh, docker-publish-hub, csharp-publish),
Repository (github-release, release-monthly, sync-labels, stale, compress-images, common-cache, common-file-check, common-retry, codeql-analysis),
Validation (validate-inputs)

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
