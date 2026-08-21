#!/usr/bin/env python3
"""Serve HumbleStudio with safe localhost supported-app export endpoints."""

from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import sys
from dataclasses import dataclass
from datetime import datetime, timezone
from http import HTTPStatus
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from typing import Mapping
from urllib.parse import parse_qs, quote, unquote, urlparse


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_PERSONAL_APPS_ROOT = Path("/Users/janpokorny/Coding/personal/apps")
DEFAULT_HUMBLESUDOKU_REPO = Path("/Users/janpokorny/Coding/personal/apps/HumbleSudoku")
DEFAULT_HUMBLECONTROL_REPO = Path("/Users/janpokorny/Coding/personal/apps/HumbleControl")
DEFAULT_HUMBLECONTROL_URL = "http://127.0.0.1:3000"
LOCAL_EXPORT_HEADER = "X-HumbleStudio-Local-Export"
CONNECTION_MANIFEST_SCHEMA = "humble.studio.connections.v1"
PREPARE_EDIT_SCHEMA = "humble.studio.prepare-edit.v1"
HELPER_LOG_PATH = "/tmp/humblecontrol-humblestudio-helper.log"
RUNTIME_AUTHORING_CAPABILITIES = [
    "workspace-launch",
    "structured-edit-draft",
    "patch-preview",
    "patch-artifact",
    "sandbox-apply",
    "proposal-center",
    "source-apply-locked",
]
CONVERGENCE_WORKFLOW_STAGES = [
    {
        "id": "connection-center",
        "rank": 1,
        "title": "Connection Center",
        "intent": "Connect HumbleControl to the active HumbleStudio helper, manifest, and selected app export.",
    },
    {
        "id": "app-switcher",
        "rank": 2,
        "title": "App Switcher",
        "intent": "Open supported Humble apps from one workspace without losing authoring context.",
    },
    {
        "id": "proposal-inbox-v2",
        "rank": 3,
        "title": "Proposal Inbox v2",
        "intent": "Keep app-scoped proposal review close to runtime readiness and edit planning.",
    },
    {
        "id": "patch-artifact-viewer",
        "rank": 4,
        "title": "Patch Artifact Viewer",
        "intent": "Review portable patch artifacts before any apply-oriented workflow is discussed.",
    },
    {
        "id": "sandbox-apply-v1",
        "rank": 5,
        "title": "Sandbox Apply v1",
        "intent": "Preview apply effects in a scratch-only lane while source writes remain disabled.",
    },
    {
        "id": "edit-boundary-ui",
        "rank": 6,
        "title": "Edit Boundary UI",
        "intent": "Make locked write requirements visible before a user can request a real edit flow.",
    },
    {
        "id": "first-safe-edit-flow",
        "rank": 7,
        "title": "First Safe Edit Flow",
        "intent": "Prepare the first explicit-confirmation edit journey while keeping current exports no-write.",
    },
    {
        "id": "shell-convergence",
        "rank": 8,
        "title": "HumbleStudio/HumbleControl Shell Convergence",
        "intent": "Move Studio authoring and Control orchestration into one connected workspace shell.",
    },
    {
        "id": "native-web-parity",
        "rank": 9,
        "title": "Native/Web Parity",
        "intent": "Expose the same workflow anchors to native Studio and the local Control web surface.",
    },
    {
        "id": "repo-orchestration",
        "rank": 10,
        "title": "Repo Orchestration",
        "intent": "Coordinate tickets, lanes, smoke checks, and promotion gates before source writes are unlocked.",
    },
]


@dataclass(frozen=True)
class SupportedAppExport:
    app_id: str
    app_name: str
    repo_path: Path
    export_relative_path: Path
    generator_command: tuple[str, ...]
    content_type: str = "application/json; charset=utf-8"
    source_kind: str = "design.json"


@dataclass(frozen=True)
class LocalExportResult:
    app: SupportedAppExport
    export_path: Path
    generated: bool


class LocalPreviewError(Exception):
    def __init__(self, status: HTTPStatus, code: str, message: str) -> None:
        super().__init__(message)
        self.status = status
        self.code = code
        self.message = message


def env_path(*names: str) -> Path | None:
    for name in names:
        value = os.environ.get(name)
        if value:
            return Path(value).expanduser()
    return None


def personal_app_repo(app_name: str, *env_names: str) -> Path:
    return env_path(*env_names) or DEFAULT_PERSONAL_APPS_ROOT / app_name


def design_json_export(app_id: str, app_name: str, repo_name: str, *env_names: str) -> SupportedAppExport:
    return SupportedAppExport(
        app_id=app_id,
        app_name=app_name,
        repo_path=personal_app_repo(repo_name, *env_names),
        export_relative_path=Path(".humble/design.json"),
        generator_command=(),
        content_type="application/json; charset=utf-8",
        source_kind="design.json",
    )


