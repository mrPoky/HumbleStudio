---
name: humblestudio-native-preview-fidelity-pass
description: Use when improving HumbleStudio macOS preview fidelity, device modeling, safe-area framing, and inspector readability without slipping back to the legacy web fallback.
---

# HumbleStudio Native Preview Fidelity Pass

Use this when the task is specifically about making the macOS app preview feel closer to real iPhone or iPad behavior.

## Goals

1. Strengthen native preview truth before expanding authoring features.
2. Make device assumptions explicit instead of hidden in ad hoc layout code.
3. Improve readability of preview and inspector detail together, not in isolation.
4. Keep legacy web available as fallback, but never as the primary answer to fidelity gaps.

## Working loop

1. Inspect the current preview surface and identify what is still simulated loosely.
2. Check whether the missing fidelity belongs to:
   - device frame and canvas sizing
   - safe areas and insets
   - navigation chrome and presentation mode
   - navigation depth, dismiss affordance, and modal layering
   - content scaling or snapshot treatment
   - inspector framing and readability
3. Implement one fidelity slice at a time.
4. Verify with:
   - `git diff --check`
   - targeted macOS build
   - visual sanity of the affected preview surface

## Heuristics

- Prefer explicit preview contracts over magic numbers spread across views.
- Keep preview controls close to the preview they affect.
- When simulating behavior, encode it as contract fields such as navigation depth or dismiss affordance instead of hardcoding one-off chrome.
- When real runtime behavior is unknown, label the surface clearly as contract-driven rather than pretending it is exact.
- Favor larger, calmer inspector layouts over dense but hard-to-parse metadata walls.

## Close-out

End by naming:
- which fidelity gap improved
- what is still only approximate
- what additional contract data would unlock the next jump
