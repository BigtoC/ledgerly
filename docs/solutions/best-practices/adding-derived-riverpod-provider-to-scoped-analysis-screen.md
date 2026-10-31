---
title: Adding a derived Riverpod provider to the scoped Analysis screen
date: 2026-10-30
category: best-practices
module: analysis
problem_type: best_practice
component: frontend_stimulus
severity: medium
applies_when:
  - "A new provider reads scoped providers (declared with dependencies) and is rendered under ChartsSection or AnalysisScreen"
  - "A @riverpod provider file calls ref.watch(xProvider.select(...)) but imports only riverpod_annotation"
  - "A sync provider derives from an AsyncValue via .value and must not show stale data after an error"
  - "A widget colors amounts green/pink on colorScheme.surfaceContainer in light and dark themes"
  - "A repository method or ARB key is added while existing tests mock the repository with mocktail"
symptoms:
  - "dart analyze reports provider_dependencies Missing dependencies in router.dart and 8 test files, one level at a time"
  - "The method 'select' isn't defined for the type 'ChartsSelectionControllerProvider'"
  - "The argument type 'Object?' can't be assigned to the parameter type 'DateTime'"
  - "After a failed query the net box kept showing the previous period's net"
  - "arb_audit_test fails with app_en.arb has keys not in plan §5"
root_cause: wrong_api
resolution_type: code_fix
related_components:
  - charts_net_total_provider
  - charts_net_total_card
  - charts_section
  - router
  - arb_audit_test
tags:
  - flutter
  - riverpod
  - riverpod-lint
  - scoped-providers
  - async-value
  - wcag-contrast
  - mocktail
  - analysis-charts
---

# Adding a derived Riverpod provider to the scoped Analysis screen

## Context

The Analysis charts screen gained a small "Net" box above the pie chart: income minus expense for the period picked in the time picker, recalculated whenever the period changes, green when positive and pink when negative. Its data comes from scoped providers (`ChartsSelectionController` is declared `dependencies: []`; `transactionRepository`, `chartsFxStatus` and `chartsCurrenciesByCode` are scoped too).

The feature itself was two new files — `lib/features/analysis/charts/charts_net_total_providers.dart` (`chartsNetByCurrency` → `chartsNetTotal`) and `widgets/charts_net_total_card.dart` — plus a repository method (`TransactionRepository.watchNetByCurrencyInRange`). Getting it to pass CI surfaced the issues below; all were caught by the analyzer, tests or review before merge. (When every currency in the period lacks an FX rate, the box shows `—` plus the "Excluded: …" caption rather than a converted `$0.00`.)

## Guidance

### 1. Expect the `@Dependencies` cascade and loop the analyzer

A provider that depends on scoped providers must declare `dependencies:`, and riverpod_lint's `provider_dependencies` then requires every `@Dependencies([...])` that can reach it to name it:

1. **The consuming widget** — `ChartsNetTotalCard` → `@Dependencies([chartsNetTotal])`.
2. **Parent widgets, by convention only** — `ChartsSection` and `AnalysisScreen` mirror their children's providers (as they already do for `SliceDrilldownController`). The lint does *not* require this.
3. **`lib/app/router.dart`** — the `router` provider's `dependencies:` list; regenerate `router.g.dart`.
4. **Test `main()`s and top-level test helpers** whose lists reach the screen (`_harness`, `_detailRouter`, `_pumpChartsSection`, a `_settle` helper in a provider test).
5. **A second wave** — once a helper's list is fixed, the lint flags the *callers* of that helper. These only appear on the next analyze pass.

`dart fix --apply` reports "Nothing to fix!", so the edits are manual. Add the entry after `chartsFxStatus,` plus the import, then loop:

```bash
dart run build_runner build --delete-conflicting-outputs
dart analyze --fatal-infos   # repeat until "No issues found!"
```

