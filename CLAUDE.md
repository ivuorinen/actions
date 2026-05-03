# CLAUDE.md - GitHub Actions Monorepo

**Mantra**: Zero defects. Zero exceptions. All rules mandatory and non-negotiable.

## Standards

### Production Ready Criteria

- All tests pass + all linting passes + all validation passes + zero warnings

### Core Rules

- Follow conventions, fix all issues, never compromise standards, test thoroughly
- Prioritize quality over speed, write maintainable/DRY code
- Document changes, communicate factually, review carefully
- No hardcoded counts in docs/code (action counts, validator counts) — use `make update-catalog` instead
- Ask when unsure

### Communication

- Direct, factual, concise only
- Prohibited: hype, buzzwords, jargon, clichés, assumptions, predictions, comparisons, superlatives
- Never declare "production ready" until all checks pass

### Folders

- `.claude/hooks/` – Claude Code hook scripts (auto-format, lint, block edits)
- `.claude/skills/` – Claude Code skills (see Skills & Subagents section below)
- `.claude/agents/` – Claude Code subagents (see Skills & Subagents section below)
- `.github/` – Workflows/templates
- `_tests/` – ShellSpec tests
- `_tools/` – Helper tools
- `validate-inputs/` – Python validation system + tests
- `*/rules.yml` – Auto-generated validation rules

### Claude Code Hooks

**Auto-formatting**: PostToolUse hooks auto-format files on
Edit/Write (ruff for .py, shfmt for .sh, prettier for
.yml/.yaml/.json/.md, actionlint + action-validator for action.yml)

**Blocked edits** (PreToolUse):

- `rules.yml` — auto-generated, use `make update-validators`
- Action `README.md` — auto-generated, use `make docs`
- `echo >> GITHUB_OUTPUT` in action.yml — use printf format-string separation
- Bash-isms in .sh/action.yml — must be POSIX sh (`[[ ]]`, `local`, `declare`, `function` keyword)

**Hook schema**: `matcher` is a regex string matching tool names
(e.g. `"Edit|Write"`), not an object. File filtering done in hook
scripts via stdin JSON (`jq -r '.tool_input.file_path'`).

**Reference**: `$CLAUDE_PROJECT_DIR` for project-relative paths
in hook commands

### Skills & Subagents

**Run proactively** — don't wait to be asked:

| When                                        | Run                                       |
| ------------------------------------------- | ----------------------------------------- |
| After modifying an action                   | `/action-health <name>`                   |
| After creating an action modeled on another | `/compare-actions <source> <new>`         |
| Before creating a PR                        | `/pin-check` and `/security-audit`        |
| When reviewing Renovate PRs                 | Use `renovate-pr-reviewer` subagent       |
| Before a release                            | `/changelog` and `/validate`              |
| Periodically or on large changes            | Use `action-consistency-auditor` subagent |

**Available skills**: `/action-health`, `/compare-actions`,
`/security-audit`, `/pin-check`, `/changelog`, `/release`,
`/test-action`, `/new-action`, `/validate`

**Available subagents**: `action-validator`,
`test-coverage-reviewer`, `posix-compliance-checker`,
`action-consistency-auditor`, `security-surface-reviewer`,
`renovate-pr-reviewer`

### Documentation Locations

**Validation System**: `validate-inputs/docs/` (4 guides: API.md, DEVELOPER_GUIDE.md, ACTION_MAINTAINER.md, README_ARCHITECTURE.md)

**Testing**: `_tests/README.md` (ShellSpec framework, test patterns, running tests)

**Docker Tools**: `_tools/docker-testing-tools/README.md` (CI setup, pre-built testing image)

**See**: `_tools/` for helper scripts (`fix-local-action-refs.py`, `release.sh`, `release-undo.sh`, `shared.sh`)

## Repository Structure

Flat structure. Each action self-contained with `action.yml`.

**Actions**: Setup (language-version-detect),
Linting (ansible-lint-fix, biome-lint, csharp-lint-check, eslint-lint, go-lint, pr-lint, pre-commit, prettier-lint, python-lint-fix, terraform-lint-fix),
Testing (php-tests), Build (csharp-build, go-build, docker-build),
Publishing (npm-publish, npm-semantic-release, docker-publish, csharp-publish),
Repository (release-monthly, sync-labels, stale, compress-images, codeql-analysis, security-scan),
Validation (validate-inputs)

