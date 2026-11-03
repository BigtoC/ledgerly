---
title: Animated fills that fade to Colors.transparent flash grey mid-transition
date: 2026-11-03
category: ui-bugs
module: analysis
problem_type: ui_bug
component: frontend_stimulus
symptoms:
  - "The Analysis period thumb (AnimatedContainer, 200 ms) blinks grey in the light theme on every period change"
  - "The summary tile tint and the search field fill and border pass through half-transparent grey when they fade"
  - "Mid-transition colour over the light track is about #B5B5B5, where the design's CSS transition never darkens"
  - "Widget tests passed because they pinned only the end value Color(0x00000000)"
root_cause: wrong_api
resolution_type: code_fix
severity: low
related_components:
  - testing_framework
tags: [flutter-color-lerp, animated-container, transparent-black, premultiplied-alpha, fade-transition, analysis, widget-test-mid-animation]
---

# Animated fills that fade to Colors.transparent flash grey mid-transition

## Problem

The Analysis page has three animated fills that faded between a colour token and transparent black (`Colors.transparent` / `const Color(0x00000000)`):

- the period selector's thumb (`lib/ui/features/analysis/charts/views/period_selector.dart`, `_PeriodSegment`)
- the summary card's type-tile tint (`lib/ui/features/analysis/charts/views/charts_summary_card.dart`, `_TypeTile`)
- the search field's fill and border (`lib/ui/features/analysis/views/analysis_search_field.dart`)

All three use an `AnimatedContainer` with a 200 ms transition (`AnalysisMotion.standardDuration`). Halfway through each transition the colour went grey, so the light theme showed a grey blink on every period change, tile switch, and search open or close. The design does not do this. It uses CSS `transition: background 200ms` to `transparent` (Main.dc.html), and that fade never darkens.

## Symptoms

- Light theme: when the period changes, the outgoing and incoming thumbs blink grey for about 200 ms over the `#EAEAEA` track. The summary tiles do the same when you switch between Expense and Income. So do the search field's fill and border when it opens or closes.
- Nothing threw and no test failed. The tests checked only the end colour, so they asserted `Color(0x00000000)` and locked the bug in.
- It was found by the Step 8 whole-page design/consistency review, not by any test.

## What Didn't Work

- **Pinning only the end state.** Asserts like `expect(off.color, const Color(0x00000000))` and `expect(income.color, Colors.transparent)` checked the value before and after the animation. The bug exists only in between, so these tests passed and also fixed the wrong colour in place.
- **Reading the `AnimatedContainer`'s `decoration` mid-animation.** In the summary card test, the first mid-transition check used the file's existing helper `_decorationOf`, which reads `tester.widget<AnimatedContainer>(find.byKey(key)).decoration`. That property is the animation's target, which is the end value, not the colour on screen. The test passed against the old, buggy code. A mid-animation test must read the `DecoratedBox` that `AnimatedContainer` builds internally.

## Solution

Fade to the same token at alpha 0 instead of transparent black. The fix is commit `5f96a17` on `feat/analysis-step8` ("fix(analysis): fade state fills to the token, not transparent black").

Before:

```dart
// period_selector.dart (_PeriodSegment)
color: selected ? colors.thumb : const Color(0x00000000),

// charts_summary_card.dart (_TypeTile)
color: selected ? tint : Colors.transparent,

// analysis_search_field.dart
color: expanded ? colors.card : const Color(0x00000000),
border: Border.all(
  color: expanded ? colors.line : const Color(0x00000000),
),
```

After:

```dart
// period_selector.dart (_PeriodSegment)
color: selected ? colors.thumb : colors.thumb.withValues(alpha: 0),

// charts_summary_card.dart (_TypeTile)
color: selected ? tint : tint.withValues(alpha: 0),

// analysis_search_field.dart
color: expanded ? colors.card : colors.card.withValues(alpha: 0),
border: Border.all(
  color: expanded ? colors.line : colors.line.withValues(alpha: 0),
),
```

The end-state tests now expect the alpha-0 token, for example `expect(off.color, c.thumb.withValues(alpha: 0))` and `expect(income.color, _c.incTint.withValues(alpha: 0))`. Each widget also gained a mid-transition test (see Prevention).

## Why This Works

