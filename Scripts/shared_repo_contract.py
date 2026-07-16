#!/usr/bin/env python3
"""Minimal shared repo contract validator vendored for HumbleStudio CI."""

from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path
from typing import Any


CUSTOM_LOCALIZATION_STRATEGIES = {
    "apple-xcstrings-and-web-inline",
    "custom-hybrid",
    "not-localized-yet",
}


@dataclass
class CheckResult:
    identifier: str
    status: str
    detail: str


def load_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def repo_glob_exists(root: Path, pattern: str) -> bool:
    return any(root.glob(pattern))


def normalize_config(config: dict[str, Any]) -> dict[str, Any]:
    rules = config.get("rules", {})
    config["_normalized_rules"] = {
        "required_paths": list(rules.get("required_paths", [])),
        "required_any_paths": list(rules.get("required_any_paths", [])),
    }
    return config


def validate_metadata(config: dict[str, Any]) -> list[CheckResult]:
    workflow = config.get("workflow", {})
    branch_hygiene = workflow.get("branch_hygiene", {})
    worktree_lanes = workflow.get("worktree_lanes", {})
    locale_policy = config.get("locale_policy", {})

    return [
        CheckResult(
            "metadata.name",
            "passed" if config.get("name") else "failed",
            config.get("name") or "missing repo name",
        ),
        CheckResult(
            "metadata.repo_type",
            "passed" if config.get("repo_type") else "failed",
            config.get("repo_type") or "missing repo_type",
        ),
        CheckResult(
            "modularity.module_roots",
            "passed" if config.get("module_roots") else "failed",
            ", ".join(config.get("module_roots", [])) or "declare module_roots",
        ),
        CheckResult(
            "localization.declared_locales",
            "passed" if locale_policy.get("declared_locales") else "failed",
            ", ".join(locale_policy.get("declared_locales", [])) or "declare at least one locale",
        ),
        CheckResult(
            "localization.strategy",
            "passed" if locale_policy.get("strategy") else "failed",
            locale_policy.get("strategy") or "declare localization strategy",
        ),
        CheckResult(
            "workflow.default_branch",
            "passed" if workflow.get("default_branch") == "main" else "failed",
            f"default branch: {workflow.get('default_branch', 'missing')}",
        ),
        CheckResult(
            "workflow.ticketed_changes",
            "passed" if workflow.get("requires_tickets") is True else "failed",
            "ticketed changes required" if workflow.get("requires_tickets") is True else "set requires_tickets=true",
        ),
        CheckResult(
            "workflow.branch_hygiene",
            "passed" if isinstance(branch_hygiene, dict) and bool(branch_hygiene) else "failed",
            "branch hygiene policy declared" if branch_hygiene else "declare workflow.branch_hygiene",
        ),
        CheckResult(
            "workflow.rebase_before_local_checks",
            "passed" if branch_hygiene.get("rebase_before_local_checks") is True else "failed",
            "rebase required before local checks" if branch_hygiene.get("rebase_before_local_checks") is True else "set workflow.branch_hygiene.rebase_before_local_checks=true",
        ),
        CheckResult(
            "workflow.rebase_before_promotion",
            "passed" if branch_hygiene.get("rebase_before_promotion") is True else "failed",
            "rebase required before promotion" if branch_hygiene.get("rebase_before_promotion") is True else "set workflow.branch_hygiene.rebase_before_promotion=true",
        ),
        CheckResult(
            "workflow.fast_promotion_after_green",
            "passed" if branch_hygiene.get("prefer_fast_promotion_after_green") is True else "failed",
            "fast promotion after green verification declared" if branch_hygiene.get("prefer_fast_promotion_after_green") is True else "set workflow.branch_hygiene.prefer_fast_promotion_after_green=true",
        ),
        CheckResult(
            "workflow.delete_merged_topic_branches",
            "passed" if branch_hygiene.get("delete_merged_topic_branches") is True else "failed",
            "merged topic branches must be deleted" if branch_hygiene.get("delete_merged_topic_branches") is True else "set workflow.branch_hygiene.delete_merged_topic_branches=true",
        ),
        CheckResult(
            "workflow.worktree_lanes",
            "passed" if isinstance(worktree_lanes, dict) and bool(worktree_lanes) else "failed",
            "worktree lane policy declared" if worktree_lanes else "declare workflow.worktree_lanes",
        ),
        CheckResult(
            "workflow.worktree_lanes_enabled",
            "passed" if worktree_lanes.get("enabled") is True else "failed",
            "worktree lanes enabled" if worktree_lanes.get("enabled") is True else "set workflow.worktree_lanes.enabled=true",
        ),
        CheckResult(
            "workflow.worktree_fixed_lanes",
            "passed" if worktree_lanes.get("lanes") == ["lane-1", "lane-2", "lane-3", "lane-4"] else "failed",
            "four fixed lanes declared" if worktree_lanes.get("lanes") == ["lane-1", "lane-2", "lane-3", "lane-4"] else "set workflow.worktree_lanes.lanes to lane-1 through lane-4",
        ),
        CheckResult(
            "workflow.worktree_lanes_root",
            "passed" if worktree_lanes.get("root") else "failed",
            worktree_lanes.get("root") or "declare workflow.worktree_lanes.root",
        ),
        CheckResult(
            "workflow.reserved_main_checkout",
            "passed" if worktree_lanes.get("reserved_main_checkout") is True else "failed",
            "main checkout reserved" if worktree_lanes.get("reserved_main_checkout") is True else "set workflow.worktree_lanes.reserved_main_checkout=true",
        ),
    ]


