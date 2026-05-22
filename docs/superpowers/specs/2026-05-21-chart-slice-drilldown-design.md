# Chart Slice Drill-Down — Design Spec

**Status:** Approved
**Date:** 2026-05-21
**Feature:** Phase 2 — Analysis chart slice drill-down (pie/legend tap → coordinated bar-chart refilter + items list)

---

## Overview

Add a drill-down interaction to the Analysis chart section. When the user taps a pie slice or its matching legend row, the selection becomes the chart's focus:

1. The pie slice elevates and non-selected legend rows dim — **existing behavior, preserved**.
2. The **daily bar chart refilters** to show only the selected slice's per-bucket breakdown.
3. A **transactions items list** appears below the chart section listing every transaction that matches the selected slice within the chart's `[anchor, period]` range.

Tapping the same slice again clears the selection (toggle). Tapping a different slice replaces it. Changing period/dimension/type/anchor also clears it.

**Scope (all three chart dimensions):**
- Category dimension — tap a category slice → drill into that category's transactions
- Account dimension — tap an account slice → drill into that account's transactions
- Currency dimension — tap a currency slice → drill into that currency's transactions
- Items list rows reuse `TransactionSearchRow`, extended with a non-dismissible/action-only delete mode for drill-down (tap-to-edit, swipe-to-delete with 4 s undo)
- Bar chart refilters to the selected slice's daily/weekly/monthly buckets

**Out of scope:**
- Multi-slice selection (selecting Food + Transport simultaneously)
- Cross-period drill-down (clicking Food persists across period swipes)
- Auto-scrolling the page to make the items list visible
- "Other" aggregate bucket drill-down (the synthetic aggregate stays non-interactive)
- Pending recurring transactions in the items list (they remain Home-only)
- Budget overlay or chart-export changes

---

## User-Facing Behavior

| Action                                                                  | Outcome                                                                                                                                                                                      |
|-------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Tap a pie slice                                                         | Selection set; pie slice elevates; legend dims others; bar chart refilters; items list renders below chart                                                                                   |
| Tap the same slice (pie or legend)                                      | Selection cleared; everything returns to the unselected view                                                                                                                                 |
| Tap a different slice                                                   | Selection replaced; visuals/list update to the new slice                                                                                                                                     |
| Tap the "Other" aggregate row                                           | No-op (the bucket has no single underlying ID)                                                                                                                                               |
| Tap "View all" → tap any row inside the sheet                           | Selection toggles using the same semantics as pie/legend taps; modal sheet auto-closes afterward                                                                                             |
| Swipe horizontally on the chart (prev/next period)                      | Selection cleared; list disappears                                                                                                                                                           |
| Toggle expense ↔ income                                                 | Selection cleared                                                                                                                                                                            |
| Switch dimension (Category/Account/Currency)                            | Selection cleared                                                                                                                                                                            |
| Change period (day/week/month/year) via the selector                    | Selection cleared                                                                                                                                                                            |
| Edit a transaction from the items list                                  | Navigate to the existing edit screen (`go_router`); on save, stream re-emits                                                                                                                 |
| Swipe a row to delete                                                   | 4 s undo snackbar appears immediately, but the row stays visible until the delete commits; on timeout, `repo.delete(id)` runs and the list/header/chart update from the next stream emission |
| The selected slice's last matching transaction is deleted / edited away | Slice disappears from the next `slices` emission; controller auto-clears the stale selection; list collapses                                                                                 |

---

## Data Layer

### New type: `SelectedSlice`

A sealed type that identifies *what* the user has drilled into. Lives in `lib/data/models/selected_slice.dart` (it crosses the data ↔ controller boundary, so it belongs in `data/models/` alongside the other domain types).

