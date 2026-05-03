# Documentation Audit Findings

Generated: 2026-04-30
Last validated: 2026-04-30

## Summary

- Total: 9 | Open: 0 | Fixed: 9 | Invalid: 0

## Open Findings

### Critical

### High

### Medium

### Low

## Fixed

### Pass 1 — 2026-04-30

#### [DOC-001] README usage section demonstrates three non-existent actions

Fixed: 2026-04-30
Notes: Replaced `node-setup`, `php-version-detect`, `version-file-parser` examples with `pre-commit` and `npm-publish`.
Removed fictional composition block. Updated tag format examples to use correct CalVer (`v2025.04.05`) and full 40-char SHA patterns.

#### [DOC-002] CLAUDE.md Repository Structure lists non-existent action `setup-test-environment`

Fixed: 2026-04-30
Notes: Removed `setup-test-environment` from the Setup action list in CLAUDE.md § "Repository Structure".

#### [DOC-003] README and CLAUDE.md `make all` description omits three steps

Fixed: 2026-04-30
Notes: Updated README.md comment from "docs, format, and lint" to full step list. Updated CLAUDE.md Commands line to match actual target: `install-tools+update-validators+docs+update-catalog+format+lint+precommit`.

#### [DOC-004] \_tests/README.md directory structure documents non-existent files and directories

Fixed: 2026-04-30
Notes: Rewrote both "Directory Structure" (§ Overview) and "Framework File Structure" (§ Framework Development) to reflect the
actual `_tests/` layout: removed `version-file-parser/`, `node-setup/`, `framework/setup.sh`, `framework/utils.sh`,
`framework/validation.py`, `integration/external-usage/`, `integration/action-chains/`; added `_tests/fixtures/`,
`_tests/shared/`, `_tests/unit/_harness/`, `_tests/framework/harness/`.

#### [DOC-005] \_tests/README.md integration test example uses a floating `@main` reference

Fixed: 2026-04-30
Notes: Replaced `ivuorinen/actions/my-action@main` with `ivuorinen/actions/my-action@<40-char-sha>` and added inline comment. Also fixed Architecture section description that said "work as `…@main`".

#### [DOC-006] CLAUDE.md references `_tools/README.md` which does not exist

Fixed: 2026-04-30
Notes: Replaced broken reference with a direct listing of the actual scripts in `_tools/`: `fix-local-action-refs.py`, `release.sh`, `release-undo.sh`, `shared.sh`.

#### [DOC-007] README and \_tests/README `make test-action` example uses non-existent action name

Fixed: 2026-04-30
Notes: Changed `ACTION=node-setup` to `ACTION=go-build` in README.md (§ Testing), `_tests/README.md` Quick Start, and the CLI example in `_tests/README.md` (§ Running Tests).

#### [DOC-008] \_tests/README.md testing pattern examples reference non-existent actions

Fixed: 2026-04-30
Notes: Renamed section from "Setup Actions (node-setup, php-version-detect, etc.)" to "Setup Actions (language-version-detect, etc.)".
Updated code examples to use `language-version-detect` with `default-version` input. Fixed version validation examples in
§ "Primary Validation Function" to use `language-version-detect`.

#### [DOC-009] \_tests/README.md Technology Stack claims ShellSpec as primary framework

Fixed: 2026-04-30
Notes: Updated Technology Stack entry from "Primary Framework: ShellSpec — BDD testing for shell scripts" to reflect
dual-mode reality: "Unit Testing: ShellSpec specs + Python-based harness (`_tests/framework/harness/`)".
Updated "Available Functions" § "Framework Development" to reference `_tests/framework/harness/` instead of the
non-existent `_tests/framework/utils.sh`.

## Invalid

### Pass 1 — 2026-04-30

(none)
