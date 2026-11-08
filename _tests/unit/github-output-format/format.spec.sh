#!/usr/bin/env shellspec
# Static check of .claude/rules/github-output-format.md across every action, the
# published ones and those under .github/actions, in action.yml or action.yaml.
#
# Every command that writes to "$GITHUB_OUTPUT" must be either
#   printf 'key=%s\n' <quoted value> >> "$GITHUB_OUTPUT"   (format separated from value)
# or the closing `} >> "$GITHUB_OUTPUT"` of a grouped multi-line (delimiter) form, as
# used in docker-build, docker-publish and security-scan, whose commands are each a
# test, a printf with a single-quoted format and quoted arguments, or a cat. Anything
# else (echo, a printf with the value inside the format string, a printf with no value
# or an unquoted one, a truncating `>`) is a violation. Each command on a line is
# checked on its own, after any reserved word such as `then`, and a command continued
# with a trailing backslash is read as one line.

Describe "GITHUB_OUTPUT write format"
# Prints "<file>:<line>: <text>" for each non-conforming write in the given files, or
# in every action under PROJECT_ROOT when no file is given; finding no action there
# fails.
violations() {
  command -v python3 >/dev/null 2>&1 || {
    echo "python3 is required" >&2
    return 1
  }
  python3 -I - "${PROJECT_ROOT}" "$@" <<'PY'
import glob
import os
import re
import sys

root, files = sys.argv[1], sys.argv[2:]
if not files:
    os.chdir(root)
    # The published actions and the repository's own under .github/actions, whose
    # dot directory a plain `*` does not match.
    files = sorted(
        path
        for pattern in ("*/action.yml", "*/action.yaml", ".github/actions/*/action.yml", ".github/actions/*/action.yaml")
        for path in glob.glob(pattern)
    )
    if not files:
        sys.exit("no action.yml or action.yaml under %s" % root)

# A redirection operator with its file descriptor (`>&2` and `2>&1` included), one
# shell word with its quoted parts, or one control operator.
token = re.compile(
    r"""\d*(?:>>|>&\d*-?|>\|?|<&\d*-?|<<-?|<>|<)"""
    r"""|(?:'[^']*'|"(?:\\.|[^"\\])*"|\\.|[^\s'";|&<>()])+"""
    r"""|&&|\|\||[;|&()]"""
)
separators = {";", "&&", "||", "|", "&"}
# An output redirection: descriptor, operator, and for `>&N` the descriptor it copies.
# `>&` is tried before `>`, so `>&1` is never read as `>` followed by `&1`.
output_op = re.compile(r"^(\d*)(>>|>&|>\||>|<>)(\d*-?)$")
# Any spelling of the target counts as a write; only the quoted ones are allowed.
target = re.compile(r"""^"?\$(?:GITHUB_OUTPUT|\{GITHUB_OUTPUT\})"?$""")
quoted_target = re.compile(r"""^"\$(?:GITHUB_OUTPUT|\{GITHUB_OUTPUT\})"$""")
# One quoted word. A quoted command substitution may quote its own arguments, as in
# "$(cat "$file")", which the tokenizer keeps as one word.
quoted = re.compile(r"""^(?:'[^']*'|"(?:\\.|[^"\\])*"|"\$\(.*\)")$""")
key_format = re.compile(r"^'[A-Za-z0-9_-]+=%s\\n'$")
# The YAML key of an inline `run:` scalar, which comes before its command.
run_key = re.compile(r"^\s*(?:-\s+)?run:\s*")


# Reserved words that open or close a compound command.
keywords = {"!", "if", "then", "elif", "else", "fi", "while", "until", "do", "done"}


def commands(text):
    """Yields each command on a line without the reserved words before it.

    A closing word on its own is no command, and a `for` header names a variable and a
    word list rather than running anything.
    """
    for words in split(text):
        while words and words[0] in keywords:
            words = words[1:]
        if words and words[0] != "for":
            yield words


def split(text):
    """Splits a line into commands, each a list of words, and drops a comment."""
    current = []
    for word in token.findall(text):
        if word.startswith("#"):
            break
        if word in separators:
            if current:
                yield current
            current = []
        else:
            current.append(word)
    if current:
        yield current


def redirections(words):
    """Yields (descriptor, operator, operand) for each output redirection of a command.

    The operand is the descriptor written into `>&N`, or else the word that follows, so
    `>&1` and `>& 1` read the same. `<>` opens descriptor 0 unless one is given.
    """
    for index, word in enumerate(words):
        match = output_op.match(word)
        if not match:
            continue
        descriptor = match.group(1) or ("0" if match.group(2) == "<>" else "1")
        operand = match.group(3) or (words[index + 1] if index + 1 < len(words) else "")
        yield descriptor, match.group(2), operand


def writes_output(words):
    """True when any redirection of the command opens $GITHUB_OUTPUT."""
    return any(target.match(operand) for _, _, operand in redirections(words))


def redirects_stdout(words):
    """True when the command sends its standard output somewhere of its own; copying
    descriptor 1 onto itself (`>&1`) leaves it where it was."""
    return any(
        descriptor == "1" and not (operator == ">&" and operand == "1")
        for descriptor, operator, operand in redirections(words)
    )


def allowed(words):
    return (
        len(words) == 5
        and words[0] == "printf"
        and key_format.match(words[1])
        and quoted.match(words[2])
        and words[3] == ">>"
        and quoted_target.match(words[4])
    )


def allowed_in_group(words):
    """A command inside a group closed by `} >> "$GITHUB_OUTPUT"`: a test, which prints
    nothing, a printf whose single-quoted format holds no expansion and whose arguments
    are all quoted, or a cat of a file."""
    if words[0] in ("[", "test"):
        return True
    if words[0] == "printf":
        return (
            len(words) >= 3
            and len(words[1]) >= 2
            and words[1][0] == words[1][-1] == "'"
            and all(quoted.match(word) for word in words[2:])
        )
    return words[0] == "cat" and len(words) >= 2 and not any(word in (">", ">>", "<<", "<<-") for word in words)


for path in files:
    with open(path, encoding="utf-8") as handle:
        lines = handle.read().splitlines()
    reports = {}
    groups = []  # the commands of each open `{` group, innermost last
    index = 0
    while index < len(lines):
        start, text = index + 1, lines[index]
        # A command continued with a trailing backslash is read as one line. A comment
        # runs to the end of its line, so a backslash that ends one continues nothing.
        while (
            text.rstrip().endswith("\\")
            and not any(word.startswith("#") for word in token.findall(text))
            and index + 1 < len(lines)
        ):
            index += 1
            text = text.rstrip()[:-1].rstrip() + " " + lines[index].strip()
        index += 1
        text = run_key.sub("", text, count=1)
        for words in commands(text):
            if words[0] == "{":
                groups.append([])
                words = words[1:]
                if not words:
                    continue
            if words[0] == "}":
                group = groups.pop() if groups else []
                if len(words) == 3 and words[1] == ">>" and quoted_target.match(words[2]):
                    for line, line_text, inner in group:
                        if not allowed_in_group(inner):
                            reports[line] = line_text
                else:
                    # A nested group feeds the outer one unless it redirects its stdout.
                    if groups and not redirects_stdout(words):
                        groups[-1].extend(group)
                    if writes_output(words):
                        reports[start] = text.strip()
                continue
            # A command that redirects its own stdout does not write through the group;
            # a direct write to the file is still checked below.
            if groups and not redirects_stdout(words):
                groups[-1].append((start, text.strip(), words))
            if writes_output(words) and not allowed(words):
                reports[start] = text.strip()
    for line in sorted(reports):
        print("%s:%d: %s" % (path, line, reports[line]))
PY
}

