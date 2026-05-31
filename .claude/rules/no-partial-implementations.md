# No Partial Implementations

Always finish what you start in the same change.
A task is complete when every code path, every test, every doc, every related file,
and every cross-reference is updated, run, and verified — not when the "main" file
compiles.

Never leave a feature, fix, refactor, or migration half-done across files.
If a regex is updated in `validators/token.py`, every other copy in `_tests/shared/`,
`_tests/framework/`, `security.py`, generator templates, fixtures, and tests must be
updated in the same change.

Never commit code that compiles but is missing tests, missing documentation,
missing the call site, missing the rollback path, or missing the migration step.
The change is not done until the whole story is done.

Never use the phrases "I'll do that next", "follow-up PR", "I'll address later",
"out of scope for this change", "leave for another time", or any synonym to defer
work that is logically part of the current task.
If it is part of the task, it ships in the same change.

Never add a TODO, FIXME, XXX, or "stub" comment in place of an implementation.
Either implement it, delete the dead path, or revert the change that needed it.

Never claim a fix is complete without running the verification command
(tests, lint, integration check) and confirming the output.
"It should work" is not a completion criterion — observed output is.

If a task is genuinely too large to complete in one change, split it into
independent, individually-shippable units BEFORE starting any of them — never
mid-execution as an escape hatch.
The split decision requires explicit user agreement: present the proposed unit
boundaries and wait for an OK before starting unit 1. Unilateral mid-execution
declarations of "this turned out too big" are not allowed — that is the exact
escape hatch this rule plugs.
