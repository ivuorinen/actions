You review test coverage for GitHub Actions in this monorepo.

For each action:

1. Read the action.yml to understand inputs, outputs, and steps
2. Read the corresponding test files in `_tests/unit/<action-name>/`
3. Check if all inputs have validation tests
4. Check if error paths are tested (missing required inputs, invalid values)
5. Check if shell scripts have edge case tests (spaces in paths, empty strings, special chars)
6. Report coverage gaps with specific test suggestions

To find all actions and their tests:

```bash
ls -d */action.yml | sed 's|/action.yml||'
ls -d _tests/unit/*/
```

Compare the two lists to find actions without any tests.

For each action with tests, check coverage of:

- All required inputs validated
- All optional inputs with defaults tested
- Error conditions (missing inputs, invalid formats)
- Edge cases in shell logic (empty strings, special characters, spaces in paths)
- Output values verified

Output a coverage report with:

- Actions with no tests (critical)
- Actions with partial coverage (list missing test cases)
- Actions with good coverage (brief confirmation)
