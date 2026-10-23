---
title: Flutter performance audit fixes — emit-path I/O loops, keepAlive family leaks, stale codegen hashes and unused asset packages
date: 2026-10-23
category: performance-issues
module: analysis
problem_type: performance_issue
component: frontend_stimulus
symptoms:
  - "The release build carried about 34 MB of `material_symbols_icons` fonts (about 15.6 MB compressed), though nothing in `lib/` imported the package"
  - "`ChartsController._emitIfReady` called `ExchangeRateRepository.refreshAll` on every emission; a partly successful fetch re-emitted `chartsFxStatus`, so the refresh looped (74 fetches in 100 ms in a test)"
  - "Each Analysis search detail opened kept its `watchByMemo` Drift subscription and its rows alive for the rest of the session (keepAlive family)"
  - "Tapping a slice in Year view built every drill-down row at once inside a `SingleChildScrollView`, and chart `debugPrint`s wrote grand totals to the release log"
  - "Edits inside a provider left the committed `.g.dart` with a stale riverpod_generator source hash"
root_cause: memory_leak
resolution_type: code_fix
severity: high
related_components:
  - charts_controller
  - charts_section
  - category_search_detail_controller
  - selected_slice_items_list
  - daily_bar_chart
  - money_formatter
  - exchange_rate_repository
  - pubspec
tags:
  - flutter
  - riverpod
  - performance
  - keepalive
  - autodispose
  - apk-size
  - code-generation
  - fl-chart
---

# Flutter performance audit fixes: emit-path I/O loops, keepAlive family leaks, stale codegen hashes and unused asset packages

## Problem

