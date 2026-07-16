# HumbleStudio Agent Rules

These repo-local rules adopt Jan Pokorny's canonical repository development
contract from
`/Users/janpokorny/Coding/personal/apps/HumbleControl/Docs/repo-development-contract.md`
and the portfolio git workflow from
`/Users/janpokorny/Coding/PLAYBOOKS/portfolio_git_workflow.md`.

If a future rule should apply across multiple repositories, update the
HumbleControl-owned canonical contract instead of silently forking policy here.

## Repo Identity

- Repository: `HumbleStudio`
- Repo contract config: `Config/repo-contract.json`
- Local workflow contract: `docs/workflow-contract.md`
- Shared contract validator entrypoint: `Scripts/validate_repo_contract.py`
- Local repo doctor entrypoint: `Scripts/humble_doctor.py`
- Repo-native ticket store: `.humble/tickets`
- Repo status surface: `.humble/status/current.json`
- Ticket id allocator: `Scripts/allocate_humble_ticket_id.py`
- Lane manager entrypoints: `Scripts/manage_humble_lanes.py`, `Scripts/start_ticket_lane.py`
- Ticket board renderer: `Scripts/render_humble_tickets.py`
- Repo status renderer: `Scripts/humble_status.py`
- Status summary renderer: `Scripts/render_humble_status.py`

## Start Of Work

Before editing files:

- Run `git status --short --branch`.
- Read this `AGENTS.md` plus the canonical contract when the work affects
  workflow, release, tickets, or shared tooling.
- Inspect relevant local workflow files before deciding implementation details.
  For HumbleStudio this usually means `README.md`, `project.yml`,
  `script/build_and_run.sh`, `HumbleStudio.xcodeproj/project.pbxproj`, and any
  existing docs in `docs/`.
- Identify the owning repo-native ticket for non-trivial work. Create or update
  a `HS-` ticket in `.humble/tickets` when the slice changes behavior,
  workflow, documentation with operating impact, release process, or shared
  repo tooling.
- Notice any dirty worktree files and leave unrelated work alone.
- Announce the concrete slice before editing.

## Git And Branch Model

- `main` is the single long-lived branch.
- Normal work belongs on short-lived topic branches created from the latest
  `main`.
- Branch names use `<type>/<short-kebab-description>`.
- Ticketed branches should include the ticket id when practical, for example
  `chore/hs-0001-repo-contract-onboarding`.
- Allowed prefixes are `feat`, `fix`, `refactor`, `chore`, `docs`, `hotfix`,
  and `release` only when a release branch is truly needed.
- Commits use `<type>(<scope>): <imperative summary>`.
- PR titles should match the intended final squash commit title.
- Rebase topic branches onto `origin/main` before meaningful local checks and
  before promotion.
- Prefer squash merge into `main`.
- Delete merged local topic branches after promotion.

## Worktree Lanes

- HumbleStudio uses fixed lane worktrees rooted at
  `/Users/janpokorny/Coding/personal/worktrees/HumbleStudio`.
- The reserved root checkout in `/Users/janpokorny/Coding/personal/apps/HumbleStudio`
  should stay a clean catalog-style checkout on `main` whenever practical.
- Active implementation slices should prefer `lane-1` through `lane-4` when the
  lane workflow is available and prepared for the task.
- Lane state lives in `.humble/coordination/lanes.json`.
- Use `python3 Scripts/start_ticket_lane.py --path <scope>` when preparing the next explicit lane-backed slice.
- If work starts before a lane is prepared, say so explicitly instead of
  pretending lane discipline was followed.

## Dirty Worktree Protocol

- Never revert, amend, clean, or stage unrelated local changes.
- Inspect overlapping dirty files before editing them.
- Stage exact paths for the completed slice only.
- Report any remaining dirty or untracked files separately from the committed
  work.
- If dirty state blocks verification, report the exact command and path.

## Ticket Discipline

- Non-trivial implementation, workflow, release, documentation-with-operating
  impact, and shared contract/tooling changes should be tracked in
  `.humble/tickets`.
- HumbleStudio ticket ids use the `HS-####` prefix.
- Ticket status must reflect reality:
  - `proposed` or `accepted` for planned backlog.
  - `in_progress` only after implementation starts.
  - `testing` only when code is done and verification remains.
  - `solved` only when acceptance criteria and evidence are present.
- Closing a ticket requires command evidence or an explicit not-applicable
  explanation.
- Do not solve a ticket in a commit that omits the implementation or evidence
  required to justify closure.

## Verification

Use the strongest practical verification for the slice.

Default workflow checks for this repo:

- `python3 Scripts/validate_humble_tickets.py`
- `python3 Scripts/validate_repo_contract.py`
- `python3 Scripts/humble_doctor.py --repo-root . --strict`
- `python3 Scripts/check_web_fallback.py`
- `bash Scripts/run_local_checks.sh --workflow-only`
- `python3 -m py_compile Scripts/*.py`
- `git diff --check`

Product checks when native app files or app workflow files are involved:

- `./script/build_and_run.sh --native-ci`
- `xcodebuild -project HumbleStudio.xcodeproj -scheme HumbleStudioMac -configuration Debug build`

Notes:

- The strict repo doctor is a branch-freshness gate. From an active topic
  branch, report that result honestly if it fails for branch hygiene reasons.
- When a verification command is skipped, explain why and name the residual
  risk.

## Definition Of Done

A slice is done only when:

- The requested change is implemented or explicitly blocked.
- Related tickets are updated with current status and evidence.
- Relevant verification passed or the skip is justified.
- Only related files are staged.
- A coherent commit exists unless the user explicitly asked not to commit.
- A fresh `git status --short --branch` has been checked.

## Final Response

After file edits, report:

- Every commit hash and subject created for the slice.
- Verification commands and whether they passed, failed, or were intentionally
  blocked.
- Whether the worktree is clean.
- Any remaining dirty or untracked files intentionally left alone.
- Any blocked follow-up or repo-specific override that still needs a user
  decision.

## Repo-Specific Overrides

- HumbleStudio currently has no repo-local CI pipeline or release automation
  checked into the repository. The strongest practical local verification is the
  shared contract tooling plus the native macOS build commands documented above.
- HumbleStudio is a hybrid repository with a static web viewer and native Apple
  app workspace. Repo contract docs and checks should describe both surfaces
  explicitly instead of assuming a single-platform Swift package layout.
