# Test File Placement

Place unit tests under `_tests/unit/<subject>/`, where `<subject>` is the action
name (e.g., `docker-build`), a component slug (e.g., `claude-hooks`,
`_harness`), or the validate-inputs Python suite (`validate-inputs`).
Place integration tests under `_tests/integration/`.
Place validate-inputs Python tests under `validate-inputs/tests/` (the pytest
suite is co-located with the Python module by design — this is not an exception
to invent ad-hoc paths for other components).
Never create test files outside these three locations.
Test fixtures and data files that are not themselves tests
(e.g., `_tools/docker-testing-tools/test-files/`) belong with their tool/
infrastructure and are not governed by this rule.
