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
- `controlPrepareEditUrl` for the prepare-edit workbench
- `controlRecoveryUrl` for no-write recovery JSON
- `reviewArtifact` for the Control review artifact download surface
- `manifestDiff` for the fields Control should compare before review
- `applyGate` with `status=locked` and write requirements

Apply remains locked until a later reviewed flow exists with:

- explicit user confirmation
- human review
- a clean worktree or backup
- a ticket-scoped change
- visible before/after evidence

The first allowed bridge is therefore:

1. HumbleStudio serves source truth and export availability.
2. HumbleControl renders connection, session, health, and proposal surfaces.
3. HumbleControl may render prepare-edit workbench, diff, recovery, review
   artifact, and dry-run contract surfaces.
4. Any repository write is rejected by default.

This keeps the future HumbleControl/HumbleStudio merge pointed toward one
control plane while preserving the current local safety boundary.
