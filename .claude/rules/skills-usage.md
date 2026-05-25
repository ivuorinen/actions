# Skills and Subagent Usage

Run skills and subagents proactively — do not wait to be asked. Discovery of an applicable trigger is enough; do not ask permission.
Follow the complete routing table in CLAUDE.md `### Skills & Subagents` section. The full mapping is:

- After modifying any action: run `/action-health <name>`.
- After creating an action modeled on another: run `/compare-actions <source> <new>`.
- Before opening any PR: run both `/pin-check` AND `/security-audit` — never one without the other.
- When reviewing Renovate PRs: invoke the `renovate-pr-reviewer` subagent.
- Before any release: run both `/changelog` AND `/validate`.
- Periodically during a session, and after any large multi-file change: invoke the `action-consistency-auditor` subagent.
- When asked to "review the whole repo", "audit", "find all problems", "tear apart", or run a release-gate check: invoke the `nitpicker` skill.
- When implementing PR review comments: invoke the `cr-implementer` skill.
- When reviewing a diff or PR: invoke the `pr-reviewer` skill.
- When checking for security issues: invoke `security-auditor`.
- When auditing architecture: invoke `arch-detector` then `arch-auditor`.
- When auditing documentation: invoke `doc-auditor`.
- When auditing `.claude/rules/` or `CLAUDE.md`: invoke `claude-rules-auditor`.

Never skip a trigger because "it's a small change" or "I already checked recently" — every semantic modification triggers its checks.
"Modification" here means a deliberate semantic change. Pure auto-format edits that
the PostToolUse formatter applies to a file you already saved (whitespace, quote
style, line wrapping, table alignment) are not modifications and do not retrigger
`/action-health` or any other skill. Any edit that changes a value, a control flow,
a list of inputs, a SHA pin, a documentation line, or a comment IS a modification —
no matter how small — and triggers its checks.
"Already checked recently" is never a defense: if you modified an action twice in
one session, `/action-health` runs twice.
