"""Check how every ``<root>/*/action.yml`` pins the tools it installs.

Prints one line per violation and exits 1. A clean tree prints the number of Renovate comments
it checked, and a tree with none of them fails, so the check cannot pass by finding nothing.
"""

from __future__ import annotations

import importlib.util
import json
from pathlib import Path
import re
import sys

import yaml

SHARED = Path(__file__).resolve().parents[2] / "shared" / "shell_scripts.py"


def load_shared():
    """Import _tests/shared/shell_scripts.py, which is not on sys.path."""
    spec = importlib.util.spec_from_file_location("shell_scripts", SHARED)
    if spec is None or spec.loader is None:
        sys.exit(f"{SHARED}: cannot be loaded")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


sh = load_shared()

# customManagers:githubActionsVersions, from renovatebot/renovate's
# lib/config/presets/internal/custom-managers.preset.ts. A comment outside this shape is never
# seen by Renovate, so its pin goes stale silently. Copied here because the contract lives
# upstream; only the named-group syntax differs (JavaScript's ?<x> is Python's ?P<x>).
RENOVATE_PRESET = re.compile(
    r"# renovate: datasource=(?P<datasource>[a-zA-Z0-9-._]+?) depName=(?P<depName>[^\s]+?)"
    r"(?: (?:lookupName|packageName)=(?P<packageName>[^\s]+?))?"
    r"(?: versioning=(?P<versioning>[^\s]+?))?"
    r"(?: extractVersion=(?P<extractVersion>[^\s]+?))?"
    r"(?: registryUrl=(?P<registryUrl>[^\s]+?))?"
    r"\s+[A-Za-z0-9_]+?_VERSION\s*:\s*[\"']?(?P<currentValue>.+?)[\"']?\s"
)

# An exact version: three components, or qemu-vX.Y.Z as tonistiigi/binfmt publishes it.
EXACT_VERSION = re.compile(r"^(qemu-)?v?\d+\.\d+\.\d+$")

# setup-php takes major.minor and installs that line's newest patch, so a PHP pin can be no finer.
# For every other tool a two-component value is a range: npm reads 1.2 as 1.2.x.
MAJOR_MINOR_DEPS = {"php/php-src"}
MAJOR_MINOR = re.compile(r"^\d+\.\d+$")

# A reference to whatever upstream published last, anywhere in the file.
FLOATING_LINE = re.compile(r"@(latest|stable|main|master)\b|\bbun-version:\s*latest\b")


# For each package runner, the global options before its subcommand that take an argument.
GLOBAL_OPTIONS = {
    "npm": {
        "--prefix",
        "--workspace",
        "-w",
        "--registry",
        "--userconfig",
        "--globalconfig",
        "--cache",
        "--loglevel",
        "--include",
        "--omit",
    },
    "pnpm": {"-C", "--dir", "--filter", "-F"},
    "yarn": {"--cwd"},
    "bun": {"--cwd", "--config", "-c"},
    "uv": {"--directory", "--project", "--cache-dir", "--python", "-p", "--config-file"},
    "pipx": set(),
}


def subcommand(name: str, args: list[str]) -> tuple[str, list[str]]:
    """Return a runner's subcommand and the words after it, past its global options."""
    options = GLOBAL_OPTIONS.get(name, set())
    index = 0
    while index < len(args):
        is_option, needs_next = sh.takes_argument(args[index], options)
        if not is_option:
            break
        index += 2 if needs_next else 1
    return (args[index], args[index + 1 :]) if index < len(args) else ("", [])


def leading_options(args: list[str]) -> set[str]:
    """Return the options before the first operand: npx and bunx pass the rest to the package."""
    options = set()
    for arg in args:
        if not arg.startswith("-"):
            break
        options.add(arg)
    return options


def fetches_floating(name: str, args: list[str]) -> bool:
    """Whether a command fetches a package from the registry at run time and runs it.

    Such a fetch floats with or without an exact version on the package (prettier@3.6.2): no
    lockfile holds its dependencies, so they resolve to whatever their ranges allow on the day,
    with no integrity hash to check them against. A tool comes from a lockfile instead.

    npx and bunx (bun x) fetch a package they do not find unless --no-install (npx: --no) comes
    before its name; npm exec reads its own options up to --. pnpm dlx, yarn dlx, pnpx, uvx,
    pipx run and uv tool run always fetch, as do create with a template and npm init with an
    initializer, and uv run --with fetches what it names.
    """
    if name == "npx":
        return not leading_options(args) & {"--no-install", "--no"}
    if name == "bunx":
        return "--no-install" not in leading_options(args)
    command, rest = subcommand(name, args)
    operand = any(not arg.startswith("-") for arg in rest)
    if name == "npm" and command in ("exec", "x"):
        own = set(rest[: rest.index("--")]) if "--" in rest else leading_options(rest)
        return not own & {"--no-install", "--no"}
    if name == "bun" and command == "x":
        return "--no-install" not in leading_options(rest)
    if (name in ("pnpm", "yarn") and command == "dlx") or (name == "pipx" and command == "run"):
        return True
    if (name in ("npm", "pnpm", "yarn", "bun") and command == "create") or (
        name == "npm" and command == "init"
    ):
        return operand
    if name == "uv":
        return (command == "tool" and rest[:1] == ["run"]) or (
            command == "run" and any(arg.split("=", 1)[0] == "--with" for arg in rest)
        )
    return name in ("pnpx", "uvx")