```dart
@freezed
sealed class SelectedSlice with _$SelectedSlice {
  /// Drill-down into a category. `currencyCode` is set ONLY when the chart
  /// was showing a per-(category, currency) slice — i.e., FX was missing and
  /// Food USD / Food EUR appeared as separate pie slices. When `currencyCode`
  /// is null (FX-converted slice), the list aggregates all currencies for
  /// that category. The UI shows converted per-row values in the chart's
  /// display currency so the header total reconciles with the visible rows.
  const factory SelectedSlice.category(
    int categoryId, {
    String? currencyCode,
  }) = SelectedCategorySlice;

  /// Drill-down into an account. Account chart slices are emitted per
  /// `(account, currency)`, so `currencyCode` stays part of the selection
  /// identity even though the account record itself has a default currency.
  const factory SelectedSlice.account(
    int accountId, {
    String? currencyCode,
  }) = SelectedAccountSlice;

  /// Drill-down into a currency.
  const factory SelectedSlice.currency(String currencyCode) =
      SelectedCurrencySlice;
}
```

### Modified type: `ChartSlice`

Add one optional field so a pie/legend tap can translate to a typed `SelectedSlice` without parallel lookup tables.

```dart
@freezed
abstract class ChartSlice with _$ChartSlice {
  const factory ChartSlice({
    required String label,
    required String currencyCode,
    required int totalMinorUnits,
    double? fraction,
    required int colorIndex,
    required String iconKey,
    /// Drill-down identity for this slice. Null for the synthetic "Other"
    /// aggregate — that row stays non-interactive.
    ///
    /// Named `selectionKey` (not `key`) to avoid confusion with Flutter's
    /// `Widget.key`. `ChartSlice` is a Freezed data class, not a widget, so
    /// there is no name collision — but readers scanning the call sites
    /// should not have to wonder.
    SelectedSlice? selectionKey,
  }) = _ChartSlice;
}
```

`ChartsController` fills `selectionKey` when it projects `CategorySlice` / `AccountSlice` / `CurrencySlice` rows into `ChartSlice`s. The "Other" synthetic row built in `ChartLegend._otherRow` continues to have `selectionKey: null`.

### New repository method

```dart
/// Transactions matching the selected chart slice within [start, end), of
/// the active type. Ordered by `date DESC, id DESC` (matches Home / Search
/// Level 2 conventions).
///
/// Filter semantics:
///   SelectedCategorySlice(id, currencyCode?) →
///     WHERE category_id = id AND type = type AND date IN range
///     [AND currency = currencyCode]   // applied only when set
///   SelectedAccountSlice(id, currencyCode?) →
///     WHERE account_id = id AND type = type AND date IN range
///     [AND currency = currencyCode]   // applied only when set
///   SelectedCurrencySlice(code) →
///     WHERE currency = code AND type = type AND date IN range
///
/// No explicit row cap — relies on the project-wide 10,000-row policy
/// declared in CLAUDE.md.
Stream<List<Transaction>> watchTransactionsForSliceInRange({
  required SelectedSlice selection,
  required DateTime start,
  required DateTime end,
  required CategoryType type,
});
```

The `type` parameter is passed through for uniformity even though it is technically redundant for `SelectedCategorySlice` (category type is locked at creation per CLAUDE.md). It is meaningful for `SelectedAccountSlice` and `SelectedCurrencySlice` because both span both transaction types and the chart's TypeToggle defines the slice the user clicked.

### Extended repository method

```dart
Stream<List<TimeBucketSlice>> watchTimeBucketsInRange({
  required DateTime start,
  required DateTime end,
  required CategoryType type,
  required TimeBucketGranularity granularity,
  /// NEW: when non-null, buckets count only rows matching this slice.
  /// When null, behavior is identical to today (regression-protected).
  SelectedSlice? selection,
});
```

### DAO changes

The underlying `_dao.watchChartRowsInRange(start, end, type)` (called from `watchTimeBucketsInRange`) gains optional `{int? categoryId, int? accountId, String? currencyCode}` parameters. The repository translates a `SelectedSlice` to those primitives via a pattern switch and forwards them. The Drift query composes a `WHERE` clause with the filters applied.

A separate DAO method (or reuse of an existing one with a similar predicate set) backs `watchTransactionsForSliceInRange` and returns full row objects rather than just chart aggregates.

### What is deliberately NOT changed