def build_supported_app_catalog() -> dict[str, SupportedAppExport]:
    sudoku_repo = (
        env_path("HUMBLESTUDIO_HUMBLESUDOKU_REPO", "HUMBLE_SUDOKU_REPO_ROOT")
        or DEFAULT_HUMBLESUDOKU_REPO
    )
    control_repo = (
        env_path("HUMBLESTUDIO_HUMBLECONTROL_REPO", "HUMBLECONTROL_REPO_ROOT")
        or DEFAULT_HUMBLECONTROL_REPO
    )
    catalog = {
        "humble-sudoku": SupportedAppExport(
            app_id="humble-sudoku",
            app_name="HumbleSudoku",
            repo_path=sudoku_repo,
            export_relative_path=Path(".humble/HumbleSudoku.humblebundle"),
            generator_command=(
                "python3",
                "Scripts/generate_humble_studio_config.py",
                "--bundle",
            ),
            content_type="application/zip",
            source_kind="humblebundle",
        ),
        "humble-control": SupportedAppExport(
            app_id="humble-control",
            app_name="HumbleControl",
            repo_path=control_repo,
            export_relative_path=Path(".humble/design.json"),
            generator_command=(),
            content_type="application/json; charset=utf-8",
            source_kind="design.json",
        ),
    }
    catalog.update(
        {
            "my-vltava-run": design_json_export(
                "my-vltava-run",
                "MyVltavaRun",
                "MyVltavaRun",
                "HUMBLESTUDIO_MYVLTAVARUN_REPO",
                "MYVLTAVARUN_REPO_ROOT",
            ),
            "humble-workout": design_json_export(
                "humble-workout",
                "HumbleWorkout",
                "HumbleWorkout",
                "HUMBLESTUDIO_HUMBLEWORKOUT_REPO",
                "HUMBLEWORKOUT_REPO_ROOT",
            ),
            "humble-kakuro": design_json_export(
                "humble-kakuro",
                "HumbleKakuro",
                "HumbleKakuro",
                "HUMBLESTUDIO_HUMBLEKAKURO_REPO",
                "HUMBLEKAKURO_REPO_ROOT",
            ),
            "humble-cycling": design_json_export(
                "humble-cycling",
                "HumbleCycling",
                "HumbleCycling",
                "HUMBLESTUDIO_HUMBLECYCLING_REPO",
                "HUMBLECYCLING_REPO_ROOT",
            ),
            "humble-home": design_json_export(
                "humble-home",
                "HumbleHome",
                "HumbleHome",
                "HUMBLESTUDIO_HUMBLEHOME_REPO",
                "HUMBLEHOME_REPO_ROOT",
            ),
            "humble-cook": design_json_export(
                "humble-cook",
                "HumbleCook",
                "HumbleCook",
                "HUMBLESTUDIO_HUMBLECOOK_REPO",
                "HUMBLECOOK_REPO_ROOT",
            ),
            "humble-architect": design_json_export(
                "humble-architect",
                "HumbleArchitect",
                "HumbleArchitect",
                "HUMBLESTUDIO_HUMBLEARCHITECT_REPO",
                "HUMBLEARCHITECT_REPO_ROOT",
            ),
            "humble-nas": design_json_export(
                "humble-nas",
                "HumbleNAS",
                "HumbleNAS",
                "HUMBLESTUDIO_HUMBLENAS_REPO",
                "HUMBLENAS_REPO_ROOT",
            ),
            "humble-subscription": design_json_export(
                "humble-subscription",
                "HumbleSubscription",
                "HumbleSubscription",
                "HUMBLESTUDIO_HUMBLESUBSCRIPTION_REPO",
                "HUMBLESUBSCRIPTION_REPO_ROOT",
            ),
            "my-family": design_json_export(
                "my-family",
                "MyFamily",
                "MyFamily",
                "HUMBLESTUDIO_MYFAMILY_REPO",
                "MYFAMILY_REPO_ROOT",
            ),
        }
    )
    return catalog


SUPPORTED_APP_EXPORTS = build_supported_app_catalog()


def resolve_under_root(root: Path, child: Path) -> Path:
    resolved_root = root.expanduser().resolve()
    resolved_child = (resolved_root / child).resolve()
    if resolved_child != resolved_root and resolved_root not in resolved_child.parents:
        raise LocalPreviewError(
            HTTPStatus.INTERNAL_SERVER_ERROR,
            "invalid_catalog_path",
            "Configured export path escapes the supported app repository.",
        )
    return resolved_child


def command_excerpt(completed: subprocess.CompletedProcess[str]) -> str:
    output = "\n".join(part.strip() for part in (completed.stdout, completed.stderr) if part.strip())
    if not output:
        return f"exit code {completed.returncode}"
    return output[-1200:]


def run_export_generator(app: SupportedAppExport, repo_root: Path) -> None:
    try:
        completed = subprocess.run(
            list(app.generator_command),
            cwd=repo_root,
            check=False,
            capture_output=True,
            text=True,
            timeout=120,
        )
    except FileNotFoundError as error:
        raise LocalPreviewError(
            HTTPStatus.INTERNAL_SERVER_ERROR,
            "generator_unavailable",
            f"Could not run export command for {app.app_name}: {error}",
        ) from error
    except subprocess.TimeoutExpired as error:
        raise LocalPreviewError(
            HTTPStatus.INTERNAL_SERVER_ERROR,
            "generator_timeout",
            f"Export command for {app.app_name} timed out.",
        ) from error

    if completed.returncode != 0:
        raise LocalPreviewError(
            HTTPStatus.INTERNAL_SERVER_ERROR,
            "generator_failed",
            f"Export command for {app.app_name} failed: {command_excerpt(completed)}",
        )


