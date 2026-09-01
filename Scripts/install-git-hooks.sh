#!/usr/bin/env bash
set -euo pipefail

# Managed by HumbleControl Scripts/portfolio_hook_rollout.py.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if [[ ! -d .githooks ]]; then
  echo "Missing .githooks directory; run the HumbleControl hook rollout first." >&2
  exit 1
fi

current="$(git config --get core.hooksPath || true)"
if [[ "$current" != ".githooks" ]]; then
  if [[ -z "$current" ]]; then
    echo "core.hooksPath was unset; setting it to .githooks"
  else
    echo "core.hooksPath was $current; setting it to .githooks"
  fi
fi

git config core.hooksPath .githooks
echo "Installed repo hooks path: $(git config core.hooksPath)"
