#!/usr/bin/env python3
"""Render HumbleStudio tickets and lane occupancy as a compact board."""

from __future__ import annotations

import argparse
import json
from collections import Counter
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
STATUS_PATH = ROOT / ".humble" / "status" / "current.json"
TICKET_DIR = ROOT / ".humble" / "tickets"
LANES_PATH = ROOT / ".humble" / "coordination" / "lanes.json"
STATUS_ORDER = [
    "idea",
    "proposed",
    "accepted",
    "ready",
    "in_progress",
    "waiting",
    "testing",
    "solved",
    "closed",
    "rejected",
]
PRIORITY_ORDER = ["critical", "high", "medium", "low"]


def app_name() -> str:
    if STATUS_PATH.exists():
        payload = json.loads(STATUS_PATH.read_text(encoding="utf-8"))
        name = payload.get("app")
        if isinstance(name, str) and name.strip():
            return name
    return ROOT.name


def load_tickets() -> list[dict[str, Any]]:
    tickets: list[dict[str, Any]] = []
    for path in sorted(TICKET_DIR.glob("HS-*.json")):
        ticket = json.loads(path.read_text(encoding="utf-8"))
        ticket["_path"] = str(path)
        tickets.append(ticket)
    return tickets


def load_lanes() -> list[dict[str, Any]]:
    if not LANES_PATH.exists():
        return []
    payload = json.loads(LANES_PATH.read_text(encoding="utf-8"))
    lanes = payload.get("lanes", [])
    return [lane for lane in lanes if isinstance(lane, dict)]


def priority_key(ticket: dict[str, Any]) -> tuple[int, str]:
    priority = str(ticket.get("priority", "low"))
    try:
        priority_index = PRIORITY_ORDER.index(priority)
    except ValueError:
        priority_index = len(PRIORITY_ORDER)
    return priority_index, str(ticket.get("id", ""))


def summary_payload(tickets: list[dict[str, Any]], lanes: list[dict[str, Any]]) -> dict[str, Any]:
    by_status = Counter(str(ticket.get("status", "unknown")) for ticket in tickets)
    by_priority = Counter(str(ticket.get("priority", "unknown")) for ticket in tickets)
    active_lanes = [lane for lane in lanes if lane.get("state") == "active"]
    quarantined_lanes = [lane for lane in lanes if lane.get("state") == "quarantined"]
    return {
        "total_tickets": len(tickets),
        "by_status": {
            status: by_status.get(status, 0)
            for status in STATUS_ORDER
            if by_status.get(status, 0)
        },
        "by_priority": {
            priority: by_priority.get(priority, 0)
            for priority in PRIORITY_ORDER
            if by_priority.get(priority, 0)
        },
        "lanes_total": len(lanes),
        "lanes_active": len(active_lanes),
        "lanes_free": len(lanes) - len(active_lanes) - len(quarantined_lanes),
        "lanes_quarantined": len(quarantined_lanes),
    }


def filtered_tickets(
    tickets: list[dict[str, Any]],
    status: str | None,
    limit: int | None,
) -> list[dict[str, Any]]:
    selected = tickets
    if status:
        selected = [ticket for ticket in selected if ticket.get("status") == status]
    selected = sorted(selected, key=priority_key)
    if limit is not None:
        selected = selected[:limit]
    return selected


def render_text(
    tickets: list[dict[str, Any]],
    lanes: list[dict[str, Any]],
    selected: list[dict[str, Any]],
) -> str:
    app = app_name()
    summary = summary_payload(tickets, lanes)
    lines = [
        f"{app} Tickets",
        f"Total tickets: {summary['total_tickets']}",
        "By status: " + ", ".join(f"{key}={value}" for key, value in summary["by_status"].items()),
        "By priority: " + ", ".join(f"{key}={value}" for key, value in summary["by_priority"].items()),
        (
            "Lanes: "
            f"{summary['lanes_active']} active / "
            f"{summary['lanes_free']} free / "
            f"{summary['lanes_quarantined']} quarantined / "
            f"{summary['lanes_total']} total"
        ),
        "",
        "Tickets",
    ]
    for ticket in selected:
        lines.append(f"- {ticket['id']} [{ticket['status']}/{ticket['priority']}] {ticket['title']}")

    lines.append("")
    lines.append("Lanes")
    for lane in lanes:
        state = lane.get("state")
        if state == "active":
            lines.append(
                f"- {lane['id']}: {lane.get('ticket', 'unassigned')} on "
                f"{lane.get('branch', 'unknown')} ({lane['worktree_path']})"
            )
        elif state == "quarantined":
            lines.append(f"- {lane['id']}: quarantined ({lane['worktree_path']})")
        else:
            lines.append(f"- {lane['id']}: free ({lane['worktree_path']})")
    return "\n".join(lines)


def render_json(
    tickets: list[dict[str, Any]],
    lanes: list[dict[str, Any]],
    selected: list[dict[str, Any]],
) -> str:
    payload = {
        "summary": summary_payload(tickets, lanes),
        "tickets": selected,
        "lanes": lanes,
    }
    return json.dumps(payload, indent=2, ensure_ascii=False)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Render HumbleStudio ticket board.")
    parser.add_argument("--format", choices=("text", "json"), default="text")
    parser.add_argument("--status")
    parser.add_argument("--limit", type=int)
    args = parser.parse_args(argv)

    tickets = load_tickets()
    lanes = load_lanes()
    selected = filtered_tickets(tickets, args.status, args.limit)

    if args.format == "json":
        print(render_json(tickets, lanes, selected))
    else:
        print(render_text(tickets, lanes, selected))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