It "has no write that breaks the format rule"
When call violations
The output should equal ""
The status should be success
End

Describe "on a fixture"
fixture() { printf '%s' "${SHELLSPEC_TMPBASE}/action.yml"; }

It "reports an echo write"
cat >"$(fixture)" <<'YAML'
runs:
  steps:
    - shell: sh
      run: |
        echo "a=b" >> "$GITHUB_OUTPUT"
YAML
When call violations "$(fixture)"
The output should equal "$(fixture):5: echo \"a=b\" >> \"\$GITHUB_OUTPUT\""
End

It "reports an echo write that shares its line with a valid printf write"
cat >"$(fixture)" <<'YAML'
runs:
  steps:
    - shell: sh
      run: |
        echo "a=b" >> "$GITHUB_OUTPUT"; printf 'k=%s\n' "v" >> "$GITHUB_OUTPUT"
YAML
When call violations "$(fixture)"
The lines of output should equal 1
The output should start with "$(fixture):5: echo"
End

It "reports an echo write whose redirection continues on the next line"
cat >"$(fixture)" <<'YAML'
runs:
  steps:
    - shell: sh
      run: |
        echo "a=b" >> \
          "$GITHUB_OUTPUT"
YAML
When call violations "$(fixture)"
The output should equal "$(fixture):5: echo \"a=b\" >> \"\$GITHUB_OUTPUT\""
End

