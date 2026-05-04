# Claude Rules Audit Findings

Generated: 2026-05-03
Last validated: 2026-05-03
Applied: 2026-05-03

## Summary

- Rules files audited: 8 (`.claude/rules/` — 7 project, 1 user-level)
- CLAUDE.md files audited: 1 (`CLAUDE.md`, 240 lines)
- Validation errors: 0 | Misplaced rules: 0 | Redundant rules: 0 | Suggestions: 0
- Pass 1: 19 rules migrated, 6 files created
- Pass 2: 2 rules added from arch-profile + security-findings, SEC-004 (pytest CVE) auto-fixed

## Open Findings

### Critical

#### [R-001] `.claude/rules/` absent — 19 atomic behavioral rules lack reliable enforcement

Category: validation
Area: `.claude/` directory (missing), `CLAUDE.md`
Problem: No `.claude/rules/` directory exists. `CLAUDE.md` contains 19 atomic behavioral
mandates. CLAUDE.md is delivered as a user message after the system prompt — there is no
strict compliance guarantee for vague or conflicting instructions. Security-critical and
zero-tolerance rules need dedicated `.claude/rules/` files for more reliable enforcement.
Evidence: 19 behavioral mandates identified across Standards, Architecture, and Skills &
Subagents sections (see Misplaced findings below).
Impact: Claude may silently deviate from critical mandates (POSIX compliance, SHA pinning,
GITHUB_OUTPUT format) because CLAUDE.md does not have the enforcement reliability of
path-injected rules files.
Fix: Create `.claude/rules/` directory and migrate the 19 rules into 6 focused files:
`communication-style.md`, `code-quality.md`, `posix-shell.md`,
`github-output-format.md`, `github-actions-security.md`, `skills-usage.md`.

#### [R-002] CLAUDE.md L21 — communication style rule misplaced

Category: misplaced
Area: `CLAUDE.md:21`
Evidence: `- Direct, factual, concise only`
Fix: Move to `.claude/rules/communication-style.md`

#### [R-003] CLAUDE.md L22 — prohibited language rule misplaced

Category: misplaced
Area: `CLAUDE.md:22`
Evidence: `- Prohibited: hype, buzzwords, jargon, clichés, assumptions, predictions, comparisons, superlatives`
Fix: Move to `.claude/rules/communication-style.md`

#### [R-004] CLAUDE.md L23 — no premature production-ready declaration misplaced

Category: misplaced
Area: `CLAUDE.md:23`
Evidence: `- Never declare "production ready" until all checks pass`
Fix: Move to `.claude/rules/communication-style.md`

#### [R-005] CLAUDE.md L14 — quality-over-speed rule misplaced

Category: misplaced
Area: `CLAUDE.md:14`
Evidence: `- Prioritize quality over speed, write maintainable/DRY code`
Fix: Move to `.claude/rules/code-quality.md`

#### [R-006] CLAUDE.md L16 — no-hardcoded-counts rule misplaced

Category: misplaced
Area: `CLAUDE.md:16`
Evidence: `- No hardcoded counts in docs/code (action counts, validator counts) — use \`make update-catalog\` instead`Fix: Move to`.claude/rules/code-quality.md`

#### [R-007] CLAUDE.md L17 — ask-when-unsure rule misplaced

Category: misplaced
Area: `CLAUDE.md:17`
Evidence: `- Ask when unsure`
Fix: Move to `.claude/rules/code-quality.md`

#### [R-008] CLAUDE.md L47 — POSIX-sh-only hook rule misplaced

Category: misplaced
Area: `CLAUDE.md:47`
Evidence: `- Bash-isms in .sh/action.yml — must be POSIX sh (\`[[]]\`, \`local\`, \`declare\`, \`function\` keyword)`Fix: Move to`.claude/rules/posix-shell.md`

#### [R-009] CLAUDE.md L133 — set-eu requirement misplaced

Category: misplaced
Area: `CLAUDE.md:133`
Evidence: `8. Use \`set -eu\` (POSIX) in shell scripts (all scripts are POSIX sh, not bash)`Fix: Move to`.claude/rules/posix-shell.md`

#### [R-010] CLAUDE.md L129 — quote-shell-vars rule misplaced

Category: misplaced
Area: `CLAUDE.md:129`
Evidence: `5. Quote shell vars: \`"$var"\`, \`basename -- "$path"\` (handles spaces)`Fix: Move to`.claude/rules/posix-shell.md`