Flutter's `Color.lerp` (in `painting.dart` in sky_engine) interpolates alpha, red, green and blue separately. It does not premultiply alpha. Transparent black (`0x00000000`) has RGB 0,0,0, so a fade from white (`#FFFFFF`, alpha 1) to it passes through `rgba(128,128,128,0.5)` at the halfway point. Over the light `#EAEAEA` track that renders at about `#B5B5B5`, which is the grey blink.

CSS interpolates in premultiplied space. There, a fully transparent endpoint adds no colour, so the fade only loses opacity and never darkens.

If both ends of the lerp have the same RGB and only alpha changes (`token` ↔ `token.withValues(alpha: 0)`), the RGB stays fixed for the whole animation. Only alpha moves, which matches the CSS result.

Other widgets on the page already followed this rule and showed no blink:

- `dimension_toggle.dart`: `colors.onBg.withValues(alpha: 0)`
- `chart_legend.dart`, `account_filter_sheet.dart`, `account_filter_button.dart`: `colors.sel.withValues(alpha: 0)`
- `selected_slice_items_list.dart`: `colors.card.withValues(alpha: 0)`

## Prevention

- **Rule:** an animated colour (`AnimatedContainer`, `ColorTween`, `AnimatedTheme`, a `BoxDecoration` or `Border` inside an implicit animation) must never use `Colors.transparent` or `Color(0x00000000)` as its "off" state. Use the "on" token at alpha 0: `token.withValues(alpha: 0)`. A static, non-animated transparent colour is fine.
- **Review check:** look for transparent black near implicit animations, for example:

  ```sh
  grep -rnE "Colors\.transparent|Color\(0x00000000\)" lib/ui
  ```

  For each hit inside an `AnimatedContainer`, `AnimatedFoo` or tween, replace it with the alpha-0 token.
- **Test the middle of the animation, not just the ends.** Pump half the duration, then read the rendered `DecoratedBox`, not `AnimatedContainer.decoration`, which holds the target or end value. Assert that alpha is strictly between 0 and 1 and that each RGB channel equals the token's:

  ```dart
  testWidgets('switching tiles fades each tint, never through grey', (
    tester,
  ) async {
    final container = await _pump(tester, _totals());
    container.read(chartsSelectionControllerProvider.notifier).toggleType();
    await tester.pump();
    await tester.pump(AnalysisMotion.standardDuration ~/ 2);

    for (final (tile, tint) in [
      (_expenseTile, _c.expTint),
      (_incomeTile, _c.incTint),
    ]) {
      // The rendered box, not the AnimatedContainer's target decoration.
      final box = tester.widget<DecoratedBox>(
        find
            .descendant(of: find.byKey(tile), matching: find.byType(DecoratedBox))
            .first,
      );
      final fill = (box.decoration as BoxDecoration).color!;
      expect(fill.a, inExclusiveRange(0, 1));
      expect(fill.r, closeTo(tint.r, 1e-6));
      expect(fill.g, closeTo(tint.g, 1e-6));
      expect(fill.b, closeTo(tint.b, 1e-6));
    }
  });
  ```

  The same pattern is in `test/widget/features/analysis/widgets/period_selector_test.dart` ("a switching thumb fades in the thumb colour, never grey"). It checks both the Week and Month segments through `segmentDecoration`, which finds the `DecoratedBox` ancestor of the label. It is also in `test/widget/features/analysis/analysis_screen_test.dart` ("opening search fades the fill and border, never grey"), which checks the fill and the border's top colour through `_searchBoxDecoration`, a `DecoratedBox` descendant of `AnalysisSearchField`.
- **Prove the test can fail.** A mid-animation assertion that passes against the old code is reading the wrong widget, as happened with the `_decorationOf` helper in `charts_summary_card_test.dart`. Run the new test against the transparent-black version once and make sure it fails before you keep it.

## Related Issues
- PR #128 (Step 8 whole-page review, finding F3/F15), commit `5f96a17`.
- [Category picker: fixed extent + FittedBox cancels text scale](category-picker-fixed-extent-fittedbox-cancels-text-scale.md) — same "assert what is rendered, not the configured value" testing rule.
- `lib/ui/features/accounts/views/account_form_screen.dart` has a static `selected ? primary : Colors.transparent` border; it does not animate today, but would flash if it ever became an `AnimatedContainer`.
