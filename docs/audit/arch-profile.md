# Architecture Profile

Generated: 2026-11-21

## Detected Patterns

### Modular Monolith — High confidence

Evidence:

- 25 action directories at the repository root, each with its own `action.yml`, a generated `README.md` and a
  generated `validate.py`. No action `uses:` another action of this repository: 0 references of the form
  `ivuorinen/actions/<name>@<sha>` across `*/action.yml`.
- An action keeps the tools and helpers it runs in its own directory: npm locks (`biome-lint`, `eslint-lint`,
  `prettier-lint`), hash-locked Python requirements (`ansible-lint-fix`, `pre-commit`, `python-lint-fix`), release
  binaries checked against `tools.sha256` by `install_tool.py` (`docker-build`, `security-scan`), and single-purpose
  scripts (`python-lint-fix/flake8_to_sarif.py`, `security-scan/inline_allows.mjs`, `sync-labels/sync.py`).
- `docker-build/install_tool.py` and `security-scan/install_tool.py` are byte-identical copies, one per action, so
  each action stays usable from its own directory; a test compares them.
- `_tests/unit/<action>/` exists for each of the 25 actions, beside directories for shared components
  (`_harness`, `claude-hooks`, `posix-shell`, `tool-version-pins`, ...).
- Shared code lives outside the actions and reaches them only at build time: `_validation/` generates each
  `validate.py`, `_tools/` holds release and maintenance scripts, and `_tests/shared/` serves the test suite.

### Pipe and Filter — Medium confidence

Evidence:

- Every action runs its `validate.py` as step 0 of `runs.steps` (25 of 25), before any checkout, which
  `_tests/unit/validate-order/order.spec.sh` enforces.
- The steps after it follow one order: checkout when the action needs the repository, tool setup or install,
  the tool run, then outputs, reports and uploads. Each step passes state forward through `GITHUB_OUTPUT`,
  `GITHUB_ENV` and files, with no fan-out between steps.
- The order is a convention of the step sequence, not a pipeline abstraction in code, so the confidence stays
  at Medium.

### Plugin / Extension — Low confidence

Evidence:

- The `_validation/kit` package keeps every input check in one table, `CHECKS[type](value) -> error | None`, and
  `_validation/spec.py` maps each action's inputs to check types. A new check type is a new entry in that table.
- Nothing is discovered at run time: `_validation/generate.py` inlines the checks an action needs into its
  `validate.py`, which imports only the standard library. The registry is a build-time table, not an extension
  point an action loads.

## Detected Combination

### Custom hybrid: Modular Monolith + Pipe and Filter, with build-time code generation

Each action is a self-contained module with a fixed step pipeline whose first stage is input validation. The
validation logic has one source, `_validation/kit/` and `_validation/spec.py`, from which `_validation/generate.py`
writes a vendored, stdlib-only `validate.py` into each module. Modules share code only through that generation or
through an identical copy that a test keeps identical, never through a runtime reference.

## Inferred Structural Rules

1. **Action isolation**: an action never reads another action's files and never `uses:` another action of this
   repository. Code two actions need is generated into both, or copied into both with a test that keeps the copies
   byte-identical (`install_tool.py`).
2. **Validation gate**: an action that accepts inputs runs its own `validate.py` as the first step, before
   `actions/checkout`, with no `if:` condition that could skip it.
3. **Single source for validation**: every check (regex, enum, range) is defined in `_validation/kit/`, and each
   action's input-to-check map in `_validation/spec.py`. `*/validate.py` is generated (`make update-validators`),
   never edited by hand, and `generate.py --check` fails CI when one is stale. The test harness imports
   `kit.CHECKS` (`_tests/shared/validation_core.py`) instead of copying a pattern.
4. **Self-contained runtime**: a generated `validate.py` uses only the Python standard library. A tool an action
   installs comes from a lockfile or a pinned digest in the action's own directory.
5. **Pipeline step ordering**: validation, then checkout when needed, then tool setup, then the tool run, then
   outputs and reporting. A step reads an earlier step's result through `steps.<id>.outputs`, `GITHUB_ENV` or a
   file, never by repeating its work.
6. **Pinning**: every external action is pinned to a 40-character commit SHA, every `docker://` image to a
   `sha256` digest, and workflows reference this repository's actions as `./<name>`.
7. **POSIX shell**: every `run:` script in an `action.yml` and every shell file outside `_tests/` is POSIX sh with
   `set -eu`; `_tests/` is bash by design.
8. **Test mirroring**: each action has `_tests/unit/<action>/`; tests of a shared component sit under
   `_tests/unit/<component>/`, and the validation suite under `_validation/tests/`.
9. **Output format**: a step writes `GITHUB_OUTPUT` with `printf 'key=%s\n' "$value"`, never by interpolating a
   value into the format string.

## Ambiguities & Contradictions

- **Duplication by design**: `install_tool.py` exists twice. That is the price of Rule 1 and stays within the
  repository's rule of three; a third action that needs it is the point to generate it from one source, as
  `validate.py` is.
- **Generated files inside modules**: `validate.py` and `README.md` sit in each action directory but are owned by
  `_validation/` and `gh-action-readme`. Pre-tool hooks block hand edits to both.
- **Repository-level actions outside the catalog**: `.github/actions/setup-test-environment/` is a local composite
  action that only CI uses; it is not one of the published modules and follows the workflow rules, not Rule 1.
- **Plugin signal is thin**: the kit's check table is resolved when the validators are generated. Calling it
  a plugin architecture would need run-time discovery, which is absent, so the confidence stays at Low.
- **No MVC, DDD, Hexagonal, CQRS or SOA signals**: no layer, domain, port or command directories, and no shared
  service action. Correctly absent.

## Drift

Compared with the profile last written at 75a604a6 (2026-06-06; its header said 2026-05-03), 202 commits outside
`docs/` ago:

- The `validate-inputs` action and its Python package are gone: `validators/registry.py`, `validators/base.py`,
  `conventions.py`, the per-action custom validators, `*/rules.yml` and `scripts/generate-tests.py`. Validation is
  now `_validation/kit.py` + `spec.py` + `generate.py`, which writes a stdlib-only `validate.py` into each action.
- The catalog has 25 actions instead of 26.
- The validation stage moved from a shared `uses:` step to a generated script that each action runs from its own
  directory as step 0, before checkout. The old Rule 2 (call `validate-inputs` first) and Rules 3–5 (validator
  registry, convention fallback, `rules.yml`) no longer apply.
- Plugin / Extension fell from High to Low confidence; the Repository Pattern (Medium) and SOA (Low) are no longer
  detected, since no shared service or run-time registry remains.
- Actions now carry their own pinned tooling: npm and Python lockfiles, `install_tool.py` with `tools.sha256`, and
  single-purpose scripts.
