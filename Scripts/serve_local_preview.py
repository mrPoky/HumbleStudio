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
from urllib.parse import quote, unquote, urlparse


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_HUMBLESUDOKU_REPO = Path("/Users/janpokorny/Coding/personal/apps/HumbleSudoku")
DEFAULT_HUMBLECONTROL_REPO = Path("/Users/janpokorny/Coding/personal/apps/HumbleControl")
DEFAULT_HUMBLECONTROL_URL = "http://127.0.0.1:3000"
LOCAL_EXPORT_HEADER = "X-HumbleStudio-Local-Export"
CONNECTION_MANIFEST_SCHEMA = "humble.studio.connections.v1"
PREPARE_EDIT_SCHEMA = "humble.studio.prepare-edit.v1"


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


def build_supported_app_catalog() -> dict[str, SupportedAppExport]:
    sudoku_repo = (
        env_path("HUMBLESTUDIO_HUMBLESUDOKU_REPO", "HUMBLE_SUDOKU_REPO_ROOT")
        or DEFAULT_HUMBLESUDOKU_REPO
    )
    control_repo = (
        env_path("HUMBLESTUDIO_HUMBLECONTROL_REPO", "HUMBLECONTROL_REPO_ROOT")
        or DEFAULT_HUMBLECONTROL_REPO
    )
    return {
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


def build_export_descriptor(app: SupportedAppExport, base_url: str) -> dict[str, object]:
    state, export_path = export_state(app)
    endpoint = f"{base_url}/api/supported-apps/{quote(app.app_id)}/export"
    bootstrap_key = "bundle" if app.source_kind == "humblebundle" else "config"
    return {
        "id": app.app_id,
        "appName": app.app_name,
        "sourceKind": app.source_kind,
        "state": state,
        "canGenerate": bool(app.generator_command),
        "endpoint": endpoint,
        "studioLoadUrl": f"{base_url}/?{bootstrap_key}={quote(endpoint, safe='')}",
        "prepareEditUrl": f"{base_url}/api/connections/humble-control/prepare-edit?app={quote(app.app_id)}",
        "repoPath": str(app.repo_path.expanduser()),
        "exportPath": str(export_path),
        "contentType": app.content_type,
        "missingExport": {
            "state": state,
            "canGenerate": bool(app.generator_command),
            "trigger": "GET supported-app export endpoint",
            "writes": False,
        },
    }


def utc_now_iso() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def build_prepare_edit_contract(
    base_url: str,
    catalog: Mapping[str, SupportedAppExport] | None = None,
) -> dict[str, object]:
    active_catalog = catalog or SUPPORTED_APP_EXPORTS
    exports = [
        build_export_descriptor(app, base_url)
        for app in sorted(active_catalog.values(), key=lambda item: item.app_id)
    ]
    return {
        "schema": PREPARE_EDIT_SCHEMA,
        "generatedAt": utc_now_iso(),
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
            "dry-run-contract",
            "missing-export-request",
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
                "missingExport": item["missingExport"],
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
        "capabilities": [
            "supported-app-export",
            "design-contract-read",
            "localhost-manifest",
            "prepare-edit-contract",
            "session-source-truth",
            "missing-export-request",
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
            self.send_json_response(
                build_prepare_edit_contract(self.local_base_url()),
                send_body=send_body,
            )
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
