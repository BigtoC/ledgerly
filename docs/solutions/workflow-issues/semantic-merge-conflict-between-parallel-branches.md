---
title: Two CI-green parallel branches broke when combined with no textual conflict
date: 2026-11-03
category: workflow-issues
module: analysis
problem_type: workflow_issue
component: development_workflow
severity: high
applies_when:
  - "Two open PRs branch from the same base and one changes a shared function's contract (new throw, new enum value, new required input)"
  - "Rebasing a branch after a sibling PR merged and GitHub reports it mergeable with no conflicts"
  - "One branch moves consumers onto a shared provider while another adds a consumer that computes its own value"
  - "Resolving conflicts in generated .g.dart files or riverpod_lint @Dependencies lists during a rebase"
symptoms:
  - "Opening the account sheet under the All period throws ArgumentError from formatPeriodLabel during build"
  - "The account sheet would list every account at 0 under All because its provider computed its own empty range"
  - "Git and GitHub reported no conflicts and each branch's CI passed on its own"
root_cause: missing_workflow_step
resolution_type: workflow_improvement
related_components:
  - testing_framework
  - tooling
tags: [semantic-merge-conflict, rebase, parallel-branches, contract-change, riverpod-dependencies, build-runner, exhaustive-enum, analysis-charts]
---

# Two CI-green parallel branches broke when combined with no textual conflict

## Context

Two Analysis-redesign PRs started from the same base and were developed in parallel:

- **PR #126 (step 7b, account filter UI)** added the account sheet (`lib/ui/features/analysis/charts/views/account_filter_sheet.dart`) in two parts:
  - a subtitle that called `formatPeriodLabel(selection.period, selection.anchorDate, locale)`;
  - a provider, `chartsAccountTotals` in `lib/ui/features/analysis/charts/view_models/account_filter_providers.dart`, that worked out its own `[start, end)` range with `normalizeAnchor`/`shiftAnchor`.
- **PR #127 (step 5b, All period)** made two changes on purpose:
  - **It changed a contract.** `formatPeriodLabel` (`lib/ui/features/analysis/charts/views/period_selector.dart`) now throws `ArgumentError` for the new `PeriodType.all`. Its doc comment says: "All has no date label: show `AppLocalizations.chartsAllTime` instead."
  - **It moved every range consumer** onto one shared provider, `chartsRange` (`charts_range_providers.dart`). On All, that provider builds the range from the transactions' date bounds.

Neither branch edited the other's lines. After #126 merged, GitHub showed #127 as mergeable with no conflicts, and CI would probably have passed: each branch's tests only exercised that branch's own code. The combined code had two defects:

1. **Crash.** Opening the account sheet under All ran `formatPeriodLabel(PeriodType.all, ...)` inside `build()`, which threw `ArgumentError`.
2. **Silently wrong data.** `chartsAccountTotals` computed its own range with `normalizeAnchor`/`shiftAnchor`. That range does not cover All's whole history (it is empty on All), so the sheet would list every account at 0.

Two things caught it. The plan tracked the dependency explicitly ("merge 7b first, then rebase 5b and route the sheet through chartsRange"), and a side agent flagged the hazard again before merge.

## Guidance

**1. When a branch changes a function's contract, look for callers on the other open branches, not only your own.** A contract change here means a new throw, a new enum value or a new required input. A rebase can add a caller that git will not warn you about. After rebasing:

```bash
# After rebasing the contract-changing branch onto the newly merged one
git grep -n "formatPeriodLabel(" lib/
git grep -n "normalizeAnchor\|shiftAnchor" lib/ui/features/analysis/
```

Every hit outside the shared helper is a consumer that has to adopt the new contract.

**2. Fix the merged code with TDD during the rebase.** Write the tests that combine both features first, and watch them fail.

Range-consumer unit test, added in `test/unit/controllers/charts_range_consumers_test.dart`:

```dart
test(
  'chartsAccountFilterOptions queries the account totals in the range',
  () async {
    when(
      () => repo.watchByAccountInRange(
        start: any(named: 'start'),
        end: any(named: 'end'),
        type: any(named: 'type'),
      ),
    ).thenAnswer((_) => Stream.value(const <AccountSlice>[]));

    final container = _container(repo);
    container.listen(chartsAccountFilterOptionsProvider, (_, _) {});
    await _flush();

    verify(
      () => repo.watchByAccountInRange(
        start: _range.start,
        end: _range.end,
        type: any(named: 'type'),
      ),
    ).called(1);
  },
);
```

