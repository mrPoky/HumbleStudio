#!/usr/bin/env python3
"""Manage HumbleStudio fixed worktree lanes."""

from __future__ import annotations

import argparse
import json
import re
import subprocess
from datetime import UTC, datetime
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
LANES_PATH = ROOT / ".humble" / "coordination" / "lanes.json"
TICKET_DIR = ROOT / ".humble" / "tickets"
ELIGIBLE_TICKET_STATUSES = {"accepted", "ready"}
BRANCH_PREFIX_BY_TYPE = {
    "feature": "feat",
    "bug": "fix",
    "qa": "chore",
    "docs": "docs",
    "refactor": "refactor",
    "release": "release",
    "design": "feat",
    "workflow": "chore",
}


class LaneError(RuntimeError):
    """Raised when lane workflow invariants are not satisfied."""


def slugify(value: str) -> str:
    cleaned = re.sub(r"[^a-z0-9]+", "-", value.lower())
    return cleaned.strip("-") or "slice"


def now_iso() -> str:
    return datetime.now(UTC).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def run_git(args: list[str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["git", *args],
        cwd=ROOT,
        check=False,
        text=True,
        capture_output=True,
    )


def load_registry(lanes_path: Path = LANES_PATH) -> dict[str, Any]:
    payload = json.loads(lanes_path.read_text(encoding="utf-8"))
    if not isinstance(payload, dict):
        raise LaneError("lane registry root must be an object")
    lanes = payload.get("lanes")
    if not isinstance(lanes, list):
        raise LaneError("lane registry must contain a `lanes` array")
    return payload


def save_registry(registry: dict[str, Any], lanes_path: Path = LANES_PATH) -> None:
    lanes_path.write_text(json.dumps(registry, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def load_ticket(ticket_id: str, ticket_dir: Path = TICKET_DIR) -> tuple[Path, dict[str, Any]]:
    path = ticket_dir / f"{ticket_id}.json"
    if not path.exists():
        raise LaneError(f"ticket not found: {ticket_id}")
    ticket = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(ticket, dict):
        raise LaneError(f"ticket has invalid JSON object shape: {ticket_id}")
    return path, ticket


def save_ticket(path: Path, ticket: dict[str, Any]) -> None:
    path.write_text(json.dumps(ticket, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def preferred_branch_name(ticket: dict[str, Any], override: str | None = None) -> str:
    if override:
        return override
    branch_prefix = BRANCH_PREFIX_BY_TYPE.get(str(ticket.get("type")), "chore")
    ticket_id = str(ticket["id"]).lower()
    title_slug = slugify(str(ticket.get("title", "")))
    return f"{branch_prefix}/{ticket_id}-{title_slug[:48].rstrip('-')}"


def resolve_lane(registry: dict[str, Any], lane_id: str | None = None) -> dict[str, Any]:
    lanes = [lane for lane in registry["lanes"] if isinstance(lane, dict)]
    if lane_id:
        for lane in lanes:
            if lane.get("id") == lane_id:
                return lane
        raise LaneError(f"unknown lane id: {lane_id}")
    for lane in lanes:
        if lane.get("state") == "free":
            return lane
    raise LaneError("no free lane is currently available")


def prepare_worktree(path: str, branch: str, base_ref: str) -> None:
    worktree_path = (ROOT / path).resolve()
    worktree_path.parent.mkdir(parents=True, exist_ok=True)

    branch_exists = run_git(["show-ref", "--verify", "--quiet", f"refs/heads/{branch}"]).returncode == 0
    if worktree_path.exists():
        result = run_git(["worktree", "list", "--porcelain"])
        if str(worktree_path) in result.stdout:
            return
        raise LaneError(f"worktree path already exists but is not a registered git worktree: {worktree_path}")

    if branch_exists:
        result = run_git(["worktree", "add", str(worktree_path), branch])
    else:
        result = run_git(["worktree", "add", "-b", branch, str(worktree_path), base_ref])
    if result.returncode != 0:
        raise LaneError(result.stderr.strip() or f"failed to prepare worktree for {branch}")


def claim_lane(
    ticket_id: str,
    scope_paths: list[str],
    owner: str = "Codex",
    lane_id: str | None = None,
    branch: str | None = None,
    note: str | None = None,
    prepare_git_worktree: bool = False,
) -> dict[str, Any]:
    registry = load_registry()
    ticket_path, ticket = load_ticket(ticket_id)
    status = str(ticket.get("status", ""))
    if status not in ELIGIBLE_TICKET_STATUSES:
        raise LaneError(
            f"ticket {ticket_id} must be in one of {sorted(ELIGIBLE_TICKET_STATUSES)} before lane claim; got `{status}`"
        )

    lane = resolve_lane(registry, lane_id=lane_id)
    if lane.get("state") != "free":
        raise LaneError(f"lane {lane['id']} is not free")

    branch_name = preferred_branch_name(ticket, override=branch)
    base_ref = str(registry.get("base_ref", "origin/main"))
    if prepare_git_worktree:
        prepare_worktree(str(lane["worktree_path"]), branch_name, base_ref)

    timestamp = now_iso()
    lane.update(
        {
            "state": "active",
            "ticket": ticket_id,
            "branch": branch_name,
            "owner": owner,
            "scope_paths": scope_paths,
            "claimed_at": timestamp,
            "heartbeat_at": timestamp,
            "released_at": None,
            "note": note or lane.get("note") or "",
        }
    )
    save_registry(registry)

    ticket["status"] = "in_progress"
    ticket["owner"] = owner
    ticket["updated_at"] = datetime.now().date().isoformat()
    agent_notes = ticket.setdefault("agent_notes", [])
    claim_note = f"Claimed {lane['id']} on branch `{branch_name}`."
    if claim_note not in agent_notes:
        agent_notes.append(claim_note)
    save_ticket(ticket_path, ticket)

    return {
        "lane_id": lane["id"],
        "ticket_id": ticket_id,
        "branch": branch_name,
        "worktree_path": str((ROOT / str(lane["worktree_path"])).resolve()),
        "prepared_worktree": prepare_git_worktree,
        "base_ref": base_ref,
    }


def release_lane(lane_id: str, note: str | None = None) -> dict[str, Any]:
    registry = load_registry()
    lane = resolve_lane(registry, lane_id=lane_id)
    previous = dict(lane)
    lane.update(
        {
            "state": "free",
            "ticket": None,
            "branch": None,
            "owner": None,
            "scope_paths": [],
            "claimed_at": None,
            "heartbeat_at": None,
            "released_at": now_iso(),
            "note": note or lane.get("note") or "",
        }
    )
    save_registry(registry)
    return {"released_lane": lane_id, "previous": previous}


def lanes_payload() -> dict[str, Any]:
    registry = load_registry()
    return {
        "base_ref": registry.get("base_ref", "origin/main"),
        "lanes": registry["lanes"],
    }


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Manage HumbleStudio fixed worktree lanes.")
    subparsers = parser.add_subparsers(dest="command", required=True)

    subparsers.add_parser("list", help="Print lane registry as JSON.")

    claim_parser = subparsers.add_parser("claim", help="Claim a free lane for a ticket.")
    claim_parser.add_argument("--ticket", required=True)
    claim_parser.add_argument("--path", dest="paths", action="append", default=[])
    claim_parser.add_argument("--owner", default="Codex")
    claim_parser.add_argument("--lane")
    claim_parser.add_argument("--branch")
    claim_parser.add_argument("--note")
    claim_parser.add_argument("--prepare-worktree", action="store_true")

    release_parser = subparsers.add_parser("release", help="Release an active lane back to free state.")
    release_parser.add_argument("--lane", required=True)
    release_parser.add_argument("--note")

    args = parser.parse_args(argv)
    try:
        if args.command == "list":
            print(json.dumps(lanes_payload(), indent=2, ensure_ascii=False))
        elif args.command == "claim":
            result = claim_lane(
                ticket_id=args.ticket,
                scope_paths=args.paths,
                owner=args.owner,
                lane_id=args.lane,
                branch=args.branch,
                note=args.note,
                prepare_git_worktree=args.prepare_worktree,
            )
            print(json.dumps(result, indent=2, ensure_ascii=False))
        elif args.command == "release":
            result = release_lane(args.lane, note=args.note)
            print(json.dumps(result, indent=2, ensure_ascii=False))
    except LaneError as error:
        print(f"FAIL: {error}")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
