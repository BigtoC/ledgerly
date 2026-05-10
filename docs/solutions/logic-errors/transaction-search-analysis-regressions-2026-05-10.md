---
title: Transaction search analysis regressions around metadata readiness and detail reuse
date: 2026-05-10
category: logic-errors
module: analysis
problem_type: logic_error
component: frontend_stimulus
symptoms:
  - Search results emitted `AnalysisEmpty` while category metadata was still loading.
  - Category metadata stream failures were hidden as empty search results instead of surfacing an error.
  - `CategorySearchDetailController` compile-broke after trying to reuse shared analysis state through a non-existent provider API.
  - Stale loading result rows needed explicit non-interactive coverage to prevent accidental navigation assumptions.
  - Invalid analysis-detail route params needed to keep redirecting back to `/analysis`.
root_cause: logic_error
resolution_type: code_fix
severity: high
related_components:
  - analysis_controller
  - category_search_detail_controller
  - analysis_screen
  - router
  - analysis_controller_test
tags:
  - flutter
  - riverpod
  - analysis
  - transaction-search
  - category-metadata
  - router
  - regression-test
  - async-state
---

# Transaction search analysis regressions around metadata readiness and detail reuse

## Problem

The Analysis search flow regressed once the controller and detail page started depending on both memo-match transactions and category metadata at the same time. Matching transactions could be treated as "no results" before metadata was ready, metadata failures could disappear behind empty-state UI, and the detail controller's shared-state reuse path was wired to a Riverpod API that does not exist for this provider.

## Symptoms

- `AnalysisController` emitted `AnalysisEmpty` for a non-empty search while `analysisCategoriesByIdProvider` was still loading.
- Category metadata stream errors were silently flattened into `{}` and never surfaced to the UI as an error state.
- `CategorySearchDetailController` failed to compile because it tried to call `analysisControllerProvider.stream` and pattern-match Freezed states without importing the matching state types.
- The stale-loading tile regression test produced hit-test warnings and `pumpAndSettle` timeouts until it asserted the real contract: loading rows are wrapped in `IgnorePointer` and must not navigate.
- Invalid `/analysis/search/:categoryId` params still needed real-router coverage to prove they redirect back to `/analysis`.

## What Didn't Work

- Treating `ref.read(analysisCategoriesByIdProvider).valueOrNull ?? const <int, Category>{}` as a safe fallback in `lib/features/analysis/search/analysis_controller.dart`. That erased the difference between metadata still loading, metadata failing, and metadata genuinely containing no matching categories.
- Trying to reuse active analysis state through `analysisControllerProvider.stream` in `lib/features/analysis/search/category_search_detail_controller.dart`. That surface is not exposed by this generated provider, so the code compile-broke before the behavioral tests could even run.
- Using `pumpAndSettle()` after tapping a stale loading tile. The tap was correctly ignored, so the test was waiting on the wrong signal and timing out noisily instead of checking that navigation never happened.

## Solution

Make metadata readiness a first-class part of the Analysis controller state instead of defaulting it away.

In `lib/features/analysis/search/analysis_controller.dart`:

```dart
final categoriesAsync = ref.read(analysisCategoriesByIdProvider);
if (categoriesAsync.hasError) {
  _emitter?.addError(
    categoriesAsync.error!,
    categoriesAsync.stackTrace ?? StackTrace.current,
  );
  return;
}

final categoriesById = categoriesAsync.valueOrNull;
if (categoriesById == null) {
  _emitter?.add(
    AnalysisState.loading(query: query, previous: _lastResults),
  );
  return;
}

_emitGroupedState(txs, categoriesById, query);
```

The category-listener path now follows the same contract: if metadata errors, forward the error; if metadata is still loading and there are already matching transactions, keep the controller in `AnalysisLoading(previous: ...)`; only emit grouped results when both streams are ready.

In `lib/features/analysis/search/category_search_detail_controller.dart`, reuse active Analysis state only when it already exists and is settled for the same query; otherwise fall back to the repository stream:

