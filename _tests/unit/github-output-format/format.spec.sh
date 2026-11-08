#!/usr/bin/env shellspec
# Static check of .claude/rules/github-output-format.md across every action.yml.
#
# Every command that writes to "$GITHUB_OUTPUT" must be either
#   printf 'key=%s\n' <quoted value> >> "$GITHUB_OUTPUT"   (format separated from value)
# or the closing `} >> "$GITHUB_OUTPUT"` of a grouped multi-line (delimiter) form, as
# used in docker-build, docker-publish and security-scan, whose commands are each a
# printf with a single-quoted format and quoted arguments, or a cat. Anything else
# (echo, a printf with the value inside the format string, a printf with no value or
# an unquoted one, a truncating `>`) is a violation. Each command on a line is checked
# on its own, and a command continued with a trailing backslash is read as one line.

Describe "GITHUB_OUTPUT write format"
# Prints "<file>:<line>: <text>" for each non-conforming write in the given files, or
# in every action.yml under PROJECT_ROOT when no file is given; finding no action.yml
# there fails.
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
    files = sorted(glob.glob("*/action.yml"))
    if not files:
        sys.exit("no action.yml under %s" % root)

# One shell word, quoted parts included, or one operator.
token = re.compile(r"""(?:'[^']*'|"(?:\\.|[^"\\])*"|\\.|[^\s'";|&<>()])+|&&|\|\||>>|<<-?|[;|&<>()]""")
separators = {";", "&&", "||", "|", "&"}
target = re.compile(r"""^"?\$\{?GITHUB_OUTPUT\}?"?$""")
quoted = re.compile(r"""^(?:'[^']*'|"(?:\\.|[^"\\])*")$""")
key_format = re.compile(r"^'[A-Za-z0-9_-]+=%s\\n'$")


def commands(text):
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


def writes_output(words):
    return any(
        word in (">", ">>") and index + 1 < len(words) and target.match(words[index + 1])
        for index, word in enumerate(words)
    )


def allowed(words):
    return (
        len(words) == 5
        and words[0] == "printf"
        and key_format.match(words[1])
        and quoted.match(words[2])
        and words[3] == ">>"
        and target.match(words[4])
    )


def allowed_in_group(words):
    """A command inside a group closed by `} >> "$GITHUB_OUTPUT"`: a printf whose
    single-quoted format holds no expansion and whose arguments are all quoted, or a
    cat of a file."""
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
        # A command continued with a trailing backslash is read as one line.
        while text.rstrip().endswith("\\") and index + 1 < len(lines):
            index += 1
            text = text.rstrip()[:-1].rstrip() + " " + lines[index].strip()
        index += 1
        for words in commands(text):
            if words[0] == "{":
                groups.append([])
                words = words[1:]
                if not words:
                    continue
            if words[0] == "}":
                group = groups.pop() if groups else []
                if len(words) == 3 and words[1] == ">>" and target.match(words[2]):
                    for line, line_text, inner in group:
                        if not allowed_in_group(inner):
                            reports[line] = line_text
                else:
                    if groups:
                        groups[-1].extend(group)
                    if writes_output(words):
                        reports[start] = text.strip()
                continue
            if groups:
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

It "accepts quoted values, braced targets, continued and commented-out writes"
cat >"$(fixture)" <<'YAML'
runs:
  steps:
    - shell: sh
      run: |
        printf 'k=%s\n' "$value" >> "$GITHUB_OUTPUT"
        printf 'k=%s\n' '' >> "${GITHUB_OUTPUT}"
        printf 'k=%s\n' "a;b" >> "$GITHUB_OUTPUT" && printf 'j=%s\n' "c" >> "$GITHUB_OUTPUT"
        printf 'k=%s\n' "$value" \
          >> "$GITHUB_OUTPUT"
        # echo "a=b" >> "$GITHUB_OUTPUT"
YAML
When call violations "$(fixture)"
The output should equal ""
The status should be success
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

It "fails when PROJECT_ROOT holds no action.yml"
mkdir -p "${SHELLSPEC_TMPBASE}/empty"
PROJECT_ROOT="${SHELLSPEC_TMPBASE}/empty"
When call violations
The status should be failure
The error should equal "no action.yml under ${SHELLSPEC_TMPBASE}/empty"
End
End
End
