# GitHub Actions Security

Pin all external actions to full SHA commits — never use `@main`, `@v1`, `@v6-beta`,
or any other floating ref. This applies to every yaml file in the repo that uses
`uses:`, including `.github/workflows/*.yml`, every `*/action.yml`, and every
workflow under `_tests/integration/workflows/`.

In `.github/workflows/` and `_tests/integration/workflows/`, reference internal
actions as `./<action-name>` — this avoids Renovate creating an endless
self-update loop and keeps test workflows self-contained.

In `action.yml` files (used externally), reference internal actions as
`ivuorinen/actions/<name>@<40-char-sha>`.

Always add `id:` to a step when any of its outputs OR its outcome OR its conclusion
is referenced via `steps.<id>.outputs.<key>`, `steps.<id>.outcome`, or
`steps.<id>.conclusion`.

Always test regex patterns against both pre-release inputs (`1.0.0-rc.1`,
`v2025.04.05-rc.1`) and build-metadata inputs (`1.0.0+build`,
`2025.4.5+sha.abc1234`). These are distinct SemVer constructs — `-rc.1` is a
pre-release, `+build` is build metadata — and a regex can accept one while
rejecting the other, so neither category substitutes for the other. "Tested"
means an automated unit test under `_tests/` or `_validation/tests/`, not a
one-off REPL check.
