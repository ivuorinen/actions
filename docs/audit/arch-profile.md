# Architecture Profile

Generated: 2026-05-03

## Detected Patterns

### Modular Monolith — High confidence

Evidence:

- 26 self-contained action directories at the repository root, each with its own
  `action.yml`, README, `rules.yml`, and shell scripts
- No shared `src/` or cross-action imports; every action is independently deployable
- Actions grouped by domain function (Setup, Linting, Testing, Build, Publishing,
  Repository, Validation) but physically colocated without subdirectory grouping
- `_tests/unit/<action-name>/` mirrors the flat action layout exactly, one test
  directory per action
- `_tools/` and `validate-inputs/` are internal shared infrastructure modules, not
  cross-cutting domain layers

### Plugin / Extension Point — High confidence

Evidence:

- `validate-inputs/validators/registry.py` implements dynamic validator discovery
- `validate-inputs/validators/base.py` defines `BaseValidator` abstract base class
- Action-specific `CustomValidator.py` files (one per action that needs custom logic,
  e.g., `codeql.py`, `docker.py`) extend `BaseValidator` and are discovered via
  `registry.py` at runtime
- Convention fallback: if no custom validator exists for an `action-type`, the system
  falls back to `conventions.py` pattern-matching — a default extension point behavior
- `validate-inputs/scripts/generate-tests.py` auto-scaffolds tests for new validators,
  reinforcing the "register and test" extension lifecycle

### Pipe and Filter — Medium confidence

Evidence:

- Each `action.yml` follows a fixed step sequence: Validate Inputs → Checkout
  Repository → Setup Tool → Run Tool → Commit/Upload Results — inputs flow through
  sequential, composable stages
- `validate-inputs` action acts as a reusable filter stage consumed by 10 of 26
  actions via SHA-pinned `uses:` reference
- Validation pipeline within `modular_validator.py`: extract env vars → normalize keys →
  dispatch to validator → collect errors → write to `GITHUB_OUTPUT`
- No branching fan-out; each stage transforms and passes state forward

### Repository Pattern — Medium confidence

Evidence:

- `validate-inputs/validators/registry.py` centralizes validator lookup, abstracting
  which concrete validator handles a given `action-type`
- `*/rules.yml` files act as declarative data stores for validation rules; generated
  by `scripts/update-validators.py`, consumed by the validator at runtime — data
  access is mediated through a layer, not accessed inline
- `CustomValidator` classes do not directly read YAML; the registry/base layer
  mediates access

### SOA (Service-Oriented) — Low confidence

Evidence:

- `validate-inputs` acts as an internal shared service: SHA-pinned at a specific
  commit, versioned independently, called by other actions via `uses:` — matches
  a service contract pattern
- No other inter-action calls exist; the pattern is present but limited to one
  shared service

## Detected Combination

### Custom hybrid: Modular Monolith + Plugin/Extension Point + Pipe and Filter

The dominant pattern is a flat GitHub Actions monorepo where each action is a
self-contained module. The `validate-inputs` subsystem implements an internal plugin
architecture (abstract base + registry + concrete validators). Actions are structured
as pipelines with a mandatory validation stage as a reusable filter.

## Inferred Structural Rules

1. **Action isolation**: Each action directory is self-contained. No action may import
   or depend on another action's internal files; cross-action use is only via SHA-pinned
   `uses:` references.
2. **Validation gate**: Any action that accepts user inputs must call `validate-inputs`
   as its first `runs.steps` entry before doing any work.
3. **Validator extension rule**: Adding a new input type requires either a new
   `validators/<type>.py` extending `BaseValidator`, or a mapping in `conventions.py`.
   The registry must be able to discover it without manual wiring.
4. **Convention fallback rule**: If no custom `CustomValidator` exists for an action
   type, the system must fall back to convention-based matching without error; hard
   coupling to a specific validator class is a violation.
5. **Rules data separation**: `*/rules.yml` is auto-generated data, never hand-edited.
   Validation logic must not be inlined in `action.yml`; it lives in the Python validator
   subsystem.
6. **Pipeline step ordering**: Within each action's `runs.steps`, the sequence is
   fixed: validation → checkout → environment setup → tool execution → output/reporting.
   Skipping validation is not permitted even when inputs seem optional.
7. **SHA pinning requirement**: All cross-action references (internal and external) are
   SHA-pinned. Floating refs (`@main`, `@v1`) violate the immutability rule enforced
   by `_tools/fix-local-action-refs.py` and CI checks.
8. **POSIX shell compliance**: All shell code in `action.yml` `run:` blocks and
   `.sh` scripts must be POSIX sh (no bash-isms); enforced by Claude Code hooks
   (`block_bashisms_spec.sh`).
9. **Test mirroring**: Every action in `<name>/` must have a corresponding
   `_tests/unit/<name>/` directory; every custom validator must have a matching
   `validate-inputs/tests/test_<name>_custom.py`.
10. **No inline GITHUB_OUTPUT interpolation**: Outputs written via `printf 'key=%s\n'
"$val"` only; `echo "key=$val"` is structurally prohibited and enforced by
    `block_echo_github_output_spec.sh` Claude hook.

## Ambiguities & Contradictions

- **Incomplete validate-inputs adoption**: 10 of 26 actions call `validate-inputs`
  via `uses:`. The remaining 16 either handle validation inline (compress-images uses
  inline `echo "::error::"` guards) or skip validation entirely (csharp-build has no
  validate step visible in its action names). This is a structural inconsistency — the
  inferred rule (Rule 2 above) is violated by more than half the actions.
- **validate-inputs is both an action and a library**: It exposes an `action.yml` for
  external calling and a Python package (`github_actions_validate_inputs-1.0.0`) for
  direct import. The dual surface creates ambiguity about which interface is canonical
  for internal use.
- **SOA signal is thin**: The shared-service pattern exists for `validate-inputs` only.
  Generalizing it to a full SOA claim would require evidence of additional shared
  services, which is absent. Confidence kept at Low.
- **No MVC/MVVM signals**: No `models/`, `views/`, `controllers/`, or `viewmodels/`
  directories. Correctly absent.
- **No DDD signals**: No `domain/`, `bounded-contexts/`, `*Entity`, `*Aggregate`,
  or `*Repository` naming (except the Repository Pattern in the validation subsystem).
  Correctly absent.

## Drift

First run — no prior profile to diff against.
