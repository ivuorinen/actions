# Context-Mode Routing — Always

Always route shell, file analysis, and search work through context-mode MCP tools:
`ctx_batch_execute`, `ctx_execute`, `ctx_execute_file`, `ctx_search`,
`ctx_fetch_and_index`, `ctx_index`.
The output-size threshold is zero: there is no "short output" exemption.
Short outputs become long after one followup, and the cumulative cost is the loophole.

Bash is permitted for exactly two commands: `git commit` and `git push`. Nothing
else may use Bash. Every other operation — whether it reads or mutates state — goes
through context-mode, or, for file content, through `Edit`/`Write`. There is no
"short output", "one line", or "state-mutating" exemption: any other command's
terminal output bloats the context window, which is exactly what this rule prevents.

- Bash-permitted — the ONLY two: `git commit` (with any flags or a `-F -` heredoc)
  and `git push`. They must run as real git so the commit/push reaches the host
  repo; their output (pre-commit hooks, the new SHA, push refs) is the single
  accepted source of terminal output.
- File CONTENT (creating or editing a file's bytes) → `Edit` / `Write` (native
  tools). Never `printf >file`, `cat <<EOF >file`, `tee`, or `sed -i` in Bash.
- Every OTHER state mutation → context-mode (`ctx_execute(language: "shell", ...)`
  or `ctx_batch_execute`): `git add` and every other `git` write (`fetch`, `pull`,
  `checkout`, `switch`, `branch`, `tag`, `rebase`, `merge`, `cherry-pick`,
  `revert`, `reset`, `restore`, `stash`, `worktree`, `remote`, `config`, `init`,
  `clone`), `mkdir`, `rm`, `mv`, `cp`, `ln`, `chmod`, `chown`, `touch`, package
  installers (`npm install`, `pip install`, `uv sync`, `cargo build`), every `make`
  target (`make format`, `make docs`, `make update-validators`, `make lint`,
  `make test`, ...), and every `gh` write (`gh pr create`, `gh release create`,
  `gh api -X POST`, ...).
  `ctx_execute` runs in the real working directory and PERSISTS filesystem and
  git-index changes to the host repo, so `ctx_execute("git add <paths>")` stages
  for a real Bash `git commit` — and only what you `echo`/`print` enters context.
- Every read-side operation → context-mode: `ls`, `cat`, `head`, `tail`, `grep`,
  `find`, `wc`, `stat`, `file`, `which`, `command -v`, every `git` read subcommand
  (`status`, `diff`, `log`, `show`, `blame`, `ls-files`, `rev-parse`, ...), every
  read-only `gh` query, and any `make`/test target whose output you read.

Committing flow under this rule: `Edit`/`Write` the files → stage with
`ctx_execute("git add <paths>")` → `git commit` (Bash) → `git push` (Bash).

If a command is not `git commit` or `git push`, it does not run in Bash. If unsure,
use context-mode.

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