def ensure_supported_app_export(
    app_id: str,
    catalog: Mapping[str, SupportedAppExport] | None = None,
) -> LocalExportResult:
    active_catalog = catalog or SUPPORTED_APP_EXPORTS
    app = active_catalog.get(app_id)
    if not app:
        raise LocalPreviewError(
            HTTPStatus.NOT_FOUND,
            "unknown_supported_app",
            f"No local export resolver is configured for supported app '{app_id}'.",
        )

    repo_root = app.repo_path.expanduser().resolve()
    if not repo_root.is_dir():
        raise LocalPreviewError(
            HTTPStatus.INTERNAL_SERVER_ERROR,
            "repository_missing",
            f"Local repository for {app.app_name} was not found at {repo_root}.",
        )

    export_path = resolve_under_root(repo_root, app.export_relative_path)
    if export_path.is_file():
        return LocalExportResult(app=app, export_path=export_path, generated=False)

    if not app.generator_command:
        raise LocalPreviewError(
            HTTPStatus.INTERNAL_SERVER_ERROR,
            "export_missing",
            f"{app.app_name} export is missing at {app.export_relative_path}; no generator is configured for this local resolver.",
        )

    run_export_generator(app, repo_root)
    if not export_path.is_file():
        raise LocalPreviewError(
            HTTPStatus.INTERNAL_SERVER_ERROR,
            "export_missing",
            f"Export command finished, but {app.app_name} did not create {app.export_relative_path}.",
        )
    return LocalExportResult(app=app, export_path=export_path, generated=True)


def parse_supported_app_export_path(request_path: str) -> str | None:
    parsed = urlparse(request_path)
    parts = [unquote(part) for part in parsed.path.split("/") if part]
    if len(parts) == 4 and parts[:2] == ["api", "supported-apps"] and parts[3] == "export":
        return parts[2]
    return None


def parse_connection_path(request_path: str) -> str | None:
    parsed = urlparse(request_path)
    parts = [unquote(part) for part in parsed.path.split("/") if part]
    if parts == ["api", "connections"]:
        return "all"
    if parts == ["api", "connections", "humble-control"]:
        return "humble-control"
    if parts == ["api", "connections", "humble-control", "prepare-edit"]:
        return "humble-control-prepare-edit"
    return None


def parse_prepare_edit_app_id(request_path: str) -> str | None:
    parsed = urlparse(request_path)
    values = parse_qs(parsed.query, keep_blank_values=True).get("app")
    if not values:
        return None
    return values[0].strip() or None


def export_state(app: SupportedAppExport) -> tuple[str, Path]:
    repo_root = app.repo_path.expanduser().resolve()
    if not repo_root.is_dir():
        return "repository_missing", repo_root / app.export_relative_path
    export_path = resolve_under_root(repo_root, app.export_relative_path)
    if export_path.is_file():
        return "available", export_path
    if app.generator_command:
        return "generatable", export_path
    return "missing", export_path


def build_workspace_launch_descriptor(app: SupportedAppExport, endpoint: str, encoded_app_id: str) -> dict[str, object]:
    return {
        "schema": "humble.studio.workspace-launch.v1",
        "controlUrl": f"/studio/{encoded_app_id}",
        "loadUrl": f"/api/connections/humblestudio/load/{encoded_app_id}",
        "exportEndpoint": endpoint,
        "helperRequired": True,
        "writes": False,
        "steps": [
            "helper-listener",
            "connection-manifest",
            "app-export",
            "workspace-route",
            "session-evidence",
        ],
    }


def build_recovery_wizard_descriptor(
    app: SupportedAppExport,
    endpoint: str,
    encoded_app_id: str,
    state: str,
) -> dict[str, object]:
    return {
        "schema": "humble.studio.recovery-wizard.v1",
        "controlUrl": f"/studio/{encoded_app_id}#recovery",
        "exportEndpoint": endpoint,
        "canGenerate": bool(app.generator_command),
        "state": state,
        "confirmationRequired": True,
        "effect": "studio-export-generator" if app.generator_command else "inspect-only",
        "writes": False,
    }


def build_apply_preview_descriptor(encoded_app_id: str) -> dict[str, object]:
    return {
        "schema": "humble.studio.apply-preview.v1",
        "controlUrl": f"/studio/{encoded_app_id}#apply-preview",
        "status": "locked",
        "writes": False,
        "requires": [
            "explicit-user-confirmation",
            "human-review",
            "clean-worktree-or-backup",
            "ticket-scoped-change",
        ],
    }


def build_edit_boundary_descriptor(encoded_app_id: str) -> dict[str, object]:
    return {
        "schema": "humble.studio.edit-boundary.v1",
        "controlUrl": f"/studio/{encoded_app_id}#edit-boundary",
        "status": "draft",
        "apply": "locked",
        "writes": False,
        "requires": [
            "repo-native-ticket",
            "review-artifact",
            "session-evidence",
            "explicit-user-confirmation",
        ],
    }