def find_commands(script: str, language: str, line_of, matches) -> list[tuple[int, str]]:
    """Return (line, command) for each command in a script, and in the scripts it runs (with
    -c, eval, trap, env -S, or a here-document fed to a shell), for which matches(name, args)
    holds, such as fetches_floating."""
    found = []
    tree = sh.parse(script, language)
    for cmd in sh.simple_commands(tree):
        words = [sh.shape(word) for word in cmd.get("Args") or []]
        calls, scripts = sh.command_names(words)
        line = line_of(cmd["Pos"]["Line"])
        text = " ".join(words).replace(sh.EXPANSION, "$...")
        found += [(line, text) for index, name in calls if matches(name, words[index + 1 :])]
        for inner, inner_language in scripts:
            found += find_commands(inner, inner_language, lambda _line, at=line: at, matches)
    for body, language_read, line in sh.heredoc_scripts(tree, script.encode("utf-8")):
        outer = line_of(line)
        found += find_commands(body, language_read, lambda _line, at=outer: at, matches)
    return found


VERSION_INPUT_DEFAULT = re.compile(
    r"^  ([\w-]*version):\n(?:    .*\n)*?    default: ['\"]?(latest|stable)['\"]?$", re.MULTILINE
)

# The env context, not a script's process.env.
ENV_REFERENCE = re.compile(r"(?<![\w.])env\.([A-Z][A-Z0-9_]*)")
STEP_START = re.compile(r"^    - ", re.MULTILINE)


def repository_managers(root: Path) -> list[re.Pattern[str]]:
    """Return the matchStrings of the repository's own regex managers in .github/renovate.json.

    Renovate reads these as well as the preset, so a comment one of them matches is tracked.
    """
    config = root / ".github" / "renovate.json"
    if not config.is_file():
        return []
    managers = json.loads(config.read_text(encoding="utf-8")).get("customManagers", [])
    return [
        re.compile(pattern.replace("(?<", "(?P<"))
        for manager in managers
        for pattern in manager.get("matchStrings", [])
    ]


def pinned_value(text: str, comment_end: int) -> str:
    """Return the whole value on the line after a renovate comment, without its quotes.

    Renovate's match captures only a prefix of a value it cannot parse, so `1.2.3 - 2.0.0`
    would pass a check of that capture; the exact-version check reads the whole scalar.
    """
    start = text.find("\n", comment_end) + 1
    end = text.find("\n", start)
    line = text[start : end if end != -1 else len(text)]
    value = line.split(":", 1)[1].strip() if ":" in line else ""
    if len(value) >= 2 and value[0] == value[-1] and value[0] in "'\"":
        value = value[1:-1]
    return value


def check_action(action: Path, managers: list[re.Pattern[str]]) -> tuple[list[str], int]:
    """Return the violations in one action.yml and the number of Renovate comments in it."""
    text = action.read_text(encoding="utf-8")
    label = action.parent.name
    problems: list[str] = []

    problems += [
        f"{label}:{number}: floating tool reference: {line.strip()}"
        for number, line in enumerate(text.splitlines(), 1)
        if FLOATING_LINE.search(line)
    ]

    try:
        for script, language, line_of in sh.step_scripts(text):
            problems += [
                f"{label}:{number}: floating tool reference: {command}"
                for number, command in find_commands(script, language, line_of, fetches_floating)
            ]
    except (yaml.YAMLError, sh.ParseError) as error:
        problems.append(f"{label}: cannot read its scripts: {error}")

    problems += [
        f"{label}: input {match.group(1)} defaults to {match.group(2)}"
        for match in VERSION_INPUT_DEFAULT.finditer(text)
    ]

    comments = list(re.finditer(r"^[ \t]*# renovate:.*$", text, re.MULTILINE))
    for comment in comments:
        start = comment.group(0).index("#") + comment.start()
        found = RENOVATE_PRESET.match(text, start) or next(
            (match for match in (manager.match(text, start) for manager in managers) if match),
            None,
        )
        if found is None:
            problems.append(f"{label}: outside the preset's shape: {comment.group(0).strip()}")
            continue
        value = pinned_value(text, comment.end())
        if found.groupdict().get("currentDigest"):
            value = value.split("@", 1)[0]
        major_minor = found.group("depName") in MAJOR_MINOR_DEPS and MAJOR_MINOR.match(value)
        if not (EXACT_VERSION.match(value) or major_minor):
            problems.append(f"{label}: not an exact version: {value}")

    # A misspelt env reference is empty at run time, and an empty version input means upstream's
    # default: the floating version again, with nothing failing to say so.
    for block in STEP_START.split(text)[1:]:
        problems += [
            f"{label}: env.{name} is not defined on the step that reads it"
            for name in ENV_REFERENCE.findall(block)
            if not re.search(rf"^\s+{name}\s*:", block, re.MULTILINE)
        ]

    return problems, len(comments)


def main() -> int:
    root = Path(sys.argv[1])
    managers = repository_managers(root)
    problems: list[str] = []
    comments = 0
    for action in sorted(root.glob("*/action.yml")):
        action_problems, action_comments = check_action(action, managers)
        problems += action_problems
        comments += action_comments

    if comments == 0:
        problems.append("no renovate comments found")
    for problem in problems:
        print(problem)
    if problems:
        return 1
    print(f"checked {comments} renovate comments")
    return 0


if __name__ == "__main__":
    sys.exit(main())