def validate_paths(config: dict[str, Any], root: Path) -> list[CheckResult]:
    checks: list[CheckResult] = []
    normalized = config["_normalized_rules"]

    for relative_path in normalized["required_paths"]:
        path = root / relative_path
        checks.append(
            CheckResult(
                f"path.{relative_path}",
                "passed" if path.exists() else "failed",
                "present" if path.exists() else "missing",
            )
        )

    for group in normalized["required_any_paths"]:
        exists = any(repo_glob_exists(root, pattern) for pattern in group)
        checks.append(
            CheckResult(
                f"path.any:{'|'.join(group)}",
                "passed" if exists else "failed",
                "present" if exists else f"none matched: {', '.join(group)}",
            )
        )

    for relative_root in config.get("module_roots", []):
        path = root / relative_root
        checks.append(
            CheckResult(
                f"module_root.{relative_root}",
                "passed" if path.exists() and path.is_dir() else "failed",
                "present" if path.exists() and path.is_dir() else "missing directory",
            )
        )

    return checks


def validate_localization(config: dict[str, Any], root: Path) -> list[CheckResult]:
    policy = config.get("locale_policy", {})
    strategy = policy.get("strategy", "")
    locales = policy.get("declared_locales", [])
    has_catalog = repo_glob_exists(root, "**/*.xcstrings")

    if strategy in CUSTOM_LOCALIZATION_STRATEGIES:
        assets_status = "passed" if has_catalog else "warning"
        assets_detail = "custom strategy; validator currently checks only declaration and asset presence heuristics" if has_catalog else "custom strategy; no .xcstrings assets found yet"
    else:
        assets_status = "warning"
        assets_detail = f"unrecognized localization strategy: {strategy or 'missing'}"

    return [
        CheckResult("localization.assets", assets_status, assets_detail),
        CheckResult(
            "localization.locale_count",
            "passed" if locales else "failed",
            f"{len(locales)} declared locale(s)" if locales else "declare at least one locale",
        ),
    ]


def collect_contract_results(repo_root: Path, config_path: Path) -> dict[str, Any]:
    config = normalize_config(load_json(config_path))
    checks = validate_metadata(config) + validate_paths(config, repo_root) + validate_localization(config, repo_root)

    overall = "passed"
    if any(check.status == "failed" for check in checks):
        overall = "failed"
    elif any(check.status == "warning" for check in checks):
        overall = "warning"

    return {
        "overall": overall,
        "project": config.get("name", repo_root.name),
        "checks": [
            {
                "identifier": check.identifier,
                "status": check.status,
                "detail": check.detail,
            }
            for check in checks
        ],
    }


def render_contract_text(payload: dict[str, Any]) -> str:
    lines = [
        f"Repo contract: {payload['overall']}",
        f"Project: {payload['project']}",
        "",
    ]
    for check in payload["checks"]:
        lines.append(f"- {check['identifier']} [{check['status']}]: {check['detail']}")
    return "\n".join(lines)