def build_authoring_session_descriptor(encoded_app_id: str) -> dict[str, object]:
    return {
        "schema": "humble.studio.authoring-session.v1",
        "controlUrl": f"/studio/{encoded_app_id}#authoring-session",
        "storage": "browser-local",
        "restores": [
            "selected-app",
            "export-identity",
            "proposal-draft",
            "recovery-confirmation",
            "locked-apply-state",
        ],
        "writes": False,
    }


def build_structured_draft_descriptor(encoded_app_id: str) -> dict[str, object]:
    return {
        "schema": "humble.studio.structured-draft.v1",
        "controlUrl": f"/studio/{encoded_app_id}#structured-draft",
        "kinds": [
            "token",
            "text",
            "navigation",
            "asset",
        ],
        "writes": False,
    }


def build_patch_preview_descriptor(encoded_app_id: str) -> dict[str, object]:
    return {
        "schema": "humble.studio.patch-preview.v1",
        "controlUrl": f"/studio/{encoded_app_id}#patch-preview",
        "status": "review-only",
        "writes": False,
    }


def build_runtime_readiness_descriptor(encoded_app_id: str) -> dict[str, object]:
    return {
        "schema": "humble.studio.runtime-readiness.v1",
        "controlUrl": f"/studio/{encoded_app_id}#runtime-readiness",
        "expectedCapabilities": RUNTIME_AUTHORING_CAPABILITIES,
        "restartAction": "reconnect",
        "writes": False,
    }


def build_proposal_center_descriptor(encoded_app_id: str) -> dict[str, object]:
    return {
        "schema": "humble.studio.proposal-center.v1",
        "controlUrl": f"/studio/{encoded_app_id}#proposal-center",
        "inboxUrl": "/studio/proposals",
        "writes": False,
    }


def build_patch_artifact_descriptor(app_id: str, encoded_app_id: str) -> dict[str, object]:
    return {
        "schema": "humble.studio.patch-artifact.v1",
        "controlUrl": f"/studio/{encoded_app_id}#patch-artifact",
        "suggestedFilename": f"{app_id}-studio-patch-artifact.json",
        "writes": False,
    }


def build_sandbox_apply_descriptor(encoded_app_id: str) -> dict[str, object]:
    return {
        "schema": "humble.studio.sandbox-apply.v1",
        "controlUrl": f"/studio/{encoded_app_id}#sandbox-apply",
        "mode": "scratch-only",
        "sourceWrites": False,
        "writes": False,
    }


def build_source_apply_lock_descriptor(encoded_app_id: str) -> dict[str, object]:
    return {
        "schema": "humble.studio.source-apply-lock.v1",
        "controlUrl": f"/studio/{encoded_app_id}#source-apply-lock",
        "status": "locked",
        "writes": False,
    }


def build_trust_level_descriptor(encoded_app_id: str, state: str) -> dict[str, object]:
    return {
        "schema": "humble.studio.trust-level.v1",
        "controlUrl": f"/studio/{encoded_app_id}#trust",
        "level": "apply-locked" if state in {"available", "generatable"} else "read-only",
        "writes": False,
    }


def build_safe_apply_boundary_descriptor(encoded_app_id: str) -> dict[str, object]:
    return {
        "schema": "humble.studio.safe-apply-boundary.v1",
        "controlUrl": f"/studio/{encoded_app_id}#safe-apply",
        "status": "locked",
        "writes": False,
        "requires": [
            "repo-native-ticket",
            "structured-edit-draft",
            "patch-preview",
            "review-artifact",
            "explicit-user-confirmation",
        ],
    }


def build_convergence_workflow_descriptor(encoded_app_id: str) -> dict[str, object]:
    return {
        "schema": "humble.studio.convergence-workflow.v1",
        "controlUrl": f"/studio/{encoded_app_id}#convergence-workflow",
        "stageCount": len(CONVERGENCE_WORKFLOW_STAGES),
        "activeStageId": "connection-center",
        "nextStageId": "app-switcher",
        "apply": "locked",
        "sourceWrites": False,
        "writes": False,
        "stages": [
            {
                **stage,
                "status": "anchored",
                "writes": False,
                "sourceWrites": False,
            }
            for stage in CONVERGENCE_WORKFLOW_STAGES
        ],
    }


def build_native_parity_descriptor(encoded_app_id: str) -> dict[str, object]:
    return {
        "schema": "humble.studio.native-parity.v1",
        "controlUrl": f"/studio/{encoded_app_id}#native-parity",
        "rows": [
            "structured-draft",
            "patch-preview",
            "trust-level",
            "safe-apply-boundary",
            "authoring-smoke",
            "runtime-readiness",
            "proposal-center",
            "patch-artifact",
            "sandbox-apply",
            "source-apply-lock",
            "convergence-workflow",
        ],
        "writes": False,
    }


