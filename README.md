# HumbleStudio

Live design system viewer for iOS apps under the [HumblePlatform](https://github.com/humbleplatform) brand.

**No dependencies. No build step. Open `index.html` in a browser.**

Load a single `.humblebundle` or a plain `.humble/design.json` from any HumblePlatform repo and instantly see the full design system — color tokens, typography, spacing, components with interactive mocks, phone mockups of every screen, and a clickable navigation map.

---

## Quick start

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
├── js/
│   ├── app.js              ← state, routing, config loaders, sidebar, export
│   ├── renderers.js        ← component + page renderers
│   └── demo.js             ← DEMO_CONFIG (HumbleSudoku)
├── configs/
│   └── humble-sudoku.json  ← full HumbleSudoku design config
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
- **HumbleInsights** — analytics dashboard for code quality reports
- **HumbleFlow** — shared CI/CD policy and hooks
