---
name: humblestudio-native-inspector-slice
description: Use when evolving the native macOS HumbleStudio inspector so each slice improves SwiftUI parity, modularity, and verification without dumping more logic into the root workspace file.
---

# HumbleStudio Native Inspector Slice

Use this when iterating on the native macOS HumbleStudio workspace.

## Priorities

1. Keep `StudioMacWorkspaceView` as shell, routing, and high-level composition.
2. Move page-specific UI, inspectors, and preview logic into focused macOS source files.
3. Prefer one coherent native inspector slice at a time over broad churn.
4. Leave unrelated iOS drift and Xcode user data out of commits.

## Working loop

1. Check `git status` for unrelated drift.
2. Measure hotspot size with `wc -l` before expanding a file.
3. Extract by surface:
   - foundation pages and inspectors
   - component/view inspectors
   - navigation/review surfaces
   - shared inspector primitives
4. Keep shared helpers intentionally visible across files only when reused.
5. Update `HumbleStudio.xcodeproj/project.pbxproj` for every new macOS source file.
6. Verify in this order:
   - `git diff --check`
   - targeted source grep or syntax sanity
   - `xcodebuild ... -scheme HumbleStudioMac ... build`
   - `./script/build_and_run.sh --verify`
7. Commit one slice-shaped checkpoint.

## Heuristics

- If a new SwiftUI type is only used by one surface, keep it in that surface file.
- If a helper is reused across inspector files, make it shared on purpose instead of leaving it hidden in the root file.
- Prefer reducing file size and ownership ambiguity before adding new product chrome.
- Treat `Legacy Web Inspector` as fallback, not a place to park unfinished native work forever.

## Close-out

End by naming:
- what moved
- what was verified
- what still depends too much on the root workspace
- the next best extraction or parity slice