def build_end_to_end_smoke_descriptor(encoded_app_id: str) -> dict[str, object]:
    return {
        "schema": "humble.studio.authoring-smoke.v1",
        "controlUrl": f"/studio/{encoded_app_id}#smoke",
        "steps": [
            "connection-manifest",
            "workspace-route",
            "runtime-readiness",
            "structured-edit-draft",
            "patch-preview",
            "proposal-center",
            "patch-artifact",
            "sandbox-apply",
            "source-apply-lock",
            "safe-apply-lock",
            "convergence-workflow",
        ],
        "writes": False,
    }


def build_smoke_check_descriptor(encoded_app_id: str) -> dict[str, object]:
    return {
        "schema": "humble.studio.workspace-smoke.v1",
        "controlWorkspaceUrl": f"/studio/{encoded_app_id}",
        "reviewUrl": f"/studio/{encoded_app_id}/review",
        "prepareEditUrl": f"/studio/{encoded_app_id}/prepare-edit",
        "writes": False,
    }


def build_export_descriptor(app: SupportedAppExport, base_url: str) -> dict[str, object]:
    state, export_path = export_state(app)
    endpoint = f"{base_url}/api/supported-apps/{quote(app.app_id)}/export"
    bootstrap_key = "bundle" if app.source_kind == "humblebundle" else "config"
    encoded_app_id = quote(app.app_id)
    return {
        "id": app.app_id,
        "appName": app.app_name,
        "sourceKind": app.source_kind,
        "state": state,
        "canGenerate": bool(app.generator_command),
        "endpoint": endpoint,
        "studioLoadUrl": f"{base_url}/?{bootstrap_key}={quote(endpoint, safe='')}",
        "prepareEditUrl": f"{base_url}/api/connections/humble-control/prepare-edit?app={quote(app.app_id)}",
        "controlWorkspaceUrl": f"/studio/{encoded_app_id}",
        "controlSessionUrl": f"/studio/{encoded_app_id}/session",
        "controlPrepareEditUrl": f"/studio/{encoded_app_id}/prepare-edit",
        "controlRecoveryUrl": f"/api/studio/{encoded_app_id}/recovery",
        "reviewArtifact": {
            "schema": "humble.control.studio-review-artifact.v1",
            "controlUrl": f"/studio/{encoded_app_id}/review",
            "suggestedFilename": f"{app.app_id}-studio-review-artifact.json",
            "writes": False,
        },
        "manifestDiff": {
            "status": "ready" if state == "available" else "attention",
            "fields": [
                "selectedAppId",
                "sourceKind",
                "repoPath",
                "exportPath",
                "operationCount",
                "applyBoundary",
                "writes",
            ],
            "writes": False,
        },
        "applyGate": {
            "status": "locked",
            "writes": False,
            "requires": [
                "explicit-user-confirmation",
                "human-review",
                "clean-worktree-or-backup",
                "ticket-scoped-change",
            ],
        },
        "repoPath": str(app.repo_path.expanduser()),
        "exportPath": str(export_path),
        "contentType": app.content_type,
        "missingExport": {
            "state": state,
            "canGenerate": bool(app.generator_command),
            "trigger": "GET supported-app export endpoint",
            "writes": False,
        },
        "workspaceLaunch": build_workspace_launch_descriptor(app, endpoint, encoded_app_id),
        "recoveryWizard": build_recovery_wizard_descriptor(app, endpoint, encoded_app_id, state),
        "applyPreview": build_apply_preview_descriptor(encoded_app_id),
        "editBoundary": build_edit_boundary_descriptor(encoded_app_id),
        "authoringSession": build_authoring_session_descriptor(encoded_app_id),
        "structuredDraft": build_structured_draft_descriptor(encoded_app_id),
        "patchPreview": build_patch_preview_descriptor(encoded_app_id),
        "runtimeReadiness": build_runtime_readiness_descriptor(encoded_app_id),
        "proposalCenter": build_proposal_center_descriptor(encoded_app_id),
        "patchArtifact": build_patch_artifact_descriptor(app.app_id, encoded_app_id),
        "sandboxApply": build_sandbox_apply_descriptor(encoded_app_id),
        "sourceApplyLock": build_source_apply_lock_descriptor(encoded_app_id),
        "trustLevel": build_trust_level_descriptor(encoded_app_id, state),
        "safeApplyBoundary": build_safe_apply_boundary_descriptor(encoded_app_id),
        "convergenceWorkflow": build_convergence_workflow_descriptor(encoded_app_id),
        "nativeParity": build_native_parity_descriptor(encoded_app_id),
        "endToEndSmoke": build_end_to_end_smoke_descriptor(encoded_app_id),
        "smokeCheck": build_smoke_check_descriptor(encoded_app_id),
    }