It "reports a write on the line after a comment that ends in a backslash"
cat >"$(fixture)" <<'YAML'
runs:
  steps:
    - shell: sh
      run: |
        printf 'k=%s\n' "v" >> "$GITHUB_OUTPUT" # written first \
        echo "a=b" >> "$GITHUB_OUTPUT"
YAML
When call violations "$(fixture)"
The output should equal "$(fixture):6: echo \"a=b\" >> \"\$GITHUB_OUTPUT\""
End

It "reports a printf write with an unquoted value"
cat >"$(fixture)" <<'YAML'
runs:
  steps:
    - shell: sh
      run: |
        printf 'k=%s\n' $value >> "$GITHUB_OUTPUT"
YAML
When call violations "$(fixture)"
The lines of output should equal 1
The output should start with "$(fixture):5: printf"
End

It "reports writes and a group closed on an unquoted target"
cat >"$(fixture)" <<'YAML'
runs:
  steps:
    - shell: sh
      run: |
        printf 'k=%s\n' "v" >> $GITHUB_OUTPUT
        printf 'k=%s\n' "v" >> ${GITHUB_OUTPUT}
        {
          printf 'k=%s\n' "v"
        } >> $GITHUB_OUTPUT
YAML
When call violations "$(fixture)"
The lines of output should equal 3
The line 1 of output should start with "$(fixture):5: "
The line 2 of output should start with "$(fixture):6: "
The line 3 of output should start with "$(fixture):9: "
End

It "reports a read-write redirection to the file"
cat >"$(fixture)" <<'YAML'
runs:
  steps:
    - shell: sh
      run: |
        printf 'k=%s\n' "v" 1<> "$GITHUB_OUTPUT"
YAML
When call violations "$(fixture)"
The lines of output should equal 1
The output should start with "$(fixture):5: printf"
End

It "reports a write that truncates the file"
cat >"$(fixture)" <<'YAML'
runs:
  steps:
    - shell: sh
      run: |
        printf 'k=%s\n' "v" > "$GITHUB_OUTPUT"
YAML
When call violations "$(fixture)"
The lines of output should equal 1
The output should start with "$(fixture):5: printf"
End

It "accepts quoted values and substitutions, braced targets, continued and commented-out writes"
cat >"$(fixture)" <<'YAML'
runs:
  steps:
    - shell: sh
      run: |
        printf 'k=%s\n' "$value" >> "$GITHUB_OUTPUT"
        printf 'k=%s\n' '' >> "${GITHUB_OUTPUT}"
        printf 'k=%s\n' "$(cat "$file")" >> "$GITHUB_OUTPUT"
        printf 'k=%s\n' "a;b" >> "$GITHUB_OUTPUT" && printf 'j=%s\n' "c" >> "$GITHUB_OUTPUT"
        printf 'k=%s\n' "$value" \
          >> "$GITHUB_OUTPUT"
        # echo "a=b" >> "$GITHUB_OUTPUT"
YAML
When call violations "$(fixture)"
The output should equal ""
The status should be success
End

It "checks the command after a reserved word on the same line"
cat >"$(fixture)" <<'YAML'
runs:
  steps:
    - shell: sh
      run: |
        if [ -n "$value" ]; then printf 'k=%s\n' "$value" >> "$GITHUB_OUTPUT"; fi
        for v in a b; do printf 'k=%s\n' "$v" >> "$GITHUB_OUTPUT"; done
        if [ -n "$value" ]; then echo "a=b" >> "$GITHUB_OUTPUT"; fi
YAML
When call violations "$(fixture)"
The lines of output should equal 1
The output should start with "$(fixture):7: if"
End

It "allows conditions and loops around the commands of a group, and checks those commands"
cat >"$(fixture)" <<'YAML'
runs:
  steps:
    - shell: sh
      run: |
        {
          if [ -n "$value" ]; then
            printf 'a=%s\n' "$value"
          else
            echo "a=$default"
          fi
          for tag in $tags; do
            printf '%s\n' "$tag"
          done
        } >> "$GITHUB_OUTPUT"
YAML
When call violations "$(fixture)"
The output should equal "$(fixture):9: echo \"a=\$default\""
End

It "reads the command of an inline run scalar"
cat >"$(fixture)" <<'YAML'
runs:
  steps:
    - shell: sh
      run: printf 'k=%s\n' "$value" >> "$GITHUB_OUTPUT"
    - shell: sh
      run: echo "a=b" >> "$GITHUB_OUTPUT"