The analysis tests in this repo satisfy the lint with `@Dependencies` on `main()`/helpers. `ProviderContainer` + `UncontrolledProviderScope` (see the in-app APK update doc below) is the alternative when a test cannot carry the annotation.

### 2. `select` inside a provider file needs the `flutter_riverpod` extension import

`riverpod_annotation` does not export `ProviderListenableSelect`, and the record type does not infer through `select`, so type the pattern explicitly:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show ProviderListenableSelect;
import 'package:riverpod_annotation/riverpod_annotation.dart';
// ...
final (PeriodType period, DateTime anchorDate) = ref.watch(
  chartsSelectionControllerProvider.select((s) => (s.period, s.anchorDate)),
);
final start = normalizeAnchor(anchorDate, period); // needs the typed record
```

Without the import: "The method 'select' isn't defined for the type 'ChartsSelectionControllerProvider'" — it looks like stale codegen but is not. Without the types: "The argument type 'Object?' can't be assigned to the parameter type 'DateTime'".

Selecting only `(period, anchorDate)` also means Expense/Income, dimension and pie-slice changes do not re-run the query (a test counts repository calls after `toggleType()` / `setDimension()`).

### 3. Riverpod 3 `.value` keeps previous data on error — check `hasError`

In Riverpod 3, `.value` (the old `valueOrNull`) returns the last data during `AsyncLoading` — wanted here, so the box does not flicker while the period slides — **and during `AsyncError`**, which would leave the previous period's number under the new period's label. A derived sync provider must check explicitly:

```dart
final netAsync = ref.watch(chartsNetByCurrencyProvider);
if (netAsync.hasError) return null; // don't show last period's net
final byCurrency = netAsync.value; // previous value kept while loading
```

Without the guard: week N loads +$1.00, the user taps Previous, the query errors, `.value` is still `{'USD': 100}`, and the card shows +$1.00 under week N−1 (test: "hides the previous period net when the new query fails").

### 4. Pick per-theme shades that meet WCAG AA

The light `surfaceContainer` (grey800 seed, ~tone 94) is too light for the accent colours. `titleLarge` at w600 is not WCAG "large text", so 4.5:1 applies (PRD: "WCAG AA contrast for all text").

| Colour | Light (on surfaceContainer) | Dark |
|---|---|---|
| `Colors.pinkAccent` | 2.87:1 ✗ | 4.90:1 ✓ |
| `Colors.pink.shade700` | ~5.1:1 ✓ | – |
| `Colors.green.shade800` | 4.41:1 ✗ | – |
| `Colors.green.shade900` | ~6.8:1 ✓ | – |
| `Colors.green.shade400` | – | 6.90:1 ✓ |

```dart
final isDark = theme.brightness == Brightness.dark;
final color = switch (minor) {
  final m? when m > 0 =>
    isDark ? Colors.green.shade400 : Colors.green.shade900,
  final m? when m < 0 => isDark ? Colors.pinkAccent : Colors.pink.shade700,
  _ => theme.colorScheme.onSurface,
};
```

### 5. Stub new repository methods where the widget matters

Existing analysis tests use `class _MockTxRepo extends Mock implements TransactionRepository {}`. An unstubbed `watchNetByCurrencyInRange` returns `null` → `TypeError` inside the provider → `AsyncError` → the card renders `SizedBox.shrink()`. Those suites stay green but never render the new widget, so any test meant to cover it must stub the method.

### 6. Register new ARB keys in the audit test

`test/unit/l10n/arb_audit_test.dart` keeps a registry of allowed keys and fails with "app_en.arb has keys not in plan §5". Add the key next to its group (`'chartsNetTotal',` after `'chartsExcludedCurrencies',`), add `app_zh_CN.arb` / `app_zh_TW.arb` entries (`app_zh.arb` is a shim), then `flutter gen-l10n`.

### 7. Keep period tests off the wall clock and DST

- Don't compute the expected anchor from `DateTime.now()` in the test — it can disagree with the controller's `now` across a week boundary. Key the mock on the first queried range:
  ```dart
  DateTime? firstStart;
  ...thenAnswer((inv) {
    final start = inv.namedArguments[#start] as DateTime;
    firstStart ??= start;
    return Stream.value({'USD': start == firstStart ? 3000 : -700});
  });
  ```
- Don't assert range length with `.inDays`: a spring-forward week is 167 h, so `inDays` is 6. Compare calendar dates: `DateTime(w.year, w.month, w.day + 7)`.

### 8. Re-announce the final footprint when another agent shares the screen

Because of the §1 cascade, re-send the final changed-file list to any agent working on the same screen once the analyzer is clean; when resolving a conflicting test file, add the new provider to *every* `@Dependencies` list in the merged layout.

### Known limitation (left on purpose)

`ChartsController._emitIfReady` requests missing FX rates only for currencies in the current Expense/Income view. The net covers both, so a currency present only on the other side with no cached rate stays in the "Excluded: …" caption until the user switches type, restarts, or changes the default currency. Fixing it means a de-duplicated refresh in `ChartsController` that also covers `chartsNetByCurrency`'s currencies; deferred because it needs an offline save plus a same-session reconnect, and AGENTS.md warns against network calls from recompute paths.

## Why This Matters

- **The cascade is invisible at planning time.** A change scoped as "two hunks in one file" touched 12 files, which changes merge-conflict risk and what a concurrent agent must be told.
- **Stale `.value` fails silently.** The UI shows a confident, wrong number for the selected period; no test fails unless the error path is written.
- **Contrast failures hide in dark-mode development** and break a PRD requirement.
- **Unstubbed mocks overstate coverage** — the suite is green while the widget never renders in it.
- **`now`/`inDays` period tests fail only near week boundaries or in DST weeks**, which makes them hard to reproduce.

## When to Apply

- Adding any provider that reads a scoped provider to a screen reachable from `router`.
- Deriving a sync provider from an `AsyncValue` in Riverpod 3, especially one whose input re-queries on a user selection.
- Using `.select(...)` inside a `@riverpod` provider file.
- Colouring signed amounts on a `surfaceContainer` background.
- Adding a repository method that existing mocktail-based widget tests mock, or a new ARB key.
- Writing tests for period / week / month range logic.

## Examples

**Lint cascade output** — first pass after adding the provider:
```
warning - lib/app/router.dart - Missing dependencies: chartsNetTotal - provider_dependencies
warning - test/integration/analysis_drilldown_test.dart - Missing dependencies: chartsNetTotal - provider_dependencies
... (11 issues)
```
Second pass, after fixing those, flags the callers of the fixed test helpers:
```
warning - test/widget/features/analysis/analysis_screen_test.dart - Missing dependencies: chartsNetTotal - provider_dependencies
```

Snippets for the `select`, `.value`, colour and test-clock cases are in Guidance §2–§4 and §7.

## Related

- `docs/solutions/runtime-errors/riverpod-cross-provider-dependencies-assertion-2026-05-10.md` — the runtime side of the same scoping contract (a provider missing a dependency inside its own `dependencies:`); this doc covers the static lint cascade into widgets, router and tests.
- `docs/solutions/logic-errors/transaction-search-analysis-regressions-2026-05-10.md` — earlier rule to check `hasError` before `.value` in Analysis search.
- `docs/solutions/logic-errors/analysis-slice-drilldown-delete-guards-fx-alignment-2026-05-22.md` — same `chartsFxStatusProvider`; totals must come from the displayable FX subset.
- `docs/solutions/architecture-patterns/android-in-app-apk-self-update-packageinstaller-session.md` — `ProviderContainer` + `UncontrolledProviderScope` as the other way to satisfy `scoped_providers_should_specify_dependencies` in tests.
- GitHub issue #73 (period-aware calendar picker on the Analysis page) touches the same time-picker UI.