def utc_now_iso() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def build_prepare_edit_contract(
    base_url: str,
    catalog: Mapping[str, SupportedAppExport] | None = None,
    app_id: str | None = None,
) -> dict[str, object]:
    active_catalog = catalog or SUPPORTED_APP_EXPORTS
    if app_id:
        app = active_catalog.get(app_id)
        if not app:
            raise LocalPreviewError(
                HTTPStatus.NOT_FOUND,
                "unknown_supported_app",
                f"No prepare-edit contract is configured for supported app '{app_id}'.",
            )
        apps = [app]
    else:
        apps = sorted(active_catalog.values(), key=lambda item: item.app_id)

    exports = [
        build_export_descriptor(app, base_url)
        for app in apps
    ]
    return {
        "schema": PREPARE_EDIT_SCHEMA,
        "generatedAt": utc_now_iso(),
        "scope": "app" if app_id else "all",
        "selectedAppId": app_id,
        "exportCount": len(exports),
        "producer": {
            "app": "HumbleStudio",
            "kind": "localhost-preview",
            "url": base_url,
            "repoPath": str(ROOT),
        },
        "consumer": {
            "app": "HumbleControl",
            "kind": "local-dashboard",
            "url": os.environ.get("HUMBLECONTROL_LOCAL_URL", DEFAULT_HUMBLECONTROL_URL),
        },
        "mode": "prepare-edit",
        "writes": False,
        "applyBoundary": {
            "status": "locked",
            "requires": [
                "explicit-user-confirmation",
                "human-review",
                "clean-worktree-or-backup",
                "ticket-scoped-change",
            ],
            "guarantees": [
                "no implicit writes",
                "no background apply",
                "no mutation from localhost manifest",
            ],
        },
        "capabilities": [
            "proposal-read",
            "session-source-truth",
            "unified-workspace",
            "dry-run-contract",
            "manifest-diff-preview",
            "review-artifact-ref",
            "readable-review-artifact",
            "local-proposal-draft",
            "missing-export-request",
            "workspace-launch",
            "recovery-wizard",
            "session-evidence",
            "authoring-session-restore",
            "structured-edit-draft",
            "patch-preview",
            "manifest-trust-levels",
            "safe-apply-boundary",
            "connection-registry",
            "native-parity-contract",
            "authoring-e2e-smoke",
            "runtime-freshness",
            "proposal-center",
            "patch-artifact",
            "sandbox-apply",
            "source-apply-locked",
            "apply-preview",
            "edit-boundary-contract",
            "workspace-smoke",
            "convergence-workflow",
            "locked-apply-boundary",
        ],
        "exports": [
            {
                "id": item["id"],
                "appName": item["appName"],
                "sourceKind": item["sourceKind"],
                "state": item["state"],
                "canGenerate": item["canGenerate"],
                "endpoint": item["endpoint"],
                "studioLoadUrl": item["studioLoadUrl"],
                "repoPath": item["repoPath"],
                "exportPath": item["exportPath"],
                "controlWorkspaceUrl": item["controlWorkspaceUrl"],
                "controlSessionUrl": item["controlSessionUrl"],
                "controlPrepareEditUrl": item["controlPrepareEditUrl"],
                "controlRecoveryUrl": item["controlRecoveryUrl"],
                "reviewArtifact": item["reviewArtifact"],
                "manifestDiff": item["manifestDiff"],
                "applyGate": item["applyGate"],
                "missingExport": item["missingExport"],
                "workspaceLaunch": item["workspaceLaunch"],
                "recoveryWizard": item["recoveryWizard"],
                "applyPreview": item["applyPreview"],
                "editBoundary": item["editBoundary"],
                "authoringSession": item["authoringSession"],
                "structuredDraft": item["structuredDraft"],
                "patchPreview": item["patchPreview"],
                "runtimeReadiness": item["runtimeReadiness"],
                "proposalCenter": item["proposalCenter"],
                "patchArtifact": item["patchArtifact"],
                "sandboxApply": item["sandboxApply"],
                "sourceApplyLock": item["sourceApplyLock"],
                "trustLevel": item["trustLevel"],
                "safeApplyBoundary": item["safeApplyBoundary"],
                "convergenceWorkflow": item["convergenceWorkflow"],
                "nativeParity": item["nativeParity"],
                "endToEndSmoke": item["endToEndSmoke"],
                "smokeCheck": item["smokeCheck"],
                "operations": [
                    {
                        "id": "inspect-export",
                        "mode": "preview-only",
                        "writes": False,
                        "target": item["exportPath"],
                    },
                    {
                        "id": "compose-proposal",
                        "mode": "preview-only",
                        "writes": False,
                        "target": item["id"],
                    },
                ],
            }
            for item in exports
        ],
    }


