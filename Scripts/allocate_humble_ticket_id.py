#!/usr/bin/env python3
"""Print the next free HumbleStudio repo-native ticket id."""

from __future__ import annotations

import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
TICKET_DIR = ROOT / ".humble" / "tickets"
ID_PATTERN = re.compile(r"^HS-(\d{4})\.json$")


def next_ticket_id(ticket_dir: Path = TICKET_DIR) -> str:
    highest = 0
    for path in ticket_dir.glob("HS-*.json"):
        match = ID_PATTERN.match(path.name)
        if match:
            highest = max(highest, int(match.group(1)))
    return f"HS-{highest + 1:04d}"


if __name__ == "__main__":
    print(next_ticket_id())
