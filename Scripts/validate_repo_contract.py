#!/usr/bin/env python3
"""Validate HumbleStudio against the shared repo contract."""

from __future__ import annotations

import sys
from pathlib import Path

from shared_repo_contract import collect_contract_results, render_contract_text


ROOT = Path(__file__).resolve().parents[1]


def main() -> int:
    payload = collect_contract_results(
        ROOT,
        ROOT / "Config" / "repo-contract.json",
    )
    print(render_contract_text(payload))
    return 1 if payload["overall"] == "failed" else 0


if __name__ == "__main__":
    raise SystemExit(main())
