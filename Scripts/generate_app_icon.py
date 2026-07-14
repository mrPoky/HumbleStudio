#!/usr/bin/env python3
"""Generate the HumbleStudio app icon."""

from pathlib import Path
import subprocess
import sys


APP_NAME = "HumbleStudio"


def main() -> int:
    repo_root = Path(__file__).resolve().parents[1]
    generator = repo_root.parent / "HumbleControl" / "Scripts" / "generate_portfolio_app_icon.py"
    if not generator.exists():
        print(f"Missing portfolio icon generator: {generator}", file=sys.stderr)
        return 1
    command = [sys.executable, str(generator), "--app", APP_NAME, "--repo-root", str(repo_root), *sys.argv[1:]]
    return subprocess.run(command, check=False).returncode


if __name__ == "__main__":
    raise SystemExit(main())
