#!/usr/bin/env shellspec
# Tests for security-scan/inline_allows.mjs, which lists the inline gitleaks:allow comments a
# pull request adds in one pull request comment that each run updates. They import the module,
# as the action's github-script step does, in a scratch repository, with a stand-in for
# github-script's github, context and core that records each API call to calls.json.

Describe "security-scan inline gitleaks:allow comment"
MODULE="${PROJECT_ROOT}/security-scan/inline_allows.mjs"

before() {
  shellspec_setup_test_env "security-scan-inline-allows-$$"
  fixture_repo
  printf 'one\n' >app.txt
  git add app.txt
  git commit -q -m base
  export BASE_SHA HEAD_SHA
  BASE_SHA=$(git rev-parse HEAD)
  HEAD_SHA=$BASE_SHA
  export GITLEAKS_CONFIG=".gitleaks.toml"
  export MODULE CALLS="${RUNNER_TEMP}/calls.json"
  export EXISTING="" EXISTING_AUTHOR="" EXISTING_TYPE="" AUTH_LOGIN="" API_FAILS=""
}
BeforeEach 'before'

after() {
  unset BASE_SHA HEAD_SHA GITLEAKS_CONFIG CALLS EXISTING EXISTING_AUTHOR EXISTING_TYPE AUTH_LOGIN API_FAILS
  shellspec_cleanup_test_env "security-scan-inline-allows-$$"
}
AfterEach 'after'

# put PATH TEXT: write TEXT as PATH and commit it.
put() {
  mkdir -p "$(dirname "$1")"
  printf '%s\n' "$2" >"$1"
  git add "$1"
  git commit -q -m "put $1"
}

# in_base PATH TEXT: commit PATH as part of the base branch.
in_base() {
  put "$1" "$2"
  BASE_SHA=$(git rev-parse HEAD)
  HEAD_SHA=$BASE_SHA
}

# in_pr PATH TEXT: commit PATH as part of the pull request.
in_pr() {
  put "$1" "$2"
  HEAD_SHA=$(git rev-parse HEAD)
}

marker() {
  node --input-type=module -e "const { pathToFileURL } = await import('node:url'); \
console.log((await import(pathToFileURL(process.env.MODULE).href)).MARKER);"
}

run_module() {
  node --input-type=module <<'JS'
import fs from 'node:fs';
import { pathToFileURL } from 'node:url';

const { default: run } = await import(pathToFileURL(process.env.MODULE).href);
const calls = [];
const fail = process.env.API_FAILS === 'true';
const record = (name, args) => {
  calls.push({ name, args });
  if (fail) {
    throw new Error('Resource not accessible by integration');
  }
};
// EXISTING is the body of a comment already on the pull request, by EXISTING_AUTHOR, a
// bot unless EXISTING_TYPE says otherwise. AUTH_LOGIN is who the token is, which only a
// user's token can tell: the workflow token's lookup fails.
const author = { login: process.env.EXISTING_AUTHOR || 'github-actions[bot]', type: process.env.EXISTING_TYPE || 'Bot' };
const github = {
  rest: {
    issues: {
      listComments: 'listComments',
      createComment: async (args) => record('createComment', args),
      updateComment: async (args) => record('updateComment', args),
    },
    users: {
      getAuthenticated: async () => {
        if (!process.env.AUTH_LOGIN) {
          throw new Error('Resource not accessible by integration');
        }
        return { data: { login: process.env.AUTH_LOGIN } };
      },
    },
  },
  paginate: async (method, args) => {
    record(method, args);
    return process.env.EXISTING ? [{ id: 7, body: process.env.EXISTING, user: author }] : [];
  },
};
const core = {
  info: (message) => console.log(`info: ${message}`),
  warning: (message, at) => console.log(`warning: ${message}${at ? ` [${at.file}:${at.startLine}]` : ''}`),
};
const context = { repo: { owner: 'octo', repo: 'demo' }, payload: { pull_request: { number: 5 } }, serverUrl: 'https://github.com' };
await run({ github, context, core });
fs.writeFileSync(process.env.CALLS, JSON.stringify(calls));
JS
}

# call_names: the API calls made, one name per line.
call_names() {
  jq -r '.[].name' "$CALLS"
}

# posted: the body of the comment created or updated.
posted() {
  jq -r '.[] | select(.name == "createComment" or .name == "updateComment") | .args.body' "$CALLS"
}

Describe "listing what the pull request adds"
It "names each added gitleaks:allow line by file and line, with a link to it"
in_base .gitleaks.toml 'title = "base"'
in_pr app.txt "$(printf 'one\ntoken = placeholder-value # gitleaks:allow')"
in_pr src/b.txt "$(printf 'k1 # gitleaks:allow\nplain\nk2 # gitleaks:allow')"
When call run_module
The status should be success
Assert test "$(call_names)" = "$(printf 'listComments\ncreateComment')"
Assert test "$(posted | grep -c '^- File \[')" -eq 3
The contents of file "$CALLS" should include "app.txt:2"
The contents of file "$CALLS" should include "src/b.txt:1"
The contents of file "$CALLS" should include "src/b.txt:3"
The contents of file "$CALLS" should include "https://github.com/octo/demo/blob/${HEAD_SHA}/app.txt#L2"
The contents of file "$CALLS" should include "adds 3 inline"
End

