# Analysis redesign — design reference

Visual source for [`docs/superpowers/specs/2026-11-02-analysis-redesign-design.md`](../../superpowers/specs/2026-11-02-analysis-redesign-design.md)
and the period picker in [`docs/superpowers/specs/2026-11-03-analysis-period-picker-design.md`](../../superpowers/specs/2026-11-03-analysis-period-picker-design.md) (issue #73).
The specs define behaviour; this folder defines exact visual values.

## Files

| File | What it is |
|---|---|
| `Main.dc.html` | Full source of the design prototype (one component, all states). |


`Main.dc.html` is a Design Component file. It needs the design canvas runtime
(`support.js`) to render, so **read it as source** rather than opening it in a
browser:

- Markup (between `<x-dc>` and `</x-dc>`): layout, paddings, radii, font sizes,
  line-heights, gaps — every value is an inline `style`.
- `renderVals()` in the `<script type="text/x-dc">` block: the light/dark
  colour tokens (`LIGHT` / `DARK`), per-state styles (selected tabs, tiles,
  chips, rows, bars), copy strings, and the interaction rules (what each tap
  sets and clears).
- Sample data (`CAT`, `MONTH_EXP`, `MATRIX`, `TX`, `SERIES`) is **mock data** for
  the prototype only. Never port it into the app.

## Artboards on the canvas

| Artboard | Props on `Main` | Shows |
|---|---|---|
| Prototype — tap around | `layout=phone` | 390×844 interactive phone screen with bottom nav |
| Month — full page | `layout=full period=month` | Whole scroll page, default state |
| Day — no trend chart | `period=day` | Trend card hidden on Day |
| Category tapped — transactions | `period=month sel=0` | Food selected: dimmed donut, filtered trend, drill-down card |
| Dark mode | `period=month dark=true` | Dark tokens |
| Account filter — pick an account | `sheet=true` | Bottom sheet open |
| Account filter — Visa card by category | `period=month acc="Visa card"` | Breakdown scoped to one account |
| Search expanded | `layout=phone search=true` | Search field expanded leftwards; account button hidden |
| All time | `layout=full period=all` | All records; chevrons hidden; monthly trend across the whole range |
| Day — pick a day | `period=day picker=true anchor=2026-10-21` | Period picker: month calendar, one day selected |
| Week — pick a week | `period=week picker=true anchor=2025-09-16` | Period picker: one row per week, ISO week numbers |
| Week — jump to a month | `period=week picker=true pickerView=months anchor=2025-09-16` | Browse title tapped: month grid for the year |
| Month — pick a month | `period=month picker=true anchor=2026-06-01` | Period picker: 3×4 month grid |
| Year — pick a year | `period=year picker=true anchor=2025-01-01` | Period picker: years from the first record to now |
| Week picker — dark | `period=week picker=true dark=true` | Dark tokens |

Design canvas: https://claude.ai/artifact/W29pRjtFLFugrTfbvANCpr (private to the owner).
Period picker canvas (#73): https://claude.ai/artifact/RyeWJ3xPQk75jUaPwv5fvg (private to the owner).

## Translating to Flutter

- 1 CSS px = 1 logical pixel (dp). Font sizes are in logical pixels.
- Icons in the mock are stroke stand-ins. Use the app's real icons: category
  icons from `icon_registry.dart`, account icons from the account type, and the
  Material icons listed in the spec for UI glyphs.
- The mock loads Roboto only to imitate Android. Do not add a font package;
  keep the platform default.
