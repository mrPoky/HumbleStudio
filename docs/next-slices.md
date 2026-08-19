# Top 10 Next Slices

Updated: 2026-08-20

This is the repository-native runway for autonomous HumbleStudio iterations. Work items are ordered by present product value; complete the highest safe item first and rerank after every completed slice.

1. **Extract a shared supported-app source contract** — keep native, web fallback, and any future HumbleControl localhost helper on the same app/source/generator truth instead of duplicating catalogs.
2. **Visually verify the web localhost HumbleSudoku click path** — check the running localhost preview loads HumbleSudoku through the helper and falls back clearly when the helper is unavailable.
3. **Add native supported-app resolver tests** — cover generator failure, missing repository, and source-context handoff from native local imports into the web bridge.
4. **Add authoring readiness model tests** — cover loaded/missing source, empty proposals, complete metadata, metadata gaps, and the blocked future edit/apply gate introduced by HS-0090.
5. **Add a source-pinned proposal session summary** — show repository, revision/source path, scope, snapshot, tickets, and validation posture as the bridge between review and future editing.
6. **Define the first Board document import fixture** — create a small deterministic fixture that can carry imported source truth without enabling editing yet.
7. **Create the BoardCommand envelope test scaffold** — prove command identity, target scope, validation result, and inverse-operation placeholders before gesture or inspector editing exists.
8. **Add read-only command preview rows to proposal details** — map structured targets into would-create command rows while keeping execution disabled.
9. **Verify preview safe-area geometry in the running macOS inspector** — complete the visual check for phone/tablet portrait and landscape after the contract now exposes raw insets and applied chrome offsets.
10. **Prepare HS-0015 TestFlight upload** — only after the native preview, local source, and authoring-readiness QA matrix is truthful enough for internal review.

## Current Status

- 2026-07-16 — completed: active safe-area inset values are shown in Preview Contract and localized through the string catalog.
- 2026-07-21 — completed: HS-0038 ties review queue and navigation audit surfaces to shared proposal scope, linked ticket, source-audit, and read-only apply readiness truth.
- 2026-07-22 — completed: HS-0040 models preview chrome from selected device safe-area geometry and exposes applied chrome offsets in the Preview Contract panel.
- 2026-08-20 — completed: HS-0090 adds a native authoring-readiness rail to the proposal workspace so read-only inspection, proposal capture, validation, and future edit/apply gates are visible together.
- 2026-08-20 — completed: HS-0091 makes the native supported-app HumbleSudoku action local-first and can generate the missing HumbleSudoku bundle through its allowlisted export command.
- 2026-08-20 — completed: HS-0092 adds a localhost web helper so the HumbleSudoku supported-app click path can load the adjacent local bundle and generate a missing export through the allowlisted command.
