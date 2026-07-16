#!/usr/bin/env python3
"""Run the shared Humble repo doctor for HumbleStudio."""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
HUMBLECONTROL_SCRIPT = Path("/Users/janpokorny/Coding/personal/apps/HumbleControl/Scripts/humble_repo_doctor.py")


def main(argv: list[str] | None = None) -> int:
    if not HUMBLECONTROL_SCRIPT.exists():
        print(f"Missing HumbleControl repo doctor: {HUMBLECONTROL_SCRIPT}", file=sys.stderr)
        return 1

    args = argv if argv is not None else sys.argv[1:]
    completed = subprocess.run(
        [
            sys.executable,
            str(HUMBLECONTROL_SCRIPT),
            "--repo-root",
            str(ROOT),
            *args,
        ],
        check=False,
    )
    return completed.returncode


if __name__ == "__main__":
    raise SystemExit(main())
