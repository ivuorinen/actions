# Fix Pre-Existing Issues Immediately

Always fix pre-existing bugs, broken patterns, incorrect comments, dead code, wrong
test data, and stale documentation the moment you encounter them — never in the next
PR, never "later", never "out of scope".

Never use the phrases "pre-existing", "unrelated", "not my change", "already broken",
"out of scope", "I'll file a ticket", "leave for follow-up", or any synonym as
justification for leaving a defect in place once you have seen it.
Discovery is ownership.

Never add a comment, a TODO, a `# noqa`, a `// FIXME`, an `eslint-disable`, a
`ruff: noqa`, or any suppression directive in place of fixing the root cause.
Suppressions are an admission that the rule still applies — fix the underlying issue
and remove the need for the suppression.

Never weaken a test, loosen a lint rule, widen a type, or relax a validation pattern
to make a pre-existing issue stop firing.
The rule exists for a reason; fix the code, not the rule.

Always include the pre-existing fix in the same change as the work that surfaced it,
with a brief note in the commit message or PR description
(e.g., "also: fix template default in generate-tests.py — `'a' * 32` was wrong").
This keeps the audit trail clean without delaying the fix.

Never claim a pre-existing fix is too risky or too large to bundle without first
attempting it.
If after attempting it becomes genuinely incompatible with the current scope
(e.g., breaking-API surface), split via the procedure in
`no-partial-implementations.md` BEFORE starting — do not retreat to it as an escape
hatch after the fact.

If a pre-existing issue would require changing public behavior, document the exact
behavior change in the same change and update every in-tree caller — see
`no-partial-implementations.md`.
Out-of-tree callers (external users consuming `ivuorinen/actions/<name>` via SHA or
CalVer tag) cannot be edited directly. They must be addressed via the
release-and-deprecation procedure: bump the CalVer tag, add a CHANGELOG entry
describing the behavior change, and add a deprecation notice in the action's README
where the old behavior was documented. "External callers exist" is never sufficient
reason to defer the fix — it changes how the fix ships, not whether.
