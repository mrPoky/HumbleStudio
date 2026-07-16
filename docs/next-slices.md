# Top 10 Next Slices

Updated: 2026-07-16

This is the repository-native runway for autonomous HumbleStudio iterations. Work items are ordered by present product value; complete the highest safe item first and rerank after every completed slice.

1. **Verify preview safe-area geometry in the running macOS inspector** — complete the visual check for portrait and landscape devices now that the contract exposes the active insets.
2. **Localize preview contract labels** — move the remaining Preview Contract labels and behavior descriptions into `Localizable.xcstrings`.
3. **Model safe-area-aware preview chrome** — inset navigation, tab, and dismiss controls to the selected device's safe area instead of only displaying the overlay.
4. **Add preview surface geometry tests** — cover orientation, device canvas, size classes, and safe-area selections without relying on visual inspection alone.
5. **Refine sheet geometry by device class** — distinguish compact and regular sheet widths, detents, and landscape behavior in the native preview model.
6. **Make full-screen cover behavior explicit** — represent status/dismiss affordance and presentation context consistently across the contract and canvas.
7. **Improve navigation preview fidelity** — derive breadcrumb and back affordances from actual exported navigation edges where available.
8. **Complete component native preview gaps** — prioritize the most frequently used components still marked fallback-needed.
9. **Complete view native preview gaps** — use exported snapshot and navigation evidence to reduce fallback-only views in the review queue.
10. **Add a repeatable native preview verification note** — document the manual visual matrix alongside the existing build workflow.

## Current status

- 2026-07-16 — completed: active safe-area inset values are shown in Preview Contract and localized through the string catalog.