- `watchForCategory(int categoryId, {int limit = 200})` — has different semantics (no range, default cap) and may have unrelated call sites; the new method is purpose-built for drill-down.
- `watchByCategoryInRange` / `watchByAccountInRange` / `watchByCurrencyInRange` — these return *aggregates*, not rows, so they are the wrong shape for the items list and remain untouched.

---

## State & Controller Layer

### `ChartsSelectionController`

Add one field to `ChartsSelection` and one command. Modify the five existing mutators to clear the selection.

```dart
@freezed
abstract class ChartsSelection with _$ChartsSelection {
  const factory ChartsSelection({
    required PeriodType period,
    required CategoryType type,
    required ChartDimension dimension,
    required DateTime anchorDate,
    /// NEW. Null means no drill-down active.
    SelectedSlice? selectedSlice,
  }) = _ChartsSelection;
}

@Riverpod(keepAlive: true, dependencies: [])
class ChartsSelectionController extends _$ChartsSelectionController {
  @override
  ChartsSelection build() => ChartsSelection(
    period: PeriodType.week,
    type: CategoryType.expense,
    dimension: ChartDimension.category,
    anchorDate: normalizeAnchor(DateTime.now(), PeriodType.week),
    selectedSlice: null,
  );

  /// Tap-toggle semantics: same slice clears, different slice replaces.
  void toggleSlice(SelectedSlice slice) {
    state = state.copyWith(
      selectedSlice: state.selectedSlice == slice ? null : slice,
    );
  }

  /// Internal — used by ChartsController when a stale selection survives
  /// a new slices emission whose `selectionKey`s no longer include the selection.
  void clearSlice() {
    if (state.selectedSlice != null) {
      state = state.copyWith(selectedSlice: null);
    }
  }

  // Each existing mutator now also resets selectedSlice to null:
  void setPeriod(PeriodType period) { /* … existing logic, plus selectedSlice: null */ }
  void setDimension(ChartDimension dim) { /* … */ }
  void toggleType() { /* … */ }
  void previousPeriod() { /* … */ }
  void nextPeriod() { /* … */ }
}
```

This replaces the local `_selectedSliceIndex` and the `didUpdateWidget` auto-clear that currently live in `_ChartBodyState` at `lib/features/analysis/charts/charts_section.dart:410-424`.

### `ChartsController`

One branch in the existing build flow — pass `selection.selectedSlice` through to the bucket query. Slices remain calculated as today.

```dart
// Pseudocode for the build() body:
final selection = ref.watch(chartsSelectionControllerProvider);
final (start, end) = chartDateRange(selection);  // existing helper

// Pie slices: UNCHANGED — pie still shows ALL slices in the dim/type/period.
final sliceStream = /* existing dispatch on dimension */;

// Bar chart buckets: pass selectedSlice through. Null = current behavior.
final bucketStream = repo.watchTimeBucketsInRange(
  start: start,
  end: end,
  type: selection.type,
  granularity: granularityFor(selection.period),
  selection: selection.selectedSlice,
);
```

**Stale-selection self-heal**: after `ChartsController` emits a new `ChartsData`, if `selection.selectedSlice != null` and no slice has a matching `selectionKey`, the selection must be cleared (covers "user deleted the last Food tx while drilled into Food").

Implementation note: calling `ref.read(chartsSelectionControllerProvider.notifier).clearSlice()` from *inside* `ChartsController.build()` re-enters its own dependency graph and is brittle. Instead, mount a small `ref.listen(chartsControllerProvider, (_, next) { … })` in `ChartsSection` (the widget already consumes both providers) — when the new data lands, check membership and clear if stale.

### Items list controller

Reuse-first decision: model this controller directly on the shipped `lib/features/analysis/search/category_search_detail_controller.dart`. That controller already owns the same `TransactionSearchRow` delete/undo contract (`kUndoWindow`, timer ownership, delete-failure effect callback, and synchronous re-emission from cached data), so the drill-down list should adapt that pattern rather than inventing a second one.

`SliceDrilldownController` is the sole state owner for the list panel. It should consume the repository stream directly as a `StreamNotifier`, rather than layering a separate `selectedSliceTransactionsProvider` underneath it.