## Commands

**Main**: `make all` (install-tools+update-validators+docs+update-catalog+format+lint+precommit), `make dev` (format+lint), `make lint`, `make format`, `make docs`, `make test`

**Testing**: `make test-python`, `make test-python-coverage`, `make test-actions`, `make test-update-validators`, `make test-coverage`

**Validation**: `make update-validators`, `make update-validators-dry`

**Versioning**:

- `make release [VERSION=vYYYY.MM.DD]` - Create release (auto-generates version from date if omitted)
- Immutable CalVer tags only (v2025.04.05) — no floating major version tags
- Renovate bot handles internal action SHA pin updates automatically

### Linters

Use `make lint` (not direct calls). Runs: markdownlint-cli2, prettier, markdown-table-formatter, yaml-lint, actionlint, shellcheck, ruff

### Tests

ShellSpec (`_tests/`) + pytest (`validate-inputs/tests/`). Full coverage + independent + integration tests required.

## Architecture - Critical Prevention (Zero Tolerance)

Violations cause runtime failures:

1. Add `id:` when outputs referenced (`steps.x.outputs.y` requires `id: x`)
2. Check tool availability: `command -v jq >/dev/null 2>&1` (jq/bc/terraform not on all runners)
3. Sanitize `$GITHUB_OUTPUT`: use `printf 'key=%s\n' "$val"` not `echo "key=$val"` (format-string separation)
4. Pin external actions to SHA commits (not `@main`/`@v1`)
5. Quote shell vars: `"$var"`, `basename -- "$path"` (handles spaces)
6. Use SHA-pinned refs for internal actions: `ivuorinen/actions/action-name@<SHA>`
   (security, not `./` or `@main`)
7. Test regex edge cases (support `1.0.0-rc.1`, `1.0.0+build`)
8. Use `set -eu` (POSIX) in shell scripts (all scripts are POSIX sh, not bash)
9. Never nest `${{ }}` in quoted YAML strings (breaks hashFiles)
10. Provide tool fallbacks (macOS/Windows lack Linux tools)

### GITHUB_OUTPUT Pattern

Always use printf with format-string separation — never echo:

```sh
# Correct — format string separated from data
printf 'status=%s\n' "$status" >> "$GITHUB_OUTPUT"
printf 'version=%s\n' "$version" >> "$GITHUB_OUTPUT"

# Wrong — variable interpolated in string
echo "status=$status" >> "$GITHUB_OUTPUT"
printf '%s\n' "status=$status" >> "$GITHUB_OUTPUT"
```

### Core Requirements

