---
title: Riverpod scoped providers must list cross-provider reads in `dependencies`
date: 2026-05-10
category: runtime-errors
module: analysis
problem_type: runtime_error
component: frontend_stimulus
symptoms:
  - Tapping a search-result tile in `/analysis` rendered "Something went wrong while searching" instead of the detail page, on every navigation, regardless of query content.
  - No exception in the default `flutter run` log — only `[GoRouter] pushing /analysis/search/...` and the screen's error branch.
  - A temporary `ProviderObserver` revealed a Riverpod debug assertion at `package:riverpod/src/framework/element.dart:639` — "tried to read analysisControllerProvider, but it specified a 'dependencies' list yet that list does not contain analysisControllerProvider".
  - Existing widget test "detail page reuses the active analysis search stream" passed despite the bug.
root_cause: config_error
resolution_type: code_fix
severity: high
related_components:
  - category_search_detail_controller
  - analysis_controller
  - category_search_detail_screen
  - category_search_detail_screen_test
  - bootstrap
tags:
  - flutter
  - riverpod
  - dependencies
  - scoped-providers
  - code-generation
  - async-state
  - transaction-search
---

# Riverpod scoped providers must list cross-provider reads in `dependencies`

## Problem

`CategorySearchDetailController` declared `@Riverpod(keepAlive: true, dependencies: [transactionRepository])` but its `build()` reads `analysisControllerProvider` to reuse cached search results. Riverpod's debug assertion treats this as a scoping-contract violation, throws synchronously inside `ref.read`, surfaces as `AsyncError` on the controller's stream, and the detail screen renders its `state.when(error: ...)` branch — looking like a generic "search failed" UI rather than a config bug.

## Symptoms

- Every navigation to `/analysis/search/<categoryId>?q=<query>&c=<currencyCode>` rendered the localized error string `analysisErrorMessage` ("Something went wrong while searching"). Reproducible with English ("coffee") and Chinese ("測試") queries alike.
- No exception printed by default. The Riverpod assertion was being captured into the `StreamNotifier`'s `AsyncError` and silently rendered.
- A `ProviderObserver` attached to the root `ProviderScope` printed:
  ```
  [provider-fail] categorySearchDetailControllerProvider:
    'package:riverpod/src/framework/element.dart': Failed assertion: line 639 pos 11
    The provider categorySearchDetailControllerProvider tried to read
    analysisControllerProvider, but it specified a 'dependencies' list yet
    that list does not contain analysisControllerProvider.
  ```
- The test that should have caught it asserted only `find.byType(CategorySearchDetailScreen)` (passes when the screen renders the error branch) and `verifyNever(() => tx.watchByMemo(...))` (passes because the assertion fires before any fallback code runs).

## What Didn't Work

