# Claude Rules — Proposed Rules Files

Extracted from the former `docs/audit/claude-rules-auditor-findings.md` so this
proposal artifact survives that file's migration into the findings store
(`docs/audit/findings/`, auditor `agent-rules`) and its subsequent removal. All
six files listed here were created (Pass 1, 2026-05-03).

The only change from the source is that backslash-escaped backticks and `${{`
were unescaped. Those escapes were a v1 authoring artifact: inside these
` ```markdown ` fences they render literally, and the rule files that
actually shipped to `.claude/rules/` use plain backticks. Unescaping restores
what was proposed rather than altering it. The rule text itself is untouched —
for the rules as they stand today, read `.claude/rules/`, not this archive.

## `.claude/rules/communication-style.md`

Covers findings: R-002, R-003, R-004

```markdown
# Communication Style

Direct, factual, concise only.
Never use hype, buzzwords, jargon, clichés, assumptions, predictions, comparisons, or superlatives.
Never declare "production ready" until all checks pass (tests + linting + validation + zero warnings).
```

## `.claude/rules/code-quality.md`

Covers findings: R-005, R-006, R-007

```markdown
# Code Quality

Prioritize quality over speed. Write maintainable, DRY code.
Never hardcode counts in docs or code (action counts, validator counts) — run `make update-catalog` instead.
Ask when unsure rather than assuming.
```

## `.claude/rules/posix-shell.md`

Covers findings: R-008, R-009, R-010, R-011, R-012

```markdown
# POSIX Shell Compliance

All shell scripts must be POSIX sh, not bash — never use `[[]]`, `local`, `declare`, or the `function` keyword.
Always use `set -eu` at the top of every shell script.
Always quote shell variables: `"$var"`, `basename -- "$path"`.
Always check tool availability with `command -v <tool> >/dev/null 2>&1` before using jq, bc, terraform, or other optional tools.
Always provide fallbacks for tools unavailable on macOS or Windows runners.
```

## `.claude/rules/github-output-format.md`

Covers findings: R-013, R-014

```markdown
# GitHub Output Format

Always use printf with format-string separation for GITHUB_OUTPUT — never echo:
printf 'key=%s\n' "$value" >> "$GITHUB_OUTPUT"
Never use: echo "key=$value" >> "$GITHUB_OUTPUT"
Never nest `${{ }}` expressions inside quoted YAML strings (breaks hashFiles).
```

## `.claude/rules/github-actions-security.md`

Covers findings: R-015, R-016, R-017, R-018

```markdown
# GitHub Actions Security

Pin all external actions to full SHA commits — never use `@main` or `@v1` floating refs.
Reference internal actions as `ivuorinen/actions/<name>@<40-char-sha>` — never `./` or `@main`.
Always add `id:` to a step when its outputs are referenced via `steps.<id>.outputs.<key>`.
Always test regex patterns against pre-release inputs (`1.0.0-rc.1`, `1.0.0+build`).
```

## `.claude/rules/skills-usage.md`

Covers finding: R-019

```markdown
# Skills and Subagent Usage

Run skills and subagents proactively — do not wait to be asked.
Follow the routing table in CLAUDE.md: run `/action-health` after modifying an action,
`/pin-check` and `/security-audit` before creating a PR, etc.
```
