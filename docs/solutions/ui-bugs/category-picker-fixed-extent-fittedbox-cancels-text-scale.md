---
title: Category picker's fixed tile height and FittedBox label silently cancelled 2x text scale
date: 2026-10-31
category: docs/solutions/ui-bugs/
module: categories
problem_type: ui_bug
component: frontend_stimulus
symptoms:
  - "At 2x text scale every picker label shrank back to about 1x, with no overflow error"
  - "The existing '2x text scale renders without overflow' widget test still passed"
  - "On a 320dp phone the 48px icon circle was squeezed to 44.8px wide"
  - "The RED test kept failing after the fix because the test font made the label width-limited"
  - "An integration test passed by accident after its tap on an off-screen CategoryChip missed"
root_cause: logic_error
resolution_type: code_fix
severity: medium
related_components:
  - features/transactions/widgets/category_chip
  - test/integration/transaction_mutation_flow_test
tags: [text-scale, fittedbox, sliver-grid, main-axis-extent, category-picker, ahem-font, ensure-visible, warn-if-missed]
---

# Category picker's fixed tile height and FittedBox label silently cancelled 2x text scale

## Problem
Issue #81 asked for the category picker to show five icons per row and to shrink long labels instead of wrapping them. The first version gave each grid tile a fixed height and put the label in a `FittedBox(fit: BoxFit.scaleDown)`. At 2× text scale the fixed height left too little room, so the `FittedBox` scaled every label back down to about 1×. Users who had asked for large text got small text, and no test noticed.

The code is `_CategoryPickerSheet._gridSlivers` and `_CategoryPickerTile` in `lib/features/categories/widgets/category_picker.dart`.

## Symptoms
- **Labels ignored the text scale.** A tile was 88px tall. 16px of vertical padding, the 48px icon and a 6px gap leave 18px for the label. At 2×, `bodySmall` needs 32px (a 16px line height × 2), so `FittedBox` shrank the label to fit 18px.
- **The 2× test stayed green.** `P05: 2x text scale renders without overflow` checks only that nothing throws and the label exists. `FittedBox` turns "doesn't fit" into "is smaller", so nothing overflowed.
- **The icon was squeezed on narrow phones.** On a 320dp screen a tile is (320 − 24 − 32) / 5 = 52.8px wide. Each tile's 4px side padding left 44.8px, so the 48px circle `Container` was laid out at 44.8×48.

## What Didn't Work
- **Using "Food" in the RED test.** After the height fix, the test still failed (22.56 against 32). flutter_test's default font (Ahem) draws every glyph as a square the size of the font. At 2×, `bodySmall` is 24px, so "Food" is about 98px wide against a 68.8px tile at the test's 400dp width. `FittedBox` was now shrinking it for width, not height. A two-letter label ("TV", 48px) fits the width, so only the tile height can shrink it. The square-glyph trait is also noted in [flutter-widget-test-and-device-verification-gotchas.md](../developer-experience/flutter-widget-test-and-device-verification-gotchas.md) section 2.
- **Confirming RED with a bare `git stash`.** That stashes the new test as well, so the "failing" run tests nothing. Stash only the production file: `git stash push lib/features/categories/widgets/category_picker.dart`, run the test, then `git stash pop`.

## Solution
Derive the tile height from the text scaler, hard-coding only the parts that don't scale (commit `a817d82`):

```dart
// Before
gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
  crossAxisCount: 5,
  mainAxisExtent: 88,
  crossAxisSpacing: 8,
  mainAxisSpacing: 8,
),

// After: 88px at 1x, 106px at 2x
gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
  crossAxisCount: 5,
  // Padding, icon and gap take 70px; the label row grows with
  // the text scale so a short label keeps its scaled size.
  mainAxisExtent: 70 + MediaQuery.textScalerOf(context).scale(18),
  crossAxisSpacing: 8,
  mainAxisSpacing: 8,
),
```

Drop the tile's horizontal padding. The grid's 8px `crossAxisSpacing` already separates tiles:

```dart
// Before: EdgeInsets.symmetric(horizontal: 4, vertical: 8)
padding: const EdgeInsets.symmetric(vertical: 8),
```

