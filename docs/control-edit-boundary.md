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
6. Any repository source write is rejected by default.

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