```dart
@freezed
sealed class SliceDrilldownState with _$SliceDrilldownState {
  const factory SliceDrilldownState.loading() = SliceDrilldownLoading;
  const factory SliceDrilldownState.data({
    required List<Transaction> rows,
    int? pendingDeleteId,
  }) = SliceDrilldownData;
  const factory SliceDrilldownState.error(Object error, StackTrace stack) =
      SliceDrilldownError;
}

@riverpod
class SliceDrilldownController extends _$SliceDrilldownController {
  @override
  Stream<SliceDrilldownState> build() {
    // Stream rows directly from the repository for the active selection/range,
    // mirroring the ownership pattern used by CategorySearchDetailController.
  }

  void delete(int id) { /* start kUndoWindow timer; keep row visible until commit */ }
  void undoDelete(int id) { /* cancel timer, clear pendingDeleteId */ }
}
```

---

## UI Layer

### Layout

`SelectedSliceItemsList` is a sibling of `_ChartBody` inside `ChartsSection`'s `Column`, rendered **outside** the existing `GestureDetector` that handles horizontal-fling period navigation. This isolates row-level swipe gestures from period navigation.

```
ChartsSection
└── Column
    ├── PeriodSelector
    ├── TypeToggle
    ├── DimensionToggle
    ├── (mixed-currencies / auto-switch / excluded-currencies banners)
    ├── GestureDetector(onHorizontalDragEnd: previousPeriod / nextPeriod)
    │   └── SlideTransition
    │       └── _ChartBody                  // pie + legend + (refiltered) bar chart
    └── SelectedSliceItemsList              // NEW — sibling, not inside fling gesture
```

### `_ChartBody` migration

Converts from `StatefulWidget` to `ConsumerWidget`. The local `_selectedSliceIndex` and `didUpdateWidget` clearing both go away — selection is now in Riverpod and clears via `ChartsSelectionController` mutators.

- Reads `chartsSelectionControllerProvider.selectedSlice` to drive the existing `selectedIndex` parameter on the pie chart and legend. Maps the typed `SelectedSlice` to an index by `slices.indexWhere((s) => s.selectionKey == selection.selectedSlice)` (returns `-1` when not found → render unselected; this is the in-between frame before the stale-selection self-heal listener clears the selection).
- Pie tap callback: `onSelectionChanged: (i) { final sel = i == null ? null : data.slices[i].selectionKey; if (sel != null) ref.read(chartsSelectionControllerProvider.notifier).toggleSlice(sel); }`
- Legend row tap callback: same dispatch via `toggleSlice`. The legend's `_otherRow` keeps `originalIndex: null` so it remains non-interactive.

### `SelectedSliceItemsList` widget (new)

A `ConsumerWidget` rendered by `ChartsSection` when `selection.selectedSlice != null`. Renders nothing (returns `SizedBox.shrink`) when null.

```
SelectedSliceItemsList
└── AnimatedSize (220 ms, Curves.easeOut)
    └── Column
        ├── _ListHeader(label, count, totalMinorUnits, currency)
        └── for (tx in rows)
               TransactionSearchRow(
                 transaction: tx,
                 category: categoriesById[tx.categoryId],
                 account:  accountsById[tx.accountId],
                 locale: locale,
                 convertedAmount: fxConvertedAmountFor(tx),
                 originalAmountLabel: l10n.analysisOriginalAmount,
                 deleteMode: TransactionSearchRowDeleteMode.actionOnly,
                 onTap:    () => context.push('/home/edit/${tx.id}'),
                 onDelete: () => controller.delete(tx.id),
               )
```

