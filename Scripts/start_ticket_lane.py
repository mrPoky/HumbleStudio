#!/usr/bin/env python3
"""Claim the next suitable HumbleStudio ticket into a fixed lane."""

from __future__ import annotations

import argparse
import json

import manage_humble_lanes as lanes


PRIORITY_ORDER = {"critical": 0, "high": 1, "medium": 2, "low": 3}


def pick_next_ticket() -> str:
    registry = lanes.load_registry()
    claimed = {
        lane["ticket"]
        for lane in registry["lanes"]
        if isinstance(lane, dict) and lane.get("state") == "active" and lane.get("ticket")
    }

    candidates: list[dict[str, str]] = []
    for path in sorted(lanes.TICKET_DIR.glob("HS-*.json")):
        _, ticket = lanes.load_ticket(path.stem)
        if ticket["status"] not in lanes.ELIGIBLE_TICKET_STATUSES:
            continue
        if ticket["id"] in claimed:
            continue
        candidates.append(ticket)

    if not candidates:
        raise lanes.LaneError("no accepted or ready ticket is currently available for lane start")

    candidates.sort(key=lambda ticket: (PRIORITY_ORDER.get(str(ticket["priority"]), 99), str(ticket["id"])))
    return str(candidates[0]["id"])


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--path", dest="paths", action="append", required=True)
    parser.add_argument("--ticket")
    parser.add_argument("--owner", default="Codex")
    parser.add_argument("--lane")
    parser.add_argument("--branch")
    parser.add_argument("--note")
    parser.add_argument("--prepare-worktree", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args(argv)

    try:
        ticket_id = args.ticket or pick_next_ticket()
        if args.dry_run:
            _, ticket = lanes.load_ticket(ticket_id)
            lane = lanes.resolve_lane(lanes.load_registry(), lane_id=args.lane)
            payload = {
                "ticket_id": ticket_id,
                "lane_id": lane["id"],
                "branch": lanes.preferred_branch_name(ticket, override=args.branch),
                "prepare_worktree": args.prepare_worktree,
                "scope_paths": args.paths,
            }
        else:
            payload = lanes.claim_lane(
                ticket_id=ticket_id,
                scope_paths=args.paths,
                owner=args.owner,
                lane_id=args.lane,
                branch=args.branch,
                note=args.note,
                prepare_git_worktree=args.prepare_worktree,
            )
    except lanes.LaneError as error:
        print(f"FAIL: {error}")
        return 1

    print(json.dumps(payload, indent=2, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
