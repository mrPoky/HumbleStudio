#!/usr/bin/env python3
"""Verify that the static HumbleStudio web fallback is internally consistent."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
INDEX_PATH = ROOT / "index.html"
CONFIG_PATHS = [ROOT / "design.template.json", ROOT / "configs" / "humble-sudoku.json"]
LOCAL_PREVIEW_HELPER_PATH = ROOT / "Scripts" / "serve_local_preview.py"
REFERENCE_PATTERN = re.compile(r"""(?:src|href)=["']([^"']+)["']""")


def is_local_reference(reference: str) -> bool:
    return not (
        reference.startswith(("http://", "https://", "mailto:", "data:", "javascript:", "#"))
    )


def referenced_files(index_path: Path) -> list[Path]:
    content = index_path.read_text(encoding="utf-8")
    results: list[Path] = []
    for reference in REFERENCE_PATTERN.findall(content):
        normalized = reference.split("?", 1)[0].split("#", 1)[0]
        if not normalized or not is_local_reference(normalized):
            continue
        results.append((index_path.parent / normalized).resolve())
    return results


def validate_json_files(paths: list[Path]) -> list[str]:
    failures: list[str] = []
    for path in paths:
        try:
            json.loads(path.read_text(encoding="utf-8"))
        except FileNotFoundError:
            failures.append(f"Missing JSON file: {path.relative_to(ROOT)}")
        except json.JSONDecodeError as error:
            failures.append(f"Invalid JSON in {path.relative_to(ROOT)}: {error}")
    return failures


def validate_markup(index_path: Path) -> list[str]:
    content = index_path.read_text(encoding="utf-8")
    required_fragments = [
        'id="page-loader"',
        'id="loaderSupportedApps"',
        'id="page-review"',
        'id="page-navmap"',
        'src="js/app.js"',
        'src="js/renderers.js"',
        'src="js/demo.js"',
    ]
    failures: list[str] = []
    for fragment in required_fragments:
        if fragment not in content:
            failures.append(f"Missing expected web fallback fragment: {fragment}")
    return failures


def validate_local_preview_helper() -> list[str]:
    if not LOCAL_PREVIEW_HELPER_PATH.exists():
        return ["Missing localhost preview helper: Scripts/serve_local_preview.py"]

    helper_content = LOCAL_PREVIEW_HELPER_PATH.read_text(encoding="utf-8")
    demo_content = (ROOT / "js" / "demo.js").read_text(encoding="utf-8")
    app_content = (ROOT / "js" / "app.js").read_text(encoding="utf-8")
    required_fragments = [
        (helper_content, "humble-sudoku", "localhost helper HumbleSudoku resolver"),
        (helper_content, "humble-control", "localhost helper HumbleControl resolver"),
        (helper_content, "humble-workout", "localhost helper broader Humble app registry"),
        (helper_content, "my-vltava-run", "localhost helper MyVltavaRun resolver"),
        (
            helper_content,
            "Scripts/generate_humble_studio_config.py",
            "localhost helper allowlisted HumbleSudoku export command",
        ),
        (
            helper_content,
            "X-HumbleStudio-Local-Export",
            "localhost helper response identity header",
        ),
        (helper_content, "/api/connections", "localhost helper connection index"),
        (helper_content, "humble.studio.connections.v1", "HumbleControl connection manifest schema"),
        (helper_content, "humble.studio.prepare-edit.v1", "HumbleControl prepare-edit contract schema"),
        (helper_content, "selectedAppId", "HumbleControl scoped prepare-edit app marker"),
        (helper_content, "exportCount", "HumbleControl scoped prepare-edit export count"),
        (helper_content, "prepare-edit-contract", "HumbleControl prepare-edit manifest capability"),
        (helper_content, "session-source-truth", "HumbleControl session source truth capability"),
        (helper_content, "unified-workspace", "HumbleControl unified app workspace capability"),
        (helper_content, "controlPrepareEditUrl", "HumbleControl prepare-edit workbench route"),
        (helper_content, "controlWorkspaceUrl", "HumbleControl unified workspace route"),
        (helper_content, "controlSessionUrl", "HumbleControl session workbench route"),
        (helper_content, "controlRecoveryUrl", "HumbleControl recovery route"),
        (helper_content, "reviewArtifact", "HumbleControl review artifact reference"),
        (helper_content, "readable-review-artifact", "HumbleControl readable review page capability"),
        (helper_content, "local-proposal-draft", "HumbleControl local proposal draft capability"),
        (helper_content, "helper-control-surface", "HumbleControl helper control capability"),
        (helper_content, "manifestDiff", "HumbleControl manifest diff reference"),
        (helper_content, "applyGate", "HumbleControl locked apply gate reference"),
        (helper_content, "workspaceLaunch", "HumbleControl workspace launch contract"),
        (helper_content, "recoveryWizard", "HumbleControl recovery wizard contract"),
        (helper_content, "session-evidence", "HumbleControl session evidence capability"),
        (helper_content, "applyPreview", "HumbleControl apply preview contract"),
        (helper_content, "editBoundary", "HumbleControl edit boundary contract"),
        (helper_content, "smokeCheck", "HumbleControl workspace smoke check contract"),
        (demo_content, "/api/supported-apps/humble-sudoku/export", "web catalog localhost API path"),
        (demo_content, "/api/supported-apps/humble-control/export", "web catalog HumbleControl API path"),
        (demo_content, "/api/supported-apps/humble-workout/export", "web catalog HumbleWorkout API path"),
        (demo_content, "/api/supported-apps/my-vltava-run/export", "web catalog MyVltavaRun API path"),
        (app_content, "loadSupportedAppFromLocalHelper", "web catalog localhost loader"),
    ]
    failures: list[str] = []
    for content, fragment, label in required_fragments:
        if fragment not in content:
            failures.append(f"Missing {label}: {fragment}")
    return failures


def main() -> int:
    failures: list[str] = []

    if not INDEX_PATH.exists():
        print(f"Missing web entrypoint: {INDEX_PATH}", file=sys.stderr)
        return 1

    for path in referenced_files(INDEX_PATH):
        if not path.exists():
            failures.append(f"Missing referenced asset: {path.relative_to(ROOT)}")

    failures.extend(validate_markup(INDEX_PATH))
    failures.extend(validate_local_preview_helper())
    failures.extend(validate_json_files(CONFIG_PATHS))

    if failures:
        print("\n".join(failures), file=sys.stderr)
        return 1

    print("web fallback: ok")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
