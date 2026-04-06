---
name: security-audit
description: Run security analysis across all or a specific action
---

# Security Audit

Run a security analysis on all actions or a specific action. Dispatches the security-surface-reviewer subagent for deep analysis.

## Arguments

- `<action-name>` (optional): Name of a specific action to audit. If omitted, audits all actions.

## Steps

### 1. Determine scope

- If `<action-name>` is provided, verify `<action-name>/action.yml` or `<action-name>/action.yaml` exists. Abort if neither is found.
- If no argument, collect all directories containing `action.yml` or `action.yaml`.

### 2. Dispatch security-surface-reviewer subagent

Use the subagent defined in `.claude/agents/security-surface-reviewer.md` to perform the security analysis.

- If a specific action is given, pass that action's directory to the subagent.
- If running across all actions, pass the full list of action directories.

The subagent checks for:

- Unpinned action references (floating tags, `@main`)
- Script injection via unsanitized inputs (`${{ github.event.*.body }}` etc.)
- Token permission scope (overly broad `${{ github.token }}` usage)
- Secret exposure (secrets printed to logs, not masked)
- Unsafe shell patterns (unquoted variables, missing `set -eu`)
- Command injection vectors (user-controlled input in shell commands)
- Path traversal risks (user input used in file paths)
- TOCTOU race conditions
- Dependency confusion risks

### 3. Classify findings by severity

Group all findings into severity levels:

- **CRITICAL**: Direct code execution, secret exposure, command injection
- **HIGH**: Unpinned actions, missing input sanitization, unmasked secrets
- **MEDIUM**: Missing `set -eu`, unquoted variables, overly broad permissions
- **LOW**: Style inconsistencies, missing best practices, documentation gaps

### 4. Suggest fixes

For each finding, provide a concrete fix suggestion with the file path and line number.

### 5. Summary

Print a consolidated report:

```text
Security Audit: <action-name> (or "All Actions")
--------------------------------------------------
CRITICAL: N findings
HIGH:     N findings
MEDIUM:   N findings
LOW:      N findings
--------------------------------------------------
Total:    N findings across M actions

[Detailed findings grouped by severity, each with:]
- Severity: CRITICAL/HIGH/MEDIUM/LOW
- Action: <action-name>
- File: <file-path>:<line>
- Issue: <description>
- Fix: <suggested fix>
```

## Output

A severity-grouped security report. CRITICAL and HIGH findings should be addressed before any release. The report includes file paths and line numbers for every finding, plus a concrete fix suggestion.