The label stays a one-line `FittedBox(fit: BoxFit.scaleDown, child: Text(label, maxLines: 1, softWrap: false))`. It now shrinks only when a label is too wide for its tile.

The tests in `test/widget/features/categories/category_picker_test.dart` check rendered sizes, not just the absence of an exception. `tester.getRect` returns the painted bounds after the `FittedBox` transform:

```dart
// P12
expense: [_c(id: 1, type: CategoryType.expense, customName: 'TV')],
textScaler: const TextScaler.linear(2),
...
expect(tester.getRect(find.text('TV')).height, closeTo(32, 0.5));

// P13, at Size(320, 640)
final circle = find.ancestor(of: find.byType(Icon), matching: find.byType(Container));
expect(tester.getSize(circle.first), const Size(48, 48));
```

P09 covers the width side. A long label ("Transportation") stays inside its `InkWell` tile and is no taller than a short one.

## Why This Works
A fixed `mainAxisExtent` is the grid version of a fixed `itemExtent`. AGENTS.md already warns that `itemExtent` breaks 2× text scale, and the perf audit rejected `itemExtent` and `prototypeItem` for the same reason. In a `ListView` the text clips or overflows, which an overflow test catches. Wrapped in `FittedBox`, it shrinks instead, which no overflow test catches. Making the label row's share of the extent come from `MediaQuery.textScalerOf(context)` gives the label the height it needs at any scale. `FittedBox` then only limits width, which is what the issue asked for.

The 320dp squeeze came from a fixed column count with fixed-size children. With five columns the tile width depends on the screen, so the padding has to fit the narrowest supported phone, not the test's default width.

## Prevention
- **Never hard-code the height of a grid tile, list row or box that contains `Text`.** Compute it as fixed parts + `MediaQuery.textScalerOf(context).scale(lineHeight)`.
- **Treat `FittedBox` around `Text` as width-only.** Add a test proving that height never limits it: render a short label at 2× and assert its rect height.
- **"No overflow" is not a text-scale test.** Assert a rendered size with `tester.getRect`, which includes `FittedBox` scaling.
- **Choose test strings that only one constraint can shrink.** Under Ahem, each character is as wide as the font size.
- **With a fixed `crossAxisCount`, check the tile width at 320dp** against every fixed-size child, such as icons and avatars.
- **In integration helpers, call `ensureVisible` before tapping.** `tester.tap` on an off-screen widget only prints a `warnIfMissed` warning. In `transaction_mutation_flow_test.dart`, `enterAmountAndFood` tapped a scrolled-off `CategoryChip`, the picker never opened, and `find.text('Food').last` matched the chip's own "Food" subtitle. The test passed by accident until commit `e40ea34` changed that subtitle to "Food · Expense":

  ```dart
  await tester.ensureVisible(find.byType(CategoryChip));
  await tester.tap(find.byType(CategoryChip));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Food').last);
  ```

  When a change edits visible text, re-check the finders that match that text.

## Related Issues
- GitHub issue #81. Commits `43fd03a` (five-per-row picker), `a817d82` (this fix) and `e40ea34` (category chip shows the type).
- The chip change in `e40ea34` happened because removing the form's Expense/Income toggle removed the only on-screen type indicator. The seeded expense and income categories are both named "Investment", so the chip now reads "Investment · Expense" or "Investment · Income".
- [flutter-widget-test-and-device-verification-gotchas.md](../developer-experience/flutter-widget-test-and-device-verification-gotchas.md): Ahem square glyphs (section 2) and 2× text scale with lazy lists (section 4).
- [flutter-performance-audit-riverpod-lifecycle-and-emit-path-fixes.md](../performance-issues/flutter-performance-audit-riverpod-lifecycle-and-emit-path-fixes.md): rejecting `itemExtent` and `prototypeItem` because they clip text at 2×.
- AGENTS.md, Performance rules: "Don't set `itemExtent` on rows that contain text".
- `docs/architecture/ui-and-layout.md`, Text scale: "All scrollable regions must survive 2× text scale."