def build_humble_control_connection_manifest(
    base_url: str,
    catalog: Mapping[str, SupportedAppExport] | None = None,
) -> dict[str, object]:
    active_catalog = catalog or SUPPORTED_APP_EXPORTS
    exports = [
        build_export_descriptor(app, base_url)
        for app in sorted(active_catalog.values(), key=lambda item: item.app_id)
    ]
    return {
        "schema": CONNECTION_MANIFEST_SCHEMA,
        "producer": {
            "app": "HumbleStudio",
            "kind": "localhost-preview",
            "url": base_url,
            "repoPath": str(ROOT),
            "runtimeEndpoint": f"{base_url}/api/connections",
        },
        "consumer": {
            "app": "HumbleControl",
            "kind": "local-dashboard",
            "url": os.environ.get("HUMBLECONTROL_LOCAL_URL", DEFAULT_HUMBLECONTROL_URL),
        },
        "mode": "read-only",
        "editBoundary": {
            "mode": "prepare-edit",
            "writes": False,
            "apply": "locked",
            "contractEndpoint": f"{base_url}/api/connections/humble-control/prepare-edit",
        },
        "workspaceLaunch": {
            "schema": "humble.studio.workspace-launch.index.v1",
            "defaultAppId": "humble-sudoku",
            "controlUrl": "/studio/humble-sudoku",
            "writes": False,
        },
        "helperDiagnostics": {
            "schema": "humble.studio.helper-diagnostics.v1",
            "endpoint": f"{base_url}/api/connections/humble-control",
            "logPath": HELPER_LOG_PATH,
            "writes": False,
        },
        "authoringSession": {
            "schema": "humble.studio.authoring-session.index.v1",
            "defaultAppId": "humble-sudoku",
            "controlUrl": "/studio/humble-sudoku#authoring-session",
            "storage": "browser-local",
            "writes": False,
        },
        "structuredDraft": {
            "schema": "humble.studio.structured-draft.index.v1",
            "defaultAppId": "humble-sudoku",
            "controlUrl": "/studio/humble-sudoku#structured-draft",
            "kinds": [
                "token",
                "text",
                "navigation",
                "asset",
            ],
            "writes": False,
        },
        "patchPreview": {
            "schema": "humble.studio.patch-preview.index.v1",
            "defaultAppId": "humble-sudoku",
            "controlUrl": "/studio/humble-sudoku#patch-preview",
            "writes": False,
        },
        "runtimeReadiness": {
            "schema": "humble.studio.runtime-readiness.index.v1",
            "defaultAppId": "humble-sudoku",
            "controlUrl": "/studio/humble-sudoku#runtime-readiness",
            "expectedCapabilities": RUNTIME_AUTHORING_CAPABILITIES,
            "writes": False,
        },
        "proposalCenter": {
            "schema": "humble.studio.proposal-center.index.v1",
            "defaultAppId": "humble-sudoku",
            "controlUrl": "/studio/humble-sudoku#proposal-center",
            "inboxUrl": "/studio/proposals",
            "writes": False,
        },
        "patchArtifact": {
            "schema": "humble.studio.patch-artifact.index.v1",
            "defaultAppId": "humble-sudoku",
            "controlUrl": "/studio/humble-sudoku#patch-artifact",
            "writes": False,
        },
        "sandboxApply": {
            "schema": "humble.studio.sandbox-apply.index.v1",
            "defaultAppId": "humble-sudoku",
            "controlUrl": "/studio/humble-sudoku#sandbox-apply",
            "mode": "scratch-only",
            "sourceWrites": False,
            "writes": False,
        },
        "sourceApplyLock": {
            "schema": "humble.studio.source-apply-lock.index.v1",
            "defaultAppId": "humble-sudoku",
            "controlUrl": "/studio/humble-sudoku#source-apply-lock",
            "status": "locked",
            "writes": False,
        },
        "trustLevels": {
            "schema": "humble.studio.trust-levels.index.v1",
            "controlUrl": "/studio/humble-sudoku#trust",
            "writes": False,
        },
        "safeApplyBoundary": {
            "schema": "humble.studio.safe-apply-boundary.index.v1",
            "defaultAppId": "humble-sudoku",
            "controlUrl": "/studio/humble-sudoku#safe-apply",
            "status": "locked",
            "writes": False,
        },
        "convergenceWorkflow": {
            "schema": "humble.studio.convergence-workflow.index.v1",
            "defaultAppId": "humble-sudoku",
            "controlUrl": "/studio/humble-sudoku#convergence-workflow",
            "stageCount": len(CONVERGENCE_WORKFLOW_STAGES),
            "activeStageId": "connection-center",
            "nextStageId": "app-switcher",
            "apply": "locked",
            "sourceWrites": False,
            "writes": False,
            "stages": [
                {
                    **stage,
                    "status": "anchored",
                    "writes": False,
                    "sourceWrites": False,
                }
                for stage in CONVERGENCE_WORKFLOW_STAGES
            ],
        },
        "connectionRegistry": {
            "schema": "humble.studio.connection-registry.index.v1",
            "controlUrl": "/studio/humble-sudoku#registry",
            "writes": False,
        },
        "nativeParity": {
            "schema": "humble.studio.native-parity.index.v1",
            "defaultAppId": "humble-sudoku",
            "controlUrl": "/studio/humble-sudoku#native-parity",
            "writes": False,
        },
        "authoringSmoke": {
            "schema": "humble.studio.authoring-smoke.index.v1",
            "defaultAppId": "humble-sudoku",
            "controlUrl": "/studio/humble-sudoku#smoke",
            "writes": False,
        },
        "smokeCheck": {
            "schema": "humble.studio.workspace-smoke.index.v1",
            "controlUrl": os.environ.get("HUMBLECONTROL_LOCAL_URL", DEFAULT_HUMBLECONTROL_URL),
            "expectedExportCount": len(exports),
            "writes": False,
        },
        "capabilities": [
            "supported-app-export",
            "design-contract-read",
            "localhost-manifest",
            "prepare-edit-contract",
            "session-source-truth",
            "unified-workspace",
            "manifest-diff-preview",
            "review-artifact-ref",
            "readable-review-artifact",
            "local-proposal-draft",
            "helper-control-surface",
            "missing-export-request",
            "workspace-launch",
            "recovery-wizard",
            "session-evidence",
            "authoring-session-restore",
            "structured-edit-draft",
            "patch-preview",
            "manifest-trust-levels",
            "safe-apply-boundary",
            "connection-registry",
            "native-parity-contract",
            "authoring-e2e-smoke",
            "runtime-freshness",
            "proposal-center",
            "patch-artifact",
            "sandbox-apply",
            "source-apply-locked",
            "apply-preview",
            "edit-boundary-contract",
            "workspace-smoke",
            "convergence-workflow",
            "locked-apply-gate",
        ],
        "exports": exports,
    }


