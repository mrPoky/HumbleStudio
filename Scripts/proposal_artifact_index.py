#!/usr/bin/env python3
"""Index read-only HumbleStudio proposal artifacts for workflow tooling."""

from __future__ import annotations

import json
import re
from dataclasses import asdict, dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PROPOSAL_DIR = ROOT / "docs" / "change-proposals"
TICKET_PATTERN = re.compile(r"\bHS-\d{4}\b")


@dataclass(frozen=True)
class ProposalArtifactInfo:
    path: str
    title: str
    scope: str
    ticket_ids: tuple[str, ...]


def _line_value(content: str, prefix: str, suffix: str = "") -> str:
    for raw_line in content.splitlines():
        line = raw_line.strip()
        if not line.startswith(prefix):
            continue
        trimmed = line[len(prefix):]
        if suffix:
            suffix_index = trimmed.find(suffix)
            if suffix_index >= 0:
                trimmed = trimmed[:suffix_index]
        return trimmed.strip()
    return ""


def load_proposals(proposal_dir: Path = PROPOSAL_DIR) -> list[ProposalArtifactInfo]:
    if not proposal_dir.exists() or not proposal_dir.is_dir():
        return []

    proposals: list[ProposalArtifactInfo] = []
    for path in sorted(proposal_dir.glob("*.md")):
        try:
            content = path.read_text(encoding="utf-8")
        except OSError:
            continue

        ticket_ids = tuple(sorted(set(TICKET_PATTERN.findall(content))))
        scope = _line_value(content, "- Surface: `", suffix="`")
        proposals.append(
            ProposalArtifactInfo(
                path=str(path),
                title=path.stem,
                scope=scope,
                ticket_ids=ticket_ids,
            )
        )
    return proposals


def linked_ticket_counts(proposals: list[ProposalArtifactInfo] | None = None) -> dict[str, int]:
    counts: dict[str, int] = {}
    for proposal in proposals or load_proposals():
        for ticket_id in proposal.ticket_ids:
            counts[ticket_id] = counts.get(ticket_id, 0) + 1
    return counts


def summary_payload(proposals: list[ProposalArtifactInfo] | None = None) -> dict[str, object]:
    entries = proposals or load_proposals()
    ticket_counts = linked_ticket_counts(entries)
    return {
        "proposal_artifact_count": len(entries),
        "linked_ticket_count": len(ticket_counts),
        "linked_proposal_count": sum(ticket_counts.values()),
        "scoped_proposal_count": sum(1 for proposal in entries if proposal.scope),
    }


def main() -> int:
    payload = {
        "summary": summary_payload(),
        "proposals": [asdict(proposal) for proposal in load_proposals()],
    }
    print(json.dumps(payload, indent=2, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
