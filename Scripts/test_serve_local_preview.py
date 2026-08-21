#!/usr/bin/env python3
"""Tests for the HumbleStudio localhost preview helper."""

from __future__ import annotations

import tempfile
import unittest
from http import HTTPStatus
from pathlib import Path

from serve_local_preview import (
    LocalPreviewError,
    SupportedAppExport,
    build_supported_app_catalog,
    build_prepare_edit_contract,
    build_humble_control_connection_manifest,
    ensure_supported_app_export,
    parse_connection_path,
    parse_prepare_edit_app_id,
    parse_supported_app_export_path,
)


def catalog_for(
    repo_root: Path,
    command: tuple[str, ...],
    *,
    app_id: str = "humble-sudoku",
    app_name: str = "HumbleSudoku",
    export_relative_path: Path = Path(".humble/HumbleSudoku.humblebundle"),
    content_type: str = "application/zip",
    source_kind: str = "humblebundle",
) -> dict[str, SupportedAppExport]:
    return {
        app_id: SupportedAppExport(
            app_id=app_id,
            app_name=app_name,
            repo_path=repo_root,
            export_relative_path=export_relative_path,
            generator_command=command,
            content_type=content_type,
            source_kind=source_kind,
        )
    }


class LocalPreviewHelperTests(unittest.TestCase):
    def test_default_catalog_includes_broader_humble_app_registry(self) -> None:
        catalog = build_supported_app_catalog()

        self.assertGreaterEqual(len(catalog), 10)
        self.assertIn("humble-sudoku", catalog)
        self.assertIn("humble-control", catalog)
        self.assertIn("my-vltava-run", catalog)
        self.assertIn("humble-workout", catalog)
        self.assertIn("humble-kakuro", catalog)

    def test_existing_export_is_returned_without_generation(self) -> None:
        with tempfile.TemporaryDirectory() as raw_root:
            repo_root = Path(raw_root)
            export_path = repo_root / ".humble" / "HumbleSudoku.humblebundle"
            export_path.parent.mkdir()
            export_path.write_bytes(b"existing")

            result = ensure_supported_app_export(
                "humble-sudoku",
                catalog_for(repo_root, ("python3", "missing-generator.py")),
            )

            self.assertFalse(result.generated)
            self.assertEqual(result.export_path.read_bytes(), b"existing")

    def test_missing_export_runs_allowlisted_generator(self) -> None:
        with tempfile.TemporaryDirectory() as raw_root:
            repo_root = Path(raw_root)
            generator = repo_root / "generate.py"
            generator.write_text(
                "from pathlib import Path\n"
                "Path('.humble').mkdir(exist_ok=True)\n"
                "Path('.humble/HumbleSudoku.humblebundle').write_bytes(b'generated')\n",
                encoding="utf-8",
            )

            result = ensure_supported_app_export(
                "humble-sudoku",
                catalog_for(repo_root, ("python3", "generate.py")),
            )

            self.assertTrue(result.generated)
            self.assertEqual(result.export_path.read_bytes(), b"generated")

    def test_existing_json_export_keeps_content_type(self) -> None:
        with tempfile.TemporaryDirectory() as raw_root:
            repo_root = Path(raw_root)
            export_path = repo_root / ".humble" / "design.json"
            export_path.parent.mkdir()
            export_path.write_text('{"meta":{"name":"HumbleControl"}}', encoding="utf-8")

            result = ensure_supported_app_export(
                "humble-control",
                catalog_for(
                    repo_root,
                    (),
                    app_id="humble-control",
                    app_name="HumbleControl",
                    export_relative_path=Path(".humble/design.json"),
                    content_type="application/json; charset=utf-8",
                    source_kind="design.json",
                ),
            )

            self.assertFalse(result.generated)
            self.assertEqual(result.app.content_type, "application/json; charset=utf-8")

    def test_missing_export_without_generator_is_reported(self) -> None:
        with tempfile.TemporaryDirectory() as raw_root:
            with self.assertRaises(LocalPreviewError) as context:
                ensure_supported_app_export(
                    "humble-control",
                    catalog_for(
                        Path(raw_root),
                        (),
                        app_id="humble-control",
                        app_name="HumbleControl",
                        export_relative_path=Path(".humble/design.json"),
                        source_kind="design.json",
                    ),
                )

        self.assertEqual(context.exception.status, HTTPStatus.INTERNAL_SERVER_ERROR)
        self.assertEqual(context.exception.code, "export_missing")

    def test_unknown_supported_app_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as raw_root:
            with self.assertRaises(LocalPreviewError) as context:
                ensure_supported_app_export(
                    "unknown",
                    catalog_for(Path(raw_root), ("python3", "generate.py")),
                )

        self.assertEqual(context.exception.status, HTTPStatus.NOT_FOUND)
        self.assertEqual(context.exception.code, "unknown_supported_app")

    def test_missing_repository_is_reported(self) -> None:
        with tempfile.TemporaryDirectory() as raw_root:
            missing_repo = Path(raw_root) / "missing"
            with self.assertRaises(LocalPreviewError) as context:
                ensure_supported_app_export(
                    "humble-sudoku",
                    catalog_for(missing_repo, ("python3", "generate.py")),
                )

        self.assertEqual(context.exception.status, HTTPStatus.INTERNAL_SERVER_ERROR)
        self.assertEqual(context.exception.code, "repository_missing")

    def test_api_path_parses_supported_app_export(self) -> None:
        self.assertEqual(
            parse_supported_app_export_path("/api/supported-apps/humble-sudoku/export"),
            "humble-sudoku",
        )
        self.assertEqual(
            parse_supported_app_export_path("/api/supported-apps/humble-sudoku/export?fresh=1"),
            "humble-sudoku",
        )
        self.assertIsNone(parse_supported_app_export_path("/configs/humble-sudoku.json"))

    def test_connection_path_parses_humble_control_manifest(self) -> None:
        self.assertEqual(parse_connection_path("/api/connections"), "all")
        self.assertEqual(parse_connection_path("/api/connections/humble-control"), "humble-control")
        self.assertEqual(
            parse_connection_path("/api/connections/humble-control/prepare-edit?app=humble-sudoku"),
            "humble-control-prepare-edit",
        )
        self.assertIsNone(parse_connection_path("/api/connections/unknown"))

    def test_prepare_edit_app_id_parses_query_scope(self) -> None:
        self.assertEqual(
            parse_prepare_edit_app_id("/api/connections/humble-control/prepare-edit?app=humble-sudoku"),
            "humble-sudoku",
        )
        self.assertIsNone(parse_prepare_edit_app_id("/api/connections/humble-control/prepare-edit"))
        self.assertIsNone(parse_prepare_edit_app_id("/api/connections/humble-control/prepare-edit?app="))

    def test_humble_control_manifest_lists_local_exports(self) -> None:
        with tempfile.TemporaryDirectory() as raw_root:
            repo_root = Path(raw_root)
            export_path = repo_root / ".humble" / "design.json"
            export_path.parent.mkdir()
            export_path.write_text('{"meta":{"name":"HumbleControl"}}', encoding="utf-8")
            catalog = catalog_for(
                repo_root,
                (),
                app_id="humble-control",
                app_name="HumbleControl",
                export_relative_path=Path(".humble/design.json"),
                content_type="application/json; charset=utf-8",
                source_kind="design.json",
            )

            manifest = build_humble_control_connection_manifest("http://127.0.0.1:8765", catalog)

        export = manifest["exports"][0]
        self.assertEqual(manifest["schema"], "humble.studio.connections.v1")
        self.assertEqual(manifest["consumer"]["app"], "HumbleControl")
        self.assertEqual(manifest["editBoundary"]["mode"], "prepare-edit")
        self.assertFalse(manifest["editBoundary"]["writes"])
        self.assertIn("prepare-edit-contract", manifest["capabilities"])
        self.assertIn("unified-workspace", manifest["capabilities"])
        self.assertIn("review-artifact-ref", manifest["capabilities"])
        self.assertIn("readable-review-artifact", manifest["capabilities"])
        self.assertIn("helper-control-surface", manifest["capabilities"])
        self.assertIn("manifest-diff-preview", manifest["capabilities"])
        self.assertIn("workspace-launch", manifest["capabilities"])
        self.assertIn("recovery-wizard", manifest["capabilities"])
        self.assertIn("session-evidence", manifest["capabilities"])
        self.assertIn("authoring-session-restore", manifest["capabilities"])
        self.assertIn("structured-edit-draft", manifest["capabilities"])
        self.assertIn("patch-preview", manifest["capabilities"])
        self.assertIn("manifest-trust-levels", manifest["capabilities"])
        self.assertIn("safe-apply-boundary", manifest["capabilities"])
        self.assertIn("connection-registry", manifest["capabilities"])
        self.assertIn("native-parity-contract", manifest["capabilities"])
        self.assertIn("authoring-e2e-smoke", manifest["capabilities"])
        self.assertIn("runtime-freshness", manifest["capabilities"])
        self.assertIn("proposal-center", manifest["capabilities"])
        self.assertIn("patch-artifact", manifest["capabilities"])
        self.assertIn("sandbox-apply", manifest["capabilities"])
        self.assertIn("source-apply-locked", manifest["capabilities"])
        self.assertIn("apply-preview", manifest["capabilities"])
        self.assertIn("edit-boundary-contract", manifest["capabilities"])
        self.assertIn("workspace-smoke", manifest["capabilities"])
        self.assertIn("convergence-workflow", manifest["capabilities"])
        self.assertEqual(manifest["workspaceLaunch"]["controlUrl"], "/studio/humble-sudoku")
        self.assertFalse(manifest["workspaceLaunch"]["writes"])
        self.assertEqual(manifest["authoringSession"]["storage"], "browser-local")
        self.assertFalse(manifest["authoringSession"]["writes"])
        self.assertEqual(manifest["structuredDraft"]["controlUrl"], "/studio/humble-sudoku#structured-draft")
        self.assertEqual(manifest["structuredDraft"]["kinds"], ["token", "text", "navigation", "asset"])
        self.assertFalse(manifest["structuredDraft"]["writes"])
        self.assertEqual(manifest["patchPreview"]["controlUrl"], "/studio/humble-sudoku#patch-preview")
        self.assertFalse(manifest["patchPreview"]["writes"])
        self.assertEqual(manifest["runtimeReadiness"]["controlUrl"], "/studio/humble-sudoku#runtime-readiness")
        self.assertIn("patch-artifact", manifest["runtimeReadiness"]["expectedCapabilities"])
        self.assertFalse(manifest["runtimeReadiness"]["writes"])
        self.assertEqual(manifest["proposalCenter"]["inboxUrl"], "/studio/proposals")
        self.assertFalse(manifest["proposalCenter"]["writes"])
        self.assertEqual(manifest["patchArtifact"]["controlUrl"], "/studio/humble-sudoku#patch-artifact")
        self.assertFalse(manifest["patchArtifact"]["writes"])
        self.assertEqual(manifest["sandboxApply"]["mode"], "scratch-only")
        self.assertFalse(manifest["sandboxApply"]["sourceWrites"])
        self.assertFalse(manifest["sandboxApply"]["writes"])
        self.assertEqual(manifest["sourceApplyLock"]["status"], "locked")
        self.assertFalse(manifest["sourceApplyLock"]["writes"])
        self.assertEqual(manifest["trustLevels"]["controlUrl"], "/studio/humble-sudoku#trust")
        self.assertFalse(manifest["trustLevels"]["writes"])
        self.assertEqual(manifest["safeApplyBoundary"]["status"], "locked")
        self.assertFalse(manifest["safeApplyBoundary"]["writes"])
        self.assertEqual(manifest["convergenceWorkflow"]["controlUrl"], "/studio/humble-sudoku#convergence-workflow")
        self.assertEqual(manifest["convergenceWorkflow"]["stageCount"], 10)
        self.assertEqual(manifest["convergenceWorkflow"]["stages"][0]["id"], "connection-center")
        self.assertEqual(manifest["convergenceWorkflow"]["stages"][-1]["id"], "repo-orchestration")
        self.assertFalse(manifest["convergenceWorkflow"]["sourceWrites"])
        self.assertFalse(manifest["convergenceWorkflow"]["writes"])
        self.assertEqual(manifest["connectionRegistry"]["controlUrl"], "/studio/humble-sudoku#registry")
        self.assertFalse(manifest["connectionRegistry"]["writes"])
        self.assertEqual(manifest["nativeParity"]["controlUrl"], "/studio/humble-sudoku#native-parity")
        self.assertFalse(manifest["nativeParity"]["writes"])
        self.assertEqual(manifest["authoringSmoke"]["controlUrl"], "/studio/humble-sudoku#smoke")
        self.assertFalse(manifest["authoringSmoke"]["writes"])
        self.assertEqual(manifest["helperDiagnostics"]["logPath"], "/tmp/humblecontrol-humblestudio-helper.log")
        self.assertFalse(manifest["smokeCheck"]["writes"])
        self.assertEqual(export["id"], "humble-control")
        self.assertEqual(export["state"], "available")
        self.assertEqual(export["missingExport"]["state"], "available")
        self.assertFalse(export["missingExport"]["writes"])
        self.assertEqual(export["controlWorkspaceUrl"], "/studio/humble-control")
        self.assertEqual(export["controlSessionUrl"], "/studio/humble-control/session")
        self.assertEqual(export["controlPrepareEditUrl"], "/studio/humble-control/prepare-edit")
        self.assertEqual(export["controlRecoveryUrl"], "/api/studio/humble-control/recovery")
        self.assertEqual(export["reviewArtifact"]["schema"], "humble.control.studio-review-artifact.v1")
        self.assertEqual(export["reviewArtifact"]["controlUrl"], "/studio/humble-control/review")
        self.assertFalse(export["reviewArtifact"]["writes"])
        self.assertEqual(export["manifestDiff"]["status"], "ready")
        self.assertFalse(export["manifestDiff"]["writes"])
        self.assertEqual(export["applyGate"]["status"], "locked")
        self.assertFalse(export["applyGate"]["writes"])
        self.assertEqual(export["workspaceLaunch"]["controlUrl"], "/studio/humble-control")
        self.assertEqual(export["workspaceLaunch"]["loadUrl"], "/api/connections/humblestudio/load/humble-control")
        self.assertFalse(export["workspaceLaunch"]["writes"])
        self.assertEqual(export["recoveryWizard"]["controlUrl"], "/studio/humble-control#recovery")
        self.assertTrue(export["recoveryWizard"]["confirmationRequired"])
        self.assertFalse(export["recoveryWizard"]["writes"])
        self.assertEqual(export["applyPreview"]["status"], "locked")
        self.assertFalse(export["applyPreview"]["writes"])
        self.assertEqual(export["editBoundary"]["apply"], "locked")
        self.assertFalse(export["editBoundary"]["writes"])
        self.assertEqual(export["authoringSession"]["controlUrl"], "/studio/humble-control#authoring-session")
        self.assertEqual(export["authoringSession"]["storage"], "browser-local")
        self.assertIn("proposal-draft", export["authoringSession"]["restores"])
        self.assertFalse(export["authoringSession"]["writes"])
        self.assertEqual(export["structuredDraft"]["controlUrl"], "/studio/humble-control#structured-draft")
        self.assertEqual(export["structuredDraft"]["kinds"], ["token", "text", "navigation", "asset"])
        self.assertFalse(export["structuredDraft"]["writes"])
        self.assertEqual(export["patchPreview"]["status"], "review-only")
        self.assertFalse(export["patchPreview"]["writes"])
        self.assertEqual(export["runtimeReadiness"]["controlUrl"], "/studio/humble-control#runtime-readiness")
        self.assertIn("source-apply-locked", export["runtimeReadiness"]["expectedCapabilities"])
        self.assertFalse(export["runtimeReadiness"]["writes"])
        self.assertEqual(export["proposalCenter"]["controlUrl"], "/studio/humble-control#proposal-center")
        self.assertEqual(export["proposalCenter"]["inboxUrl"], "/studio/proposals")
        self.assertFalse(export["proposalCenter"]["writes"])
        self.assertEqual(export["patchArtifact"]["suggestedFilename"], "humble-control-studio-patch-artifact.json")
        self.assertFalse(export["patchArtifact"]["writes"])
        self.assertEqual(export["sandboxApply"]["mode"], "scratch-only")
        self.assertFalse(export["sandboxApply"]["sourceWrites"])
        self.assertFalse(export["sandboxApply"]["writes"])
        self.assertEqual(export["sourceApplyLock"]["controlUrl"], "/studio/humble-control#source-apply-lock")
        self.assertEqual(export["sourceApplyLock"]["status"], "locked")
        self.assertFalse(export["sourceApplyLock"]["writes"])
        self.assertEqual(export["trustLevel"]["level"], "apply-locked")
        self.assertFalse(export["trustLevel"]["writes"])
        self.assertEqual(export["safeApplyBoundary"]["status"], "locked")
        self.assertIn("structured-edit-draft", export["safeApplyBoundary"]["requires"])
        self.assertFalse(export["safeApplyBoundary"]["writes"])
        self.assertEqual(export["convergenceWorkflow"]["controlUrl"], "/studio/humble-control#convergence-workflow")
        self.assertEqual(export["convergenceWorkflow"]["stageCount"], 10)
        self.assertEqual(export["convergenceWorkflow"]["activeStageId"], "connection-center")
        self.assertEqual(export["convergenceWorkflow"]["nextStageId"], "app-switcher")
        self.assertFalse(export["convergenceWorkflow"]["sourceWrites"])
        self.assertFalse(export["convergenceWorkflow"]["writes"])
        self.assertIn("patch-preview", export["nativeParity"]["rows"])
        self.assertIn("runtime-readiness", export["nativeParity"]["rows"])
        self.assertIn("patch-artifact", export["nativeParity"]["rows"])
        self.assertIn("sandbox-apply", export["nativeParity"]["rows"])
        self.assertIn("source-apply-lock", export["nativeParity"]["rows"])
        self.assertIn("convergence-workflow", export["nativeParity"]["rows"])
        self.assertFalse(export["nativeParity"]["writes"])
        self.assertIn("runtime-readiness", export["endToEndSmoke"]["steps"])
        self.assertIn("patch-artifact", export["endToEndSmoke"]["steps"])
        self.assertIn("sandbox-apply", export["endToEndSmoke"]["steps"])
        self.assertIn("safe-apply-lock", export["endToEndSmoke"]["steps"])
        self.assertIn("convergence-workflow", export["endToEndSmoke"]["steps"])
        self.assertFalse(export["endToEndSmoke"]["writes"])
        self.assertEqual(export["smokeCheck"]["reviewUrl"], "/studio/humble-control/review")
        self.assertFalse(export["smokeCheck"]["writes"])
        self.assertEqual(
            export["endpoint"],
            "http://127.0.0.1:8765/api/supported-apps/humble-control/export",
        )
        self.assertEqual(
            export["studioLoadUrl"],
            "http://127.0.0.1:8765/?config=http%3A%2F%2F127.0.0.1%3A8765%2Fapi%2Fsupported-apps%2Fhumble-control%2Fexport",
        )
        self.assertEqual(
            export["prepareEditUrl"],
            "http://127.0.0.1:8765/api/connections/humble-control/prepare-edit?app=humble-control",
        )

    def test_prepare_edit_contract_is_locked_and_read_only(self) -> None:
        with tempfile.TemporaryDirectory() as raw_root:
            repo_root = Path(raw_root)
            export_path = repo_root / ".humble" / "HumbleSudoku.humblebundle"
            export_path.parent.mkdir()
            export_path.write_bytes(b"bundle")
            catalog = catalog_for(repo_root, ("python3", "generate.py"))

            contract = build_prepare_edit_contract("http://127.0.0.1:8765", catalog)

        export = contract["exports"][0]
        self.assertEqual(contract["schema"], "humble.studio.prepare-edit.v1")
        self.assertEqual(contract["scope"], "all")
        self.assertIsNone(contract["selectedAppId"])
        self.assertEqual(contract["exportCount"], 1)
        self.assertEqual(contract["mode"], "prepare-edit")
        self.assertFalse(contract["writes"])
        self.assertEqual(contract["applyBoundary"]["status"], "locked")
        self.assertIn("session-source-truth", contract["capabilities"])
        self.assertIn("unified-workspace", contract["capabilities"])
        self.assertIn("review-artifact-ref", contract["capabilities"])
        self.assertIn("readable-review-artifact", contract["capabilities"])
        self.assertIn("local-proposal-draft", contract["capabilities"])
        self.assertIn("manifest-diff-preview", contract["capabilities"])
        self.assertIn("workspace-launch", contract["capabilities"])
        self.assertIn("recovery-wizard", contract["capabilities"])
        self.assertIn("session-evidence", contract["capabilities"])
        self.assertIn("authoring-session-restore", contract["capabilities"])
        self.assertIn("structured-edit-draft", contract["capabilities"])
        self.assertIn("patch-preview", contract["capabilities"])
        self.assertIn("manifest-trust-levels", contract["capabilities"])
        self.assertIn("safe-apply-boundary", contract["capabilities"])
        self.assertIn("connection-registry", contract["capabilities"])
        self.assertIn("native-parity-contract", contract["capabilities"])
        self.assertIn("authoring-e2e-smoke", contract["capabilities"])
        self.assertIn("runtime-freshness", contract["capabilities"])
        self.assertIn("proposal-center", contract["capabilities"])
        self.assertIn("patch-artifact", contract["capabilities"])
        self.assertIn("sandbox-apply", contract["capabilities"])
        self.assertIn("source-apply-locked", contract["capabilities"])
        self.assertIn("apply-preview", contract["capabilities"])
        self.assertIn("edit-boundary-contract", contract["capabilities"])
        self.assertIn("workspace-smoke", contract["capabilities"])
        self.assertIn("convergence-workflow", contract["capabilities"])
        self.assertEqual(export["id"], "humble-sudoku")
        self.assertEqual(export["state"], "available")
        self.assertEqual(export["controlWorkspaceUrl"], "/studio/humble-sudoku")
        self.assertEqual(export["controlPrepareEditUrl"], "/studio/humble-sudoku/prepare-edit")
        self.assertEqual(export["reviewArtifact"]["controlUrl"], "/studio/humble-sudoku/review")
        self.assertEqual(export["reviewArtifact"]["suggestedFilename"], "humble-sudoku-studio-review-artifact.json")
        self.assertEqual(export["manifestDiff"]["fields"][0], "selectedAppId")
        self.assertEqual(export["applyGate"]["status"], "locked")
        self.assertEqual(export["workspaceLaunch"]["controlUrl"], "/studio/humble-sudoku")
        self.assertEqual(export["recoveryWizard"]["effect"], "studio-export-generator")
        self.assertEqual(export["applyPreview"]["controlUrl"], "/studio/humble-sudoku#apply-preview")
        self.assertEqual(export["editBoundary"]["controlUrl"], "/studio/humble-sudoku#edit-boundary")
        self.assertEqual(export["authoringSession"]["controlUrl"], "/studio/humble-sudoku#authoring-session")
        self.assertIn("recovery-confirmation", export["authoringSession"]["restores"])
        self.assertEqual(export["structuredDraft"]["controlUrl"], "/studio/humble-sudoku#structured-draft")
        self.assertEqual(export["patchPreview"]["controlUrl"], "/studio/humble-sudoku#patch-preview")
        self.assertEqual(export["runtimeReadiness"]["controlUrl"], "/studio/humble-sudoku#runtime-readiness")
        self.assertEqual(export["proposalCenter"]["controlUrl"], "/studio/humble-sudoku#proposal-center")
        self.assertEqual(export["patchArtifact"]["controlUrl"], "/studio/humble-sudoku#patch-artifact")
        self.assertEqual(export["patchArtifact"]["suggestedFilename"], "humble-sudoku-studio-patch-artifact.json")
        self.assertEqual(export["sandboxApply"]["controlUrl"], "/studio/humble-sudoku#sandbox-apply")
        self.assertEqual(export["sourceApplyLock"]["controlUrl"], "/studio/humble-sudoku#source-apply-lock")
        self.assertEqual(export["trustLevel"]["controlUrl"], "/studio/humble-sudoku#trust")
        self.assertEqual(export["safeApplyBoundary"]["controlUrl"], "/studio/humble-sudoku#safe-apply")
        self.assertEqual(export["convergenceWorkflow"]["controlUrl"], "/studio/humble-sudoku#convergence-workflow")
        self.assertEqual(export["convergenceWorkflow"]["stageCount"], 10)
        self.assertEqual(export["convergenceWorkflow"]["stages"][0]["id"], "connection-center")
        self.assertEqual(export["convergenceWorkflow"]["stages"][-1]["id"], "repo-orchestration")
        self.assertFalse(export["convergenceWorkflow"]["sourceWrites"])
        self.assertFalse(export["convergenceWorkflow"]["writes"])
        self.assertEqual(export["nativeParity"]["controlUrl"], "/studio/humble-sudoku#native-parity")
        self.assertEqual(export["endToEndSmoke"]["controlUrl"], "/studio/humble-sudoku#smoke")
        self.assertEqual(export["smokeCheck"]["prepareEditUrl"], "/studio/humble-sudoku/prepare-edit")
        self.assertFalse(export["operations"][0]["writes"])

    def test_prepare_edit_contract_can_scope_to_one_supported_app(self) -> None:
        with tempfile.TemporaryDirectory() as raw_root:
            repo_root = Path(raw_root)
            sudoku_export = repo_root / "sudoku" / ".humble" / "HumbleSudoku.humblebundle"
            sudoku_export.parent.mkdir(parents=True)
            sudoku_export.write_bytes(b"bundle")
            control_export = repo_root / "control" / ".humble" / "design.json"
            control_export.parent.mkdir(parents=True)
            control_export.write_text('{"meta":{"name":"HumbleControl"}}', encoding="utf-8")
            catalog = {
                "humble-sudoku": SupportedAppExport(
                    app_id="humble-sudoku",
                    app_name="HumbleSudoku",
                    repo_path=repo_root / "sudoku",
                    export_relative_path=Path(".humble/HumbleSudoku.humblebundle"),
                    generator_command=("python3", "generate.py"),
                    content_type="application/zip",
                    source_kind="humblebundle",
                ),
                "humble-control": SupportedAppExport(
                    app_id="humble-control",
                    app_name="HumbleControl",
                    repo_path=repo_root / "control",
                    export_relative_path=Path(".humble/design.json"),
                    generator_command=(),
                    content_type="application/json; charset=utf-8",
                    source_kind="design.json",
                ),
            }

            contract = build_prepare_edit_contract(
                "http://127.0.0.1:8765",
                catalog,
                app_id="humble-sudoku",
            )

        self.assertEqual(contract["scope"], "app")
        self.assertEqual(contract["selectedAppId"], "humble-sudoku")
        self.assertEqual(contract["exportCount"], 1)
        self.assertEqual([item["id"] for item in contract["exports"]], ["humble-sudoku"])
        self.assertEqual(contract["exports"][0]["controlWorkspaceUrl"], "/studio/humble-sudoku")
        self.assertEqual(contract["exports"][0]["controlSessionUrl"], "/studio/humble-sudoku/session")
        self.assertEqual(contract["exports"][0]["controlRecoveryUrl"], "/api/studio/humble-sudoku/recovery")
        self.assertEqual(contract["exports"][0]["workspaceLaunch"]["controlUrl"], "/studio/humble-sudoku")
        self.assertEqual(contract["exports"][0]["applyPreview"]["status"], "locked")
        self.assertEqual(contract["exports"][0]["authoringSession"]["storage"], "browser-local")
        self.assertEqual(contract["exports"][0]["structuredDraft"]["kinds"], ["token", "text", "navigation", "asset"])
        self.assertEqual(contract["exports"][0]["patchPreview"]["status"], "review-only")
        self.assertIn("patch-artifact", contract["exports"][0]["runtimeReadiness"]["expectedCapabilities"])
        self.assertEqual(contract["exports"][0]["proposalCenter"]["inboxUrl"], "/studio/proposals")
        self.assertEqual(contract["exports"][0]["patchArtifact"]["suggestedFilename"], "humble-sudoku-studio-patch-artifact.json")
        self.assertFalse(contract["exports"][0]["sandboxApply"]["sourceWrites"])
        self.assertEqual(contract["exports"][0]["sourceApplyLock"]["status"], "locked")
        self.assertEqual(contract["exports"][0]["trustLevel"]["level"], "apply-locked")
        self.assertEqual(contract["exports"][0]["safeApplyBoundary"]["status"], "locked")
        self.assertEqual(contract["exports"][0]["convergenceWorkflow"]["stageCount"], 10)
        self.assertFalse(contract["exports"][0]["convergenceWorkflow"]["sourceWrites"])
        self.assertFalse(contract["exports"][0]["convergenceWorkflow"]["writes"])
        self.assertIn("authoring-smoke", contract["exports"][0]["nativeParity"]["rows"])
        self.assertIn("convergence-workflow", contract["exports"][0]["nativeParity"]["rows"])
        self.assertEqual(contract["exports"][0]["endToEndSmoke"]["controlUrl"], "/studio/humble-sudoku#smoke")
        self.assertFalse(contract["writes"])

    def test_prepare_edit_contract_rejects_unknown_supported_app(self) -> None:
        with tempfile.TemporaryDirectory() as raw_root:
            with self.assertRaises(LocalPreviewError) as context:
                build_prepare_edit_contract(
                    "http://127.0.0.1:8765",
                    catalog_for(Path(raw_root), ("python3", "generate.py")),
                    app_id="unknown-app",
                )

        self.assertEqual(context.exception.status, HTTPStatus.NOT_FOUND)
        self.assertEqual(context.exception.code, "unknown_supported_app")


if __name__ == "__main__":
    unittest.main()