class HumbleStudioLocalPreviewHandler(SimpleHTTPRequestHandler):
    server_version = "HumbleStudioLocalPreview/1.0"

    def __init__(self, *args, directory: str | None = None, **kwargs) -> None:
        super().__init__(*args, directory=directory or str(ROOT), **kwargs)

    def do_GET(self) -> None:
        app_id = parse_supported_app_export_path(self.path)
        if app_id:
            self.handle_supported_app_export(app_id, send_body=True)
            return
        connection_id = parse_connection_path(self.path)
        if connection_id:
            self.handle_connections(connection_id, send_body=True)
            return
        super().do_GET()

    def do_HEAD(self) -> None:
        app_id = parse_supported_app_export_path(self.path)
        if app_id:
            self.handle_supported_app_export(app_id, send_body=False)
            return
        connection_id = parse_connection_path(self.path)
        if connection_id:
            self.handle_connections(connection_id, send_body=False)
            return
        super().do_HEAD()

    def handle_supported_app_export(self, app_id: str, send_body: bool) -> None:
        try:
            result = ensure_supported_app_export(app_id)
        except LocalPreviewError as error:
            self.send_json_error(error)
            return

        size = result.export_path.stat().st_size
        self.send_response(HTTPStatus.OK)
        self.send_header("Content-Type", result.app.content_type)
        self.send_header("Content-Length", str(size))
        self.send_header(LOCAL_EXPORT_HEADER, "1")
        self.send_header("X-HumbleStudio-App-Id", result.app.app_id)
        self.send_header("X-HumbleStudio-App-Name", result.app.app_name)
        self.send_header("X-HumbleStudio-Generated", "1" if result.generated else "0")
        self.send_header("Cache-Control", "no-store")
        self.end_headers()

        if not send_body:
            return
        with result.export_path.open("rb") as handle:
            shutil.copyfileobj(handle, self.wfile)

    def local_base_url(self) -> str:
        host = self.headers.get("Host")
        if host:
            return f"http://{host}"
        address, port = self.server.server_address[:2]
        return f"http://{address}:{port}"

    def handle_connections(self, connection_id: str, send_body: bool) -> None:
        manifest = build_humble_control_connection_manifest(self.local_base_url())
        if connection_id == "humble-control-prepare-edit":
            try:
                contract = build_prepare_edit_contract(
                    self.local_base_url(),
                    app_id=parse_prepare_edit_app_id(self.path),
                )
            except LocalPreviewError as error:
                self.send_json_error(error)
                return
            self.send_json_response(contract, send_body=send_body)
            return
        if connection_id == "humble-control":
            self.send_json_response(manifest, send_body=send_body)
            return
        self.send_json_response(
            {
                "schema": "humble.studio.connections.index.v1",
                "connections": [
                    {
                        "id": "humble-control",
                        "appName": "HumbleControl",
                        "endpoint": f"{self.local_base_url()}/api/connections/humble-control",
                        "prepareEditEndpoint": f"{self.local_base_url()}/api/connections/humble-control/prepare-edit",
                        "mode": manifest["mode"],
                        "capabilities": manifest["capabilities"],
                    }
                ],
            },
            send_body=send_body,
        )

    def send_json_response(
        self,
        payload: Mapping[str, object],
        status: HTTPStatus = HTTPStatus.OK,
        send_body: bool = True,
    ) -> None:
        body = json.dumps(payload, ensure_ascii=True, indent=2).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        if send_body:
            self.wfile.write(body)

    def send_json_error(self, error: LocalPreviewError) -> None:
        self.send_json_response(
            {"error": error.code, "message": error.message},
            status=error.status,
            send_body=self.command != "HEAD",
        )


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--host", default="127.0.0.1", help="Host interface to bind.")
    parser.add_argument("--port", type=int, default=8765, help="Port for the local preview.")
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv or sys.argv[1:])
    server = ThreadingHTTPServer((args.host, args.port), HumbleStudioLocalPreviewHandler)
    url = f"http://{args.host}:{args.port}"
    print(f"HumbleStudio local preview: {url}", flush=True)
    print("Open the URL above, then click HumbleSudoku in Supported apps.", flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nStopping HumbleStudio local preview.", flush=True)
    finally:
        server.server_close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
