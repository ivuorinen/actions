#!/usr/bin/env python3
"""Fix local action references in GitHub Action YAML files.

This script finds and fixes uses: ../action-name references to use: ./action-name
following GitHub's recommended pattern for same-repository action references.

Usage:
    python3 fix-local-action-refs.py [--check] [--dry-run]

Options:
    --check     Check for issues without fixing (exit code 1 if issues found)
    --dry-run   Show what would be changed without making changes
    --help      Show this help message

Examples:
    python3 fix-local-action-refs.py --check      # Check for issues
    python3 fix-local-action-refs.py --dry-run    # Preview changes
    python3 fix-local-action-refs.py              # Fix all issues
"""

from __future__ import annotations

import argparse
from pathlib import Path
import re
import sys


class LocalActionRefsFixer:
    """Fix local action references from ../action-name to ./action-name pattern."""

    def __init__(self, project_root: Path | None = None) -> None:
        """Initialize with project root directory."""
        if project_root is None:
            # Assume script is in _tools/ directory
            script_dir = Path(__file__).resolve().parent
            self.project_root = script_dir.parent
        else:
            self.project_root = Path(project_root).resolve()

    def find_action_files(self) -> list[Path]:
        """Find all action.yml files in the project."""
        action_files = []

        # Look for action.yml files in top-level directories
        for item in self.project_root.iterdir():
            if item.is_dir() and not item.name.startswith(".") and not item.name.startswith("_"):
                action_file = item / "action.yml"
                if action_file.exists():
                    action_files.append(action_file)

        return sorted(action_files)

    def get_available_actions(self) -> list[str]:
        """Get list of available action names in the repository."""
        actions = []
        for action_file in self.find_action_files():
            action_name = action_file.parent.name
            actions.append(action_name)
        return sorted(actions)

    def find_local_ref_issues(self, content: str) -> list[tuple[int, str, str, str]]:
        """Find lines with ../action-name references that should be ./action-name.

        Returns:
            List of (line_number, line_content, old_ref, new_ref) tuples
        """
        issues = []
        available_actions = self.get_available_actions()

        # Pattern to match "uses: ../action-name" references
        pattern = re.compile(r"^(\s*uses:\s+)\.\./([\w-]+)(\s*(?:#.*)?)\s*$")

        lines = content.splitlines()
        for line_num, line in enumerate(lines, 1):
            match = pattern.match(line)
            if match:
                _prefix, action_name, _suffix = match.groups()

                # Only fix if this is actually one of our actions
                if action_name in available_actions:
                    old_ref = f"../{action_name}"
                    new_ref = f"./{action_name}"
                    issues.append((line_num, line, old_ref, new_ref))

        return issues

    def fix_content(self, content: str) -> tuple[str, int]:
        """Fix ../action-name references to ./action-name in content.

        Returns:
            Tuple of (fixed_content, number_of_fixes)
        """
        available_actions = self.get_available_actions()
        fixes_made = 0

        # Pattern to match and replace "uses: ../action-name" references
        def replace_ref(match: re.Match[str]) -> str:
            nonlocal fixes_made
            prefix, action_name, suffix = match.groups()

            # Only fix if this is actually one of our actions
            if action_name in available_actions:
                fixes_made += 1
                return f"{prefix}./{action_name}{suffix}"
            # Don't change external references
            return match.group(0)

        pattern = re.compile(r"^(\s*uses:\s+)\.\./([\w-]+)(\s*(?:#.*)?)\s*$", re.MULTILINE)
        fixed_content = pattern.sub(replace_ref, content)

        return fixed_content, fixes_made

    def check_file(self, file_path: Path) -> dict:
        """Check a single file for local action reference issues.

        Returns:
            Dict with file info and issues found
        """
        try:
            content = file_path.read_text(encoding="utf-8")
            issues = self.find_local_ref_issues(content)

            return {"file": file_path, "issues": issues, "error": None}
        except Exception as e:
            return {"file": file_path, "issues": [], "error": str(e)}

    def fix_file(self, file_path: Path, *, dry_run: bool = False) -> dict:
        """Fix local action references in a single file.

        Returns:
            Dict with file info and fixes made
        """
        try:
            content = file_path.read_text(encoding="utf-8")
            fixed_content, fixes_made = self.fix_content(content)

            if fixes_made > 0 and not dry_run:
                file_path.write_text(fixed_content, encoding="utf-8")

            return {"file": file_path, "fixes_made": fixes_made, "error": None}
        except Exception as e:
            return {"file": file_path, "fixes_made": 0, "error": str(e)}

    def check_all_files(self) -> list[dict]:
        """Check all action files for issues."""
        results = []
        action_files = self.find_action_files()

        for file_path in action_files:
            result = self.check_file(file_path)
            if result["issues"] or result["error"]:
                results.append(result)

        return results

    def fix_all_files(self, *, dry_run: bool = False) -> list[dict]:
        """Fix all action files."""
        results = []
        action_files = self.find_action_files()

        for file_path in action_files:
            result = self.fix_file(file_path, dry_run=dry_run)
            if result["fixes_made"] > 0 or result["error"]:
                results.append(result)

        return results


