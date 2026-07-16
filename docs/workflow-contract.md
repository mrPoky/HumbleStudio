# HumbleStudio Workflow Contract

This document captures the repository-local workflow rules that are important
enough to deserve enforcement, not just memory.

## Shared Contract

- HumbleStudio adopts Jan Pokorny's canonical repository development contract in
  `/Users/janpokorny/Coding/personal/apps/HumbleControl/Docs/repo-development-contract.md`.
- The machine-readable local contract lives in `Config/repo-contract.json`.
- The shared validator and doctor logic remain owned by HumbleControl in
  `/Users/janpokorny/Coding/personal/apps/HumbleControl/Scripts/`.
- If a rule should apply across multiple repositories, prefer changing the
  HumbleControl-owned contract or validator instead of silently forking policy
  here.

## Repository Shape

- HumbleStudio is a hybrid repository:
  - a static web viewer rooted at `index.html`, `js/`, and `studio.css`
  - a native Apple workspace rooted at `AppleApps/`
- Workflow documentation and verification must talk about both surfaces instead
  of assuming a single-platform Swift package layout.
- Localization truth currently spans Apple `.xcstrings` plus web-inline strings.
  That is a repo-specific implementation detail, not a weakening of the shared
  contract.

## Git Workflow

- `main` is the single long-lived branch.
- Normal work happens on short-lived topic branches created from the latest
  `main`.
- Branch names use `<type>/<short-kebab-description>`.
- Commit subjects use `<type>(<scope>): <imperative summary>`.
- PR titles should match the intended squash commit title.
- Topic branches should be rebased onto the latest `origin/main` before
  meaningful local checks and before promotion.
- Prefer squash merge into `main`.
- Delete merged local topic branches after promotion.

## Worktree Lanes

- The canonical HumbleStudio lane root is
  `/Users/janpokorny/Coding/personal/worktrees/HumbleStudio`.
- Lane inventory and claims live in `.humble/coordination/lanes.json`.
- `lane-1` through `lane-4` are the fixed implementation lanes.
- The root checkout at
  `/Users/janpokorny/Coding/personal/apps/HumbleStudio` is reserved as the main
  catalog checkout and should remain on a clean `main` whenever practical.
- If a slice started before a lane was prepared, document that explicitly in the
  ticket or final report instead of pretending lane workflow existed earlier.

## Ticket Workflow

- Non-trivial work belongs in `.humble/tickets`.
- HumbleStudio uses the `HS-####` ticket prefix.
- Read-only ticket board rendering lives in `python3 Scripts/render_humble_tickets.py`.
- Ticket status should describe reality:
  - `accepted` or `ready` before implementation
  - `in_progress` after implementation starts
  - `testing` once code is done and verification remains
  - `solved` only after acceptance criteria and evidence are present
- Ticket validation should run through `python3 Scripts/validate_humble_tickets.py`.

## Status Workflow

- Repo-owned directional status truth lives in `.humble/status/current.json`.
- `python3 Scripts/humble_status.py` is the supported read-only way to combine
  that repo truth with live git, ticket, lane, and worktree state.
- The script is an observability surface, not a source of derived policy.

## Verification

Use the strongest practical verification for the slice.

Shared workflow checks:

- `python3 Scripts/validate_humble_tickets.py`
- `python3 Scripts/validate_repo_contract.py`
- `python3 Scripts/humble_doctor.py --repo-root . --strict`
- `python3 -m py_compile Scripts/*.py`
- `git diff --check`

Native/product checks when relevant:

- `./script/build_and_run.sh --native-ci`
- `xcodebuild -project HumbleStudio.xcodeproj -scheme HumbleStudioMac -configuration Debug build`

Web/product checks when relevant:

- open or sanity-check `index.html` and the static viewer assets that changed
- run any focused command added by the slice; there is no repo-local CI or test
  harness for the static web surface yet

## Repo-Specific Overrides

- HumbleStudio does not yet have a committed CI pipeline, deploy workflow, or
  automated release notes surface. That is a tooling gap to document honestly,
  not a reason to weaken the canonical contract.
- Strict repo doctor branch-freshness checks are promotion or clean-main gates.
  When run from an active topic branch, branch-hygiene failures should be
  recorded as workflow debt separately from the onboarding slice itself.
- Because HumbleStudio mixes static web assets and native Apple sources, module
  roots are `AppleApps`, `js`, and `docs` rather than the `Sources`/`Modules`
  defaults used by some other Humble repositories.
