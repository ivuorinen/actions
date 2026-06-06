# Code Quality

Always favor quality over speed.
A change is "done" only when it is correct, fully tested, fully documented, and
passes every linter and test in the repo — never sooner.
See `.claude/rules/no-partial-implementations.md`.

Write DRY code under the rule of three: a pattern may appear in two places, but the
third occurrence is the trigger to extract a shared utility — and the extraction
ships with the third occurrence in the same change, never as a "later" follow-up.
Regexes, validation patterns, and schemas are stricter: see "Never duplicate a
regex, validation pattern, or schema" below — those must be kept in lockstep on
every occurrence regardless of count.
Never copy-paste-modify as an expedient — if a near-duplicate is the right design
on the second occurrence, document why in a one-line comment so the third
occurrence's extraction has the rationale.

Never hardcode counts in docs or code (action counts, validator counts, rule counts,
test counts).
Always run `make update-catalog` instead.
Generated counts appear in `README.md`, `docs/`, and any catalog file — never edit
those values by hand.

Never assume — when a fact about the codebase, an API, a tool, a token format, or an
external library is needed and you do not know it with certainty, look it up via
official docs (`ctx_fetch_and_index`), inspect the source via `ctx_execute_file`, or
ask the user.
Hunches, guesses, and "I think it's…" are forbidden.

Never introduce a new external tool, language runtime, dependency, or pattern without
explicit user approval — even when it would simplify the current change.
Replacement counts as introduction: swapping `prettier` for `dprint`, `ruff` for
`black`+`isort`, `make` for `just`, or any equivalent substitution requires the
same approval as adding a brand-new dependency. "I'm not adding, I'm replacing" is
not an exemption.

Never duplicate a regex, validation pattern, or schema across files.
The canonical source for every validation regex, enum, and range is
`_validation/kit.py`. Both consumers read from that one source: the generated
`<action>/validate.py` validators inline checks from it (regenerate via
`make update-validators`, never hand-edit), and the ShellSpec test harness
(`_tests/shared/validation_core.py`) imports `kit.CHECKS` rather than re-implementing
the patterns. If you ever find a validation pattern copied into a second file, fold it
back into `_validation/kit.py`; see `.claude/rules/no-partial-implementations.md`.
