#!/usr/bin/env python3
"""Repo-owned HumbleStudio status provider."""

from __future__ import annotations

import argparse
import json
import subprocess
from pathlib import Path
from typing import Any

import proposal_artifact_index


ROOT = Path(__file__).resolve().parents[1]
STATUS_PATH = ROOT / ".humble" / "status" / "current.json"
LANES_PATH = ROOT / ".humble" / "coordination" / "lanes.json"
TICKET_DIR = ROOT / ".humble" / "tickets"


def run_git(args: list[str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["git", *args],
        cwd=ROOT,
        check=False,
        capture_output=True,
        text=True,
    )


def git_output(args: list[str]) -> str:
    return run_git(args).stdout.strip()


def parse_ahead_behind(upstream: str | None) -> tuple[int | None, int | None]:
    if not upstream:
        return None, None
    result = run_git(["rev-list", "--left-right", "--count", f"HEAD...{upstream}"])
    if result.returncode != 0:
        return None, None
    parts = result.stdout.split()
    if len(parts) != 2:
        return None, None
    try:
        return int(parts[0]), int(parts[1])
    except ValueError:
        return None, None


def load_lane_registry() -> dict[str, Any]:
    if not LANES_PATH.exists():
        return {"lanes": []}
    payload = json.loads(LANES_PATH.read_text(encoding="utf-8"))
    if isinstance(payload, dict):
        return payload
    return {"lanes": []}


def collect_worktrees() -> dict[str, Any]:
    result = run_git(["worktree", "list", "--porcelain"])
    worktrees: list[dict[str, str]] = []
    current: dict[str, str] = {}
    for line in result.stdout.splitlines():
        if not line:
            if current:
                worktrees.append(current)
                current = {}
            continue
        key, _, value = line.partition(" ")
        if key == "worktree":
            current["worktree"] = value
        elif key == "HEAD":
            current["HEAD"] = value
        elif key == "branch":
            current["branch"] = value
    if current:
        worktrees.append(current)
    return {"worktrees": worktrees}


def collect_status() -> dict[str, Any]:
    status = json.loads(STATUS_PATH.read_text(encoding="utf-8"))
    git_status = run_git(["status", "--short", "--branch"])
    branch = git_output(["branch", "--show-current"]) or "DETACHED"
    upstream_result = run_git(["rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{u}"])
    upstream = upstream_result.stdout.strip() if upstream_result.returncode == 0 else None
    ahead, behind = parse_ahead_behind(upstream)
    dirty = [
        line for line in git_status.stdout.splitlines()
        if line and not line.startswith("## ")
    ]

    status["git"] = {
        "branch": branch,
        "upstream": upstream,
        "clean": not dirty,
        "dirty_count": len(dirty),
        "dirty_paths": dirty,
        "ahead": ahead,
        "behind": behind,
        "status_line": git_status.stdout.splitlines()[0] if git_status.stdout else "",
    }
    status["repo"] = {
        "root": str(ROOT),
        "branch": branch,
        "clean": not dirty,
        "dirty_count": len(dirty),
        "dirty_paths": dirty,
    }
    status["worktrees"] = collect_worktrees()

    lane_registry = load_lane_registry()
    lanes = lane_registry.get("lanes", [])
    active_lanes = [lane for lane in lanes if lane.get("state") == "active"]
    quarantined_lanes = [lane for lane in lanes if lane.get("state") == "quarantined"]
    proposal_summary = proposal_artifact_index.summary_payload()
    status["workflow"] = {
        "ticket_count": len(sorted(TICKET_DIR.glob("HS-*.json"))),
        "lane_count": len(lanes),
        "active_lane_count": len(active_lanes),
        "free_lane_count": len(lanes) - len(active_lanes) - len(quarantined_lanes),
        "quarantined_lane_count": len(quarantined_lanes),
        "proposal_artifact_count": proposal_summary["proposal_artifact_count"],
        "linked_proposal_count": proposal_summary["linked_proposal_count"],
        "linked_proposal_ticket_count": proposal_summary["linked_ticket_count"],
    }
    return status


def render_text(payload: dict[str, Any]) -> str:
    git = payload["git"]
    workflow = payload["workflow"]
    lines = [
        f"{payload['app']} Repo Status",
        "",
        f"- branch: {git['branch']}",
        f"- upstream: {git['upstream'] or 'none'}",
        f"- clean: {git['clean']} ({git['dirty_count']} dirty paths)",
        f"- ticket board: {workflow['ticket_count']} tickets",
        (
            "- lane pool: "
            f"{workflow['active_lane_count']} active / "
            f"{workflow['free_lane_count']} free / "
            f"{workflow['quarantined_lane_count']} quarantined"
        ),
        (
            "- proposal links: "
            f"{workflow['proposal_artifact_count']} artifacts / "
            f"{workflow['linked_proposal_count']} linked ticket references"
        ),
        f"- headline: {payload['summary']['headline']}",
        (
            f"- overall: {payload['summary']['overall_percent']}% "
            f"({payload['summary']['confidence']})"
        ),
        "",
        "Top Gaps",
    ]
    for gap in payload.get("top_gaps", [])[:3]:
        lines.append(f"- {gap['rank']}. {gap['title']}")
    return "\n".join(lines)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Render HumbleStudio status.")
    parser.add_argument("--format", choices=("text", "json"), default="text")
    args = parser.parse_args(argv)

    payload = collect_status()
    if args.format == "json":
        print(json.dumps(payload, indent=2, ensure_ascii=False))
    else:
        print(render_text(payload))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
