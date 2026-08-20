# HumbleControl Edit Boundary

HumbleStudio exposes HumbleControl connection data in two layers:

- `read-only` manifest discovery at `/api/connections/humble-control`
- `prepare-edit` proposal/session planning at `/api/connections/humble-control/prepare-edit`

Both layers are intentionally no-write. They can describe source truth, export
state, missing-export recovery, proposal operations, and dry-run intent, but they
must not mutate HumbleStudio, HumbleControl, or a supported app repository.

Apply remains locked until a later reviewed flow exists with:

- explicit user confirmation
- human review
- a clean worktree or backup
- a ticket-scoped change
- visible before/after evidence

The first allowed bridge is therefore:

1. HumbleStudio serves source truth and export availability.
2. HumbleControl renders connection, session, health, and proposal surfaces.
3. HumbleControl may request or display a dry-run contract.
4. Any repository write is rejected by default.

This keeps the future HumbleControl/HumbleStudio merge pointed toward one
control plane while preserving the current local safety boundary.