- **Regenerating stale `.g.dart` only.** The generated provider class was `AutoDisposeStreamNotifierProviderImpl` even though the source declared `@Riverpod(keepAlive: true)` — `build_runner` had not been re-run after the `keepAlive: true` was added. Running `dart run build_runner build --delete-conflicting-outputs` did align the runtime with the annotation, but the assertion still fired because the `dependencies` list was independently incomplete.
- **Removing the `analysis.hasError` propagation in the detail controller.** Replacing the early-return `Stream.error(analysis.error!, ...)` with an opportunistic cache-only path was a real defensive improvement (the detail screen shouldn't inherit transient analysis errors), but it didn't fix this bug — Riverpod's assertion fires inside `ref.read`, *before* any of the cache-vs-fallback logic runs.
- **Speculating about Chinese-character handling.** The URL-encoded `q=%E6%B8%AC%E8%A9%A6` in the GoRouter log was a red herring; the assertion fires regardless of query content.

## Solution

Declare every scoped provider that the controller reads. `analysisControllerProvider` itself has `dependencies: [transactionRepository]`, so reading it from another scoped provider requires listing it explicitly:

`lib/features/analysis/search/category_search_detail_controller.dart`:

```dart
// Before — assertion violation
@Riverpod(keepAlive: true, dependencies: [transactionRepository])
class CategorySearchDetailController extends _$CategorySearchDetailController {
  @override
  Stream<CategorySearchDetailState> build({...}) {
    if (ref.exists(analysisControllerProvider)) {
      final analysis = ref.read(analysisControllerProvider);  // throws
      ...
    }
  }
}

// After — declares both scoped providers
@Riverpod(
  keepAlive: true,
  dependencies: [transactionRepository, AnalysisController],
)
class CategorySearchDetailController extends _$CategorySearchDetailController {
  // unchanged body
}
```

After the annotation change:

```bash
dart run build_runner build --delete-conflicting-outputs
```

The regenerated `category_search_detail_controller.g.dart` adds `analysisControllerProvider` to both `_dependencies` and `_allTransitiveDependencies`, satisfying the assertion at `element.dart:639`.

Strengthen the widget test so this regression class can't slip through again. The original test asserted screen presence and "no fresh stream call"; both pass when the controller is in `AsyncError`. Add positive-render and error-absent assertions:

`test/widget/features/analysis/category_search_detail_screen_test.dart`:

```dart
verifyNever(() => tx.watchByMemo('coffee'));
expect(find.byType(CategorySearchDetailScreen), findsOneWidget);
// Detail must render the row from cached data, not the error state.
// Without this assertion, a Riverpod `dependencies` violation in the
// detail controller (which surfaces as `AsyncError`) would silently
// pass — the widget tree still contains `CategorySearchDetailScreen`.
expect(find.byType(TransactionSearchRow), findsOneWidget);
final l10n = AppLocalizations.of(
  tester.element(find.byType(CategorySearchDetailScreen)),
);
expect(find.text(l10n.analysisErrorMessage), findsNothing);
```

### Diagnostic technique that found it

Before the assertion was visible, the bug looked like a generic feature failure. Attaching a `ProviderObserver` to the root `ProviderScope` made the underlying error visible:

```dart
class _ProviderErrorLogger extends ProviderObserver {
  const _ProviderErrorLogger();

  @override
  void providerDidFail(
    ProviderBase<Object?> provider,
    Object error,
    StackTrace stackTrace,
    ProviderContainer container,
  ) {
    debugPrint(
      '[provider-fail] ${provider.name ?? provider.runtimeType}: $error\n$stackTrace',
    );
  }
}

// In bootstrap.dart
ProviderScope(
  observers: const [_ProviderErrorLogger()],
  ...
)
```

Use this any time an `AsyncValue` enters the error branch but no exception lands in the console. Riverpod swallows synchronous `build()` throws and assertion failures into `AsyncError`, and they only appear via `providerDidFail`. The observer was reverted after diagnosis — keep it as a triage tool, not a permanent fixture.

## Why This Works

Riverpod's `dependencies` parameter declares the scoping contract: any scoped provider this provider reads must either share the same scope ancestry or be listed in `dependencies`. The runtime assertion at `_debugAssertCanDependOn` (`element.dart:639`) enforces this in debug builds. Adding `AnalysisController` to the list:

1. Tells Riverpod that this provider's transitive dependency closure includes `analysisControllerProvider` and everything *it* depends on.
2. Allows `ref.read(analysisControllerProvider)` and `ref.read(analysisControllerProvider.notifier).lastTransactions` to pass the assertion.
3. Keeps the cache-reuse path working without regressing the standalone path (the detail provider still falls back to `repo.watchByMemo` when no active analysis state exists).

The `keepAlive: true` regen was a separate-but-necessary fix: the family provider was running as `autoDispose` at runtime because the source annotation had drifted ahead of the generated code. Both issues had to be fixed; either alone left the bug.

## Prevention

- **Whenever you add `ref.read(otherScopedProvider)` or `ref.watch(otherScopedProvider)` inside a `@Riverpod`-annotated provider, immediately add that provider to your own `dependencies` list.** The runtime assertion only fires in debug builds and only when the read path is exercised — easy to miss in static review.

- **Re-run `dart run build_runner build --delete-conflicting-outputs` after every change to a `@Riverpod` annotation** (`keepAlive`, `dependencies`, `family` parameters). The generated `.g.dart` encodes runtime behavior; source-only changes are silently ignored until regen. CLAUDE.md already calls this out, but it bears restating: an out-of-date `.g.dart` will not produce a compile error — it will produce a runtime divergence.

- **Widget tests for cross-provider state reuse must assert positive render, not just widget presence.** A screen widget remains in the tree when its body is the error branch. Always pair `find.byType(<Screen>)` with `find.byType(<expected child>)` and `find.text(<error message>), findsNothing`.

- **Wire a `ProviderObserver` (with `providerDidFail`) any time an `AsyncValue` reports `hasError` without a console exception.** Riverpod converts synchronous `build()` throws and debug assertions into `AsyncError`, which bypasses the default Flutter error reporter. Keep the observer as a temporary diagnostic — revert it after the bug is found.

- **Don't speculate ahead of the trace.** Three rounds of plausible-but-incomplete fixes (regen-only, `analysis.hasError` removal, Chinese-character theorizing) were spent before the `ProviderObserver` was attached. When a controller emits `AsyncError` and the screen has no other error sources, the cheapest next step is observing the actual error, not refactoring the suspected error path.

## Related Issues

- [`docs/solutions/logic-errors/transaction-search-analysis-regressions-2026-05-10.md`](../logic-errors/transaction-search-analysis-regressions-2026-05-10.md) — same module, same day, same files. Covers a different root cause (state-machine flattening of metadata-readiness) but flags the same `category_search_detail_controller.dart` as a hotspot for reuse-of-shared-analysis-state regressions. Should be updated to add a back-reference to this doc.
- [`docs/solutions/best-practices/reactive-feature-flow-ownership-2026-04-25.md`](../best-practices/reactive-feature-flow-ownership-2026-04-25.md) — broader Riverpod ownership pattern (router → repo → controller → widget). This learning reinforces the contract at the provider-declaration layer.
- Verified with:
  - `dart run build_runner build --delete-conflicting-outputs`
  - `flutter analyze lib/features/analysis lib/app/bootstrap.dart test/widget/features/analysis`
  - `flutter test test/widget/features/analysis/ test/unit/controllers/category_search_detail_controller_test.dart test/unit/controllers/analysis_controller_test.dart test/unit/app/router_test.dart`
