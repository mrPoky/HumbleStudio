# HumbleStudio Change-Marking Contract

Use when evolving HumbleStudio toward read-only authoring flows that capture proposed UI changes without mutating source truth yet.

## Goals

- keep proposals auditable and git-friendly
- attach each proposal to exported native evidence
- separate "review what should change" from "apply the change"

## Workflow

1. Prefer native inspector context first: component id, view id, token id, source path, and preview coverage.
2. Encode proposed changes as markdown artifacts before any write-back mechanism.
3. Keep each proposal narrow:
   - one scope
   - one intent
   - one acceptance check
4. Preserve preview contract notes:
   - device
   - navigation depth
   - modal layering
   - coverage level
5. If a future write-back step is added, keep it separate from proposal capture.
6. Prefer repository-aware artifacts:
   - save proposals under `docs/change-proposals/`
   - keep filenames stable per scope when possible
   - read proposal artifacts back into native review flows before planning apply steps

## Output Shape

- `Scope`
- `Requested Change`
- `Structured Targets`
- `Acceptance Notes`

Prefer the repository document at `docs/change-marking-contract.md` as the canonical template.
