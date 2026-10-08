#!/usr/bin/env python3
"""Print one version's section from CHANGELOG.md (for GitHub release notes).

Usage: extract_changelog.py <version> <changelog>

<version> may be "2.0.0" or "v2.0.0". Prints the section body (everything
under "## [X.Y.Z]" up to the next "## [", or EOF). A missing section prints
a one-line stub instead of failing, so a release can never be blocked by
changelog bookkeeping."""
import re
import sys


def extract(changelog_text: str, version: str) -> str:
    version = version.lstrip("v")
    pattern = re.compile(
        r"^## \[" + re.escape(version) + r"\][^\n]*\n(.*?)(?=^## \[|\Z)",
        re.MULTILINE | re.DOTALL,
    )
    match = pattern.search(changelog_text)
    if not match:
        return f"Release {version} — see CHANGELOG.md for the details.\n"
    return match.group(1).strip() + "\n"


def main() -> int:
    if len(sys.argv) != 3:
        print(__doc__, file=sys.stderr)
        return 2
    version, path = sys.argv[1], sys.argv[2]
    with open(path, encoding="utf-8") as f:
        sys.stdout.write(extract(f.read(), version))
    return 0


if __name__ == "__main__":
    sys.exit(main())
