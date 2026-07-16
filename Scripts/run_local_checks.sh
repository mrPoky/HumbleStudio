#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

MODE="${1:---default}"

run_workflow_checks() {
  printf "\n[1/5] Validate repo-native tickets...\n"
  python3 Scripts/validate_humble_tickets.py

  printf "\n[2/5] Validate repo contract...\n"
  python3 Scripts/validate_repo_contract.py

  printf "\n[3/5] Compile workflow scripts...\n"
  python3 -m py_compile Scripts/*.py

  printf "\n[4/5] Web fallback verification...\n"
  python3 Scripts/check_web_fallback.py

  printf "\n[5/5] Diff whitespace check...\n"
  git diff --check
}

run_native_checks() {
  printf "\n[Native] macOS targeted sanity build...\n"
  ./script/build_and_run.sh --native-ci
}

case "$MODE" in
  --workflow-only)
    run_workflow_checks
    ;;
  --native)
    run_workflow_checks
    run_native_checks
    ;;
  --default|--workflow)
    run_workflow_checks
    ;;
  *)
    echo "usage: $0 [--workflow-only|--workflow|--native]" >&2
    exit 2
    ;;
esac

echo "Local checks passed."