def _create_argument_parser() -> argparse.ArgumentParser:
    """Create and configure the argument parser."""
    docstring = "" if __doc__ is None else __doc__

    parser = argparse.ArgumentParser(
        description="Fix local action references from ../action-name to ./action-name",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=docstring.split("Usage:")[1] if "Usage:" in docstring else None,
    )

    parser.add_argument(
        "--check",
        action="store_true",
        help="Check for issues without fixing (exit 1 if issues found)",
    )

    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show what would be changed without making changes",
    )

    return parser


def _run_check_mode(fixer: LocalActionRefsFixer) -> int:
    """Run in check mode and return exit code."""
    print("🔍 Checking for local action reference issues...")
    results = fixer.check_all_files()

    if not results:
        print("✅ No local action reference issues found!")
        return 0

    total_issues = 0
    for result in results:
        if result["error"]:
            print(f"❌ Error checking {result['file']}: {result['error']}")
            continue

        file_path = result["file"]
        issues = result["issues"]
        total_issues += len(issues)

        print(f"\n📄 {file_path.relative_to(fixer.project_root)}")
        for line_num, line, old_ref, new_ref in issues:
            print(f"  Line {line_num}: {old_ref} → {new_ref}")
            print(f"    {line.strip()}")

    print(f"\n⚠️  Found {total_issues} local action reference issues in {len(results)} files")
    print("Run without --check to fix these issues")
    return 1


def _run_fix_mode(fixer: LocalActionRefsFixer, *, dry_run: bool) -> int:
    """Run in fix/dry-run mode and return exit code."""
    action = (
        "🔍 Checking what would be fixed..." if dry_run else "🔧 Fixing local action references..."
    )

    print(f"{action}")

    results = fixer.fix_all_files(dry_run=dry_run)

    if not results:
        print("✅ No local action reference issues found!")
        return 0

    total_fixes = 0
    for result in results:
        if result["error"]:
            print(f"❌ Error processing {result['file']}: {result['error']}")
            continue

        file_path = result["file"]
        fixes_made = result["fixes_made"]
        total_fixes += fixes_made

        if fixes_made > 0:
            action_word = "Would fix" if dry_run else "Fixed"
            relative_path = file_path.relative_to(fixer.project_root)
            print(
                f"📄 {action_word} {fixes_made} reference(s) in {relative_path}",
            )

    if dry_run:
        print(f"\n📋 Would fix {total_fixes} local action references in {len(results)} files")
        print("Run without --dry-run to apply these fixes")
    else:
        print(f"\n✅ Fixed {total_fixes} local action references in {len(results)} files")

    return 0


def main() -> int:
    """Main entry point."""
    parser = _create_argument_parser()
    args = parser.parse_args()
    fixer = LocalActionRefsFixer()

    if args.check:
        return _run_check_mode(fixer)

    return _run_fix_mode(fixer, dry_run=args.dry_run)


if __name__ == "__main__":
    sys.exit(main())
