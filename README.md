# HumbleStudio

Live design system viewer for iOS apps under the [HumblePlatform](https://github.com/humbleplatform) brand.

HumbleStudio currently ships in two surfaces:
- a zero-build web viewer opened via `index.html`
- a native Apple app workspace inside `AppleApps/` focused on macOS inspection, modular native tooling, and preview fidelity work

Load a single `.humblebundle` or a plain `.humble/design.json` from any HumblePlatform repo and instantly see the full design system — color tokens, typography, spacing, components with interactive mocks, phone mockups of every screen, and a clickable navigation map.

---

## Quick start

### Web viewer

```
open index.html
```

Then pick one of three ways to load a config:

| Method | When to use |
|--------|-------------|
| **URL** | Paste a raw GitHub URL to `.humble/HumbleSudoku.humblebundle` or `.humble/design.json` on any branch |
| **File** | Upload a local `.humblebundle`, `.zip`, or `design.json` for offline work |
| **Demo** | Click "Load HumbleSudoku demo config" to explore a real example |

Hosted niceties included:
- drag & drop onto the upload card
- remembers the last URL or demo source in `localStorage`
- supports URL bootstrap via `?bundle=https://...` or `?config=https://...`

### Native macOS app

Open `HumbleStudio.xcodeproj` in Xcode and run the `HumbleStudioMac` scheme.

Fast local workflow:
- `./script/build_and_run.sh run` builds and opens the macOS app
- `./script/build_and_run.sh --verify` rebuilds and checks that the app launches
- `./script/build_and_run.sh --native-ci` regenerates the project and runs a build-only native sanity pass
- `xcodebuild -project HumbleStudio.xcodeproj -scheme HumbleStudioMac -configuration Debug build` is the targeted CI-style sanity check

Current native priorities:
- modular macOS inspector architecture
- larger native detail views for tokens, components, views, and navigation
- preview fidelity work for device framing, orientation, safe-area modeling, and contract-driven behavior such as navigation depth, stack context, and modal layering
- explicit parity truth with `1:1`, `degraded`, and `fallback-only` states instead of a binary native/fallback story
- read-only change-marking contracts that can later grow into safe write-back workflows
- repo-aware change proposals stored in `docs/change-proposals/` and readable back from the native review inspector
- keeping the legacy web inspector available only as fallback

---

## Config format

Each app repo can expose either a plain `.humble/design.json` or a packaged `.humblebundle` containing `design.json`, icons, and snapshots. Minimal `design.json` structure:

```json
{
  "meta": { "name": "MyApp", "version": "1.0", "platform": "ios" },
  "tokens": {
    "colors":     { "accent": { "dark": "#1DB8A0", "light": "#0D9B86", "group": "Accent" } },
    "typography": [ { "role": "displayTitle", "swiftui": ".largeTitle .bold", "size": 28, "weight": 700 } ],
    "spacing":    { "sp4": { "value": "16", "usage": "card padding" } },
    "radius":     { "card": { "value": "16px", "usage": "card, sheet" } }
  },
  "components": [
    {
      "id": "primary-button", "name": "PrimaryButton", "group": "Buttons",
      "renderer": "button", "swiftui": "PrimaryButton(title:style:)",
      "mocks": [
        { "id": "default", "label": "Default", "props": { "title": "Continue", "style": "primary" } }
      ]
    }
  ],
  "views": [
    {
      "id": "home", "name": "HomeView", "root": true,
      "navbar": { "title": "MyApp", "back": false, "actions": ["⚙"] },
      "components": ["primary-button"],
      "navigatesTo": [ { "viewId": "detail", "trigger": "Continue button", "type": "push" } ]
    }
  ],
  "navigation": { "root": "home", "type": "stack" }
}
```

See [`design.template.json`](design.template.json) for a copy-paste starter.  
See [`configs/humble-sudoku.json`](configs/humble-sudoku.json) for a full real-world example.

---

## What you get

### Native macOS workspace
- native sidebar, quick open, review queue, and detail inspectors
- snapshot-first component and view inspection backed by exported bundle truth
- evolving device preview surface with explicit preview configuration for orientation, behavior depth, stack context, modal layering, and device framing
- review and navigation surfaces that now expose contract-driven preview coverage instead of hiding all uncertainty behind the fallback
- source and recovery workflow surfaces that now expose recommended actions instead of passive diagnostics only
- routing and inspector flows designed to replace legacy web fallback over time

### Foundation
- **Tokens** — color swatches with dark/light values, grouped by category
- **Typography** — type scale table with live size/weight preview
- **Spacing & Radius** — visual bar chart for spacing, box previews for radius

### Components
Each component renders as an HTML approximation of its SwiftUI counterpart. Switch between mocks via the dropdown to see all variants (disabled state, different styles, etc.).

**Supported renderers:**

| `renderer` value    | SwiftUI analog            |
|---------------------|---------------------------|
| `button`            | `HumbleButton(title:style:)` |
| `badge`             | `HumbleBadge(label:style:)` |
| `timer`             | `TimerBadge(value:accent:)` |
| `difficulty-picker` | `DifficultyPicker(selected:)` |
| `numpad`            | `NumberPad(selected:onTap:)` |
| `list`              | `SettingsList(sections:)` |
| `navbar`            | `GameNavigationBar(title:actions:)` |
| `stat-chips`        | `StatChipsRow(difficulty:time:)` |
| `cell-states`       | `GridCell(state:value:)` |
| `action-card`       | `ActionCard(title:subtitle:buttons:)` |

Unknown renderers fall back to a JSON dump of their props.

### Views
- Grid of phone mockups — one card per screen
- Click any view to open a detail with a phone mockup, component list, and navigation targets
- Click a component pill to jump to its component page
- Click a navigation target to jump to that view

### Navigation Map
Interactive SVG diagram generated from `views[].navigatesTo`. Click any node to open the view detail.

| Arrow style | Type |
|-------------|------|
| Teal solid  | `push` |
| Blue dashed | `sheet` |
| Yellow solid | `replace` |

---

## File structure

```
HumbleStudio/
├── index.html              ← app shell (HTML only)
├── studio.css              ← all styles, CSS variables, dark/light theme
├── AppleApps/              ← native iOS/macOS workspace and shared shell model
├── docs/                   ← future-facing product and authoring contracts
├── js/
│   ├── app.js              ← state, routing, config loaders, sidebar, export
│   ├── renderers.js        ← component + page renderers
│   └── demo.js             ← DEMO_CONFIG (HumbleSudoku)
├── configs/
│   └── humble-sudoku.json  ← full HumbleSudoku design config
├── .codex/skills/          ← local workflow and iteration skills for Codex
└── design.template.json    ← minimal starter for new apps
```

---

## Adding HumbleStudio to your app repo

1. Create `.humble/design.json` (copy from `design.template.json`)
2. Fill in your tokens, components, and views
3. In HumbleStudio, load via raw GitHub URL:
   ```
   https://raw.githubusercontent.com/mrPoky/<repo>/develop/.humble/design.json
   ```

---

## HumblePlatform

HumbleStudio is part of the HumblePlatform toolchain alongside:
- **HumbleSudoku** — the iOS app this viewer was built for
- **HumbleControl Web** — integrated analytics dashboard for code quality reports
- **HumbleFlow** — shared CI/CD policy and hooks
