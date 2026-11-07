"""Convert flake8 results to a SARIF 2.1.0 log for GitHub code scanning.

flake8 has no SARIF output of its own. Its documented route to one is a formatter
plugin, and neither plugin on PyPI fits this action:

* ``flake8-sarif`` 1.0.15 leaves ``--output-file`` empty because its ``stop()`` never
  closes the file. Written to stdout instead, its log fails the SARIF schema on E999
  and E902 (``snippet.text`` is null, ``startLine`` is 0), and ``upload-sarif`` rejects
  a log that fails the schema.
* ``flake8-sarif-formatter`` depends on ``requests`` and ``beautifulsoup4``, which
  this job has no other use for.

So action.yml uses flake8's documented custom ``--format`` string to write one Python
literal per result, and this standard-library script turns those into SARIF.

Usage: flake8_to_sarif.py RESULTS_FILE SARIF_FILE ROOT_DIR

Run it from the directory flake8 ran in, because RESULTS_FILE paths are relative to
it. SARIF URIs are written relative to ROOT_DIR, the root of the repository, as code
scanning expects. Prints the number of results.
"""

from __future__ import annotations

import ast
import json
import os
from pathlib import Path
import sys
from urllib.parse import quote

SRCROOT = "%SRCROOT%"


def parse_results(raw: str) -> list[tuple[int, int, str, str, str]]:
    """Return the ``(row, col, code, path, text)`` results in flake8's output.

    Other lines are skipped: a caller's config can turn on ``statistics`` and
    ``benchmark``, which flake8 writes to the same file.
    """
    results = []
    for line in raw.splitlines():
        try:
            row, col, code, path, text = ast.literal_eval(line)
        except (SyntaxError, TypeError, ValueError):
            continue
        results.append((row, col, code, path, text))
    return results


def build_sarif(results: list[tuple[int, int, str, str, str]], root: str) -> dict:
    """Build the SARIF log for ``results``, with URIs relative to ``root``."""
    real_root = os.path.realpath(root)
    rules: dict[str, dict] = {}
    sarif_results = []
    for row, col, code, path, text in results:
        level = "error" if code.startswith("E") else "warning"
        rules.setdefault(code, {"id": code, "defaultConfiguration": {"level": level}})
        relative_path = os.path.relpath(path, real_root)
        sarif_results.append(
            {
                "ruleId": code,
                "level": level,
                "message": {"text": text},
                "locations": [
                    {
                        "physicalLocation": {
                            "artifactLocation": {
                                "uri": quote(relative_path, errors="surrogateescape"),
                                "uriBaseId": SRCROOT,
                            },
                            # flake8 reports line 0 for a file it cannot read; SARIF
                            # lines and columns start at 1.
                            "region": {"startLine": max(row, 1), "startColumn": max(col, 1)},
                        },
                    },
                ],
            },
        )
    return {
        "$schema": "https://json.schemastore.org/sarif-2.1.0.json",
        "version": "2.1.0",
        "runs": [
            {
                "tool": {
                    "driver": {
                        "name": "flake8",
                        "informationUri": "https://flake8.pycqa.org/",
                        "rules": list(rules.values()),
                    },
                },
                "originalUriBaseIds": {SRCROOT: {"uri": Path(real_root).as_uri() + "/"}},
                "results": sarif_results,
            },
        ],
    }


def main(argv: list[str]) -> int:
    """Convert RESULTS_FILE to SARIF_FILE and print the number of results."""
    results_file, sarif_file, root = argv
    # Results are ASCII because of %a; replacing only touches the lines parse_results skips.
    results = parse_results(Path(results_file).read_text(encoding="utf-8", errors="replace"))
    Path(sarif_file).write_text(
        json.dumps(build_sarif(results, root), indent=2) + "\n",
        encoding="utf-8",
    )
    print(len(results))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
