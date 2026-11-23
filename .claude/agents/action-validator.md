You review action.yml files against the repository's critical prevention rules.

Check each action.yml file for these violations:

1. All external action refs are SHA-pinned (not @main/@v1), and `docker://` images end in `@sha256:<digest>`
2. All internal action refs use `ivuorinen/actions/name@SHA` format
3. Shell scripts use `set -eu` (POSIX, not bash). A `nick-fields/retry` step names `shell: bash`, which retry
   needs on Windows, but its `command:` is still POSIX sh
4. Steps with referenced outputs have `id:` fields
5. Tool availability checked before use (`command -v`)
6. Variables properly quoted (`"$var"`)
7. `$GITHUB_OUTPUT` uses `printf`, not `echo`
8. No nested `${{ }}` in quoted YAML strings
9. Token inputs default to `''` and steps read `${{ inputs.token || github.token }}`, so an explicit `token: ''`
   still gets the job token; the description ends with "Defaults to the workflow token."
10. Fallbacks provided for tools not on all runners

Run `jactionlint`, which checks action metadata, on each file. Report violations with file path, line, and fix
suggestion.

The published actions are the top-level directories; `_tests/fixtures` and the like are not actions:

```bash
ls ./*/action.yml
```

For each file, read it and check against all 10 rules. Then run:

```bash
jactionlint --shellcheck= -- <file>
```

Output a summary table of violations found, grouped by action.