#### [R-011] CLAUDE.md L126 — check-tool-availability rule misplaced

Category: misplaced
Area: `CLAUDE.md:126`
Evidence: `2. Check tool availability: \`command -v jq >/dev/null 2>&1\` (jq/bc/terraform not on all runners)`Fix: Move to`.claude/rules/posix-shell.md`

#### [R-012] CLAUDE.md L135 — provide-tool-fallbacks rule misplaced

Category: misplaced
Area: `CLAUDE.md:135`
Evidence: `10. Provide tool fallbacks (macOS/Windows lack Linux tools)`
Fix: Move to `.claude/rules/posix-shell.md`

#### [R-013] CLAUDE.md L127+L139 — GITHUB_OUTPUT printf rule misplaced

Category: misplaced
Area: `CLAUDE.md:127,139`
Evidence: `Always use printf with format-string separation — never echo` (stated at L139;
referenced in numbered list at L127)
Fix: Move to `.claude/rules/github-output-format.md`

#### [R-014] CLAUDE.md L134 — no nested expressions in quoted YAML rule misplaced

Category: misplaced
Area: `CLAUDE.md:134`
Evidence: `9. Never nest \`\${{ }}\` in quoted YAML strings (breaks hashFiles)`Fix: Move to`.claude/rules/github-output-format.md`

#### [R-015] CLAUDE.md L128 — pin external actions rule misplaced

Category: misplaced
Area: `CLAUDE.md:128`
Evidence: `4. Pin external actions to SHA commits (not \`@main\`/\`@v1\`)`Fix: Move to`.claude/rules/github-actions-security.md`

#### [R-016] CLAUDE.md L130 — SHA-pin internal actions rule misplaced

Category: misplaced
Area: `CLAUDE.md:130`
Evidence: `6. Use SHA-pinned refs for internal actions: \`ivuorinen/actions/action-name@<SHA>\``Fix: Move to`.claude/rules/github-actions-security.md`

#### [R-017] CLAUDE.md L125 — add id when outputs referenced rule misplaced

Category: misplaced
Area: `CLAUDE.md:125`
Evidence: `1. Add \`id:\` when outputs referenced (\`steps.x.outputs.y\` requires \`id: x\`)`Fix: Move to`.claude/rules/github-actions-security.md`

#### [R-018] CLAUDE.md L132 — test regex edge cases rule misplaced

Category: misplaced
Area: `CLAUDE.md:132`
Evidence: `7. Test regex edge cases (support \`1.0.0-rc.1\`, \`1.0.0+build\`)`Fix: Move to`.claude/rules/github-actions-security.md`

#### [R-019] CLAUDE.md L58 — skills proactive usage rule misplaced

Category: misplaced
Area: `CLAUDE.md:58`
Evidence: `**Run proactively** — don't wait to be asked:`
Fix: Move to `.claude/rules/skills-usage.md`

### Medium

#### [R-020] CLAUDE.md still 240 lines — context-mode block (≈60 lines) prevents reaching 200

Category: validation
Area: `CLAUDE.md`
Problem: After migrating 19 rules, CLAUDE.md is 240 lines. The remaining overage is the
context-mode routing block (lines ~180–240) which is mandatory meta-documentation injected
from the global CLAUDE.md. Project-authored content is ≈180 lines (under 200).
Evidence: `wc -l CLAUDE.md` → 240; context-mode block ≈60 lines
Impact: Low — the rules most at risk of being buried have been moved to `.claude/rules/`.
Fix: Accept as-is. The 200-line guideline is met for project-authored content.

### Advisory

(none — all advisories resolved in Pass 2)

## Proposed Rules Files

### `.claude/rules/communication-style.md`

Covers findings: R-002, R-003, R-004

```markdown
# Communication Style

Direct, factual, concise only.
Never use hype, buzzwords, jargon, clichés, assumptions, predictions, comparisons, or superlatives.
Never declare "production ready" until all checks pass (tests + linting + validation + zero warnings).
```

### `.claude/rules/code-quality.md`

Covers findings: R-005, R-006, R-007

```markdown
# Code Quality

Prioritize quality over speed. Write maintainable, DRY code.
Never hardcode counts in docs or code (action counts, validator counts) — run \`make update-catalog\` instead.
Ask when unsure rather than assuming.
```

### `.claude/rules/posix-shell.md`

Covers findings: R-008, R-009, R-010, R-011, R-012

