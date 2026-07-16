#!/usr/bin/env python3
"""Validate HumbleStudio repo-native ticket files."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
TICKET_DIR = ROOT / ".humble" / "tickets"
ID_PATTERN = re.compile(r"^HS-[0-9]{4}$")

REQUIRED_FIELDS = {
    "id",
    "title",
    "status",
    "type",
    "priority",
    "owner",
    "created_at",
    "updated_at",
    "source",
    "summary",
    "acceptance_criteria",
    "evidence",
    "related_files",
    "blocked_by",
    "trigger",
}
OPTIONAL_FIELDS = {
    "commands",
    "agent_notes",
    "relationships",
    "validation",
    "human_decision",
}

STATUSES = {
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
}
TYPES = {"feature", "bug", "qa", "docs", "refactor", "release", "design", "workflow"}
PRIORITIES = {"critical", "high", "medium", "low"}
SOURCES = {"user", "agent", "gap-status", "humblecontrol", "test-failure"}
TRIGGER_KINDS = {
    "manual_prompt",
    "automation",
    "agent_self_assigned",
    "scheduled_review",
    "humblecontrol",
    "test_failure",
}
INTERACTION_MODES = {
    "manual_interactive",
    "manual_autonomous",
    "automation_autonomous",
    "agent_autonomous",
}
QUESTION_POLICIES = {"ask_at_start", "allowed", "forbidden", "only_blocking"}
EVIDENCE_KINDS = {"command", "report", "snapshot", "screenshot", "pr", "note"}
EVIDENCE_STATUSES = {"pending", "passed", "failed", "blocked", "not_applicable"}


class ValidationFailure(Exception):
    pass


def load_json(path: Path) -> dict[str, Any]:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as error:
        raise ValidationFailure(f"{path.name}: invalid JSON: {error}") from error
    if not isinstance(data, dict):
        raise ValidationFailure(f"{path.name}: ticket root must be an object")
    return data


def require_non_empty_string(ticket: dict[str, Any], field: str, path: Path) -> str:
    value = ticket.get(field)
    if not isinstance(value, str) or not value.strip():
        raise ValidationFailure(f"{path.name}: `{field}` must be a non-empty string")
    return value


def require_array(ticket: dict[str, Any], field: str, path: Path) -> list[Any]:
    value = ticket.get(field)
    if not isinstance(value, list):
        raise ValidationFailure(f"{path.name}: `{field}` must be an array")
    return value


def validate_trigger(path: Path, ticket: dict[str, Any]) -> None:
    trigger = ticket.get("trigger")
    if not isinstance(trigger, dict):
        raise ValidationFailure(f"{path.name}: `trigger` must be an object")

    for field in ("kind", "interaction_mode", "question_policy", "source_ref"):
        if field not in trigger:
            raise ValidationFailure(f"{path.name}: `trigger.{field}` is required")

    if trigger["kind"] not in TRIGGER_KINDS:
        raise ValidationFailure(f"{path.name}: invalid trigger kind `{trigger['kind']}`")
    if trigger["interaction_mode"] not in INTERACTION_MODES:
        raise ValidationFailure(f"{path.name}: invalid interaction mode `{trigger['interaction_mode']}`")
    if trigger["question_policy"] not in QUESTION_POLICIES:
        raise ValidationFailure(f"{path.name}: invalid question policy `{trigger['question_policy']}`")
    if trigger["source_ref"] is not None and not isinstance(trigger["source_ref"], str):
        raise ValidationFailure(f"{path.name}: `trigger.source_ref` must be a string or null")


def validate_evidence(path: Path, ticket: dict[str, Any]) -> None:
    evidence = require_array(ticket, "evidence", path)
    for index, item in enumerate(evidence):
        if not isinstance(item, dict):
            raise ValidationFailure(f"{path.name}: evidence item {index} must be an object")
        if item.get("kind") not in EVIDENCE_KINDS:
            raise ValidationFailure(f"{path.name}: evidence item {index} has invalid kind")
        if item.get("status") not in EVIDENCE_STATUSES:
            raise ValidationFailure(f"{path.name}: evidence item {index} has invalid status")
        note = item.get("note")
        if note is not None and not isinstance(note, str):
            raise ValidationFailure(f"{path.name}: evidence item {index} note must be a string")


def validate_commands(path: Path, ticket: dict[str, Any]) -> list[str]:
    commands = ticket.get("commands")
    if commands is None:
        return []
    if not isinstance(commands, list):
        raise ValidationFailure(f"{path.name}: `commands` must be an array when present")
    if not all(isinstance(item, str) and item.strip() for item in commands):
        raise ValidationFailure(f"{path.name}: `commands` must contain non-empty strings")
    return commands


def validate_ticket(path: Path) -> None:
    ticket = load_json(path)
    unexpected = set(ticket) - REQUIRED_FIELDS - OPTIONAL_FIELDS
    if unexpected:
        raise ValidationFailure(f"{path.name}: unexpected fields: {', '.join(sorted(unexpected))}")
    missing = REQUIRED_FIELDS - set(ticket)
    if missing:
        raise ValidationFailure(f"{path.name}: missing required fields: {', '.join(sorted(missing))}")

    ticket_id = require_non_empty_string(ticket, "id", path)
    if not ID_PATTERN.match(ticket_id):
        raise ValidationFailure(f"{path.name}: invalid ticket id `{ticket_id}`")
    if path.stem != ticket_id:
        raise ValidationFailure(f"{path.name}: filename must match ticket id `{ticket_id}`")

    require_non_empty_string(ticket, "title", path)
    require_non_empty_string(ticket, "created_at", path)
    require_non_empty_string(ticket, "updated_at", path)
    require_non_empty_string(ticket, "summary", path)

    if ticket["status"] not in STATUSES:
        raise ValidationFailure(f"{path.name}: invalid status `{ticket['status']}`")
    if ticket["type"] not in TYPES:
        raise ValidationFailure(f"{path.name}: invalid type `{ticket['type']}`")
    if ticket["priority"] not in PRIORITIES:
        raise ValidationFailure(f"{path.name}: invalid priority `{ticket['priority']}`")
    if ticket["source"] not in SOURCES:
        raise ValidationFailure(f"{path.name}: invalid source `{ticket['source']}`")
    if ticket["owner"] is not None and not isinstance(ticket["owner"], str):
        raise ValidationFailure(f"{path.name}: `owner` must be a string or null")
    if ticket["blocked_by"] is not None and not isinstance(ticket["blocked_by"], (dict, list, str)):
        raise ValidationFailure(f"{path.name}: `blocked_by` must be null, object, array, or string")

    acceptance = require_array(ticket, "acceptance_criteria", path)
    if not acceptance or not all(isinstance(item, str) and item.strip() for item in acceptance):
        raise ValidationFailure(f"{path.name}: `acceptance_criteria` must contain non-empty strings")

    related_files = require_array(ticket, "related_files", path)
    if not all(isinstance(item, str) and item.strip() for item in related_files):
        raise ValidationFailure(f"{path.name}: `related_files` must contain non-empty strings")

    validate_trigger(path, ticket)
    validate_evidence(path, ticket)
    commands = validate_commands(path, ticket)

    if ticket["status"] in {"in_progress", "testing", "solved"} and not ticket["owner"]:
        raise ValidationFailure(f"{path.name}: `{ticket['status']}` tickets must have an owner")
    if ticket["status"] == "testing" and not commands:
        raise ValidationFailure(f"{path.name}: testing tickets must list `commands`")
    if ticket["status"] == "solved":
        if not commands:
            raise ValidationFailure(f"{path.name}: solved tickets must list `commands`")
        if not ticket["evidence"]:
            raise ValidationFailure(f"{path.name}: solved tickets must include evidence")
        if not any(item.get("status") in {"passed", "not_applicable"} for item in ticket["evidence"]):
            raise ValidationFailure(f"{path.name}: solved tickets need at least one passed or not_applicable evidence item")


def iter_ticket_paths(paths: list[str]) -> list[Path]:
    if paths:
        return [Path(path).resolve() for path in paths]
    return sorted(TICKET_DIR.glob("HS-*.json"))


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Validate HumbleStudio ticket files.")
    parser.add_argument("paths", nargs="*")
    args = parser.parse_args(argv)

    failures: list[str] = []
    ticket_paths = iter_ticket_paths(args.paths)
    for path in ticket_paths:
        try:
            validate_ticket(path)
        except ValidationFailure as error:
            failures.append(str(error))

    if failures:
        print("\n".join(failures), file=sys.stderr)
        return 1

    print(f"valid: {len(ticket_paths)} tickets")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
