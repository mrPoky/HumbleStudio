---
name: humblestudio-native-localization-parity-pass
description: Use when expanding HumbleStudio's macOS native shell and inspector with typed localization, parity truth, and user-facing recovery wording in the same slice.
---

# HumbleStudio Native Localization + Parity Pass

Use this when a HumbleStudio iteration touches user-facing native inspector surfaces and should improve both language quality and product truth together.

## Goals

1. Move visible text into `StudioStrings` and `Localizable.xcstrings`.
2. Keep parity, coverage, and recovery wording consistent across sidebar, context bar, overview, and inspectors.
3. Prefer product-truth labels such as `1:1`, `Degraded`, and `Fallback-only` over vague status copy.
4. When adding new review or recovery actions, make their user-facing wording localization-ready in the same change.

## Workflow

1. Inventory visible text in the touched native surfaces.
2. Add typed accessors in `AppleApps/Shared/Sources/StudioStrings.swift`.
3. Add English and Czech entries to `AppleApps/Shared/Resources/Localizable.xcstrings`.
4. Reuse shared parity and recovery wording instead of rephrasing per view.
5. Verify with `git diff --check` and a targeted `HumbleStudioMac` build.

## Heuristics

- Favor one shared label for the same concept across sidebar, overview, and detail.
- If a label depends on product truth, derive it from a resolver instead of duplicating string logic in views.
- Keep markdown export and review flows user-facing and localization-friendly from the start.