**Header** (private widget inlined in `selected_slice_items_list.dart` — no separate file):
- Label: resolved slice display name (category name via existing `categoryDisplayName(...)`; account name; currency code).
- Count: localized plural, computed from the rows currently rendered by the widget (`rows.length`). During the undo window the row stays visible, so the count remains aligned with the chart/header until the delete commits.
- Total: taken directly from the selected `ChartSlice.totalMinorUnits` (which is already in the chart's chosen display unit) — **not** re-summed from the items list rows. This stays in lockstep with the pie slice's labeled amount.
  - Format via `MoneyFormatter` using `slice.currencyCode` (already on every slice — equals the source currency for mixed-currency-without-FX slices and equals `displayCurrencyCode` for FX-converted slices).
  - For FX-converted category slices (`selectionKey` is category with `currencyCode == null`), each row renders the converted display-currency amount as the primary amount because it reconciles with the header total.
  - The original booked amount remains visible as a secondary labeled value (`analysisOriginalAmount` / original-currency caption) so users can still inspect the stored transaction currency.
  - Non-converted slices keep the existing single-amount `TransactionSearchRow` layout.
  - To get the slice into the header widget, `ChartsSection` passes the currently selected `ChartSlice` (looked up by `selectionKey`) down to `SelectedSliceItemsList`.

**Async states**: match the shipped analysis detail-screen precedent in `lib/features/analysis/search/category_search_detail_screen.dart`.
- First load while a selection is active: render an inline centered `CircularProgressIndicator` in place of the rows.
- Empty data: render the inline `analysisDrilldownEmpty` placeholder.
- Error: render inline `analysisErrorMessage` text in place of the rows. No extra Retry button — this list is a subordinate panel under an already-live chart surface.

**Animation**: `AnimatedSize` (220 ms, matching the legend's dim transition). Selection clear → list collapses smoothly.

**No nested scrolling**: the list is a plain `Column`. The outer `SingleChildScrollView` from `analysis_screen.dart:81-85` handles all scrolling. If a future pathological dataset ever needs lazy build, swap to `ListView.builder(shrinkWrap: true, physics: NeverScrollableScrollPhysics())` — not done preemptively per CLAUDE.md MVP policy.

**No auto-scroll-into-view**: the user opted against automatic page scrolling on selection.

### "View all" modal sheet change

In `ChartLegend._openFullLegend`, the row tap currently calls `onSelectSlice` only. Update it to also call `Navigator.pop(sheetCtx)` so the sheet closes after the selection toggles:

```dart
// Inside _openFullLegend's row construction:
onTap: () {
  onSelectSlice?.call(originalIndex);  // existing
  Navigator.pop(sheetCtx);             // NEW
},
```

### Tablet (≥600 dp)

No special handling. The 600 dp breakpoint per CLAUDE.md only switches bottom-nav ↔ NavigationRail at the shell level; internal layout flows the same way. The chart and items list both flow vertically in the main column.

### Accessibility

`analysis_screen.dart` already wraps the body in `Semantics(liveRegion: true, container: true)`. The items list inherits this — screen readers announce changes when the selection updates. Each `TransactionSearchRow` is already semantically labeled (ListTile + currency-formatted amount). Header gets a `Semantics(header: true)`.

Legend rows are the canonical accessible drill-down control. Keep `CategoryPieChart` as a descriptive semantic image, but make each interactive legend row expose button semantics plus selected/not-selected state so the full drill-down remains operable without the chart gesture surface. The synthetic `Other` row remains non-interactive and should be exposed as plain text, not a button.

**Text scaling**: per CLAUDE.md, all scrollable regions must survive 2× scale. The items list reflows naturally; the header uses `TextOverflow.ellipsis` on the label. No fixed-height widgets in the list, so 2× scale just reflows.

---

## Edge Cases

| Case                                                                                        | Handling                                                                                                                                                                                                                                                                                                                                                                                                     |
|---------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Stale selection (slice disappears from new emission)                                        | A `ref.listen` on `chartsControllerProvider` in `ChartsSection` calls `clearSlice()` when no `slice.selectionKey` matches the active `selectedSlice`. List collapses cleanly.                                                                                                                                                                                                                                |
| "Other" aggregate row                                                                       | `selectionKey: null` on the synthetic slice; tap is a no-op. Status quo.                                                                                                                                                                                                                                                                                                                                     |
| "View all" sheet row tap                                                                    | Calls `toggleSlice` AND `Navigator.pop(sheetCtx)` so the sheet closes after the selection toggles.                                                                                                                                                                                                                                                                                                           |
| Mixed currencies in category dim (FX missing)                                               | Multiple pie slices per category, each carrying its `currencyCode`. Tapping "Food (USD)" drills into Food + USD only. Tapping a different (category, currency) replaces.                                                                                                                                                                                                                                     |
| Pending recurring transactions                                                              | Excluded. Items list queries `transactions` only — matches what the chart counts. `PendingSection` remains Home-only per CLAUDE.md.                                                                                                                                                                                                                                                                          |
| Items list empty despite live selection (race between stream emits)                         | Inline "No transactions in this period" placeholder. With the self-heal path above, this should be transient.                                                                                                                                                                                                                                                                                                |
| `ChartsBlockedByMissingRates`                                                               | Items list works independently of FX (queries raw transactions). Previous chart + banner render; if a previous-data slice is still selected, the list continues to display correctly. FX-converted per-row values reuse the same last-known display currency until fresh rates land, and the row/header treatment adds an explicit stale-rates label so those converted values are not presented as current. |
| Type toggle change with active selection                                                    | `toggleType()` clears `selectedSlice`.                                                                                                                                                                                                                                                                                                                                                                       |
| Dimension change with active selection                                                      | `setDimension()` clears `selectedSlice`.                                                                                                                                                                                                                                                                                                                                                                     |
| Period change via prev/next or selector                                                     | `previousPeriod()` / `nextPeriod()` / `setPeriod()` clear `selectedSlice`.                                                                                                                                                                                                                                                                                                                                   |
| Chart transitions to `ChartsEmpty`, `ChartsError`, or any state without current `chartData` | Clear `selectedSlice` immediately so the items list/header never outlive the chart slice metadata they depend on.                                                                                                                                                                                                                                                                                            |

---

## Localization

**Reuse existing key** for the row count:
- `analysisTransactionCount` ([`app_en.arb:877`](l10n/app_en.arb)) — already defined as `{count, plural, =1{{count} transaction} other{{count} transactions}}` and used by Level 1 search result cards in `CategorySearchTile`. Same semantics, same copy.

**New keys** added to all four ARB files (`l10n/app_en.arb`, `l10n/app_zh.arb`, `l10n/app_zh_CN.arb`, `l10n/app_zh_TW.arb`):

```jsonc
"analysisDrilldownEmpty": "No transactions in this period",
"@analysisDrilldownEmpty": {
  "description": "Inline placeholder in the slice drill-down items list when the live emission has zero rows (transient race between selection toggle and stream emit)"
},
"analysisOriginalAmount": "Original amount",
"@analysisOriginalAmount": {
  "description": "Label for the booked transaction amount shown as the secondary amount on FX-converted drill-down rows"
},
"analysisRatesStale": "Using last known exchange rates",
"@analysisRatesStale": {
  "description": "Inline label shown when drill-down converted amounts are derived from stale cached FX rates"
}
```

The slice **label** resolves via existing helpers (`categoryDisplayName(...)` for seeded categories using `l10n_key`; account name as stored; currency code as displayed elsewhere). No new label key required.

**Pin reminder (CLAUDE.md)**: `l10n/app_zh.arb` must keep at least `appTitle` so `flutter_localizations` codegen succeeds. We only *add* keys to it.

---

## Testing Strategy

Organized by architectural layer per CLAUDE.md.

### Repository tests (`test/unit/repositories/transaction_repository_slice_drilldown_test.dart`)

In-memory Drift.

- `watchTransactionsForSliceInRange` for each `SelectedSlice` variant × range × type → returns matching rows only, ordered `date DESC, id DESC`.
- `SelectedCategorySlice` with `currencyCode` set vs unset → currency filter applied conditionally.
- Range boundary: `[start, end)` — tx at `start` included; tx at `end` excluded. Matches the documented convention for the existing `watchByCategoryInRange` family.
- Stream reactivity: insert / update / delete after subscription → new emission with updated rows.
- `watchTimeBucketsInRange` with `selection: null` → bit-for-bit regression of current behavior.
- `watchTimeBucketsInRange` with each `SelectedSlice` variant → buckets count only matching rows.

### Controller tests (`test/unit/controllers/`)

`ProviderContainer` overrides + `mocktail`.

- `ChartsSelectionController`:
  - `toggleSlice(s1)` from null → `selectedSlice == s1`.
  - `toggleSlice(s1)` from `s1` → null (toggle off).
  - `toggleSlice(s2)` from `s1` → `s2` (replace).
  - Each of `setPeriod`, `setDimension`, `toggleType`, `previousPeriod`, `nextPeriod` clears `selectedSlice`.
  - `clearSlice()` is a no-op when already null.
  - All existing tests still pass (regression).
- `ChartsController`:
  - `selectedSlice == null` → bucket query called with `selection: null` (regression).
  - `selectedSlice` set → bucket query called with that selection.
  - Slices list shape unchanged across selection state (pie still shows all).
  - Non-data chart states (`ChartsEmpty`, `ChartsError`, blocked-without-previous) clear `selectedSlice`.
  - All three dimensions covered.
- `SliceDrilldownController`:
  - Reuses the delete/undo mechanics proven in `CategorySearchDetailController`.
  - Owns the transaction stream directly as a `StreamNotifier`; no separate `selectedSliceTransactionsProvider` remains.
  - `delete(id)` records `pendingDeleteId` and schedules commit at `kUndoWindow`, but does not hide the row before commit.
  - Commit fires `repo.delete(id)` after the window if not cancelled.
  - `undoDelete(id)` cancels the timer; `repo.delete` never called.
  - Transitions through `loading → data → data (with pending) → error` as appropriate.

### Widget tests (`test/widget/`)

- `SelectedSliceItemsList` renders inline loading, error, header + rows in `data`, inline empty when `rows` is empty, and nothing when parent's selection is null.
- **Stale-selection self-heal**: `ChartsSection`'s `ref.listen` clears `selectedSlice` when a new `ChartsData` emission contains no slice whose `selectionKey` matches the current selection. Verified by pumping a sequence where the selected slice exists in emission N but not in emission N+1.
- Pie tap with non-null `selectionKey` → `chartsSelectionControllerProvider.notifier.toggleSlice` called with the correct typed slice.
- Legend row tap → same.
- "Other" row tap → no `toggleSlice` call.
- "View all" sheet row tap → `toggleSlice` called AND sheet closes (`Navigator.pop` invoked).
- FX-converted drill-down rows show converted per-row values in the display currency so the header total reconciles with the visible list.
- FX-converted drill-down rows keep converted amount primary and original amount secondary/labeled.
- `TransactionSearchRow` drill-down mode uses a non-dismissible delete action rather than immediate row dismissal.
- Legend rows expose selected-state semantics; the "Other" row exposes no tap action.
- Visual selection treatment regression: selected slice elevates and others dim (preserve the existing 220 ms transitions).
- 2× text scale: items list reflows; no overflow.

### Golden tests (`test/widget/golden/`)

Each pumped with a fixed seed dataset (deterministic dates / IDs / amounts), `MaterialApp` + `MediaQuery(size: Size(390, 844))` for a stable mobile viewport, and the actual app theme so colors resolve through `colorForIndex(...)`.

- `selected_slice_items_list_zh.png` — Chinese locale; verifies the new ARB keys land and the header does not overflow.
- `chart_with_selected_slice_light.png` — full chart section with a slice selected: elevated pie slice + dimmed legend + refiltered bar chart + items list together. This is the headline new visual artifact.

### Integration tests (`test/integration/`)

`pumpAndSettle` end-to-end flows.

- Open Analysis tab → tap pie slice → header + rows appear → tap same → list collapses → tap different → list updates.
- Bar chart refilter visible after selection (assert via the bucket data exposed through the provider, not via pixel goldens).
- Period swipe with active selection → list disappears (auto-clear path).
- Edit row → navigates to edit screen.
- Swipe-delete row → undo snackbar appears while the row remains visible → wait `kUndoWindow` + small buffer → repo confirms deletion and the row disappears on the next stream emission.

### What is **not** tested

- No migration tests — no schema change in this feature.
- No live network — drill-down does not involve Ankr at all.
- No performance benchmarks — MVP policy.

---

## Architecture & Layer Compliance

Per CLAUDE.md non-negotiables:

- New repository method (`watchTransactionsForSliceInRange`) lives in `lib/data/repositories/transaction_repository.dart` and its abstract interface; DAO query changes stay in `lib/data/database/`. **Repositories remain the only writers of Drift queries.**
- `SelectedSlice` lives in `lib/data/models/selected_slice.dart` as a Freezed sealed class — it's a typed value that crosses the data ↔ controller boundary.
- `ChartsSelectionController`, `ChartsController`, and `SliceDrilldownController` expose state + commands; widgets read state and invoke commands.
- Repositories return `Stream<T>` backed by Drift `.watch()`; controllers consume via Riverpod `StreamNotifier` / `AsyncNotifier`. **Reactive by default.**
- Money: all totals stay in integer minor units; `MoneyFormatter` is the only formatter at the UI boundary.
- Categories: drill-down by `categoryId` — `l10n_key` / `custom_name` distinction handled at the display layer through existing `categoryDisplayName(...)`.
- No `try/catch` in widgets; errors propagate via `AsyncValue` and the sealed `SliceDrilldownState.error` variant.

---

## File Touch List

**New:**
- `lib/data/models/selected_slice.dart`
- `lib/features/analysis/charts/widgets/selected_slice_items_list.dart` (includes the private `_ListHeader` widget — no separate file)
- `lib/features/analysis/charts/slice_drilldown_controller.dart`
- `lib/features/analysis/charts/slice_drilldown_state.dart`
- `test/unit/repositories/transaction_repository_slice_drilldown_test.dart`
- `test/unit/controllers/charts_selection_controller_slice_test.dart`
- `test/unit/controllers/charts_controller_slice_test.dart`
- `test/unit/controllers/slice_drilldown_controller_test.dart`
- `test/widget/selected_slice_items_list_test.dart`
- `test/widget/chart_slice_selection_interaction_test.dart`
- `test/widget/golden/*.png` (2 goldens listed above)
- `test/integration/analysis_drilldown_test.dart`

**Modified:**
- `lib/features/analysis/charts/charts_state.dart` — `ChartSlice.selectionKey`
- `lib/features/analysis/charts/charts_selection_controller.dart` — `selectedSlice` field, `toggleSlice`, `clearSlice`, mutator clears
- `lib/features/analysis/charts/charts_controller.dart` — pass selection into bucket query
- `lib/features/analysis/charts/charts_section.dart` — render `SelectedSliceItemsList` as sibling of `_ChartBody`; host the stale-selection-self-heal `ref.listen` on `chartsControllerProvider`
- `lib/features/analysis/charts/widgets/chart_legend.dart` — `_openFullLegend` row tap also pops the sheet
- `lib/features/analysis/charts/charts_providers.dart` — no new selected-slice row provider; FX/supporting chart providers remain here
- `lib/data/repositories/transaction_repository.dart` — abstract + concrete `watchTransactionsForSliceInRange`; extend `watchTimeBucketsInRange` with optional `selection`
- `lib/data/database/` — DAO query for `watchChartRowsInRange` gains optional filter params; new method backs `watchTransactionsForSliceInRange`
- `l10n/app_en.arb`, `l10n/app_zh.arb`, `l10n/app_zh_CN.arb`, `l10n/app_zh_TW.arb` — `analysisDrilldownEmpty`, `analysisOriginalAmount`, and stale-rates drill-down copy (the count copy reuses the existing `analysisTransactionCount`)

---

## References

- `PRD.md` — Architecture, Data Model Invariants, Layout Primitives, Testing
- `CLAUDE.md` — Non-negotiables, dependency pins, MVP cap
- `docs/superpowers/specs/2026-05-18-basic-charts-design.md` — Original charts spec (this drill-down extends it)
- `docs/superpowers/specs/2026-05-09-transaction-search-design.md` — Level 1 / Level 2 search UX precedent
- `docs/superpowers/specs/2026-05-07-recurring-transactions-design.md` — `kUndoWindow` optimistic-delete precedent
- `lib/features/analysis/search/widgets/transaction_search_row.dart` — reusable row widget
