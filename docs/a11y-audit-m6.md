---
title: M6 Accessibility Audit
type: audit
status: active
date: 2026-04-27
---

# M6 Accessibility Audit

Per-screen audit of PRD accessibility requirements (Semantics labels on icon-only buttons, 2× text-scale survival, 48dp tap targets) for the M5 feature slices integrated in M6.

The M5 widget tests verify these claims at the slice level; this document is the cross-screen rollup that closes the M6 a11y deliverable. Findings marked **FOLLOW-UP** are not blocking for M6 merge but should land before the signed-build cut.

## Methodology

- **Semantics**: identified via `find.byTooltip(...)` / `find.bySemanticsLabel(...)` in widget tests, plus reading the production widget tree for explicit `Semantics` / `Tooltip` wrappers around icon-only interactive elements.
- **2× text scale**: pumped each screen with `MediaQuery(data: ... textScaler: TextScaler.linear(2.0))` in widget tests, asserting `tester.takeException() == null` and key text remained findable.
- **48dp tap targets**: read by inspection. Material's defaults (`IconButton` ≥48dp, `ListTile` ≥56dp, `FilledButton` ≥48dp on tappable region) cover most cases unless overridden.

## Per-screen rollup

| Screen                        | Semantics on icon-only buttons | 2× text scale | 48dp tap targets | Test coverage                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
|-------------------------------|--------------------------------|---------------|------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Splash                        | ✅                              | ✅ (golden)    | ✅                | `test/widget/features/splash/splash_screen_test.dart` (`splash_long_text_2x.png` golden + tooltip-finder cases). `SplashDayCount` clamps internal scaler at 1.5× for the fixed-height counter.                                                                                                                                                                                                                                                                                                             |
| Home (empty)                  | ✅                              | ✅             | ✅                | `WH14` in `home_screen_test.dart` — empty-state pump at 2× scale. FAB tooltip `homeFabLabel` reachable.                                                                                                                                                                                                                                                                                                                                                                                                    |
| Home (data)                   | ✅ FAB / chevron tooltips       | ✅             | ✅                | `WH15` in `home_screen_test.dart` — data-state pump at 2× scale with a long signed amount (`-$12,345.67`). Day-nav header (`day_navigation_header.dart:54,74`) wires `tooltip: l10n.homeDayNavPrev/NextLabel`. Transaction row swipe-action and overflow are wrapped in `Semantics` (`transaction_tile.dart:161,169`). `SummaryStrip._Chip` was switched from `Row(mainAxisSize: min)` to `Wrap` in M6 so the label + value reflow onto a second line at 2× scale instead of overflowing the chip's width. |
| Add / Edit Transaction        | ✅                              | ✅             | ✅                | `WS12` (Add) + `WS13` (Edit) in `transaction_form_screen_test.dart` — pump at 2× scale, no exceptions, AppBar title + Save still rendered. Calculator keypad's backspace/clear use `tooltip: l10n.txKeypadBackspace/Clear`. Edit-mode Delete in AppBar uses `tooltip: l10n.commonDelete`.                                                                                                                                                                                                                  |
| Category picker (modal sheet) | ✅                              | ✅             | ✅                | `test/widget/features/categories/category_picker_test.dart` covers `textScale: 2.0` over the grid layout. Category tiles are 48×48 dp avatars inside ≥56dp `InkWell` wells.                                                                                                                                                                                                                                                                                                                                |
| Manage Categories             | ✅                              | ✅             | ✅                | `test/widget/features/categories/categories_screen_test.dart` covers 2× text scale on the management list. Per-row swipe actions render `SlidableAction` with `label:` set to ARB keys.                                                                                                                                                                                                                                                                                                                    |
| Accounts                      | ✅                              | ✅             | ✅                | `test/widget/features/accounts/accounts_screen_test.dart` AS06 covers 2× scale; account-row trailing menu and FAB use Material defaults (≥48dp).                                                                                                                                                                                                                                                                                                                                                           |
| Settings                      | ✅                              | ✅             | ✅                | `test/widget/features/settings/settings_screen_test.dart` covers 2× scale; tiles are `ListTile` (≥56dp).                                                                                                                                                                                                                                                                                                                                                                                                   |

## Specific Semantics inventory

