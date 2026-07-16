#!/usr/bin/env python3
"""Validate HumbleStudio against the shared repo contract."""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
HUMBLECONTROL_SCRIPT = Path("/Users/janpokorny/Coding/personal/apps/HumbleControl/Scripts/validate_repo_contract.py")


def main() -> int:
    if not HUMBLECONTROL_SCRIPT.exists():
        print(f"Missing HumbleControl validator: {HUMBLECONTROL_SCRIPT}", file=sys.stderr)
        return 1

    completed = subprocess.run(
        [
            sys.executable,
            str(HUMBLECONTROL_SCRIPT),
            "--repo-root",
            str(ROOT),
            "--config",
            str(ROOT / "Config" / "repo-contract.json"),
        ],
        check=False,
    )
    return completed.returncode


if __name__ == "__main__":
    raise SystemExit(main())