It "never puts the allowed line's text in the comment"
in_base .gitleaks.toml 'title = "base"'
in_pr app.txt "$(printf 'one\ntoken = placeholder-value # gitleaks:allow')"
When call run_module
The status should be success
Assert test -n "$(posted)"
The contents of file "$CALLS" should not include "placeholder-value"
End

It "leaves out the gitleaks:allow comments the base branch already has"
in_base .gitleaks.toml 'title = "base"'
in_base app.txt "$(printf 'one\nold # gitleaks:allow')"
in_pr app.txt "$(printf 'one\nold # gitleaks:allow\nnew line')"
When call run_module
The status should be success
Assert test "$(call_names)" = "listComments"
End

It "leaves out a gitleaks:allow line the pull request removes"
in_base .gitleaks.toml 'title = "base"'
in_base app.txt "$(printf 'one\nold # gitleaks:allow')"
in_pr app.txt 'one'
When call run_module
The status should be success
Assert test "$(call_names)" = "listComments"
End

It "names a file with a space without the tab git puts after it in the header"
in_base .gitleaks.toml 'title = "base"'
in_pr "my file.txt" 'value # gitleaks:allow'
When call run_module
The status should be success
The contents of file "$CALLS" should include '[`my file.txt:1`](https://github.com/octo/demo/blob/'
The contents of file "$CALLS" should include '/my%20file.txt#L1)'
The contents of file "$CALLS" should not include '%09'
End

It "encodes the parentheses in a name, so an unbalanced one cannot end the link"
in_base .gitleaks.toml 'title = "base"'
in_pr 'a)b(c.txt' 'value # gitleaks:allow'
When call run_module
The status should be success
The contents of file "$CALLS" should include '/a%29b%28c.txt#L1)'
End

# An item starting with [ would be a link reference definition, an empty bullet on GitHub.
It "starts each item with a word, so a name ending in ] cannot hide it"
in_base .gitleaks.toml 'title = "base"'
in_pr 'notes]' 'value # gitleaks:allow'
When call run_module
The status should be success
Assert test "$(posted | grep -c '^- \[')" -eq 0
The contents of file "$CALLS" should include '- File [`notes]:1`](https://github.com/octo/demo/blob/'
End

It "annotates a file with a space by its name when it cannot comment"
API_FAILS=true
in_base .gitleaks.toml 'title = "base"'
in_pr "my file.txt" 'value # gitleaks:allow'
When call run_module
The status should be success
The output should include "Gitleaks skips this line [my file.txt:1]"
End

It "does not read a +++ line inside a hunk as a file name"
in_base .gitleaks.toml 'title = "base"'
in_pr app.txt "$(printf 'one\n++ not a header\nvalue # gitleaks:allow')"
When call run_module
The status should be success
The contents of file "$CALLS" should include "app.txt:3"
End

It "reads git attributes from the base commit, so a -diff the pull request adds hides nothing"
in_base .gitleaks.toml 'title = "base"'
in_pr .gitattributes '*.txt -diff'
in_pr app.txt "$(printf 'one\nvalue # gitleaks:allow')"
When call run_module
The status should be success
The contents of file "$CALLS" should include "app.txt:2"
End

It "decodes a name git quotes with an octal escape"
in_base .gitleaks.toml 'title = "base"'
in_pr "$(printf 'a\001b.txt')" 'value # gitleaks:allow'
When call run_module
The status should be success
The contents of file "$CALLS" should include '/a%01b.txt#L1)'
End

Describe "git configuration that would change the diff"
Parameters
diff.noprefix true
diff.mnemonicPrefix true
diff.interHunkContext 1
End

It "names the right file and line with $1 set to $2"
in_base .gitleaks.toml 'title = "base"'
in_base app.txt "$(printf 'one\ntwo\nthree')"
git config "$1" "$2"
in_pr app.txt "$(printf 'ONE\ntwo\nthree # gitleaks:allow')"
When call run_module
The status should be success
The contents of file "$CALLS" should include '[`app.txt:3`]'
The contents of file "$CALLS" should include '/app.txt#L3)'
End
End
End

Describe "the base branch's Gitleaks files"
It "posts nothing when the base branch keeps no Gitleaks config or ignore file"
in_pr app.txt "$(printf 'one\nvalue # gitleaks:allow')"
When call run_module
The status should be success
The output should include "keeps no Gitleaks config or ignore file"
Assert test "$(jq length "$CALLS")" -eq 0
End