Widget test that opens the sheet under All, in `test/widget/features/analysis/widgets/account_filter_sheet_test.dart`. It reproduced the `ArgumentError` before the fix:

```dart
testWidgets('under All: subtitle says All time and rows cover the whole '
    'history', (tester) async {
  _MockTxRepo? repo;
  final container = _container(
    dateBounds: (first: DateTime(2024, 3, 10), last: DateTime(2026, 1, 2)),
    onRepo: (r) => repo = r,
  );
  container
      .read(chartsSelectionControllerProvider.notifier)
      .setPeriod(PeriodType.all);
  await _open(tester, container);

  expect(tester.takeException(), isNull);
  expect(find.text('Filters the whole page · All time'), findsOneWidget);
  final now = DateTime.now();
  verify(
    () => repo!.watchByAccountInRange(
      start: DateTime(2024, 3),
      end: DateTime(now.year, now.month + 1),
      type: any(named: 'type'),
    ),
  ).called(greaterThanOrEqualTo(1));
});
```

**3. Route the new caller through the shared contract.**

`chartsAccountTotals` before (from #126; this is what the diff in commit `34bd9cc` replaces):

```dart
@Riverpod(dependencies: [transactionRepository, ChartsSelectionController])
Stream<List<AccountSlice>> chartsAccountTotals(Ref ref) {
  final (PeriodType period, DateTime anchorDate, CategoryType type) = ref.watch(
    chartsSelectionControllerProvider.select(
      (s) => (s.period, s.anchorDate, s.type),
    ),
  );
  final start = normalizeAnchor(anchorDate, period);
  final end = shiftAnchor(start, period, 1);
  return ref
      .watch(transactionRepositoryProvider)
      .watchByAccountInRange(start: start, end: end, type: type);
}
```

After:

```dart
@Riverpod(
  dependencies: [transactionRepository, chartsRange, ChartsSelectionController],
)
Stream<List<AccountSlice>> chartsAccountTotals(Ref ref) {
  final range = ref.watch(chartsRangeProvider);
  final type = ref.watch(
    chartsSelectionControllerProvider.select((s) => s.type),
  );
  if (range case AsyncError(:final error, :final stackTrace)) {
    return Stream.error(error, stackTrace);
  }
  // Loading: wait for the range without querying.
  final value = range.value;
  if (value == null) return const Stream.empty();
  return ref
      .watch(transactionRepositoryProvider)
      .watchByAccountInRange(start: value.start, end: value.end, type: type);
}
```

Sheet subtitle before → after:

```dart
// before
l10n.chartsFilterSheetSubtitle(
  formatPeriodLabel(selection.period, selection.anchorDate, locale),
)

// after
l10n.chartsFilterSheetSubtitle(
  selection.period == PeriodType.all
      ? l10n.chartsAllTime
      : formatPeriodLabel(selection.period, selection.anchorDate, locale),
)
```

**4. Where both branches changed the same provider, keep both changes.** `chartsNetByCurrency` (`charts_net_total_providers.dart`) needs the range from `chartsRange` (#127) and also the account filter `accountFilterId` (#126). Taking either side alone would have dropped a feature:

```dart
final range = ref.watch(chartsRangeProvider);
final accountId = ref.watch(
  chartsSelectionControllerProvider.select((s) => s.accountFilterId),
);
// ... error/loading guards ...
return ref.watch(transactionRepositoryProvider).watchTotalsByTypeInRange(
  start: value.start, end: value.end, accountId: accountId,
);
```

**5. Resolve conflicts in riverpod_lint `@Dependencies` lists by keeping both entries.** Then run `dart analyze --fatal-infos`, even on files git merged cleanly. In this rebase it caught a test file with no textual conflict that was missing the `chartsRange`/`chartsAccountFilterOptions` dependency.

**6. Never hand-merge `.g.dart` conflicts.** Take either side, then regenerate:

```bash
dart run build_runner build --delete-conflicting-outputs
```

`riverpod_generator` embeds a hash of the provider source plus the dependency lists, so a hand-merged `.g.dart` is stale even when it compiles.

## Why This Matters

- **No conflict is not the same as compatible.** Git detects overlapping edits, not broken contracts. One branch tightened a function (`formatPeriodLabel` throws on All) while the other added a caller of the old contract. Each branch was green on its own.
- **One failure is loud, the other is silent.** The `ArgumentError` crash would at least show up in testing. The account sheet showing every account at 0 under All is a quietly wrong financial view that nothing would flag.
- **A deliberate throw only works as a tripwire if a test reaches it.** Making the exhaustive helper throw on `PeriodType.all` was the right design, because it turns a silent bad label into a loud failure. But it fires only if some test renders the new caller under the new enum value. Before the rebase-time widget test, neither branch had such a test.
- **Shared-provider migrations miss late consumers.** #127 moved "every range consumer" onto `chartsRange`, but "every" meant every consumer on #127's base. `chartsAccountTotals` did not exist there yet.

## When to Apply

- Two or more branches are open at once from the same base, and one of them:
  - adds an enum value that exhaustive `switch`es or helpers must handle (here `PeriodType.all`);
  - makes a helper throw for some inputs, or adds a required parameter;
  - centralises duplicated logic into a shared provider, so all consumers must move (here `chartsRange` replacing per-provider `normalizeAnchor`/`shiftAnchor`).
- You rebase after another PR merges, even when `git rebase` reports no conflicts.
- A `.g.dart` file or a riverpod `@Dependencies` list shows up in a conflict.
- A plan orders branches by merge sequence ("merge X first, then rebase Y"). Write the dependency into the plan as an explicit rebase task with the exact consumers to reroute, as this plan did.

Run this checklist after every rebase:

```bash
git grep -n "<changed function or enum>" lib/ test/   # new callers from the other branch
dart run build_runner build --delete-conflicting-outputs
dart format --set-exit-if-changed .
dart analyze --fatal-infos                            # catches missing @Dependencies
flutter test                                          # full suite, not just touched files
```

Add at least one test that exercises the combination: the other branch's new UI under this branch's new enum value or contract. The test should assert `tester.takeException()` is null and that the expected repository arguments were used.

## Examples

- **The crash (this case):** before the rebase, `account_filter_sheet.dart` called `formatPeriodLabel(selection.period, ...)`, and `period_selector.dart` had `case PeriodType.all: throw ArgumentError.value(period, 'period', 'All has no date label');`. Opening the sheet under All threw during `build()`. The guard now lives at `account_filter_sheet.dart` lines ~153-161, mirroring the navigator's own guard at `period_selector.dart` lines ~106-108.
- **The silent zeros (this case):** `chartsAccountTotals` worked out its own snapped range, which does not cover the whole history on All. The regression test checks that `watchByAccountInRange` is called with `start: DateTime(2024, 3)` (the earliest transaction's month) and `end: DateTime(now.year, now.month + 1)`, which is what `chartsRange` resolves for All.
- **Combining both sides:** `chartsNetByCurrency` watches `chartsRangeProvider` (#127) and `accountFilterId` (#126), and passes both to `watchTotalsByTypeInRange`.
- **Clean merge, broken lint:** after keeping both entries in the conflicting `@Dependencies` lists, `dart analyze --fatal-infos` still found a test file that merged cleanly but was missing the `chartsRange`/`chartsAccountFilterOptions` dependency.
- **Relevant commits:** `34bd9cc` "refactor(analysis): resolve every period range through chartsRange" (adds `charts_range_consumers_test.dart` and moves `chartsAccountTotals` onto `chartsRange`). `0f06f94` "feat(analysis): add the All period" (the `formatPeriodLabel` throw and the account sheet's All-time subtitle).

## Related
- PRs #126 (account filter UI) and #127 (All period); rebase commits `34bd9cc` and `0f06f94`.
- [Adding a derived Riverpod provider to the scoped Analysis screen](../best-practices/adding-derived-riverpod-provider-to-scoped-analysis-screen.md) — the `@Dependencies` cascade and keeping the new provider in every list when resolving test conflicts (§1, §8).
- [Flutter performance audit](../performance-issues/flutter-performance-audit-riverpod-lifecycle-and-emit-path-fixes.md) — the `git rebase --exec` + build_runner sweep for `.g.dart` conflicts.
- [Flutter widget test and device verification gotchas](../developer-experience/flutter-widget-test-and-device-verification-gotchas.md) §7 — analyze and test every commit so a regression can be bisected.