```dart
if (ref.exists(analysisControllerProvider)) {
  final analysis = ref.read(analysisControllerProvider);
  final state = analysis.valueOrNull;
  final matchesActiveQuery = switch (state) {
    AnalysisLoading(:final query) => query == trimmed,
    AnalysisResults(:final query) => query == trimmed,
    AnalysisEmpty(:final query) => query == trimmed,
    _ => false,
  };

  if (matchesActiveQuery && state is! AnalysisLoading) {
    final all = ref.read(analysisControllerProvider.notifier).lastTransactions;
    if (all != null) {
      return Stream.value(
        _buildState(
          all: all,
          categoryId: categoryId,
          currencyCode: trimmedCurrencyCode,
        ),
      );
    }
  }
}

return repo.watchByMemo(trimmed).map(
  (all) => _buildState(
    all: all,
    categoryId: categoryId,
    currencyCode: trimmedCurrencyCode,
  ),
);
```

That preserves the single-source-of-truth behavior for in-flow drill-downs without breaking standalone tests or direct-entry routes that have no live `AnalysisController` state yet.

The test harnesses were updated to match the real contracts:

- `test/unit/controllers/analysis_controller_test.dart` now locks in metadata-loading and metadata-error behavior.
- `test/unit/controllers/category_search_detail_controller_test.dart` still proves the repository fallback path.
- `test/widget/features/analysis/analysis_screen_test.dart` verifies stale loading rows do not navigate by tapping with `warnIfMissed: false` and checking the route stays put.
- `test/widget/features/analysis/category_search_detail_screen_test.dart` verifies the detail page reuses the active analysis search when available.
- `test/unit/app/router_test.dart` exercises the real router and confirms invalid Analysis detail params redirect to `/analysis`.

## Why This Works

The fixed code stops flattening three distinct states into one:

- transactions found + metadata loading
- transactions found + metadata error
- transactions found + metadata ready

That keeps the UI honest about whether search results are still resolving, genuinely empty, or actually broken. The detail controller also now reuses shared state only through APIs Riverpod really exposes, which removes the compile-time failure and keeps the fallback behavior intact for standalone detail consumers.

## Prevention

- Do not replace `AsyncValue` loading or error states with default containers when downstream behavior depends on the difference.
- If two controllers derive the same filtered/grouped view, keep the transformation in one helper or one clearly mirrored path so they cannot drift on edge cases.
- Guard any provider-state reuse with `ref.exists(...)` when the reused provider may not be initialized in every entry path.
- In widget tests for intentionally ignored taps, assert the non-navigation contract directly instead of relying on `pumpAndSettle()` timeouts.
- Keep regression coverage for:
  - non-empty search while category metadata is still loading
  - category metadata error propagation
  - detail reuse of active analysis state vs repository fallback
  - stale loading rows remaining non-interactive
  - invalid Analysis detail params redirecting to `/analysis`

## Related Issues

- `docs/solutions/best-practices/reactive-feature-flow-ownership-2026-04-25.md` — broader guidance on router-owned navigation and reactive state ownership
- `docs/solutions/test-failures/analysis-manage-accounts-review-followups-2026-05-05.md` — nearby Analysis-area review fallout and stale route/l10n drift
- Verified with:
  - `"/Users/bigtochan/flutter/flutter/bin/flutter" test "test/unit/controllers/analysis_controller_test.dart"`
  - `"/Users/bigtochan/flutter/flutter/bin/flutter" test "test/widget/features/analysis/analysis_screen_test.dart"`
  - `"/Users/bigtochan/flutter/flutter/bin/flutter" test "test/widget/features/analysis/category_search_detail_screen_test.dart"`
  - `"/Users/bigtochan/flutter/flutter/bin/flutter" test "test/unit/controllers/category_search_detail_controller_test.dart"`
  - `"/Users/bigtochan/flutter/flutter/bin/flutter" test "test/unit/app/router_test.dart"`
  - `"/Users/bigtochan/flutter/flutter/bin/flutter" analyze ...`
