# HumbleStudio Change-Marking Contract

This document defines a read-only contract for future Figma-like authoring inside HumbleStudio.

The goal is to let a reviewer point at a native surface, describe a desired change, and export that intent into a durable markdown artifact before any write-back touches source truth.

Current repository convention:
- proposals are saved under `docs/change-proposals/`
- the macOS review inspector can read those markdown artifacts back for the matching component or view scope
- proposal capture remains read-only; no proposal mutates exported truth on save

## Principles

- Keep authoring intent separate from current exported truth.
- Treat every marked change as a proposal until a human or later workflow applies it.
- Prefer small, traceable patches over free-form design commentary.
- Preserve source evidence: component id, view id, token id, and source path when available.

## Suggested Markdown Shape

```md
# Change Proposal

## Scope
- Surface: `view:home`
- Evidence: `HomeView.swift`, `design.json`
- Coverage: `Contract-driven`

## Requested Change
- Area: `Primary CTA`
- Intent: Increase bottom spacing and promote visual hierarchy.
- Why: Current action stack feels cramped on compact phones.

## Structured Targets
- Token candidate: `spacing.sp6`
- Component candidate: `primary-button`
- View candidate: `home`

## Acceptance Notes
- Keep safe-area behavior unchanged.
- Preserve sheet presentation behavior.
- Re-check iPhone Compact and iPad Portrait preview contracts.
```

Preferred metadata additions for native read-back:
- `Area` keeps the proposal diff-oriented instead of burying the affected region in prose.
- `Why` captures the review rationale separately from the requested change.
- `Token candidate`, `Component candidate`, and `View candidate` make structured targets easier to surface in native inspectors and future apply previews.
- multiple evidence code spans on the `Evidence` line are allowed and should be preserved.
- native read-back should distinguish `folder missing`, `directory unreadable`, and `artifact unreadable` recovery states instead of silently collapsing every reload problem into an empty list.

## What This Enables Later

- review queues that can open a change proposal directly from a native inspector
- repo-aware proposal loops where the same artifact can be saved, refreshed, opened, and reviewed again in-app
- authoring trails that stay auditable in git
- future write-back workflows that can map proposals back to `.humble/design.json` or source files safely

## What It Does Not Do Yet

- no automatic mutation of `design.json`
- no source-code rewrite
- no guarantee that a proposal is valid until a later apply step verifies it