```markdown
# POSIX Shell Compliance

All shell scripts must be POSIX sh, not bash — never use \`[[]]\`, \`local\`, \`declare\`, or the \`function\` keyword.
Always use \`set -eu\` at the top of every shell script.
Always quote shell variables: \`"$var"\`, \`basename -- "$path"\`.
Always check tool availability with \`command -v <tool> >/dev/null 2>&1\` before using jq, bc, terraform, or other optional tools.
Always provide fallbacks for tools unavailable on macOS or Windows runners.
```

### `.claude/rules/github-output-format.md`

Covers findings: R-013, R-014

```markdown
# GitHub Output Format

Always use printf with format-string separation for GITHUB_OUTPUT — never echo:
printf 'key=%s\n' "$value" >> "$GITHUB_OUTPUT"
Never use: echo "key=$value" >> "$GITHUB_OUTPUT"
Never nest \`\${{ }}\` expressions inside quoted YAML strings (breaks hashFiles).
```

### `.claude/rules/github-actions-security.md`

Covers findings: R-015, R-016, R-017, R-018

```markdown
# GitHub Actions Security

Pin all external actions to full SHA commits — never use \`@main\` or \`@v1\` floating refs.
Reference internal actions as \`ivuorinen/actions/<name>@<40-char-sha>\` — never \`./\` or \`@main\`.
Always add \`id:\` to a step when its outputs are referenced via \`steps.<id>.outputs.<key>\`.
Always test regex patterns against pre-release inputs (\`1.0.0-rc.1\`, \`1.0.0+build\`).
```

### `.claude/rules/skills-usage.md`

Covers finding: R-019

```markdown
# Skills and Subagent Usage

Run skills and subagents proactively — do not wait to be asked.
Follow the routing table in CLAUDE.md: run \`/action-health\` after modifying an action,
\`/pin-check\` and \`/security-audit\` before creating a PR, etc.
```

## Fixed

### Pass 1 — 2026-05-03

#### [R-001] `.claude/rules/` created — 19 rules migrated

Fixed: 2026-05-03
Notes: Created `.claude/rules/` with 6 files: `communication-style.md`,
`code-quality.md`, `posix-shell.md`, `github-output-format.md`,
`github-actions-security.md`, `skills-usage.md`. Removed corresponding
rule statements from CLAUDE.md. CLAUDE.md reduced from 266 to 240 lines.

#### [R-002 through R-019] All misplaced rules migrated to .claude/rules/

Fixed: 2026-05-03
Notes: All 19 misplaced rule statements removed from CLAUDE.md and
placed in the appropriate rules file per findings above.

### Pass 2 — 2026-05-03

#### [R-021] Missing arch-profile.md and security-findings.md — artifacts generated

Fixed: 2026-05-03
Notes: Ran `arch-detector` and `security-auditor` skills. Produced
`docs/audit/arch-profile.md` and `docs/audit/security-findings.md`.

#### [R-022] communication-style.md moved to user-level

Fixed: 2026-05-03
Notes: Moved from `.claude/rules/communication-style.md` to
`~/.claude/rules/communication-style.md` so it applies to all projects.

#### [R-023] test-file-placement.md created

Fixed: 2026-05-03
Notes: Created `.claude/rules/test-file-placement.md` capturing the
`_tests/unit/<action-name>/` and `_tests/integration/` placement convention.

#### [R-024] validate-inputs-pattern.md created from arch-profile Rule 2/5/8

Fixed: 2026-05-03
Notes: Created `.claude/rules/validate-inputs-pattern.md` from arch-profile
structural rules: validation gate mandatory, no inlined validation logic,
`*/rules.yml` never hand-edited.

#### [R-025] workflow-inputs-safety.md created from SEC-001/002/003/005/006

Fixed: 2026-05-03
Notes: Created `.claude/rules/workflow-inputs-safety.md` — never interpolate
workflow_dispatch/action inputs directly into shell `run:` steps; use `env:` block.

#### [SEC-004] pytest upgraded to 9.0.3 (CVE-2025-71176)

Fixed: 2026-05-03
Notes: Ran `uv lock --upgrade-package pytest` in `validate-inputs/`. pytest
upgraded to 9.0.3 for Python ≥ 3.10. Python < 3.10 remains on 8.4.2 —
pytest 9.x dropped Python < 3.10 support so no fix available for those runtimes.

## Invalid

(none yet)
