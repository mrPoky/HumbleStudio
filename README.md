# HumbleStudio

Design system viewer for iOS apps under the HumblePlatform brand.

Single-file, no dependencies, no build step — open `index.html` in a browser.

## Usage

1. Open `index.html` in any browser
2. Load a `.humble/design.json` from your repository:
   - **URL** — paste a raw GitHub URL
   - **File** — upload from disk
   - **Demo** — click "Load HumbleSudoku demo config"

## Config format

Each app repo should have `.humble/design.json` describing:

```
tokens        → colors (dark/light), typography, spacing, radius
components    → SwiftUI components with renderer type and mocks
views         → app screens with component lists and navigation
navigation    → root view and navigation type
```

See `design.template.json` for a minimal starter config.

## Supported renderers

| renderer          | SwiftUI analog            |
|-------------------|---------------------------|
| `button`          | `HumbleButton`            |
| `badge`           | `HumbleBadge`             |
| `timer`           | `TimerBadge`              |
| `difficulty-picker` | `DifficultyPicker`      |
| `numpad`          | `NumberPad`               |
| `list`            | `SettingsList`            |
| `navbar`          | `GameNavigationBar`       |
| `stat-chips`      | `StatChipsRow`            |
| `cell-states`     | `GridCell`                |
| `action-card`     | `ActionCard`              |

## Navigation map

Views with `navigatesTo[]` relations are rendered as an interactive SVG flow diagram. Navigation types:
- `push` — teal arrow
- `sheet` — blue dashed arrow
- `replace` — yellow arrow
