#!/usr/bin/env python3
"""Render repo-native HumbleStudio status as text, JSON, or Mermaid."""

from __future__ import annotations

import argparse
import json
from typing import Any

import humble_status


def progress_bar(percent: int, width: int = 20) -> str:
    filled = round((percent / 100) * width)
    return "[" + "#" * filled + "-" * (width - filled) + f"] {percent}%"


def render_text(payload: dict[str, Any]) -> str:
    summary = payload["summary"]
    workflow = payload["workflow"]
    rows = [
        f"# {payload['app']} Status",
        "",
        f"Branch: {payload['git']['branch']}",
        f"Overall: {progress_bar(int(summary['overall_percent']))} ({summary['confidence']})",
        f"Headline: {summary['headline']}",
        "",
        "## Workflow Signals",
        f"- tickets: {workflow['ticket_count']}",
        f"- lanes: {workflow['active_lane_count']} active / {workflow['free_lane_count']} free / {workflow['quarantined_lane_count']} quarantined",
        f"- proposals: {workflow['proposal_artifact_count']} artifacts / {workflow['linked_proposal_count']} linked ticket references",
        "",
        "## Operating Layers",
    ]
    for layer in payload.get("operating_layers", []):
        rows.append(f"- {layer['label']}: {progress_bar(int(layer['percent']))} {layer['status']}")
    rows.extend(["", "## Top Gaps"])
    for gap in payload.get("top_gaps", [])[:5]:
        rows.append(f"- {gap['rank']}. {gap['title']}")
    return "\n".join(rows)


def render_mermaid(payload: dict[str, Any]) -> str:
    confidence_x = {"low": 0.25, "medium": 0.6, "high": 0.9}
    lines = [
        "quadrantChart",
        f"  title {payload['app']} Operating Layers",
        "  x-axis Lower confidence --> Higher confidence",
        "  y-axis Lower maturity --> Higher maturity",
        '  quadrant-1 "Healthy"',
        '  quadrant-2 "Promote next"',
        '  quadrant-3 "Prepare"',
        '  quadrant-4 "Needs evidence"',
    ]
    confidence_for_status = {"healthy": "high", "uneven": "medium", "blocked": "low"}
    for layer in payload.get("operating_layers", [])[:12]:
        confidence = confidence_for_status.get(str(layer.get("status")), "medium")
        lines.append(f'  "{layer["label"]}": [{confidence_x[confidence]}, {round(int(layer["percent"]) / 100, 2)}]')
    return "\n".join(lines)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--format", choices=("text", "json", "mermaid"), default="text")
    args = parser.parse_args(argv)

    payload = humble_status.collect_status()
    if args.format == "json":
        print(json.dumps(payload, indent=2, ensure_ascii=False))
    elif args.format == "mermaid":
        print(render_mermaid(payload))
    else:
        print(render_text(payload))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