It "ignores a Gitleaks config the pull request adds"
in_pr .gitleaks.toml 'title = "pull request"'
in_pr app.txt "$(printf 'one\nvalue # gitleaks:allow')"
When call run_module
The status should be success
The output should include "keeps no Gitleaks config or ignore file"
Assert test "$(jq length "$CALLS")" -eq 0
End

It "counts a .gitleaksignore in the base branch"
in_base .gitleaksignore 'abc:app.txt:generic-api-key:1'
in_pr app.txt "$(printf 'one\nvalue # gitleaks:allow')"
When call run_module
The status should be success
Assert test "$(call_names)" = "$(printf 'listComments\ncreateComment')"
End

It "counts the config at the gitleaks-config path"
export GITLEAKS_CONFIG="security/gitleaks.toml"
in_base security/gitleaks.toml 'title = "custom"'
in_pr app.txt "$(printf 'one\nvalue # gitleaks:allow')"
When call run_module
The status should be success
Assert test "$(call_names)" = "$(printf 'listComments\ncreateComment')"
End
End

Describe "the one comment"
It "updates its existing comment instead of adding another"
EXISTING="$(marker) earlier"
in_base .gitleaks.toml 'title = "base"'
in_pr app.txt "$(printf 'one\nvalue # gitleaks:allow')"
When call run_module
The status should be success
Assert test "$(call_names)" = "$(printf 'listComments\nupdateComment')"
Assert test "$(jq -r '.[1].args.comment_id' "$CALLS")" = "7"
End

It "turns its comment green once the pull request adds none"
EXISTING="$(marker) earlier"
in_base .gitleaks.toml 'title = "base"'
in_pr app.txt "$(printf 'one\nplain')"
When call run_module
The status should be success
Assert test "$(call_names)" = "$(printf 'listComments\nupdateComment')"
The contents of file "$CALLS" should include "✅"
The contents of file "$CALLS" should include "No inline \`gitleaks:allow\` found anymore."
End

It "posts no comment when the pull request never added one"
in_base .gitleaks.toml 'title = "base"'
in_pr app.txt "$(printf 'one\nplain')"
When call run_module
The status should be success
Assert test "$(call_names)" = "listComments"
End

It "leaves alone a comment that does not start with its marker"
EXISTING="A reviewer mentions gitleaks:allow and $(marker)"
in_base .gitleaks.toml 'title = "base"'
in_pr app.txt "$(printf 'one\nplain')"
When call run_module
The status should be success
Assert test "$(call_names)" = "listComments"
End

It "does not take a user's comment with its marker for its own"
EXISTING="$(marker) planted"
EXISTING_AUTHOR="someone"
EXISTING_TYPE="User"
in_base .gitleaks.toml 'title = "base"'
in_pr app.txt "$(printf 'one\nvalue # gitleaks:allow')"
When call run_module
The status should be success
Assert test "$(call_names)" = "$(printf 'listComments\ncreateComment')"
End

It "does not take another bot's comment with its marker for its own"
EXISTING="$(marker) planted"
EXISTING_AUTHOR="other-app[bot]"
EXISTING_TYPE="Bot"
in_base .gitleaks.toml 'title = "base"'
in_pr app.txt "$(printf 'one\nvalue # gitleaks:allow')"
When call run_module
The status should be success
Assert test "$(call_names)" = "$(printf 'listComments\ncreateComment')"
End

It "finds its comment by the token's own login when the token can tell it"
EXISTING="$(marker) earlier"
EXISTING_AUTHOR="maintainer"
EXISTING_TYPE="User"
AUTH_LOGIN="maintainer"
in_base .gitleaks.toml 'title = "base"'
in_pr app.txt "$(printf 'one\nvalue # gitleaks:allow')"
When call run_module
The status should be success
Assert test "$(call_names)" = "$(printf 'listComments\nupdateComment')"
End
End

It "shows a file name escaped, so a line break in it cannot end the code span"
in_base .gitleaks.toml 'title = "base"'
in_pr "$(printf 'odd\n\n[x](y).txt')" 'value # gitleaks:allow'
When call run_module
The status should be success
Assert test "$(posted | grep -c '^- File \[')" -eq 1
Assert test "$(posted | grep -c '^\[x\](y)')" -eq 0
The contents of file "$CALLS" should include 'odd\\n\\n[x](y).txt:1'
End

It "warns with a file and line annotation for each one when it cannot comment"
API_FAILS=true
in_base .gitleaks.toml 'title = "base"'
in_pr app.txt "$(printf 'one\nvalue # gitleaks:allow')"
When call run_module
The status should be success
The output should include "warning: Inline gitleaks:allow added: Gitleaks skips this line [app.txt:2]"
The output should include "warning: Could not post the inline gitleaks:allow comment, which needs pull-requests: write"
End
End