A Flutter performance audit covered rendering, memory, startup and package size. It confirmed the problems below and rejected 19 other findings (see What Didn't Work). The work is the commits after `03f3c45` on `perf/app-optimization`.

## Symptoms

- **FX fetch loop.** One test used EUR and TWD transactions with a fake service that returns only EUR, so TWD never gets a rate. `ExchangeRateService.fetchRates` was called 74 times in 100 ms.
  - The cost was not limited to Analysis. `ChartsController` is keepAlive and listens to `chartsFxStatus`, so once Analysis had loaded, the loop kept making network round trips and Drift upserts while other tabs were showing, until the app was killed.
  - It needs a *partly* successful fetch. When a fetch fails completely (offline), nothing is upserted and nothing re-emits.
- **Leaked detail controllers.** Every search-detail screen opened (keyed by `(categoryId, query, currencyCode)`) left its notifier, its cached list and a live `watchByMemo` Drift query running until the app restarted.
- **StateError after the first lifecycle fix.** Tapping Undo on the still-visible SnackBar after the commit window threw `StateError: Bad state: Cannot add event after closing`.
- **Payload bloat.** The release `flutter_assets` was 34,652 KB. Almost all of it was the Outlined, Rounded and Sharp `material_symbols_icons` fonts, yet nothing in `lib/` or `test/` imported the package.
- **Totals in release logs.** Release logcat showed lines like `[ChartsController] … grand=$grandTotal excluded=…`.

## What Didn't Work

- **A requested-currency set that was never cleared.** The plan kept `_refreshRequested` across `build()` and cleared it only when the default currency changed or on `retry()`. `refreshAll` swallows errors, so a fetch that failed once was never tried again. Most of the states this leads to have no Retry button. The per-commit reviewer caught it.
- **An autoDispose conversion with no dispose guard.** The first switch from `keepAlive: true` to autoDispose plus a `KeepAliveLink` left `_emitter` pointing at the closed `StreamController`.
  - On Flutter 3.47, a `SnackBar` with an `action` defaults to `persist: true` (`persist ?? action != null`), so Undo stays tappable after the 4 s commit has disposed the provider.
  - Tapping it ran `undoDelete()` → `_emitFromCache()` → `_emitter.add`, which threw.
- **A "Show N more" label that counted every hidden row.** The label used the full remaining count, but each tap reveals only 50, so 300 rows read "Show 250 more" and then showed 50. It now counts `min(50, remaining)`.
- **Skipping build_runner after edits that changed no annotation.** CI regenerates code before analysis, so nothing failed, but the committed `.g.dart` hashes were stale at those commits.
- **The audit rejected 19 findings as premature or wrong.** The main ones are below. Don't revive them without profiling evidence.
  - **Splitting the transaction-form keypad or the Home/Pending roots into `select()`-scoped widgets.** The rebuilds cost under 1 ms, and the root is rebuilt by the `homeController` watch anyway.
  - **Running the preference reads before `runApp` in parallel.** The saving is sub-millisecond, and those reads prevent theme, locale and splash flashes ([m4-app-shell-first-frame-hydration](../logic-errors/m4-app-shell-first-frame-hydration-2026-04-23.md)).
  - **Adding Drift indexes.** The date, account and category indexes already exist.
  - **Adding R8 or resource-shrinking Gradle flags.** Flutter's `FlutterPlugin.kt` already turns both on for release builds.
  - **Setting `itemExtent` or `prototypeItem`.** Either one clips text at the required 2× text scale.
  - **Setting `cacheWidth` on the splash image.** It is about screen resolution under `BoxFit.cover`, so a smaller decode would blur it.
  - **Using deferred components.** They need Play Feature Delivery, and our APKs ship through GitHub Releases.
  - **Also rejected:** the random box-shadow colour (a deliberate design choice), `Opacity` on recurring rows, N+1 streams on Accounts (indexed, and run on a background isolate), bucketing in Dart (under 1 ms), and `--split-debug-info` (marginal).

## Solution

### 1. Request missing FX rates once per attempt (`charts_controller.dart`, `43b1bc1`)

```dart
final Set<String> _refreshRequested = {};
String? _refreshRequestedFor;

// in _emitIfReady — before: `if (missingRate) unawaited(repo.refreshAll(...));`
if (fx.defaultCurrencyCode != _refreshRequestedFor) {
  _refreshRequestedFor = fx.defaultCurrencyCode;
  _refreshRequested.clear();
}
final toRequest = missingCurrencies.difference(_refreshRequested);
if (toRequest.isNotEmpty) {
  _refreshRequested.addAll(toRequest);
  final repo = ref.read(exchangeRateRepositoryProvider);
  unawaited(repo.refreshAll(fx.defaultCurrencyCode));
}
```

The set is also cleared in `build()`, which re-runs on each selection change, and in `retry()`.

### 2. Keep the search-detail family alive only while an undo is pending (`category_search_detail_controller.dart`, `76f15f5`)

```dart
import 'package:flutter_riverpod/misc.dart' show KeepAliveLink; // not re-exported by riverpod_annotation

@Riverpod(dependencies: [transactionRepository, AnalysisController]) // was keepAlive: true
class CategorySearchDetailController extends _$CategorySearchDetailController {
  KeepAliveLink? _undoLink;

  Future<void> deleteTransaction(int id) async {
    // ...
    _pendingDelete = CategorySearchPendingDelete(transaction: tx);
    _undoLink ??= ref.keepAlive(); // held only while the undo is pending
    // ...
  }

  // Called from undoDelete() and both _commitDelete branches.
  void _releaseUndoLink() {
    _undoLink?.close();
    _undoLink = null;
  }
}
```

In `build()`, calls that arrive after dispose become no-ops:

```dart
final controller = StreamController<CategorySearchDetailState>();
_emitter = controller;
ref.onDispose(() {
  // ...cancel timer and subscription, `_undoLink = null`...
  if (identical(_emitter, controller)) _emitter = null; // late undoDelete becomes a no-op
  _lastTransactions = null;
  controller.close();
});
```

The link is only forgotten here, not closed, because a rebuild or dispose already drops the old Ref's links.

### 3. Regenerate code at every commit after the fact

```sh
git rebase <base> --exec 'dart run build_runner build --delete-conflicting-outputs >/dev/null 2>&1 \
  && git add -u -- "*.g.dart" \
  && (git diff --cached --quiet || git commit -q --amend --no-edit)'
```

If a later commit also touched that `.g.dart`, the rebase stops on a conflict. In that case re-run build_runner, `git add` the file, then run `git rebase --continue`.

Each commit was then checked out in a temporary worktree. At every commit build_runner left no diff, and format, analyze and the tests were clean.

### 4. Drop the unused asset-bearing dependency (`d52a007`)

Removing `material_symbols_icons` took `flutter_assets` from 34,652 KB to 896 KB. Compressed with `zip -9`, the payload went from 21.7 MB to 6.1 MB.

### 5. Smaller fixes

- **No totals in release logs (`98fc15c`).** `debugPrint` is not compiled out of release builds, so the trace logs were deleted. Error paths now log `${e.runtimeType}` only.
- **Drill-down capped at 50 rows (`e6698e3`, plus a label fix).**
  - Rows render through `data.rows.take(_visibleCount)`, followed by a "Show N more" button where N is `min(50, remaining)`.
  - `didUpdateWidget` resets the count when `slice.selectionKey` changes, because the parent `Builder` does not key the widget.
  - This caps the widget tree only. `SliceDrilldownController` still loads every row of the slice, and each tap grows the same non-lazy `Column`.
- **Chart repaints isolated (`f0cde36`).**
  - `RepaintBoundary` wraps `CategoryPieChart` and `DailyBarChart`, because fl_chart adds no boundary of its own.
  - `DailyBarChart.touchCallback` calls `setState` only when the touched bar changes.
  - The repaint gain was not profiled.
- **`NumberFormat` reuse (`0701c52`).** `MoneyFormatter` caches its formats by `(locale, symbol, decimals)`. Measured at 1.34 µs → 0.49 µs per call, which is about 40 µs per build for 50 rows. That is hygiene, not a hot-path fix.
- **Duplicate splash images (`325c624`).** The light and dark splash entries pointed at the same PNG, and flutter_native_splash copies each entry separately. Dropping the dark entries removed three 704 KB copies.

## Why This Works

- **FX loop.** Each rate upsert re-emits `chartsFxStatus`, which reaches the controller through `ref.listen` and calls `_emitIfReady` again. Any currency the service never returns re-triggered `refreshAll`, and every partial success upserted again.
  - Recording what has been requested, scoped to the current default currency, breaks the loop.
  - Clearing the record in `build()` is safe as long as no selection change *caused by an emission* can repeat without bound. Two such paths exist today, and each costs at most one extra request:
    - `ChartsSection` calls `clearSlice()`, which returns early once the slice is already null.
    - The currency auto-switch is gated by `_autoSwitchedToCurrency`.
  - Keep that invariant whenever you add a selection change driven by an emission.
  - The tradeoff is that each period swipe or slice tap while offline fires one new `refreshAll`. That is bounded by user actions.
- **Family leak.** A `keepAlive` family keeps one instance alive per argument tuple for the whole session.
  - AutoDispose ties each instance to its screen. Holding a `KeepAliveLink` only while an undo is pending keeps Undo and the delayed commit working after the screen pops.
  - Taking a new link right after `_commitDelete` releases one is safe. Riverpod schedules autoDispose (Timer(0) or vsync) and re-checks links before it disposes.
  - The `identical` check stops a rebuild from clearing the new build's emitter.
- **Stale `.g.dart`.** riverpod_generator embeds `sha1` of the annotated provider's source, with comments excluded, for hot-reload detection.
  - Any non-comment edit inside the provider therefore changes the expected `.g.dart`.
  - A stale hash has no runtime or performance effect. It only leaves the committed history inconsistent.
- **Font bloat.** Flutter bundles every font a dependency declares under `flutter: fonts:`. The icon tree shaker subsets only fonts referenced by `IconData` constants and ships every other font in full, so the only fix is to remove the dependency.

## Prevention

- Follow `## Performance rules` in AGENTS.md (`a218ad2`).
- Run `dart run build_runner build --delete-conflicting-outputs` before every commit that touches a file with a `part '*.g.dart'`, even when no annotation changed. Use the rebase sweep in Solution §3 to clean up afterwards.
- **When testing a locale-keyed cache, pick locales whose output differs.** en and zh_TW both render `1,234.56`, so the `MoneyFormatter` test alternates en_US and de_DE.
- Check size when adding a dependency or asset. Run `flutter build apk --analyze-size`. Without a signing key, inspect `build/app/intermediates/flutter/release/flutter_assets` instead.
- **Regression tests:**
  - `charts_controller_test.dart`: "requests missing rates once, not on every FX re-emission".
  - `category_search_detail_controller_test.dart`:
    - "disposes and cancels the repo subscription once unlistened"
    - "pending delete outlives its last listener, commits, then disposes"
    - "undoDelete after the commit disposed the provider is a no-op"
  - `selected_slice_items_list_test.dart`:
    - "caps rendered rows at 50 behind a Show more button"
    - "switching to another slice resets the cap to 50"
  - `daily_bar_chart_test.dart`: "moving within the touched bar does not rebuild the chart".
  - `money_formatter_test.dart`: the "cached formats stay locale-specific" group.
- **Open follow-up.** Because of `persist: true`, an Undo SnackBar stays visible after its delete has committed, and tapping it then does nothing. This predates the work above and affects both the search-detail and drill-down undo flows. Consider setting `persist: false` on undo SnackBars, or hiding them when the commit fires.

## Related Issues

- [riverpod-cross-provider-dependencies-assertion](../runtime-errors/riverpod-cross-provider-dependencies-assertion-2026-05-10.md): added the `keepAlive: true` that this work reverses. Its regeneration rule is widened here.
- [analysis-slice-drilldown-delete-guards-fx-alignment](../logic-errors/analysis-slice-drilldown-delete-guards-fx-alignment-2026-05-22.md): the same chart, drill-down and FX stack.
- [home-delete-undo-stream-coordination](../logic-errors/home-delete-undo-stream-coordination-2026-04-26.md): the original undo-window pattern that this lifecycle extends.
- [home-pending-recurring-approval-visibility-and-undo-coordination](../logic-errors/home-pending-recurring-approval-visibility-and-undo-coordination-2026-05-09.md): why `keepAlive` stays correct for a controller that is not a family.
- [m4-app-shell-first-frame-hydration](../logic-errors/m4-app-shell-first-frame-hydration-2026-04-23.md): why the reads `bootstrap()` makes before `runApp` stay.
- [reactive-feature-flow-ownership](../best-practices/reactive-feature-flow-ownership-2026-04-25.md): the general ownership pattern between Riverpod and the repositories.
- No related GitHub issues.