YAML
When call violations "$(fixture)"
The output should equal "$(fixture):6: echo \"a=b\" >> \"\$GITHUB_OUTPUT\""
End

It "reports an echo and an expanding format inside a group written to the file"
cat >"$(fixture)" <<'YAML'
runs:
  steps:
    - shell: sh
      run: |
        {
          printf 'k=%s\n' "v"
          echo "a=$value"
          printf "b=$value\n"
        } >> "$GITHUB_OUTPUT"
YAML
When call violations "$(fixture)"
The lines of output should equal 2
The line 1 of output should equal "$(fixture):7: echo \"a=\$value\""
The line 2 of output should equal "$(fixture):8: printf \"b=\$value\\n\""
End

It "accepts the delimiter and key groups the actions use, and groups written elsewhere"
cat >"$(fixture)" <<'YAML'
runs:
  steps:
    - shell: sh
      run: |
        {
          printf 'metadata<<%s\n' "$_delim"
          cat /tmp/build-metadata.json
          printf '%s\n' "$_delim"
        } >> "$GITHUB_OUTPUT"
        {
          printf '%s\n' 'tags<<EOF'
          printf '%s\n' "$tags"
          printf '%s\n' 'EOF'
        } >> "$GITHUB_OUTPUT"
        { printf 'a=%s\n' "b"; printf 'c=%s\n' "d"; } >> "$GITHUB_OUTPUT"
        {
          echo "not written to the output file"
        } >/dev/null
YAML
When call violations "$(fixture)"
The output should equal ""
The status should be success
End

It "leaves commands that redirect their stdout out of the group rules"
cat >"$(fixture)" <<'YAML'
runs:
  steps:
    - shell: sh
      run: |
        {
          printf 'k=%s\n' "v"
          echo "::debug::writing k" >&2
          echo "noise" >/dev/null 2>&1
          {
            echo "nested noise"
          } >/dev/null
          printf 'j=%s\n' "w" >> "$GITHUB_OUTPUT"
        } >> "$GITHUB_OUTPUT"
YAML
When call violations "$(fixture)"
The output should equal ""
The status should be success
End

It "reports commands that copy stdout onto itself inside a group"
cat >"$(fixture)" <<'YAML'
runs:
  steps:
    - shell: sh
      run: |
        {
          echo "a=b" >&1
          echo "c=d" >& 1
        } >> "$GITHUB_OUTPUT"
YAML
When call violations "$(fixture)"
The lines of output should equal 2
The line 1 of output should start with "$(fixture):6: echo"
The line 2 of output should start with "$(fixture):7: echo"
End

It "reports an invalid direct write inside a group"
cat >"$(fixture)" <<'YAML'
runs:
  steps:
    - shell: sh
      run: |
        {
          printf 'k=%s\n' "v"
          echo "bad=1" >> "$GITHUB_OUTPUT"
        } >> "$GITHUB_OUTPUT"
YAML
When call violations "$(fixture)"
The output should equal "$(fixture):7: echo \"bad=1\" >> \"\$GITHUB_OUTPUT\""
End

It "reports an echo in a nested group that writes through the outer group"
cat >"$(fixture)" <<'YAML'
runs:
  steps:
    - shell: sh
      run: |
        {
          {
            echo "a=b"
          }
        } >> "$GITHUB_OUTPUT"
YAML
When call violations "$(fixture)"
The output should equal "$(fixture):7: echo \"a=b\""
End

It "scans action.yaml files and the actions under .github/actions by default"
mkdir -p "${SHELLSPEC_TMPBASE}/scan/.github/actions/local" "${SHELLSPEC_TMPBASE}/scan/published"
for file in .github/actions/local/action.yml published/action.yaml; do
  cat >"${SHELLSPEC_TMPBASE}/scan/${file}" <<'YAML'
runs:
  steps:
    - shell: sh
      run: |
        echo "a=b" >> "$GITHUB_OUTPUT"
YAML
done
PROJECT_ROOT="${SHELLSPEC_TMPBASE}/scan"
When call violations
The lines of output should equal 2
The line 1 of output should start with ".github/actions/local/action.yml:5: echo"
The line 2 of output should start with "published/action.yaml:5: echo"
End

It "fails when PROJECT_ROOT holds no action"
mkdir -p "${SHELLSPEC_TMPBASE}/empty"
PROJECT_ROOT="${SHELLSPEC_TMPBASE}/empty"
When call violations
The status should be failure
The error should equal "no action.yml or action.yaml under ${SHELLSPEC_TMPBASE}/empty"
End
End
End
