# HumbleControl Edit Boundary

HumbleStudio exposes HumbleControl connection data in two layers:

- `read-only` manifest discovery at `/api/connections/humble-control`
- `prepare-edit` proposal/session planning at `/api/connections/humble-control/prepare-edit`
- scoped `prepare-edit` planning at `/api/connections/humble-control/prepare-edit?app=<id>`

Both layers are intentionally no-write. They can describe source truth, export
state, missing-export recovery, proposal operations, manifest diff fields,
review artifact references, and dry-run intent, but they must not mutate
HumbleStudio, HumbleControl, or a supported app repository.
When `app=<id>` is present, HumbleStudio returns a contract scoped to that
supported app only. Unknown app ids return a JSON error instead of falling back
to an aggregate contract.

Each export descriptor may also include Control-owned routes:

- `controlSessionUrl` for the per-app session dossier
- `controlWorkspaceUrl` for the unified Control app workspace
- `controlPrepareEditUrl` for the prepare-edit workbench
- `controlRecoveryUrl` for no-write recovery JSON
- `reviewArtifact` for the readable Control review page and JSON export
- `manifestDiff` for the fields Control should compare before review
- `applyGate` with `status=locked` and write requirements
- `workspaceLaunch` for Control-owned click-to-open routing
- `recoveryWizard` for confirmable missing-export generation requests
- `applyPreview` for read-only impact checks before any apply discussion
- `editBoundary` for the future real-edit rules that must be satisfied first
- `authoringSession` for browser-local restoration of selected app, export,
  proposal draft, recovery confirmation, and locked apply state
- `structuredDraft` for typed token, text, navigation, and asset edit
  boundaries
- `patchPreview` for dry-run target review with `writes:false` and
  `applied:false`
- `runtimeReadiness` for helper/manifest freshness before authoring continues
- `proposalCenter` for the Control proposal inbox and selected-app proposal
  detail
- `patchArtifact` for an exportable JSON package that can be reviewed before
  sandbox apply
- `sandboxApply` for scratch-only apply preview descriptors with
  `sourceWrites:false`
- `sourceApplyLock` for the explicit locked source-write boundary
- `trustLevel` for the selected export trust posture
- `safeApplyBoundary` for explicit allowlisted preview artifacts and rejected
  source targets
- `nativeParity` for the native Studio catalog rows that should mirror the web
  workspace contract
- `endToEndSmoke` for manifest, workspace, draft, preview, and apply-lock smoke
  verification
- `smokeCheck` for end-to-end workspace route verification

Apply remains locked until a later reviewed flow exists with:

- explicit user confirmation
- human review
- a clean worktree or backup
- a ticket-scoped change
- visible before/after evidence
- a read-only apply preview that matches the selected app, ticket, and review artifact

The first allowed bridge is therefore:

1. HumbleStudio serves source truth and export availability.
2. HumbleControl renders connection, session, health, and proposal surfaces.
3. HumbleControl may render a unified app workspace, prepare-edit workbench,
   diff, recovery, readable review artifact, local proposal draft, and dry-run
   contract surfaces.
4. HumbleControl may ask HumbleStudio to run an allowlisted export generator
   only after explicit confirmation, and only through the supported-app export
   endpoint. That may create the missing export artifact, but it is not a
   source edit/apply path.
5. HumbleControl may persist session evidence in browser-local storage for
   continuity. Browser-local evidence is useful context, not repository truth.
6. HumbleControl may persist an authoring session snapshot in browser-local
   storage so refresh can restore the working draft and recovery confirmation.
   This snapshot is convenience state, not durable source truth.
7. HumbleControl may combine authoring session, structured draft, patch preview,
   native parity, trust, registry, recovery, proposal review, and smoke evidence
   into one authoring control plane.
8. HumbleControl may export a patch artifact and inspect a sandbox apply
   descriptor as scratch-only evidence. This remains `writes:false` from
   Studio and `sourceWrites:false` for supported app repositories.
9. Any repository source write is rejected by default.

The first real edit boundary should remain narrow:

- one selected supported app
- one repo-native ticket
- one generated review artifact
- one apply preview that lists expected touched files or contract fields
- one explicit confirmation immediately before the write
- no background apply, no cross-app writes, and no implicit generator-to-apply
  escalation

This keeps the future HumbleControl/HumbleStudio merge pointed toward one
control plane while preserving the current local safety boundary.
