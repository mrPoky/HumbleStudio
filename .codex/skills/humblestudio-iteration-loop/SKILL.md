---
name: humblestudio-iteration-loop
description: Use when continuing HumbleStudio work in iterative slices that must revisit the prior Top 10, prioritize macOS native quality first, verify changes, and always end with the next ranked Top 10.
---

# HumbleStudio Iteration Loop

Use this when continuing work in the HumbleStudio repo across multiple iterations.

## Goals

1. Re-check the previous Top 10 from the thread before picking the next task.
2. Prioritize macOS native app quality, modularity, and 1:1 preview fidelity before broader feature expansion.
3. Keep each iteration slice-sized, verifiable, and easy to continue.
4. Always finish with an updated Top 10 ordered by present value, not by habit.

## Start-of-turn loop

1. Inspect the current repo state and `git status`.
2. Find the previous Top 10 from the conversation.
3. Re-rank it against the current codebase:
   - remove stale items
   - promote blockers
   - merge duplicates
   - demote low-leverage cleanup
4. Implement the highest-value safe slice you can finish and verify in one turn.

## Branch and commit hygiene

1. Work from a lane-backed topic branch when available instead of the root
   checkout.
2. If the slice is ticketed, include the primary `HS-####` ids in the branch
   name.
3. If the slice is ticketed, use the same ticket ids in the commit scope, for
   example `refactor(hs-0011,hs-0012): strengthen native recovery truth`.
4. Before calling a stale remote branch "unfinished", compare it directly
   against current `main` with `git diff HEAD..origin/<branch>` so you do not
   accidentally revive older code that `main` already superseded.

## Priority rules

1. macOS native shell and inspector modularity
2. native preview fidelity and device behavior modeling
3. larger-detail inspector UX for tokens, components, views, and navigation
4. routing, history, and import correctness
5. README and workflow truthfulness
6. web parity improvements that support product understanding
7. future authoring workflows such as change-marking and exportable review artifacts

## Verification

Run these when relevant:

1. `git diff --check`
2. targeted source sanity checks
3. `xcodebuild -project HumbleStudio.xcodeproj -scheme HumbleStudioMac -configuration Debug build`
4. `./script/build_and_run.sh --verify` when the slice touches that workflow and the script is available

## Close-out

End every iteration with:

1. a short outcome summary
2. what was verified
3. a lightweight analysis of what still limits the app
4. the next Top 10 ranked by importance and expected benefit

## Notes

- Prefer adding focused local skills over ad hoc repeated instructions when a workflow keeps recurring.
- Treat the legacy web inspector as support, not as the main destination for unfinished macOS work.
- Favor changes that move the repo toward a tokenized, modular, inspectable app shell.
