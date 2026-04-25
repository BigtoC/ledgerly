---
title: Deterministic splash golden harness across local and GitHub Actions runners
date: 2026-04-25
category: test-failures
module: splash-golden-tests
problem_type: test_failure
component: testing_framework
symptoms:
  - Splash goldens passed locally but failed only on GitHub Actions Ubuntu with small pixel diffs.
  - `splash_default_en_100d.png`, `splash_custom_zhtw.png`, and `splash_long_text_2x.png` all failed in CI.
  - The remaining diffs were concentrated in rasterized areas like the bottom button, not broken layout structure.
root_cause: test_isolation
resolution_type: test_fix
severity: medium
related_components:
  - github-actions
  - mediaquery
  - splash-screen
tags: [flutter, golden-test, github-actions, mediaquery, safe-area, device-pixel-ratio, splash]
---

# Deterministic splash golden harness across local and GitHub Actions runners

## Problem

The splash screen golden tests were inheriting runner-specific rendering state from the widget-test environment. They passed locally but failed on GitHub Actions Ubuntu because the harness was not fully deterministic.

## Symptoms

- `test/widget/features/splash/splash_screen_golden_test.dart` passed locally but failed only in GitHub Actions.
- CI reported small pixel diffs instead of full visual breakage: roughly 0.10% to 4.96% depending on the variant and attempted fix state.
- The failure images showed the most stable structural regions matching while rasterized details like button edges and text blocks drifted.

## What Didn't Work

- Treating the original failures as generic cross-platform font noise did not identify the actual harness leaks.
- Replacing only `MediaQuery.of(context).copyWith(...)` with a fresh `MediaQueryData(...)` fixed inherited safe-area padding, but it did not remove the remaining CI drift.
- Forcing a canonical Material platform in the `MaterialApp` theme or by test variants did not eliminate the residual diffs, because the strongest remaining differences were tied to renderer inputs rather than the splash widget's logical layout.

## Solution

The fix was to make the golden harness explicitly deterministic in the two places the splash tests were leaking runner state:

1. Stop inheriting ambient `MediaQuery` values.
2. Pin the test view device pixel ratio for each golden case.

The harness now creates a fresh `MediaQueryData` instead of copying the ambient one:

```dart
builder: (context, child) => MediaQuery(
  data: MediaQueryData(
    size: size,
    textScaler: textScaler ?? TextScaler.noScaling,
  ),
  child: child!,
),
```

Each golden test also pins the test view DPR:

```dart
await tester.binding.setSurfaceSize(const Size(390, 844));
addTearDown(() => tester.binding.setSurfaceSize(null));
tester.view.devicePixelRatio = 1.0;
addTearDown(tester.view.resetDevicePixelRatio);
```

A regression test was added to prove the harness no longer leaks ambient safe-area padding:

```dart
tester.view.padding = const FakeViewPadding(top: 32, bottom: 20);
tester.view.viewPadding = const FakeViewPadding(top: 32, bottom: 20);

await tester.pumpWidget(harness(container: container));

final mediaQuery = MediaQuery.of(tester.element(find.byType(SplashScreen)));
expect(mediaQuery.padding, EdgeInsets.zero);
expect(mediaQuery.viewPadding, EdgeInsets.zero);
```

Verified with:

```bash
flutter test test/widget/features/splash/splash_screen_golden_test.dart --reporter expanded
flutter test test/widget/features/splash --reporter expanded
```

## Why This Works

The splash widget uses gradients, shadows, and rounded button edges, so small renderer differences matter. The original harness still inherited ambient view state from the test runner, and the golden cases also relied on the default test-view device pixel ratio. That meant the same logical widget tree could rasterize slightly differently between local runs and GitHub Actions.

Resetting `MediaQuery` to a fresh value removes inherited safe-area padding and view padding. Pinning `tester.view.devicePixelRatio` removes the remaining renderer-dependent input that was changing the final pixels. With both values fixed, the checked-in goldens match again without changing the splash UI itself.

## Prevention

- Do not build golden harnesses from `MediaQuery.of(context).copyWith(...)` when the snapshot must be runner-independent.
- Pin `tester.view.devicePixelRatio` in goldens that include gradients, shadows, anti-aliased rounded shapes, or other rasterization-sensitive visuals.
- When a golden fails only in CI with a small diff percentage, inspect whether the mismatch is concentrated in painted edges or shadows before changing production widgets.
- Add harness-level regression tests for ambient environment leaks so future golden files start from a known baseline.

## Related Issues

- `docs/solutions/logic-errors/m4-app-shell-first-frame-hydration-2026-04-23.md`
- `docs/plans/m5-ui-feature-slices/wave-1/splash-plan.md`
