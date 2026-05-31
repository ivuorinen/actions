# Context-Mode Routing — Always

Always route shell, file analysis, and search work through context-mode MCP tools:
`ctx_batch_execute`, `ctx_execute`, `ctx_execute_file`, `ctx_search`,
`ctx_fetch_and_index`, `ctx_index`.
The output-size threshold is zero: there is no "short output" exemption.
Short outputs become long after one followup, and the cumulative cost is the loophole.

Always pass commands through `ctx_execute(language: "shell", ...)` or `ctx_batch_execute`
instead of Bash, even when the expected output is one line.
The split is by intent, not output size:

- Bash is permitted for state-mutating operations whose stdout you do not parse:
  `mkdir`, `rm`, `mv`, `cp`, `ln`, `chmod`, `chown`, `cd`, `touch`,
  output redirection that creates a new file (`>file`, `>>file`),
  package installers (`npm install`, `pip install`, `uv sync`, `cargo build`),
  and `git` write subcommands: `add`, `commit`, `push`, `fetch`, `pull`,
  `checkout`, `switch`, `branch -d`/`-D`/`-m`, `tag` create/delete, `rebase`,
  `merge`, `cherry-pick`, `revert`, `reset`, `restore`, `stash`, `worktree`,
  `remote add`/`remove`/`set-url`,
  `config --global`/`--local <key> <value>` (and `--unset`, `--add`,
  `--replace-all`, `--rename-section`, `--remove-section`),
  `init`, `clone`.
- `make` targets split by intent:
  - Bash-permitted (mutate state, output not parsed): `make install`,
    `make install-tools`, `make format`, `make format-*`, `make fix-*`,
    `make update-validators`, `make update-catalog`, `make docs`,
    `make release`, `make release-prep`, `make release-tag`, `make release-undo`,
    `make clean`, `make precommit`, `make all`, `make dev`.
  - Context-mode required (produce information you parse): `make lint`,
    `make lint-*`, `make test`, `make test-*`, `make check`, `make check-*`,
    `make stats`, `make ci`, any target whose output you intend to read.
  - If unsure, default to context-mode.
- Context-mode is mandatory for every read-side operation:
  `ls`, `cat`, `head`, `tail`, `grep`, `find`, `wc`, `stat`, `file`, `which`,
  `command -v`, `printf` (when used to inspect),
  every `git` read subcommand (`log`, `diff`, `status`, `blame`, `show`,
  `cat-file`, `ls-files`, `ls-tree`, `rev-parse`, `rev-list`,
  `tag --list`/`tag -l`, `branch --list`/`branch -a`, `remote -v`,
  `config --get`, `describe`, `reflog`, `bisect view`, `shortlog`),
  and every `gh` invocation that is not in the explicit `gh` write-list below.

`gh` write-list (Bash-permitted):
`gh auth login`, `gh auth logout`, `gh auth refresh`, `gh auth setup-git`,
`gh repo create`, `gh repo clone`, `gh repo delete`, `gh repo rename`,
`gh repo set-default`, `gh repo archive`,
`gh pr create`, `gh pr edit`, `gh pr close`, `gh pr merge`, `gh pr ready`,
`gh pr review`, `gh pr comment`, `gh pr reopen`,
`gh issue create`, `gh issue edit`, `gh issue close`, `gh issue comment`,
`gh issue reopen`, `gh issue transfer`,
`gh release create`, `gh release edit`, `gh release delete`,
`gh release upload`,
`gh secret set`, `gh secret delete`, `gh variable set`, `gh variable delete`,
`gh ssh-key add`, `gh ssh-key delete`,
`gh api -X POST`, `gh api -X PUT`, `gh api -X PATCH`, `gh api -X DELETE`,
`gh workflow run`, `gh workflow enable`, `gh workflow disable`,
`gh run rerun`, `gh run cancel`, `gh run delete`, `gh cache delete`,
`gh label create`, `gh label edit`, `gh label delete`,
`gh gist create`, `gh gist edit`, `gh gist delete`.

If a command is not in the explicit write-side list above, default to context-mode.
If unsure whether a command mutates state, use context-mode.
The principle is: "did this command produce information I will use?"
If yes, context-mode.

Always use `ctx_execute_file` when reading a file to analyze, summarize, or extract.
Only use the native `Read` tool when the next step is an `Edit` or `Write` that
needs the exact bytes in context (`Edit` matches against `old_string`; `Write`
requires a prior `Read` per its tool contract).
"Plan to edit later" is not the trigger — only edit-immediately. If the file is
large and the edit is small, `ctx_execute_file` to locate the exact region first,
then `Read` with `offset`/`limit` for just that region, then `Edit`.

Always use `ctx_fetch_and_index` for any web fetch.
Never use `WebFetch`, `curl`, `wget`, or inline `fetch()`/`requests.get()`/
`http.request()` calls in Bash or any other surface.

Always batch related read-side commands into a single `ctx_batch_execute` call with
`queries`, never spread them across multiple individual calls.
One round trip with N commands beats N round trips, regardless of expected output size.

Never invoke Bash with phrases like "this is quick", "just one line",
"trivial output", "small enough".
Those phrases are the loophole this rule plugs.
If the call reads data of any kind, it goes through context-mode.
