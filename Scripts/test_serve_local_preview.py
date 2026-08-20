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
    build_prepare_edit_contract,
    build_humble_control_connection_manifest,
    ensure_supported_app_export,
    parse_connection_path,
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
        self.assertEqual(export["id"], "humble-control")
        self.assertEqual(export["state"], "available")
        self.assertEqual(export["missingExport"]["state"], "available")
        self.assertFalse(export["missingExport"]["writes"])
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
        self.assertEqual(contract["mode"], "prepare-edit")
        self.assertFalse(contract["writes"])
        self.assertEqual(contract["applyBoundary"]["status"], "locked")
        self.assertIn("session-source-truth", contract["capabilities"])
        self.assertEqual(export["id"], "humble-sudoku")
        self.assertEqual(export["state"], "available")
        self.assertFalse(export["operations"][0]["writes"])


if __name__ == "__main__":
    unittest.main()
