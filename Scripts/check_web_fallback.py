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


def main() -> int:
    failures: list[str] = []

    if not INDEX_PATH.exists():
        print(f"Missing web entrypoint: {INDEX_PATH}", file=sys.stderr)
        return 1

    for path in referenced_files(INDEX_PATH):
        if not path.exists():
            failures.append(f"Missing referenced asset: {path.relative_to(ROOT)}")

    failures.extend(validate_markup(INDEX_PATH))
    failures.extend(validate_json_files(CONFIG_PATHS))

    if failures:
        print("\n".join(failures), file=sys.stderr)
        return 1

    print("web fallback: ok")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
