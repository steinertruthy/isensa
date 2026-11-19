# Design — Sensa

Sensa should feel like a precision instrument made by the same people who made macOS: calm chrome,
exact numbers, and color that only ever means *data* or *state*.

## Tokens

### Color

Chrome is entirely system-dynamic (window background, control background, separators, labels), so light,
dark, increased contrast and tinting behave like any Apple app. Hue is reserved for data, and each component
keeps **one hue everywhere** — sidebar icon, charts, gauges, popover, menu bar graph.

| Role | Light | Dark | Source |
|---|---|---|---|
| CPU | `#007AFF` | `#0A84FF` | systemBlue |
| GPU | `#AF52DE` | `#BF5AF2` | systemPurple |
| Memory | `#00C7BE` | `#63E6E2` | systemMint |
| Thermal | `#FF9500` | `#FF9F0A` | systemOrange |
| Power | `#C27C00` | `#FFD60A` | custom amber (systemYellow is illegible on white) |
| Battery | `#34C759` | `#30D158` | systemGreen |
| Fans | `#32ADE6` | `#64D2FF` | systemCyan |
| Network | `#5856D6` | `#5E5CE6` | systemIndigo |
| Storage | `#A2845E` | `#AC8E68` | systemBrown |

Status keeps its own channel — green / orange / red — always paired with a symbol and words.

### Type

SF Pro only (the system font), in two voices:

- **Text voice** — SF Pro Text/Display at the macOS scale: title 26 semibold, headline 13 semibold,
  body 13, callout 12, caption 11.
- **Number voice** — SF Pro Rounded, semibold, tabular digits. A value is *typeset*: the number at full
  size, its unit at ~55 % size in the secondary color (`48 °C` → **48** °C). Digits never jitter while updating.

### Layout

Group, don't box. Related metrics share one surface divided by hairlines; a group's title sits above the
surface, as in System Settings.

```
┌ Greeting ─────────────────────────────── Mac, chip, memory ┐
│ ╭ PULSE ──────────────────────────────────────────────────╮ │
│ │ Health sentence                       status · insights │ │
│ │ ~~~~~~~ live CPU + GPU waveform, full width ~~~~~~~~~~~ │ │
│ ╰─────────────────────────────────────────────────────────╯ │
│ Performance                                                 │
│ ╭ CPU ─────────┬ GPU ─────────┬ Memory ──────────────────╮  │
│ ╰──────────────┴──────────────┴──────────────────────────╯  │
│ Thermals and power                                          │
│ ╭ Temperature ─┬ Power ───────┬ Fans ────────────────────╮  │
│ ╰──────────────┴──────────────┴──────────────────────────╯  │
│ Battery, storage and network                                │
│ ╭ Battery ─────┬ Storage ─────┬ Network ─────────────────╮  │
│ ╰──────────────┴──────────────┴──────────────────────────╯  │
└─────────────────────────────────────────────────────────────┘
```

Content is left-aligned on a single column of max 1,040 pt; numbers align on their baseline. Detail
screens follow the same rhythm: title and plain-language summary, one hero instrument, then grouped facts.
The sidebar uses System Settings–style tinted squares, one per component hue.

### Motion

Every animation goes through `Motion` and honours both the app's Animations setting (full / reduced /
off) and macOS Reduce Motion: reduced turns movement into short fades, off makes changes instant.

| Moment | Motion |
|---|---|
| Sidebar collapse/expand (button or ⌃⌘S) | `Motion.sidebar` spring |
| Changing screen or settings pane | new screen fades in rising 10 pt (`Motion.screen`); the old one fades out faster (`Motion.exit`) |
| Selecting a sidebar row; opening a screen | the hued icon's glyph bounces once (full motion only) |
| A screen appears | gauges and meters fill from zero (`Motion.reveal`) |
| Live samples (every second) | gauges and bars ease in 0.3 s (`Motion.update`) — never springs |
| Headline numbers | digits roll (`MetricText(rolls: true)`, 0.22 s); other numbers swap without animation |

Live data refreshes every second, so its motion must finish well within that second: an earlier
spring kept the CPU screen redrawing continuously (18 % CPU, now 6 %), and rolling every number on the
overview cost about 6 points of CPU. Measure with motion on and off before adding motion to live values.

## Principles

1. **Data is the color.** Neutral chrome; a hue appears only where it identifies a component's data.
2. **Numbers are typeset.** Value and unit have different weights and sizes; digits are tabular.
3. **Group, don't box.** One surface per group, hairlines inside it — never a card per number.
4. **One heartbeat.** The Pulse waveform is the only ambient motion. Everything else moves only to answer
   the user (open, expand, confirm) or to show a value changing.
5. **Sound is rare.** Confirmations and alerts only, always optional, and silent when the system's
   interface sound effects are off.
6. **Honest by design.** Derived, estimated and experimental values say so, quietly.

## Review against generic defaults

The first draft kept a grid of nine identical tiles with gradient sparklines — the generic dashboard any
monitoring brief produces. Revised: tiles became cells inside three grouped surfaces, the only large chart is
the Pulse, and color moved from decoration to a fixed component mapping. The draft also had an eyebrow
label above every section; group titles now appear only where they name a real grouping.