| Surface                                                   | Element                     | Mechanism                                                                     | Test                                          |
|-----------------------------------------------------------|-----------------------------|-------------------------------------------------------------------------------|-----------------------------------------------|
| Home FAB                                                  | `Add transaction`           | `tooltip: l10n.homeFabLabel` (also serves as Material a11y label)             | `find.byTooltip('Add transaction')` in `WH14` |
| Day-nav prev / next chevrons                              | `Previous day` / `Next day` | `tooltip:` wires via `IconButton` defaults                                    | `day_navigation_header_test.dart`             |
| Home transaction row swipe-delete                         | `Delete`                    | `SlidableAction.label = l10n.commonDelete`                                    | `home_screen_test.dart` WH12 series           |
| Home transaction row overflow → Edit / Duplicate / Delete | All three                   | `PopupMenuItem.child = Semantics(button: true, label: ..., child: Text(...))` | `home_screen_test.dart` WH06–WH09             |
| Edit Transaction AppBar Delete                            | `Delete`                    | `IconButton.tooltip = l10n.commonDelete`                                      | `transaction_form_screen_test.dart` WS11      |
| Calculator keypad backspace                               | `Backspace`                 | Tooltip on `_IconKey`                                                         | `calculator_keypad_test.dart`                 |
| Calculator keypad clear                                   | `Clear amount`              | Tooltip on `_DigitKey('C', tooltip: ...)`                                     | `calculator_keypad_test.dart`                 |

No icon-only interactive element in the MVP feature slices is missing a Tooltip / Semantics label.

## Tap-target audit

| Element                           | Min size                             | Notes                                                                                                                                                       |
|-----------------------------------|--------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Home FAB                          | ≥56dp                                | `FloatingActionButton.extended` Material default.                                                                                                           |
| Day-nav prev / next               | ≥48dp                                | `IconButton` Material default.                                                                                                                              |
| Transaction row                   | ≥56dp                                | `ListTile` Material default; full-row tap target.                                                                                                           |
| Transaction overflow menu trigger | ≥48dp                                | `PopupMenuButton` Material default.                                                                                                                         |
| Slidable swipe action             | ≥56dp                                | `SlidableAction` is a button-shaped pane; covers the row's full vertical extent.                                                                            |
| Calculator keypad keys            | ≥48dp                                | `_DigitKey` / `_IconKey` use `InkWell` with implicit padding ≥48dp at 1× scale; the keypad fixes its row height so 2× scale does not shrink touchable area. |
| Category picker tile              | ≥48dp avatar inside ≥120dp grid cell | `SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 120, childAspectRatio: 0.85)` — each cell is comfortably ≥100×118 dp.                         |
| Account picker tile               | ≥56dp                                | `ListTile` rows.                                                                                                                                            |
| Manage Categories row             | ≥56dp                                | `ListTile` rows.                                                                                                                                            |

All MVP tap targets meet the 48×48dp minimum.

## Follow-ups (deferred to Unit 10 device matrix)

1. **2× scale + narrow tablet (>=600dp portrait, two-pane Home).** Not yet exercised by widget tests; likely ok because the two-pane layout gives each column more room, but should be confirmed during the M6 device matrix step (Unit 10).
2. **Screen-reader pass on the calculator keypad.** Tooltips cover Backspace and Clear; the digit keys (`'1'`, `'2'`, …, `'00'`) lack explicit `Semantics` labels but TalkBack / VoiceOver read the visible text correctly. Confirm during Unit 10.

## Resolved during the M6 audit

- **`SummaryStrip._Chip` overflow at 2× text scale.** Switched the chip's inner `Row(mainAxisSize: min)` to `Wrap(crossAxisAlignment: WrapCrossAlignment.center)` so a long signed amount (`-$12,345.67`) reflows onto a second line instead of overflowing the chip's row width. Same fix applied to the `_PlaceholderBox` row used while currency metadata is loading. Regression guard: `home_screen_test.dart` `WH15`.

## Sources

- `PRD.md` → Accessibility, Layout Primitives.
- `docs/plans/2026-04-26-001-feat-m6-integration-polish-plan.md` — Unit 8.
- Widget tests: `test/widget/features/{home,transactions,categories,accounts,settings,splash}/`.