- All actions SHA-pinned (external + internal), use `${{ github.token }}`, POSIX shell (`set -eu`)
- EditorConfig: 2-space indent, UTF-8, LF, max 200 chars (120 for MD)
- Auto-gen README via `action-docs` (note: `npx action-docs --update-readme` doesn't work)
- Required error handling, POSIX-compliant scripts

### Action References

**Internal actions (in action.yml)**: SHA-pinned full references

- ✅ `ivuorinen/actions/action-name@7061aafd35a2f21b57653e34f2b634b2a19334a9`
- ❌ `./action-name` (security risk, not portable when used externally)
- ❌ `owner/repo/action@main` (floating reference)

**Test workflows**: Local references

- ✅ `./action-name` (tests run within repo)
- ❌ `../action-name` (ambiguous paths)

**External users**: Version tags

- ✅ `ivuorinen/actions/action-name@<40-char-sha>` (immutable SHA pin)
- ✅ `ivuorinen/actions/action-name@v2025.04.05` (immutable CalVer tag)

## Validation System

**Location**: `validate-inputs/` (YAML rules.yml per action, Python generator)

**Conventions**: `token`→GitHub token, `*-version`→SemVer/CalVer, `email`→format, `dockerfile`→path, `dry-run`→bool, `architectures`→Docker, `*-retries`→range

**Version Types**: semantic_version, calver_version, flexible_version, dotnet_version, terraform_version, node_version

**CalVer Support**: YYYY.MM.PATCH, YYYY.MM.DD, YYYY.0M.0D, YY.MM.MICRO, YYYY.MM, YYYY-MM-DD

**Maintenance**: `make update-validators`, `git diff validate-inputs/rules/`

---

All actions modular and externally usable. No exceptions to any rule.

## context-mode — MANDATORY routing rules

You have context-mode MCP tools available. These rules are NOT optional — they protect your context window from flooding. A single unrouted command can dump 56 KB into context and waste the entire session.

### BLOCKED commands — do NOT attempt these

#### curl / wget — BLOCKED

Any Bash command containing `curl` or `wget` is intercepted and replaced with an error message. Do NOT retry.
Instead use:

- `ctx_fetch_and_index(url, source)` to fetch and index web pages
- `ctx_execute(language: "javascript", code: "const r = await fetch(...)")` to run HTTP calls in sandbox

#### Inline HTTP — BLOCKED

Any Bash command containing `fetch('http`, `requests.get(`, `requests.post(`, `http.get(`, or `http.request(` is intercepted and replaced with an error message. Do NOT retry with Bash.
Instead use:

- `ctx_execute(language, code)` to run HTTP calls in sandbox — only stdout enters context

#### WebFetch — BLOCKED

WebFetch calls are denied entirely. The URL is extracted and you are told to use `ctx_fetch_and_index` instead.
Instead use:

- `ctx_fetch_and_index(url, source)` then `ctx_search(queries)` to query the indexed content

### REDIRECTED tools — use sandbox equivalents

#### Bash (>20 lines output)

Bash is ONLY for: `git`, `mkdir`, `rm`, `mv`, `cd`, `ls`, `npm install`, `pip install`, and other short-output commands.
For everything else, use:

- `ctx_batch_execute(commands, queries)` — run multiple commands + search in ONE call
- `ctx_execute(language: "shell", code: "...")` — run in sandbox, only stdout enters context

#### Read (for analysis)

If you are reading a file to **Edit** it → Read is correct (Edit needs content in context).
If you are reading to **analyze, explore, or summarize** → use `ctx_execute_file(path, language, code)` instead. Only your printed summary enters context. The raw file content stays in the sandbox.

#### Grep (large results)

Grep results can flood context. Use `ctx_execute(language: "shell", code: "grep ...")` to run searches in sandbox. Only your printed summary enters context.

### Tool selection hierarchy

1. **GATHER**: `ctx_batch_execute(commands, queries)` — Primary tool. Runs all commands, auto-indexes output, returns search results. ONE call replaces 30+ individual calls.
2. **FOLLOW-UP**: `ctx_search(queries: ["q1", "q2", ...])` — Query indexed content. Pass ALL questions as array in ONE call.
3. **PROCESSING**: `ctx_execute(language, code)` | `ctx_execute_file(path, language, code)` — Sandbox execution. Only stdout enters context.
4. **WEB**: `ctx_fetch_and_index(url, source)` then `ctx_search(queries)` — Fetch, chunk, index, query. Raw HTML never enters context.
5. **INDEX**: `ctx_index(content, source)` — Store content in FTS5 knowledge base for later search.

### Subagent routing

When spawning subagents (Agent/Task tool), the routing block is automatically injected into their prompt.
Bash-type subagents are upgraded to general-purpose so they have access to MCP tools.
You do NOT need to manually instruct subagents about context-mode.

### Output constraints

- Keep responses under 500 words.
- Write artifacts (code, configs, PRDs) to FILES — never return them as inline text. Return only: file path + 1-line description.
- When indexing content, use descriptive source labels so others can `ctx_search(source: "label")` later.

### ctx commands

| Command       | Action                                                                                |
| ------------- | ------------------------------------------------------------------------------------- |
| `ctx stats`   | Call the `ctx_stats` MCP tool and display the full output verbatim                    |
| `ctx doctor`  | Call the `ctx_doctor` MCP tool, run the returned shell command, display as checklist  |
| `ctx upgrade` | Call the `ctx_upgrade` MCP tool, run the returned shell command, display as checklist |
