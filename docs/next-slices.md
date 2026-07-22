# Top 10 Next Slices

Updated: 2026-07-22

This is the repository-native runway for autonomous HumbleStudio iterations. Work items are ordered by present product value; complete the highest safe item first and rerank after every completed slice.

1. **Verify preview safe-area geometry in the running macOS inspector** — complete the visual check for phone/tablet portrait and landscape after the contract now exposes both raw insets and applied chrome offsets.
2. **Add preview surface geometry tests** — cover orientation, device canvas, size classes, safe-area selections, and derived chrome geometry without relying on visual inspection alone.
3. **Refine sheet geometry by device class** — distinguish compact and regular sheet widths, detents, and landscape behavior in the native preview model.
4. **Make full-screen cover behavior explicit** — represent status/dismiss affordance and presentation context consistently across the contract and canvas.
5. **Improve navigation preview fidelity** — derive breadcrumb and back affordances from actual exported navigation edges where available.
6. **Complete component native preview gaps** — prioritize the most frequently used components still marked fallback-needed.
7. **Complete view native preview gaps** — use exported snapshot and navigation evidence to reduce fallback-only views in the review queue.
8. **Add a repeatable native preview verification note** — document the manual visual matrix alongside the existing build workflow.
9. **Prepare HS-0015 TestFlight upload** — only after the native preview QA matrix is truthful enough for internal review.
10. **Deepen proposal scope and source-audit parity across remaining non-proposal inspector truth surfaces** — keep the same inspection-truth standard visible beyond the proposal workspace.

## Current status

- 2026-07-16 — completed: active safe-area inset values are shown in Preview Contract and localized through the string catalog.
- 2026-07-21 — completed: HS-0038 ties review queue and navigation audit surfaces to shared proposal scope, linked ticket, source-audit, and read-only apply readiness truth.
- 2026-07-22 — completed: HS-0040 models preview chrome from selected device safe-area geometry and exposes applied chrome offsets in the Preview Contract panel.
