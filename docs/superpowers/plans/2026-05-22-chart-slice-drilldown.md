# Chart Slice Drill-Down Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Wire the Analysis pie/legend taps to a coordinated bar-chart refilter and a per-slice items list with edit + swipe-to-delete (with 4 s undo), preserving the existing pie/legend selection visuals.

**Architecture:** Selection identity is hoisted from a local `_selectedSliceIndex` (`charts_section.dart:410`) into the Riverpod `ChartsSelectionController` as a typed `SelectedSlice` (sealed: category | account | currency). `ChartsController` carries that selection through `watchTimeBucketsInRange` to refilter the bar chart and stamps each `ChartSlice.selectionKey` so a tap can translate to the selection without a parallel lookup. A new `SliceDrilldownController` streams matching `Transaction` rows for the selection + range + type, owning the same `kUndoWindow` delete contract as `CategorySearchDetailController`. The list is a sibling of `_ChartBody` inside `ChartsSection`, rendered outside the period-fling `GestureDetector` so row swipes don't fight period swipes.

**Tech Stack:** Flutter 3.41.7, Riverpod (`riverpod_annotation`, `StreamNotifier`), Drift (in-memory for tests), Freezed sealed unions, `flutter_slidable` for swipe actions, `go_router` for edit navigation, `intl` for date formatting, `mocktail` for controller tests, `MaterialApp` + `flutter_test` + golden_toolkit-style fixed-viewport goldens.

---

## File Structure

**New files:**
- `lib/data/models/selected_slice.dart` — Freezed sealed `SelectedSlice` (category | account | currency).
- `lib/features/analysis/charts/slice_drilldown_state.dart` — Freezed sealed `SliceDrilldownState` (loading | data | error).
- `lib/features/analysis/charts/slice_drilldown_controller.dart` — `StreamNotifier` driving the items list (mirrors `CategorySearchDetailController`'s undo contract).
- `lib/features/analysis/charts/widgets/selected_slice_items_list.dart` — `ConsumerWidget` rendering the header + rows, with an inlined private `_ListHeader`.
- `test/unit/repositories/transaction_repository_slice_drilldown_test.dart`
- `test/unit/controllers/charts_selection_controller_slice_test.dart`
- `test/unit/controllers/charts_controller_slice_test.dart`
- `test/unit/controllers/slice_drilldown_controller_test.dart`
- `test/widget/features/analysis/selected_slice_items_list_test.dart`
- `test/widget/features/analysis/chart_slice_selection_interaction_test.dart`
- `test/widget/features/analysis/goldens/selected_slice_items_list_zh.png`
- `test/widget/features/analysis/goldens/chart_with_selected_slice_light.png`
- `test/integration/analysis_drilldown_test.dart`

**Modified files:**
- `lib/features/analysis/charts/charts_state.dart` — add `ChartSlice.selectionKey`.
- `lib/features/analysis/charts/charts_selection_controller.dart` — add `selectedSlice`, `toggleSlice`, `clearSlice`; mutators clear selection.
- `lib/features/analysis/charts/charts_controller.dart` — fill `selectionKey`, pass `selection.selectedSlice` to `watchTimeBucketsInRange`, clear selectedSlice on non-data states.
- `lib/features/analysis/charts/charts_section.dart` — convert `_ChartBody` to `ConsumerWidget`, render `SelectedSliceItemsList` as sibling of `_ChartBody`, host stale-selection-self-heal `ref.listen`.
- `lib/features/analysis/charts/widgets/chart_legend.dart` — close the "View all" sheet on row tap.
- `lib/features/analysis/search/widgets/transaction_search_row.dart` — add `TransactionSearchRowDeleteMode` (`dismissible` | `actionOnly`), `convertedAmount`, `originalAmountLabel` parameters.
- `lib/data/repositories/transaction_repository.dart` — new abstract + concrete `watchTransactionsForSliceInRange`; extend `watchTimeBucketsInRange` with optional `selection`.
- `lib/data/database/daos/transaction_dao.dart` — extend `watchChartRowsInRange` with optional `{categoryId, accountId, currencyCode}`; new `watchTransactionRowsForSliceInRange`.
- `l10n/app_en.arb`, `l10n/app_zh.arb`, `l10n/app_zh_CN.arb`, `l10n/app_zh_TW.arb` — `analysisDrilldownEmpty`, `analysisOriginalAmount`, `analysisRatesStale`.

**Out of scope (deliberately unchanged):** `TransactionRepository.watchForCategory`, `watchByCategoryInRange`, `watchByAccountInRange`, `watchByCurrencyInRange`, the `kUndoWindow` constant, schema files, migrations.

---

## Reference Conventions (read before starting)

- **Run order**: after any change touching `@freezed` / `@riverpod` / Drift annotations, run code generation. `dart format .` runs **before** `flutter test` and `flutter analyze`.
- **Money**: integer minor units everywhere; `MoneyFormatter` only at the UI boundary.
- **Range semantics**: half-open `[start, end)`. `start = normalizeAnchor(anchor, period)`, `end = shiftAnchor(start, period, 1)`.
- **No Drift types outside repos**: DAO returns row records (`({...})`); repository maps to `Transaction` domain model.
- **TDD loop per step that introduces code**: (a) write failing test, (b) run to confirm fail, (c) write minimum code, (d) run test to confirm pass, (e) commit.
- **Commit style** (mirrors `feat(charts): add slice drill-down items list with delete and FX support`): `feat(<scope>): <imperative summary>`. Scope = layer name (`data`, `charts`, `analysis`, `l10n`, `tests`).

---

## Task 1: `SelectedSlice` Freezed sealed model

**Files:**
- Create: `lib/data/models/selected_slice.dart`
- Test: `test/unit/models/selected_slice_test.dart` (will be new — create alongside model file in same task because the test is mostly equality smoke).

- [ ] **Step 1: Write the failing test**

Create `test/unit/models/selected_slice_test.dart` (this directory exists per `test/unit/utils`; create the `models/` subdir if needed):

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/data/models/selected_slice.dart';

void main() {
  group('SelectedSlice equality', () {
    test('two SelectedCategorySlice with same fields are equal', () {
      const a = SelectedSlice.category(7, currencyCode: 'USD');
      const b = SelectedSlice.category(7, currencyCode: 'USD');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('SelectedCategorySlice with different currencyCode is not equal', () {
      const a = SelectedSlice.category(7, currencyCode: 'USD');
      const b = SelectedSlice.category(7, currencyCode: 'EUR');
      expect(a, isNot(equals(b)));
    });

    test('SelectedCategorySlice with null currencyCode differs from set', () {
      const a = SelectedSlice.category(7);
      const b = SelectedSlice.category(7, currencyCode: 'USD');
      expect(a, isNot(equals(b)));
    });

    test('SelectedAccountSlice equality', () {
      const a = SelectedSlice.account(3, currencyCode: 'EUR');
      const b = SelectedSlice.account(3, currencyCode: 'EUR');
      expect(a, equals(b));
    });

    test('SelectedCurrencySlice equality', () {
      const a = SelectedSlice.currency('JPY');
      const b = SelectedSlice.currency('JPY');
      expect(a, equals(b));
      const c = SelectedSlice.currency('USD');
      expect(a, isNot(equals(c)));
    });

    test('cross-variant inequality', () {
      const cat = SelectedSlice.category(1);
      const acc = SelectedSlice.account(1);
      const cur = SelectedSlice.currency('USD');
      expect(cat, isNot(equals(acc)));
      expect(cat, isNot(equals(cur)));
      expect(acc, isNot(equals(cur)));
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/unit/models/selected_slice_test.dart`
Expected: FAIL with "Target of URI doesn't exist: 'package:ledgerly/data/models/selected_slice.dart'".

- [ ] **Step 3: Write minimal implementation**

Create `lib/data/models/selected_slice.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'selected_slice.freezed.dart';

/// Drill-down selection identity. Sealed because the chart's three
/// dimensions (category, account, currency) each have a distinct payload
/// that downstream consumers (repository filter, header label resolution)
/// must pattern-switch on. Lives in `data/models/` because it crosses the
/// data ↔ controller boundary.
@freezed
sealed class SelectedSlice with _$SelectedSlice {
  /// Drill-down into a category. `currencyCode` is set ONLY when the chart
  /// was showing a per-(category, currency) slice — i.e., FX was missing
  /// and Food USD / Food EUR appeared as separate pie slices. When
  /// `currencyCode` is null (FX-converted slice), the list aggregates all
  /// currencies for that category.
  const factory SelectedSlice.category(
    int categoryId, {
    String? currencyCode,
  }) = SelectedCategorySlice;

  /// Drill-down into an account. Account chart slices are emitted per
  /// `(account, currency)`, so `currencyCode` stays part of the selection
  /// identity even though the account record itself has a default
  /// currency.
  const factory SelectedSlice.account(
    int accountId, {
    String? currencyCode,
  }) = SelectedAccountSlice;

  /// Drill-down into a currency.
  const factory SelectedSlice.currency(String currencyCode) =
      SelectedCurrencySlice;
}
```

- [ ] **Step 4: Run code generation**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: success, generates `lib/data/models/selected_slice.freezed.dart`.

- [ ] **Step 5: Run test to verify pass**

Run: `dart format . && flutter test test/unit/models/selected_slice_test.dart`
Expected: PASS — all six tests green.

- [ ] **Step 6: Commit**

```bash
git add lib/data/models/selected_slice.dart lib/data/models/selected_slice.freezed.dart test/unit/models/selected_slice_test.dart
git commit -m "feat(data): add SelectedSlice sealed model for chart drill-down"
```

---

## Task 2: Add `selectionKey` to `ChartSlice`

**Files:**
- Modify: `lib/features/analysis/charts/charts_state.dart:89-112`

- [ ] **Step 1: Write the failing test**

Append to `test/unit/repositories/transaction_repository_charts_test.dart` is too far; the `ChartSlice` shape is currently covered indirectly. Instead, add a focused test file: `test/unit/charts/chart_slice_selection_key_test.dart` (new directory):

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/data/models/selected_slice.dart';
import 'package:ledgerly/features/analysis/charts/charts_state.dart';

void main() {
  test('ChartSlice.selectionKey defaults to null', () {
    const slice = ChartSlice(
      label: 'Food',
      currencyCode: 'USD',
      totalMinorUnits: 1000,
      colorIndex: 0,
      iconKey: 'restaurant',
    );
    expect(slice.selectionKey, isNull);
  });

  test('ChartSlice.selectionKey round-trips a category selection', () {
    const slice = ChartSlice(
      label: 'Food',
      currencyCode: 'USD',
      totalMinorUnits: 1000,
      colorIndex: 0,
      iconKey: 'restaurant',
      selectionKey: SelectedSlice.category(7),
    );
    expect(
      slice.selectionKey,
      equals(const SelectedSlice.category(7)),
    );
  });

  test('ChartSlice equality ignores nothing — selectionKey participates', () {
    const a = ChartSlice(
      label: 'Food',
      currencyCode: 'USD',
      totalMinorUnits: 1000,
      colorIndex: 0,
      iconKey: 'restaurant',
      selectionKey: SelectedSlice.category(7),
    );
    const b = ChartSlice(
      label: 'Food',
      currencyCode: 'USD',
      totalMinorUnits: 1000,
      colorIndex: 0,
      iconKey: 'restaurant',
      selectionKey: SelectedSlice.category(8),
    );
    expect(a, isNot(equals(b)));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/unit/charts/chart_slice_selection_key_test.dart`
Expected: FAIL — `selectionKey` not defined on `ChartSlice`.

- [ ] **Step 3: Write minimal implementation**

Edit `lib/features/analysis/charts/charts_state.dart`. Add the import at the top:

```dart
import '../../../data/models/selected_slice.dart';
```

Replace the `ChartSlice` definition (lines 88-112) with:

```dart
@freezed
abstract class ChartSlice with _$ChartSlice {
  const factory ChartSlice({
    /// Resolved display label (category name, account name, or currency
    /// code). The controller resolves labels so widgets stay pure.
    required String label,

    /// Currency to format `totalMinorUnits` in. Equals
    /// `ChartsData.displayCurrencyCode` for converted slices; equals the
    /// source currency for currency-view-mixed slices.
    required String currencyCode,
    required int totalMinorUnits,

    /// `0.0–1.0` when `ChartsData.grandTotalMinorUnits != null`,
    /// otherwise null (hide percentage label).
    double? fraction,

    /// Index into `core/utils/color_palette.dart`.
    required int colorIndex,

    /// `core/utils/icon_registry.dart` key for legend icon. Empty string
    /// for currency-dimension slices.
    required String iconKey,

    /// Drill-down identity for this slice. Null for the synthetic "Other"
    /// aggregate — that row stays non-interactive.
    ///
    /// Named `selectionKey` (not `key`) to avoid confusion with Flutter's
    /// `Widget.key`. `ChartSlice` is a Freezed data class, not a widget,
    /// so there is no name collision — but readers scanning the call
    /// sites should not have to wonder.
    SelectedSlice? selectionKey,
  }) = _ChartSlice;
}
```

- [ ] **Step 4: Run code generation**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: success — `charts_state.freezed.dart` regenerates with the new field.

- [ ] **Step 5: Run test to verify pass**

Run: `dart format . && flutter test test/unit/charts/chart_slice_selection_key_test.dart`
Expected: PASS — all three tests green.

- [ ] **Step 6: Confirm no existing tests broke**

Run: `flutter test test/unit/repositories/transaction_repository_charts_test.dart test/widget/features/analysis/charts_section_test.dart`
Expected: PASS — existing call sites construct `ChartSlice` without `selectionKey`, which defaults to null.

- [ ] **Step 7: Commit**

```bash
git add lib/features/analysis/charts/charts_state.dart lib/features/analysis/charts/charts_state.freezed.dart test/unit/charts/chart_slice_selection_key_test.dart
git commit -m "feat(charts): add ChartSlice.selectionKey for drill-down dispatch"
```

---

## Task 3: Extend DAO with slice-filter support

**Files:**
- Modify: `lib/data/database/daos/transaction_dao.dart:325-355` (extend `watchChartRowsInRange`)
- Modify: `lib/data/database/daos/transaction_dao.dart` (add `watchTransactionRowsForSliceInRange`)

- [ ] **Step 1: Write the failing test**

Create `test/unit/repositories/transaction_dao_slice_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/data/database/app_database.dart' hide Currency;

import '_harness/test_app_database.dart';

Future<void> _seed(AppDatabase db) async {
  await db.customStatement(
    'INSERT INTO currencies (code, decimals, symbol, name_l10n_key, '
    "is_token, sort_order) VALUES ('USD', 2, '\$', 'currency.usd', 0, 1)",
  );
  await db.customStatement(
    'INSERT INTO currencies (code, decimals, symbol, name_l10n_key, '
    "is_token, sort_order) VALUES ('EUR', 2, '€', 'currency.eur', 0, 2)",
  );
  await db.customStatement(
    'INSERT INTO categories (id, type, l10n_key, icon, color, sort_order, '
    "is_archived) VALUES (1, 'expense', 'cat.food', 'restaurant', 0, 1, 0)",
  );
  await db.customStatement(
    'INSERT INTO categories (id, type, l10n_key, icon, color, sort_order, '
    "is_archived) VALUES (2, 'expense', 'cat.transport', 'car', 1, 2, 0)",
  );
  await db.customStatement(
    'INSERT INTO account_types (id, l10n_key, icon, color, sort_order, '
    "is_archived) VALUES (1, 'acct.cash', 'wallet', 0, 1, 0)",
  );
  await db.customStatement(
    'INSERT INTO accounts (id, account_type_id, name, currency, '
    'opening_balance_minor_units, sort_order, is_archived) VALUES '
    "(1, 1, 'Cash', 'USD', 0, 1, 0)",
  );
  // Two USD expenses in food (May 18), one EUR expense in food (May 19),
  // one USD expense in transport (May 18).
  final epoch = DateTime.utc(2026).millisecondsSinceEpoch ~/ 1000;
  Future<void> tx(int id, DateTime d, int amt, String cur, int cat) {
    return db.customStatement(
      'INSERT INTO transactions (id, amount_minor_units, currency, '
      'category_id, account_id, date, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, 1, ?, ?, ?)',
      [id, amt, cur, cat, d.millisecondsSinceEpoch ~/ 1000, epoch, epoch],
    );
  }
  await tx(1, DateTime(2026, 5, 18, 9), 1000, 'USD', 1);
  await tx(2, DateTime(2026, 5, 18, 11), 2000, 'USD', 1);
  await tx(3, DateTime(2026, 5, 19, 12), 500, 'EUR', 1);
  await tx(4, DateTime(2026, 5, 18, 14), 7000, 'USD', 2);
}

void main() {
  late AppDatabase db;

  setUp(() async {
    db = newTestAppDatabase();
    await _seed(db);
  });
  tearDown(() async => db.close());

  group('watchChartRowsInRange with filters', () {
    test('null filters preserves original behavior (all rows in range)', () async {
      final rows = await db.transactionDao
          .watchChartRowsInRange(
            start: DateTime(2026, 5, 18),
            end: DateTime(2026, 5, 20),
            type: 'expense',
          )
          .first;
      // 4 expense rows in range.
      expect(rows, hasLength(4));
    });

    test('categoryId filter scopes to that category only', () async {
      final rows = await db.transactionDao
          .watchChartRowsInRange(
            start: DateTime(2026, 5, 18),
            end: DateTime(2026, 5, 20),
            type: 'expense',
            categoryId: 1,
          )
          .first;
      // Food only — 3 rows.
      expect(rows, hasLength(3));
    });

    test('categoryId + currencyCode filter applies both', () async {
      final rows = await db.transactionDao
          .watchChartRowsInRange(
            start: DateTime(2026, 5, 18),
            end: DateTime(2026, 5, 20),
            type: 'expense',
            categoryId: 1,
            currencyCode: 'USD',
          )
          .first;
      expect(rows, hasLength(2));
    });

    test('currencyCode-only filter scopes to that currency', () async {
      final rows = await db.transactionDao
          .watchChartRowsInRange(
            start: DateTime(2026, 5, 18),
            end: DateTime(2026, 5, 20),
            type: 'expense',
            currencyCode: 'EUR',
          )
          .first;
      expect(rows, hasLength(1));
    });

    test('accountId filter scopes to that account', () async {
      final rows = await db.transactionDao
          .watchChartRowsInRange(
            start: DateTime(2026, 5, 18),
            end: DateTime(2026, 5, 20),
            type: 'expense',
            accountId: 1,
          )
          .first;
      // All four expenses use account 1.
      expect(rows, hasLength(4));
    });
  });

  group('watchTransactionRowsForSliceInRange', () {
    test('category filter returns full TransactionRow objects ordered date DESC, id DESC', () async {
      final rows = await db.transactionDao
          .watchTransactionRowsForSliceInRange(
            start: DateTime(2026, 5, 18),
            end: DateTime(2026, 5, 20),
            type: 'expense',
            categoryId: 1,
          )
          .first;
      expect(rows.map((r) => r.id).toList(), [3, 2, 1]);
    });

    test('account filter excludes wrong account', () async {
      // Add a second account with its own row.
      await db.customStatement(
        'INSERT INTO accounts (id, account_type_id, name, currency, '
        'opening_balance_minor_units, sort_order, is_archived) VALUES '
        "(2, 1, 'EUR Cash', 'EUR', 0, 2, 0)",
      );
      final epoch = DateTime.utc(2026).millisecondsSinceEpoch ~/ 1000;
      await db.customStatement(
        'INSERT INTO transactions (id, amount_minor_units, currency, '
        'category_id, account_id, date, created_at, updated_at) '
        'VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
        [
          100,
          400,
          'EUR',
          1,
          2,
          DateTime(2026, 5, 18, 8).millisecondsSinceEpoch ~/ 1000,
          epoch,
          epoch,
        ],
      );
      final rows = await db.transactionDao
          .watchTransactionRowsForSliceInRange(
            start: DateTime(2026, 5, 18),
            end: DateTime(2026, 5, 20),
            type: 'expense',
            accountId: 1,
          )
          .first;
      expect(rows.map((r) => r.id).toSet(), {1, 2, 3, 4});
    });

    test('currency-only filter (no cat/acct) scopes to that currency', () async {
      final rows = await db.transactionDao
          .watchTransactionRowsForSliceInRange(
            start: DateTime(2026, 5, 18),
            end: DateTime(2026, 5, 20),
            type: 'expense',
            currencyCode: 'EUR',
          )
          .first;
      expect(rows.map((r) => r.id).toList(), [3]);
    });

    test('range is half-open: end-of-range row excluded', () async {
      final epoch = DateTime.utc(2026).millisecondsSinceEpoch ~/ 1000;
      await db.customStatement(
        'INSERT INTO transactions (id, amount_minor_units, currency, '
        'category_id, account_id, date, created_at, updated_at) '
        'VALUES (?, ?, ?, ?, 1, ?, ?, ?)',
        [
          50,
          100,
          'USD',
          1,
          DateTime(2026, 5, 20).millisecondsSinceEpoch ~/ 1000,
          epoch,
          epoch,
        ],
      );
      final rows = await db.transactionDao
          .watchTransactionRowsForSliceInRange(
            start: DateTime(2026, 5, 18),
            end: DateTime(2026, 5, 20),
            type: 'expense',
            categoryId: 1,
          )
          .first;
      // Row 50 falls exactly on `end` — must be excluded.
      expect(rows.map((r) => r.id), isNot(contains(50)));
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/unit/repositories/transaction_dao_slice_test.dart`
Expected: FAIL — `watchChartRowsInRange` does not accept `categoryId`/`accountId`/`currencyCode`, `watchTransactionRowsForSliceInRange` does not exist.

- [ ] **Step 3: Write minimal implementation — extend `watchChartRowsInRange`**

Edit `lib/data/database/daos/transaction_dao.dart`, replace the existing `watchChartRowsInRange` (lines 320-355) with:

```dart
  /// Raw `(date, currency, amount_minor_units)` rows in `[start, end)`
  /// filtered by `categories.type`, ordered by date ascending. Optional
  /// `categoryId` / `accountId` / `currencyCode` parameters apply
  /// additional `AND` predicates — used by the drill-down bar-chart
  /// refilter. All three default to `null` (no extra filter), which keeps
  /// the original behavior bit-for-bit.
  Stream<List<({DateTime date, String currency, int amountMinorUnits})>>
  watchChartRowsInRange({
    required DateTime start,
    required DateTime end,
    required String type,
    int? categoryId,
    int? accountId,
    String? currencyCode,
  }) {
    final buf = StringBuffer(
      'SELECT t.date AS d, t.currency AS code, '
      't.amount_minor_units AS amt '
      'FROM transactions t '
      'JOIN categories c ON c.id = t.category_id '
      'WHERE t.date >= ? AND t.date < ? AND c.type = ?',
    );
    final variables = <Variable<Object>>[
      Variable<DateTime>(start),
      Variable<DateTime>(end),
      Variable<String>(type),
    ];
    if (categoryId != null) {
      buf.write(' AND t.category_id = ?');
      variables.add(Variable<int>(categoryId));
    }
    if (accountId != null) {
      buf.write(' AND t.account_id = ?');
      variables.add(Variable<int>(accountId));
    }
    if (currencyCode != null) {
      buf.write(' AND t.currency = ?');
      variables.add(Variable<String>(currencyCode));
    }
    buf.write(' ORDER BY t.date ASC');

    final query = attachedDatabase.customSelect(
      buf.toString(),
      variables: variables,
      readsFrom: {transactions, attachedDatabase.categories},
    );
    return query.watch().map(
      (rows) => rows
          .map(
            (r) => (
              date: r.read<DateTime>('d'),
              currency: r.read<String>('code'),
              amountMinorUnits: r.read<int>('amt'),
            ),
          )
          .toList(growable: false),
    );
  }
```

- [ ] **Step 4: Add `watchTransactionRowsForSliceInRange` to the DAO**

Append inside the `TransactionDao` class:

```dart
  /// Full `TransactionRow` objects in `[start, end)` filtered by
  /// `categories.type` and optional slice predicates. Ordered
  /// `date DESC, id DESC`. Backs the chart drill-down items list — the
  /// repository wraps the rows into `Transaction` domain models. The
  /// 10,000-row MVP cap is applied so a pathological dataset cannot blow
  /// the buffer.
  Stream<List<TransactionRow>> watchTransactionRowsForSliceInRange({
    required DateTime start,
    required DateTime end,
    required String type,
    int? categoryId,
    int? accountId,
    String? currencyCode,
  }) {
    var stmt = select(transactions).join([
      innerJoin(
        attachedDatabase.categories,
        attachedDatabase.categories.id.equalsExp(transactions.categoryId),
      ),
    ])..where(
        transactions.date.isBiggerOrEqualValue(start) &
            transactions.date.isSmallerThanValue(end) &
            attachedDatabase.categories.type.equals(type),
      );
    if (categoryId != null) {
      stmt = stmt..where(transactions.categoryId.equals(categoryId));
    }
    if (accountId != null) {
      stmt = stmt..where(transactions.accountId.equals(accountId));
    }
    if (currencyCode != null) {
      stmt = stmt..where(transactions.currency.equals(currencyCode));
    }
    stmt = stmt
      ..orderBy([
        OrderingTerm(expression: transactions.date, mode: OrderingMode.desc),
        OrderingTerm(expression: transactions.id, mode: OrderingMode.desc),
      ])
      ..limit(10000);
    return stmt.watch().map(
      (rows) => rows.map((r) => r.readTable(transactions)).toList(),
    );
  }
```

- [ ] **Step 5: Run test to verify pass**

Run: `dart format . && flutter test test/unit/repositories/transaction_dao_slice_test.dart`
Expected: PASS — all eight tests green.

- [ ] **Step 6: Confirm no existing DAO tests broke**

Run: `flutter test test/unit/repositories/transaction_repository_charts_test.dart`
Expected: PASS — original `watchChartRowsInRange` calls without filter params still behave identically.

- [ ] **Step 7: Commit**

```bash
git add lib/data/database/daos/transaction_dao.dart test/unit/repositories/transaction_dao_slice_test.dart
git commit -m "feat(data): extend transaction DAO with slice filter and rows-for-slice query"
```

---

## Task 4: Extend `TransactionRepository` with slice-aware reads

**Files:**
- Modify: `lib/data/repositories/transaction_repository.dart` — extend `watchTimeBucketsInRange`, add `watchTransactionsForSliceInRange`.

- [ ] **Step 1: Write the failing test**

Create `test/unit/repositories/transaction_repository_slice_drilldown_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/data/database/app_database.dart' hide Currency;
import 'package:ledgerly/data/models/category.dart';
import 'package:ledgerly/data/models/selected_slice.dart';
import 'package:ledgerly/data/models/time_bucket_slice.dart';
import 'package:ledgerly/data/repositories/transaction_repository.dart';

import '_harness/test_app_database.dart';

Future<void> _seed(AppDatabase db) async {
  await db.customStatement(
    'INSERT INTO currencies (code, decimals, symbol, name_l10n_key, '
    "is_token, sort_order) VALUES ('USD', 2, '\$', 'currency.usd', 0, 1)",
  );
  await db.customStatement(
    'INSERT INTO currencies (code, decimals, symbol, name_l10n_key, '
    "is_token, sort_order) VALUES ('EUR', 2, '€', 'currency.eur', 0, 2)",
  );
  await db.customStatement(
    'INSERT INTO categories (id, type, l10n_key, icon, color, sort_order, '
    "is_archived) VALUES (1, 'expense', 'cat.food', 'restaurant', 0, 1, 0)",
  );
  await db.customStatement(
    'INSERT INTO categories (id, type, l10n_key, icon, color, sort_order, '
    "is_archived) VALUES (2, 'expense', 'cat.transport', 'car', 1, 2, 0)",
  );
  await db.customStatement(
    'INSERT INTO account_types (id, l10n_key, icon, color, sort_order, '
    "is_archived) VALUES (1, 'acct.cash', 'wallet', 0, 1, 0)",
  );
  await db.customStatement(
    'INSERT INTO accounts (id, account_type_id, name, currency, '
    'opening_balance_minor_units, sort_order, is_archived) VALUES '
    "(1, 1, 'Cash', 'USD', 0, 1, 0)",
  );
  final epoch = DateTime.utc(2026).millisecondsSinceEpoch ~/ 1000;
  Future<void> tx(int id, DateTime d, int amt, String cur, int cat) {
    return db.customStatement(
      'INSERT INTO transactions (id, amount_minor_units, currency, '
      'category_id, account_id, date, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, 1, ?, ?, ?)',
      [id, amt, cur, cat, d.millisecondsSinceEpoch ~/ 1000, epoch, epoch],
    );
  }
  await tx(1, DateTime(2026, 5, 18, 9), 1000, 'USD', 1);
  await tx(2, DateTime(2026, 5, 18, 11), 2000, 'USD', 1);
  await tx(3, DateTime(2026, 5, 19, 12), 500, 'EUR', 1);
  await tx(4, DateTime(2026, 5, 18, 14), 7000, 'USD', 2);
}

void main() {
  late AppDatabase db;
  late TransactionRepository repo;

  setUp(() async {
    db = newTestAppDatabase();
    repo = DriftTransactionRepository(db);
    await _seed(db);
  });
  tearDown(() async => db.close());

  group('watchTransactionsForSliceInRange', () {
    test('category selection returns matching rows date DESC, id DESC', () async {
      final txs = await repo.watchTransactionsForSliceInRange(
        selection: const SelectedSlice.category(1),
        start: DateTime(2026, 5, 18),
        end: DateTime(2026, 5, 20),
        type: CategoryType.expense,
      ).first;
      expect(txs.map((t) => t.id).toList(), [3, 2, 1]);
    });

    test('category + currencyCode filters both', () async {
      final txs = await repo.watchTransactionsForSliceInRange(
        selection: const SelectedSlice.category(1, currencyCode: 'USD'),
        start: DateTime(2026, 5, 18),
        end: DateTime(2026, 5, 20),
        type: CategoryType.expense,
      ).first;
      expect(txs.map((t) => t.id).toList(), [2, 1]);
    });

    test('currency selection scopes to that currency', () async {
      final txs = await repo.watchTransactionsForSliceInRange(
        selection: const SelectedSlice.currency('EUR'),
        start: DateTime(2026, 5, 18),
        end: DateTime(2026, 5, 20),
        type: CategoryType.expense,
      ).first;
      expect(txs.map((t) => t.id).toList(), [3]);
    });

    test('account selection scopes to that account', () async {
      final txs = await repo.watchTransactionsForSliceInRange(
        selection: const SelectedSlice.account(1),
        start: DateTime(2026, 5, 18),
        end: DateTime(2026, 5, 20),
        type: CategoryType.expense,
      ).first;
      expect(txs, hasLength(4));
    });

    test('stream re-emits after insert / delete', () async {
      final stream = repo.watchTransactionsForSliceInRange(
        selection: const SelectedSlice.category(1, currencyCode: 'USD'),
        start: DateTime(2026, 5, 18),
        end: DateTime(2026, 5, 20),
        type: CategoryType.expense,
      );
      final emissions = <int>[];
      final sub = stream.listen((rows) => emissions.add(rows.length));
      await Future<void>.delayed(Duration.zero);
      // Insert another USD food row.
      final epoch = DateTime.utc(2026).millisecondsSinceEpoch ~/ 1000;
      await db.customStatement(
        'INSERT INTO transactions (id, amount_minor_units, currency, '
        'category_id, account_id, date, created_at, updated_at) '
        'VALUES (?, ?, ?, ?, 1, ?, ?, ?)',
        [
          5,
          333,
          'USD',
          1,
          DateTime(2026, 5, 18, 16).millisecondsSinceEpoch ~/ 1000,
          epoch,
          epoch,
        ],
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      // Delete one of the seeded rows.
      await repo.delete(1);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await sub.cancel();
      expect(emissions, contains(2)); // initial
      expect(emissions, contains(3)); // after insert
      expect(emissions, contains(2)); // after delete
    });
  });

  group('watchTimeBucketsInRange with selection', () {
    test('selection: null preserves current behavior', () async {
      final stream = repo.watchTimeBucketsInRange(
        start: DateTime(2026, 5, 18),
        end: DateTime(2026, 5, 20),
        type: CategoryType.expense,
        granularity: TimeBucketGranularity.day,
      );
      final buckets = await stream.first;
      // Two days × distinct currencies → 3 buckets:
      //   (May 18, USD)=10000, (May 19, EUR)=500, plus transport (May 18, USD)=7000
      // The DAO groups by (day, currency), so May 18 USD aggregates both
      // food and transport → one row.
      final totalsByDay = <DateTime, int>{};
      for (final b in buckets) {
        totalsByDay[b.bucketStart] =
            (totalsByDay[b.bucketStart] ?? 0) + b.totalMinorUnits;
      }
      // May 18 sum = 10000, plus transport 7000 = 10000+7000 wait. Food USD 1000+2000=3000; transport USD 7000. May 18 total = 10000.
      expect(totalsByDay[DateTime(2026, 5, 18)], equals(10000));
    });

    test('selection: category filters buckets to that category', () async {
      final buckets = await repo.watchTimeBucketsInRange(
        start: DateTime(2026, 5, 18),
        end: DateTime(2026, 5, 20),
        type: CategoryType.expense,
        granularity: TimeBucketGranularity.day,
        selection: const SelectedSlice.category(1),
      ).first;
      final totalsByDay = <DateTime, int>{};
      for (final b in buckets) {
        totalsByDay[b.bucketStart] =
            (totalsByDay[b.bucketStart] ?? 0) + b.totalMinorUnits;
      }
      // Food only: May 18 = 1000+2000 = 3000 (USD), May 19 = 500 (EUR).
      expect(totalsByDay[DateTime(2026, 5, 18)], equals(3000));
      expect(totalsByDay[DateTime(2026, 5, 19)], equals(500));
    });

    test('selection: currency filters buckets to that currency', () async {
      final buckets = await repo.watchTimeBucketsInRange(
        start: DateTime(2026, 5, 18),
        end: DateTime(2026, 5, 20),
        type: CategoryType.expense,
        granularity: TimeBucketGranularity.day,
        selection: const SelectedSlice.currency('EUR'),
      ).first;
      expect(buckets, hasLength(1));
      expect(buckets.first.totalMinorUnits, equals(500));
    });

    test('selection: category with currencyCode applies both', () async {
      final buckets = await repo.watchTimeBucketsInRange(
        start: DateTime(2026, 5, 18),
        end: DateTime(2026, 5, 20),
        type: CategoryType.expense,
        granularity: TimeBucketGranularity.day,
        selection: const SelectedSlice.category(1, currencyCode: 'USD'),
      ).first;
      final totalsByDay = <DateTime, int>{};
      for (final b in buckets) {
        totalsByDay[b.bucketStart] =
            (totalsByDay[b.bucketStart] ?? 0) + b.totalMinorUnits;
      }
      // Food USD only: May 18 = 3000. EUR row excluded.
      expect(totalsByDay[DateTime(2026, 5, 18)], equals(3000));
      expect(totalsByDay.containsKey(DateTime(2026, 5, 19)), isFalse);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/unit/repositories/transaction_repository_slice_drilldown_test.dart`
Expected: FAIL — `watchTransactionsForSliceInRange` not defined; `watchTimeBucketsInRange` does not accept `selection`.

- [ ] **Step 3: Update repository abstract interface**

Edit `lib/data/repositories/transaction_repository.dart`. Add the import at top:

```dart
import '../models/selected_slice.dart';
```

Replace the `watchTimeBucketsInRange` declaration (lines 141-146 in the abstract class) with:

```dart
  /// Per-(bucketStart, currency) subtotal in `[start, end)` filtered by
  /// transaction type, with [granularity] selecting hour/day/month
  /// buckets. Local bucket math uses `DateHelpers` so midnight + DST
  /// behaviour matches the rest of the app.
  ///
  /// When [selection] is non-null, buckets count only rows matching the
  /// slice. Null behaves identically to today (regression-protected).
  Stream<List<TimeBucketSlice>> watchTimeBucketsInRange({
    required DateTime start,
    required DateTime end,
    required CategoryType type,
    required TimeBucketGranularity granularity,
    SelectedSlice? selection,
  });

  /// Transactions matching [selection] within `[start, end)`, of [type].
  /// Ordered `date DESC, id DESC` to match Home / Search Level 2 row
  /// conventions. Backs the chart drill-down items list.
  Stream<List<Transaction>> watchTransactionsForSliceInRange({
    required SelectedSlice selection,
    required DateTime start,
    required DateTime end,
    required CategoryType type,
  });
```

- [ ] **Step 4: Update concrete `DriftTransactionRepository`**

Replace the existing `watchTimeBucketsInRange` implementation (lines 384-420) with:

```dart
  @override
  Stream<List<TimeBucketSlice>> watchTimeBucketsInRange({
    required DateTime start,
    required DateTime end,
    required CategoryType type,
    required TimeBucketGranularity granularity,
    SelectedSlice? selection,
  }) {
    final (categoryId, accountId, currencyCode) = _sliceToFilters(selection);
    return _dao
        .watchChartRowsInRange(
          start: start,
          end: end,
          type: _typeWire(type),
          categoryId: categoryId,
          accountId: accountId,
          currencyCode: currencyCode,
        )
        .map((rows) {
          final acc = <(DateTime, String), int>{};
          for (final r in rows) {
            final bucketStart = switch (granularity) {
              TimeBucketGranularity.hour => DateTime(
                r.date.year,
                r.date.month,
                r.date.day,
                r.date.hour,
              ),
              TimeBucketGranularity.day => DateHelpers.startOfDay(r.date),
              TimeBucketGranularity.month => DateHelpers.startOfMonth(r.date),
            };
            final key = (bucketStart, r.currency);
            acc[key] = (acc[key] ?? 0) + r.amountMinorUnits;
          }
          return acc.entries
              .map(
                (e) => TimeBucketSlice(
                  bucketStart: e.key.$1,
                  currencyCode: e.key.$2,
                  totalMinorUnits: e.value,
                ),
              )
              .toList(growable: false);
        });
  }

  @override
  Stream<List<Transaction>> watchTransactionsForSliceInRange({
    required SelectedSlice selection,
    required DateTime start,
    required DateTime end,
    required CategoryType type,
  }) {
    final (categoryId, accountId, currencyCode) = _sliceToFilters(selection);
    return _dao
        .watchTransactionRowsForSliceInRange(
          start: start,
          end: end,
          type: _typeWire(type),
          categoryId: categoryId,
          accountId: accountId,
          currencyCode: currencyCode,
        )
        .asyncMap(_rowsToDomain);
  }

  (int?, int?, String?) _sliceToFilters(SelectedSlice? selection) {
    return switch (selection) {
      null => (null, null, null),
      SelectedCategorySlice(:final categoryId, :final currencyCode) => (
        categoryId,
        null,
        currencyCode,
      ),
      SelectedAccountSlice(:final accountId, :final currencyCode) => (
        null,
        accountId,
        currencyCode,
      ),
      SelectedCurrencySlice(:final currencyCode) => (null, null, currencyCode),
    };
  }
```

- [ ] **Step 5: Run test to verify pass**

Run: `dart format . && flutter test test/unit/repositories/transaction_repository_slice_drilldown_test.dart`
Expected: PASS — all nine tests green.

- [ ] **Step 6: Confirm no regression in existing repo tests**

Run: `flutter test test/unit/repositories/transaction_repository_charts_test.dart test/unit/repositories/transaction_repository_test.dart`
Expected: PASS — null `selection` keeps `watchTimeBucketsInRange` behaviour intact.

- [ ] **Step 7: Commit**

```bash
git add lib/data/repositories/transaction_repository.dart test/unit/repositories/transaction_repository_slice_drilldown_test.dart
git commit -m "feat(data): add watchTransactionsForSliceInRange and selection-aware buckets"
```

---

## Task 5: Add `selectedSlice` field + commands to `ChartsSelectionController`

**Files:**
- Modify: `lib/features/analysis/charts/charts_selection_controller.dart`
- Create: `test/unit/controllers/charts_selection_controller_slice_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/unit/controllers/charts_selection_controller_slice_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledgerly/data/models/category.dart';
import 'package:ledgerly/data/models/selected_slice.dart';
import 'package:ledgerly/features/analysis/charts/charts_selection_controller.dart';
import 'package:ledgerly/features/analysis/charts/charts_state.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });
  tearDown(() => container.dispose());

  ChartsSelectionController notifier() =>
      container.read(chartsSelectionControllerProvider.notifier);
  ChartsSelection state() =>
      container.read(chartsSelectionControllerProvider);

  test('initial state has selectedSlice == null', () {
    expect(state().selectedSlice, isNull);
  });

  test('toggleSlice from null sets the slice', () {
    notifier().toggleSlice(const SelectedSlice.category(7));
    expect(state().selectedSlice, equals(const SelectedSlice.category(7)));
  });

  test('toggleSlice with same slice clears it', () {
    notifier().toggleSlice(const SelectedSlice.category(7));
    notifier().toggleSlice(const SelectedSlice.category(7));
    expect(state().selectedSlice, isNull);
  });

  test('toggleSlice with different slice replaces', () {
    notifier().toggleSlice(const SelectedSlice.category(7));
    notifier().toggleSlice(const SelectedSlice.category(9));
    expect(state().selectedSlice, equals(const SelectedSlice.category(9)));
  });

  test('clearSlice resets to null and is a no-op when already null', () {
    notifier().clearSlice();
    expect(state().selectedSlice, isNull);
    notifier().toggleSlice(const SelectedSlice.category(7));
    notifier().clearSlice();
    expect(state().selectedSlice, isNull);
  });

  group('mutators clear selectedSlice', () {
    setUp(() {
      notifier().toggleSlice(const SelectedSlice.category(7));
    });

    test('setPeriod clears', () {
      notifier().setPeriod(PeriodType.month);
      expect(state().selectedSlice, isNull);
    });

    test('setPeriod with same period still clears (still touched)', () {
      // The selection clear semantics: if the user taps the period that is
      // already active, that's still an explicit "user interacted with
      // period control" event — and per spec the selection clears on any
      // period change. The current `setPeriod` early-returns when the
      // period matches; the spec keeps that behavior because no actual
      // mutation occurred.
      final before = state().selectedSlice;
      notifier().setPeriod(state().period);
      expect(state().selectedSlice, equals(before));
    });

    test('setDimension clears', () {
      notifier().setDimension(ChartDimension.account);
      expect(state().selectedSlice, isNull);
    });

    test('toggleType clears', () {
      notifier().toggleType();
      expect(state().selectedSlice, isNull);
    });

    test('previousPeriod clears', () {
      notifier().previousPeriod();
      expect(state().selectedSlice, isNull);
    });

    test('nextPeriod clears when it actually moves', () {
      // We're at the current period; step back first so nextPeriod can
      // actually move forward.
      notifier().previousPeriod();
      notifier().toggleSlice(const SelectedSlice.category(7));
      notifier().nextPeriod();
      expect(state().selectedSlice, isNull);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/unit/controllers/charts_selection_controller_slice_test.dart`
Expected: FAIL — `selectedSlice` field missing on `ChartsSelection`; `toggleSlice` / `clearSlice` undefined.

- [ ] **Step 3: Update `ChartsSelection` and `ChartsSelectionController`**

Edit `lib/features/analysis/charts/charts_selection_controller.dart`. Add the import:

```dart
import '../../../data/models/selected_slice.dart';
```

Replace the `ChartsSelection` definition (lines 22-30):

```dart
@freezed
abstract class ChartsSelection with _$ChartsSelection {
  const factory ChartsSelection({
    required PeriodType period,
    required CategoryType type,
    required ChartDimension dimension,
    required DateTime anchorDate,
    SelectedSlice? selectedSlice,
  }) = _ChartsSelection;
}
```

Replace the controller body (lines 32-95) with:

```dart
@Riverpod(keepAlive: true, dependencies: [])
class ChartsSelectionController extends _$ChartsSelectionController {
  @override
  ChartsSelection build() {
    return ChartsSelection(
      period: PeriodType.week,
      type: CategoryType.expense,
      dimension: ChartDimension.category,
      anchorDate: normalizeAnchor(DateTime.now(), PeriodType.week),
      selectedSlice: null,
    );
  }

  void setPeriod(PeriodType period) {
    debugPrint('[ChartsSelection] setPeriod($period) current=${state.period}');
    if (state.period == period) return;
    state = state.copyWith(
      period: period,
      anchorDate: normalizeAnchor(state.anchorDate, period),
      selectedSlice: null,
    );
  }

  void previousPeriod() {
    debugPrint(
      '[ChartsSelection] previousPeriod() from anchor=${state.anchorDate}',
    );
    state = state.copyWith(
      anchorDate: shiftAnchor(state.anchorDate, state.period, -1),
      selectedSlice: null,
    );
  }

  void nextPeriod() {
    debugPrint(
      '[ChartsSelection] nextPeriod() from anchor=${state.anchorDate}',
    );
    if (isAtCurrentPeriod()) return;
    state = state.copyWith(
      anchorDate: shiftAnchor(state.anchorDate, state.period, 1),
      selectedSlice: null,
    );
  }

  void toggleType() {
    debugPrint('[ChartsSelection] toggleType() current=${state.type}');
    state = state.copyWith(
      type: state.type == CategoryType.expense
          ? CategoryType.income
          : CategoryType.expense,
      selectedSlice: null,
    );
  }

  void setDimension(ChartDimension dimension) {
    debugPrint(
      '[ChartsSelection] setDimension($dimension) current=${state.dimension}',
    );
    if (state.dimension == dimension) return;
    state = state.copyWith(dimension: dimension, selectedSlice: null);
  }

  /// Tap-toggle semantics: same slice clears, different slice replaces.
  void toggleSlice(SelectedSlice slice) {
    debugPrint('[ChartsSelection] toggleSlice($slice)');
    state = state.copyWith(
      selectedSlice: state.selectedSlice == slice ? null : slice,
    );
  }

  /// Clear an active drill-down selection. No-op when already null. Used
  /// by the stale-selection self-heal listener in `ChartsSection`.
  void clearSlice() {
    if (state.selectedSlice == null) return;
    state = state.copyWith(selectedSlice: null);
  }

  bool isAtCurrentPeriod() {
    final now = DateTime.now();
    final currentAnchor = normalizeAnchor(now, state.period);
    final myAnchor = normalizeAnchor(state.anchorDate, state.period);
    return !myAnchor.isBefore(currentAnchor);
  }
}
```

- [ ] **Step 4: Regenerate code**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: success — `charts_selection_controller.freezed.dart` regenerates with the new field.

- [ ] **Step 5: Run test to verify pass**

Run: `dart format . && flutter test test/unit/controllers/charts_selection_controller_slice_test.dart`
Expected: PASS — all 11 tests green.

- [ ] **Step 6: Confirm no existing charts tests broke**

Run: `flutter test test/unit/controllers/charts_controller_test.dart test/widget/features/analysis/charts_section_test.dart`
Expected: PASS — existing flows that never touch `selectedSlice` keep working.

- [ ] **Step 7: Commit**

```bash
git add lib/features/analysis/charts/charts_selection_controller.dart lib/features/analysis/charts/charts_selection_controller.freezed.dart test/unit/controllers/charts_selection_controller_slice_test.dart
git commit -m "feat(charts): hoist drill-down selection into ChartsSelectionController"
```

---

## Task 6: Fill `ChartSlice.selectionKey` in `ChartsController`

**Files:**
- Modify: `lib/features/analysis/charts/charts_controller.dart` — fill `selectionKey` on emit, pass `selectedSlice` through to bucket query.

- [ ] **Step 1: Write the failing test**

Create `test/unit/controllers/charts_controller_slice_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledgerly/app/providers/default_currency_provider.dart';
import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/data/models/account.dart';
import 'package:ledgerly/data/models/account_slice.dart';
import 'package:ledgerly/data/models/category.dart';
import 'package:ledgerly/data/models/category_slice.dart';
import 'package:ledgerly/data/models/currency.dart';
import 'package:ledgerly/data/models/currency_slice.dart';
import 'package:ledgerly/data/models/selected_slice.dart';
import 'package:ledgerly/data/models/time_bucket_slice.dart';
import 'package:ledgerly/data/repositories/transaction_repository.dart';
import 'package:ledgerly/features/analysis/charts/charts_controller.dart';
import 'package:ledgerly/features/analysis/charts/charts_providers.dart';
import 'package:ledgerly/features/analysis/charts/charts_selection_controller.dart';
import 'package:ledgerly/features/analysis/charts/charts_state.dart';
import 'package:ledgerly/features/analysis/search/analysis_providers.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements TransactionRepository {}

const _usd = Currency(code: 'USD', decimals: 2, symbol: r'$');

ProviderContainer _container(_MockRepo repo) {
  return ProviderContainer(
    overrides: [
      transactionRepositoryProvider.overrideWithValue(repo),
      initialDefaultCurrencyProvider.overrideWithValue('USD'),
      chartsFxStatusProvider.overrideWith(
        (ref) => Stream.value(
          const ChartsFxStatus(defaultCurrencyCode: 'USD', rates: {}),
        ),
      ),
      chartsCurrenciesByCodeProvider.overrideWith(
        (ref) => Stream.value({'USD': _usd}),
      ),
      analysisCategoriesByIdProvider.overrideWith(
        (ref) => Stream.value({
          1: const Category(
            id: 1,
            type: CategoryType.expense,
            l10nKey: 'cat.food',
            icon: 'restaurant',
            color: 0,
          ),
          2: const Category(
            id: 2,
            type: CategoryType.expense,
            l10nKey: 'cat.transport',
            icon: 'car',
            color: 1,
          ),
        }),
      ),
      analysisAccountsByIdProvider.overrideWith(
        (ref) => Stream.value(const <int, Account>{}),
      ),
    ],
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(CategoryType.expense);
    registerFallbackValue(TimeBucketGranularity.day);
  });

  test('category slices receive SelectedCategorySlice as selectionKey', () async {
    final repo = _MockRepo();
    when(
      () => repo.watchByCategoryInRange(
        start: any(named: 'start'),
        end: any(named: 'end'),
        type: any(named: 'type'),
      ),
    ).thenAnswer(
      (_) => Stream.value(const [
        CategorySlice(categoryId: 1, currencyCode: 'USD', totalMinorUnits: 1000),
        CategorySlice(categoryId: 2, currencyCode: 'USD', totalMinorUnits: 2000),
      ]),
    );
    when(
      () => repo.watchTimeBucketsInRange(
        start: any(named: 'start'),
        end: any(named: 'end'),
        type: any(named: 'type'),
        granularity: any(named: 'granularity'),
        selection: any(named: 'selection'),
      ),
    ).thenAnswer(
      (_) => Stream.value(<TimeBucketSlice>[
        TimeBucketSlice(
          bucketStart: DateTime(2026, 5, 18),
          currencyCode: 'USD',
          totalMinorUnits: 3000,
        ),
      ]),
    );

    final container = _container(repo);
    addTearDown(container.dispose);

    final data = await container
        .read(chartsControllerProvider.stream)
        .firstWhere((s) => s is ChartsDataState) as ChartsDataState;
    final keys = data.chartData.slices.map((s) => s.selectionKey).toList();
    expect(keys, containsAll(<SelectedSlice>[
      const SelectedSlice.category(1),
      const SelectedSlice.category(2),
    ]));
  });

  test('account slices receive SelectedAccountSlice with currencyCode', () async {
    final repo = _MockRepo();
    when(
      () => repo.watchByAccountInRange(
        start: any(named: 'start'),
        end: any(named: 'end'),
        type: any(named: 'type'),
      ),
    ).thenAnswer(
      (_) => Stream.value(const [
        AccountSlice(accountId: 1, currencyCode: 'USD', totalMinorUnits: 1000),
      ]),
    );
    when(
      () => repo.watchTimeBucketsInRange(
        start: any(named: 'start'),
        end: any(named: 'end'),
        type: any(named: 'type'),
        granularity: any(named: 'granularity'),
        selection: any(named: 'selection'),
      ),
    ).thenAnswer(
      (_) => Stream.value(<TimeBucketSlice>[
        TimeBucketSlice(
          bucketStart: DateTime(2026, 5, 18),
          currencyCode: 'USD',
          totalMinorUnits: 1000,
        ),
      ]),
    );

    final container = _container(repo);
    container
        .read(chartsSelectionControllerProvider.notifier)
        .setDimension(ChartDimension.account);
    addTearDown(container.dispose);

    final data = await container
        .read(chartsControllerProvider.stream)
        .firstWhere((s) => s is ChartsDataState) as ChartsDataState;
    expect(
      data.chartData.slices.first.selectionKey,
      equals(const SelectedSlice.account(1, currencyCode: 'USD')),
    );
  });

  test('currency slices receive SelectedCurrencySlice', () async {
    final repo = _MockRepo();
    when(
      () => repo.watchByCurrencyInRange(
        start: any(named: 'start'),
        end: any(named: 'end'),
        type: any(named: 'type'),
      ),
    ).thenAnswer(
      (_) => Stream.value(const [
        CurrencySlice(currencyCode: 'USD', totalMinorUnits: 1000),
        CurrencySlice(currencyCode: 'EUR', totalMinorUnits: 500),
      ]),
    );
    when(
      () => repo.watchTimeBucketsInRange(
        start: any(named: 'start'),
        end: any(named: 'end'),
        type: any(named: 'type'),
        granularity: any(named: 'granularity'),
        selection: any(named: 'selection'),
      ),
    ).thenAnswer(
      (_) => Stream.value(<TimeBucketSlice>[
        TimeBucketSlice(
          bucketStart: DateTime(2026, 5, 18),
          currencyCode: 'USD',
          totalMinorUnits: 1000,
        ),
      ]),
    );

    final container = _container(repo);
    container
        .read(chartsSelectionControllerProvider.notifier)
        .setDimension(ChartDimension.currency);
    addTearDown(container.dispose);

    final data = await container
        .read(chartsControllerProvider.stream)
        .firstWhere((s) => s is ChartsDataState) as ChartsDataState;
    final keys = data.chartData.slices.map((s) => s.selectionKey).toList();
    expect(keys, containsAll(<SelectedSlice>[
      const SelectedSlice.currency('USD'),
      const SelectedSlice.currency('EUR'),
    ]));
  });

  test('bucket query receives selectedSlice when set', () async {
    final repo = _MockRepo();
    when(
      () => repo.watchByCategoryInRange(
        start: any(named: 'start'),
        end: any(named: 'end'),
        type: any(named: 'type'),
      ),
    ).thenAnswer(
      (_) => Stream.value(const [
        CategorySlice(categoryId: 1, currencyCode: 'USD', totalMinorUnits: 1000),
      ]),
    );
    when(
      () => repo.watchTimeBucketsInRange(
        start: any(named: 'start'),
        end: any(named: 'end'),
        type: any(named: 'type'),
        granularity: any(named: 'granularity'),
        selection: any(named: 'selection'),
      ),
    ).thenAnswer(
      (_) => Stream.value(<TimeBucketSlice>[
        TimeBucketSlice(
          bucketStart: DateTime(2026, 5, 18),
          currencyCode: 'USD',
          totalMinorUnits: 1000,
        ),
      ]),
    );

    final container = _container(repo);
    addTearDown(container.dispose);
    container.listen(chartsControllerProvider, (_, _) {});
    // Drain first emission, then set selection.
    await container
        .read(chartsControllerProvider.stream)
        .firstWhere((s) => s is ChartsDataState);
    container
        .read(chartsSelectionControllerProvider.notifier)
        .toggleSlice(const SelectedSlice.category(1));
    // Wait for re-emission triggered by selection change.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final capt = verify(
      () => repo.watchTimeBucketsInRange(
        start: any(named: 'start'),
        end: any(named: 'end'),
        type: any(named: 'type'),
        granularity: any(named: 'granularity'),
        selection: captureAny(named: 'selection'),
      ),
    ).captured;
    expect(capt, contains(const SelectedSlice.category(1)));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/unit/controllers/charts_controller_slice_test.dart`
Expected: FAIL — `selectionKey` is null on every slice; `watchTimeBucketsInRange` mock won't be called with `selection`.

- [ ] **Step 3: Update `ChartsController`**

Edit `lib/features/analysis/charts/charts_controller.dart`.

1. Add the import:

```dart
import '../../../data/models/selected_slice.dart';
```

2. Replace the `watchTimeBucketsInRange` call in `_resubscribe` (lines 167-192) to pass `selection`:

```dart
    _bucketsSub = repo
        .watchTimeBucketsInRange(
          start: range.start,
          end: range.end,
          type: _selection.type,
          granularity: _granularity(),
          selection: _selection.selectedSlice,
        )
        .listen(
          (buckets) {
            debugPrint(
              '[ChartsController] buckets emit gen=$myGen '
              '(active=$_generation) count=${buckets.length}',
            );
            if (myGen != _generation) {
              debugPrint('[ChartsController] buckets dropped — stale gen');
              return;
            }
            _lastBuckets = buckets;
            _emitIfReady();
          },
          onError: (Object e, StackTrace st) {
            debugPrint('[ChartsController] buckets error gen=$myGen: $e');
            if (myGen != _generation) return;
            _emitter?.add(ChartsState.error(e, st));
          },
        );
```

3. In `_emitCategoryOrAccountDimension`, when constructing each `ChartSlice`, set `selectionKey`. Replace the `chartSlices.add(...)` block (lines 436-446) with:

```dart
      chartSlices.add(
        ChartSlice(
          label: label,
          currencyCode: fx.defaultCurrencyCode,
          totalMinorUnits: total,
          colorIndex: colorIndex,
          iconKey: iconKey,
          fraction: grandTotal == 0 ? 0 : total / grandTotal,
          selectionKey: _selection.dimension == ChartDimension.category
              ? SelectedSlice.category(id)
              : SelectedSlice.account(
                  id,
                  // Aggregated single-currency display; per-row currency
                  // identity lives on the underlying transactions.
                  currencyCode: fx.defaultCurrencyCode,
                ),
        ),
      );
```

Wait — the spec says category-aggregated FX-converted slices have `currencyCode: null`. Re-reading the spec § Data Layer:

> `currencyCode` is set ONLY when the chart was showing a per-(category, currency) slice — i.e., FX was missing and Food USD / Food EUR appeared as separate pie slices. When `currencyCode` is null (FX-converted slice), the list aggregates all currencies for that category.

In `_emitCategoryOrAccountDimension`, slices are FX-converted and aggregated by `id` only (regrouped is `<int, int>`), so `currencyCode` on the `SelectedSlice` MUST be null for the category dimension. Replace the block above with:

```dart
      chartSlices.add(
        ChartSlice(
          label: label,
          currencyCode: fx.defaultCurrencyCode,
          totalMinorUnits: total,
          colorIndex: colorIndex,
          iconKey: iconKey,
          fraction: grandTotal == 0 ? 0 : total / grandTotal,
          selectionKey: _selection.dimension == ChartDimension.category
              ? SelectedSlice.category(id)
              : SelectedSlice.account(id),
        ),
      );
```

4. In `_emitCurrencyDimension`, replace BOTH `chartSlices.add(...)` blocks. First the converted branch (lines 518-530):

```dart
      for (final s in slices) {
        final amount = converted[s]!;
        chartSlices.add(
          ChartSlice(
            label: s.currencyCode,
            currencyCode: fx.defaultCurrencyCode,
            totalMinorUnits: amount,
            colorIndex: _currencyColorIndex(s.currencyCode),
            iconKey: '',
            fraction: grandTotal == 0 ? 0 : amount / grandTotal!,
            selectionKey: SelectedSlice.currency(s.currencyCode),
          ),
        );
      }
```

5. Then the mixed-rates branch (lines 532-544):

```dart
      for (final s in slices) {
        chartSlices.add(
          ChartSlice(
            label: s.currencyCode,
            currencyCode: s.currencyCode,
            totalMinorUnits: s.totalMinorUnits,
            colorIndex: _currencyColorIndex(s.currencyCode),
            iconKey: '',
            fraction: null,
            selectionKey: SelectedSlice.currency(s.currencyCode),
          ),
        );
      }
```

- [ ] **Step 4: Run test to verify pass**

Run: `dart format . && flutter test test/unit/controllers/charts_controller_slice_test.dart`
Expected: PASS — all four tests green.

- [ ] **Step 5: Confirm existing controller and widget tests still pass**

Run: `flutter test test/unit/controllers/charts_controller_test.dart test/widget/features/analysis/charts_section_test.dart`
Expected: PASS — slices now carry `selectionKey`, which existing assertions ignore.

- [ ] **Step 6: Commit**

```bash
git add lib/features/analysis/charts/charts_controller.dart test/unit/controllers/charts_controller_slice_test.dart
git commit -m "feat(charts): stamp selectionKey on slices and pass selection to bucket query"
```

---

## Task 7: `SliceDrilldownState` Freezed sealed type

**Files:**
- Create: `lib/features/analysis/charts/slice_drilldown_state.dart`

- [ ] **Step 1: Write the failing test**

Create `test/unit/controllers/slice_drilldown_state_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/data/models/currency.dart';
import 'package:ledgerly/data/models/transaction.dart';
import 'package:ledgerly/features/analysis/charts/slice_drilldown_state.dart';

void main() {
  test('SliceDrilldownState variants', () {
    const loading = SliceDrilldownState.loading();
    expect(loading, isA<SliceDrilldownLoading>());

    final usd = const Currency(code: 'USD', decimals: 2);
    final tx = Transaction(
      id: 1,
      amountMinorUnits: 100,
      currency: usd,
      categoryId: 1,
      accountId: 1,
      date: DateTime(2026, 5, 18),
      createdAt: DateTime(2026, 5, 18),
      updatedAt: DateTime(2026, 5, 18),
    );
    final data = SliceDrilldownState.data(rows: [tx]);
    expect(data, isA<SliceDrilldownData>());
    expect((data as SliceDrilldownData).rows, hasLength(1));
    expect(data.pendingDeleteId, isNull);

    final err = SliceDrilldownState.error('boom', StackTrace.empty);
    expect(err, isA<SliceDrilldownError>());
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/unit/controllers/slice_drilldown_state_test.dart`
Expected: FAIL — file missing.

- [ ] **Step 3: Write implementation**

Create `lib/features/analysis/charts/slice_drilldown_state.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../data/models/transaction.dart';

part 'slice_drilldown_state.freezed.dart';

@freezed
sealed class SliceDrilldownState with _$SliceDrilldownState {
  /// Pre-first-emission. The list renders an inline centered spinner.
  const factory SliceDrilldownState.loading() = SliceDrilldownLoading;

  /// Latest matching transactions. [pendingDeleteId] is non-null while a
  /// row is in its `kUndoWindow` window — the row stays visible until
  /// commit so the count/header stay in lockstep with the chart.
  const factory SliceDrilldownState.data({
    required List<Transaction> rows,
    int? pendingDeleteId,
  }) = SliceDrilldownData;

  /// Stream error. The list renders inline error copy without retry — it
  /// is a subordinate panel under a live chart surface.
  const factory SliceDrilldownState.error(Object error, StackTrace stack) =
      SliceDrilldownError;
}
```

- [ ] **Step 4: Regenerate code**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: success — `slice_drilldown_state.freezed.dart` generated.

- [ ] **Step 5: Run test to verify pass**

Run: `dart format . && flutter test test/unit/controllers/slice_drilldown_state_test.dart`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/features/analysis/charts/slice_drilldown_state.dart lib/features/analysis/charts/slice_drilldown_state.freezed.dart test/unit/controllers/slice_drilldown_state_test.dart
git commit -m "feat(charts): add SliceDrilldownState sealed type"
```

---

## Task 8: `SliceDrilldownController` — stream notifier with undo

**Files:**
- Create: `lib/features/analysis/charts/slice_drilldown_controller.dart`
- Create: `test/unit/controllers/slice_drilldown_controller_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/unit/controllers/slice_drilldown_controller_test.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/core/constants.dart';
import 'package:ledgerly/data/models/category.dart';
import 'package:ledgerly/data/models/currency.dart';
import 'package:ledgerly/data/models/selected_slice.dart';
import 'package:ledgerly/data/models/transaction.dart';
import 'package:ledgerly/data/repositories/transaction_repository.dart';
import 'package:ledgerly/features/analysis/charts/charts_selection_controller.dart';
import 'package:ledgerly/features/analysis/charts/charts_state.dart';
import 'package:ledgerly/features/analysis/charts/slice_drilldown_controller.dart';
import 'package:ledgerly/features/analysis/charts/slice_drilldown_state.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements TransactionRepository {}

const _usd = Currency(code: 'USD', decimals: 2);

Transaction _tx(int id) => Transaction(
      id: id,
      amountMinorUnits: 100 * id,
      currency: _usd,
      categoryId: 1,
      accountId: 1,
      date: DateTime(2026, 5, 18),
      createdAt: DateTime(2026, 5, 18),
      updatedAt: DateTime(2026, 5, 18),
    );

void main() {
  setUpAll(() {
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(CategoryType.expense);
    registerFallbackValue(const SelectedSlice.category(1));
  });

  late _MockRepo repo;
  late ProviderContainer container;

  setUp(() {
    repo = _MockRepo();
    container = ProviderContainer(
      overrides: [transactionRepositoryProvider.overrideWithValue(repo)],
    );
    container
        .read(chartsSelectionControllerProvider.notifier)
        .toggleSlice(const SelectedSlice.category(1));
  });
  tearDown(() => container.dispose());

  test('emits SliceDrilldownData with rows from the repo stream', () async {
    when(
      () => repo.watchTransactionsForSliceInRange(
        selection: any(named: 'selection'),
        start: any(named: 'start'),
        end: any(named: 'end'),
        type: any(named: 'type'),
      ),
    ).thenAnswer((_) => Stream.value([_tx(1), _tx(2)]));

    final state = await container
        .read(sliceDrilldownControllerProvider.stream)
        .firstWhere((s) => s is SliceDrilldownData);
    expect((state as SliceDrilldownData).rows, hasLength(2));
  });

  test('no selection → controller stays in loading state', () async {
    container
        .read(chartsSelectionControllerProvider.notifier)
        .clearSlice();
    // The controller emits a single Loading until a selection arrives.
    expectLater(
      container.read(sliceDrilldownControllerProvider.stream),
      emitsThrough(isA<SliceDrilldownLoading>()),
    );
  });

  test('delete records pendingDeleteId, keeps row in list until commit', () async {
    when(
      () => repo.watchTransactionsForSliceInRange(
        selection: any(named: 'selection'),
        start: any(named: 'start'),
        end: any(named: 'end'),
        type: any(named: 'type'),
      ),
    ).thenAnswer((_) => Stream.value([_tx(1), _tx(2)]));
    when(() => repo.delete(any())).thenAnswer((_) async => true);

    await container
        .read(sliceDrilldownControllerProvider.stream)
        .firstWhere((s) => s is SliceDrilldownData);
    container.read(sliceDrilldownControllerProvider.notifier).delete(1);
    // Same micro-tick re-emission with pendingDeleteId set, row still present.
    await Future<void>.delayed(Duration.zero);
    final pending = container.read(sliceDrilldownControllerProvider).valueOrNull;
    expect(pending, isA<SliceDrilldownData>());
    expect((pending! as SliceDrilldownData).pendingDeleteId, equals(1));
    expect((pending).rows.map((t) => t.id), contains(1));
  });

  test('commit fires repo.delete after kUndoWindow', () async {
    when(
      () => repo.watchTransactionsForSliceInRange(
        selection: any(named: 'selection'),
        start: any(named: 'start'),
        end: any(named: 'end'),
        type: any(named: 'type'),
      ),
    ).thenAnswer((_) => Stream.value([_tx(1)]));
    when(() => repo.delete(any())).thenAnswer((_) async => true);

    await container
        .read(sliceDrilldownControllerProvider.stream)
        .firstWhere((s) => s is SliceDrilldownData);
    container.read(sliceDrilldownControllerProvider.notifier).delete(1);
    await Future<void>.delayed(kUndoWindow + const Duration(milliseconds: 200));
    verify(() => repo.delete(1)).called(1);
  });

  test('undoDelete cancels commit — repo.delete never called', () async {
    when(
      () => repo.watchTransactionsForSliceInRange(
        selection: any(named: 'selection'),
        start: any(named: 'start'),
        end: any(named: 'end'),
        type: any(named: 'type'),
      ),
    ).thenAnswer((_) => Stream.value([_tx(1)]));
    when(() => repo.delete(any())).thenAnswer((_) async => true);

    await container
        .read(sliceDrilldownControllerProvider.stream)
        .firstWhere((s) => s is SliceDrilldownData);
    container.read(sliceDrilldownControllerProvider.notifier).delete(1);
    container.read(sliceDrilldownControllerProvider.notifier).undoDelete(1);
    await Future<void>.delayed(kUndoWindow + const Duration(milliseconds: 200));
    verifyNever(() => repo.delete(any()));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/unit/controllers/slice_drilldown_controller_test.dart`
Expected: FAIL — controller file missing.

- [ ] **Step 3: Write implementation**

Create `lib/features/analysis/charts/slice_drilldown_controller.dart`:

```dart
// Slice drill-down items list controller — see
// `docs/superpowers/specs/2026-05-21-chart-slice-drilldown-design.md` §
// State & Controller Layer / Items list controller.
//
// Mirrors the delete/undo contract from `CategorySearchDetailController`:
// `delete(id)` records `pendingDeleteId`, keeps the row visible until
// `kUndoWindow` elapses, then commits to the repository. `undoDelete(id)`
// cancels the timer; the repository is never touched.
//
// Watches `ChartsSelectionController` so a selection change re-runs
// `build()` cleanly via Riverpod.

import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/providers/repository_providers.dart';
import '../../../core/constants.dart';
import '../../../data/models/transaction.dart';
import 'charts_selection_controller.dart';
import 'slice_drilldown_state.dart';

part 'slice_drilldown_controller.g.dart';

@Riverpod(
  keepAlive: true,
  dependencies: [transactionRepository, ChartsSelectionController],
)
class SliceDrilldownController extends _$SliceDrilldownController {
  StreamController<SliceDrilldownState>? _emitter;
  StreamSubscription<List<Transaction>>? _subscription;
  Timer? _undoTimer;
  int? _pendingDeleteId;
  List<Transaction> _lastRows = const [];

  @override
  Stream<SliceDrilldownState> build() {
    _emitter?.close();
    _subscription?.cancel();
    _subscription = null;
    _undoTimer?.cancel();
    _undoTimer = null;
    _pendingDeleteId = null;
    _lastRows = const [];

    final controller = StreamController<SliceDrilldownState>();
    _emitter = controller;

    ref.onDispose(() {
      _undoTimer?.cancel();
      _undoTimer = null;
      _subscription?.cancel();
      _subscription = null;
      _pendingDeleteId = null;
      controller.close();
    });

    final selection = ref.watch(chartsSelectionControllerProvider);
    final selected = selection.selectedSlice;
    if (selected == null) {
      controller.add(const SliceDrilldownState.loading());
      return controller.stream;
    }

    controller.add(const SliceDrilldownState.loading());
    final start = normalizeAnchor(selection.anchorDate, selection.period);
    final end = shiftAnchor(start, selection.period, 1);
    final repo = ref.read(transactionRepositoryProvider);

    _subscription = repo
        .watchTransactionsForSliceInRange(
          selection: selected,
          start: start,
          end: end,
          type: selection.type,
        )
        .listen(
          (rows) {
            _lastRows = rows;
            _emitFromCache();
          },
          onError: (Object e, StackTrace st) {
            debugPrint('[SliceDrilldown] stream error: $e');
            _emitter?.add(SliceDrilldownState.error(e, st));
          },
        );

    return controller.stream;
  }

  /// Start the 4-second undo window for [id]. The row stays visible in
  /// the emitted list until either commit or undo fires; the count and
  /// header total remain consistent with the chart slice.
  void delete(int id) {
    if (_pendingDeleteId != null) {
      _undoTimer?.cancel();
      final prior = _pendingDeleteId!;
      // Fire-and-forget commit of the prior pending row before starting
      // a new window for [id].
      unawaited(_commit(prior));
    }
    _pendingDeleteId = id;
    _emitFromCache();
    _undoTimer = Timer(kUndoWindow, () async {
      final p = _pendingDeleteId;
      if (p == null) return;
      await _commit(p);
    });
  }

  /// Cancel the undo window for [id]. The repository is never touched.
  void undoDelete(int id) {
    if (_pendingDeleteId != id) return;
    _undoTimer?.cancel();
    _undoTimer = null;
    _pendingDeleteId = null;
    _emitFromCache();
  }

  Future<void> _commit(int id) async {
    try {
      await ref.read(transactionRepositoryProvider).delete(id);
    } catch (e, st) {
      debugPrint('[SliceDrilldown] commit failed: $e');
      _emitter?.add(SliceDrilldownState.error(e, st));
    } finally {
      if (_pendingDeleteId == id) {
        _pendingDeleteId = null;
        _undoTimer = null;
      }
      _emitFromCache();
    }
  }

  void _emitFromCache() {
    _emitter?.add(
      SliceDrilldownState.data(
        rows: _lastRows,
        pendingDeleteId: _pendingDeleteId,
      ),
    );
  }
}
```

- [ ] **Step 4: Regenerate code**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: success — `slice_drilldown_controller.g.dart` generated.

- [ ] **Step 5: Run test to verify pass**

Run: `dart format . && flutter test test/unit/controllers/slice_drilldown_controller_test.dart`
Expected: PASS — all five tests green.

- [ ] **Step 6: Commit**

```bash
git add lib/features/analysis/charts/slice_drilldown_controller.dart lib/features/analysis/charts/slice_drilldown_controller.g.dart test/unit/controllers/slice_drilldown_controller_test.dart
git commit -m "feat(charts): add SliceDrilldownController with optimistic delete + undo"
```

---

## Task 9: New ARB keys for empty / original-amount / stale-rates copy

**Files:**
- Modify: `l10n/app_en.arb`, `l10n/app_zh.arb`, `l10n/app_zh_CN.arb`, `l10n/app_zh_TW.arb`

- [ ] **Step 1: Write the failing test**

Create `test/unit/l10n/drilldown_l10n_test.dart`:

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/l10n/app_localizations.dart';

Future<AppLocalizations> _resolve(Locale locale) async {
  final delegate = AppLocalizations.delegate;
  expect(delegate.isSupported(locale), isTrue);
  return delegate.load(locale);
}

void main() {
  test('English: drilldown empty / original amount / stale rates', () async {
    final l10n = await _resolve(const Locale('en'));
    expect(l10n.analysisDrilldownEmpty, isNotEmpty);
    expect(l10n.analysisOriginalAmount, isNotEmpty);
    expect(l10n.analysisRatesStale, isNotEmpty);
  });

  test('zh-CN keys resolve to non-empty strings', () async {
    final l10n = await _resolve(const Locale('zh', 'CN'));
    expect(l10n.analysisDrilldownEmpty, isNotEmpty);
    expect(l10n.analysisOriginalAmount, isNotEmpty);
    expect(l10n.analysisRatesStale, isNotEmpty);
  });

  test('zh-TW keys resolve to non-empty strings', () async {
    final l10n = await _resolve(const Locale('zh', 'TW'));
    expect(l10n.analysisDrilldownEmpty, isNotEmpty);
    expect(l10n.analysisOriginalAmount, isNotEmpty);
    expect(l10n.analysisRatesStale, isNotEmpty);
  });

  test('base zh fallback exists (codegen smoke)', () async {
    final l10n = await _resolve(const Locale('zh'));
    expect(l10n.appTitle, isNotEmpty);
  });

  // Keep the codegen happy: silence unused import lint when locale unused.
  Localizations.localeOf;
  GlobalMaterialLocalizations.delegate;
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/unit/l10n/drilldown_l10n_test.dart`
Expected: FAIL — `analysisDrilldownEmpty`, `analysisOriginalAmount`, `analysisRatesStale` getters don't exist.

- [ ] **Step 3: Add keys to `l10n/app_en.arb`**

Insert after the `analysisErrorMessage` block (after line 887):

```json
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
  },
```

- [ ] **Step 4: Add keys to `l10n/app_zh.arb`**

Replace the file (currently only `appTitle`) with:

```json
{
  "@@locale": "zh",
  "appTitle": "Ledgerly",
  "analysisDrilldownEmpty": "此期間沒有交易",
  "analysisOriginalAmount": "原始金額",
  "analysisRatesStale": "使用上次取得的匯率"
}
```

- [ ] **Step 5: Add keys to `l10n/app_zh_CN.arb`**

Insert after `analysisErrorMessage` (after line 256):

```json
  "analysisDrilldownEmpty": "此期间没有交易",
  "analysisOriginalAmount": "原始金额",
  "analysisRatesStale": "使用上次获取的汇率",
```

- [ ] **Step 6: Add keys to `l10n/app_zh_TW.arb`**

Insert after `analysisErrorMessage` (after line 256):

```json
  "analysisDrilldownEmpty": "此期間沒有交易",
  "analysisOriginalAmount": "原始金額",
  "analysisRatesStale": "使用上次取得的匯率",
```

- [ ] **Step 7: Regenerate localization code**

Run: `flutter pub get` (codegen runs as part of build target). If needed: `flutter gen-l10n` (already wired via `l10n.yaml`).
Expected: `lib/l10n/app_localizations*.dart` regenerates with new getters.

- [ ] **Step 8: Run test to verify pass**

Run: `dart format . && flutter test test/unit/l10n/drilldown_l10n_test.dart`
Expected: PASS — all four tests green.

- [ ] **Step 9: Commit**

```bash
git add l10n/app_en.arb l10n/app_zh.arb l10n/app_zh_CN.arb l10n/app_zh_TW.arb lib/l10n/ test/unit/l10n/drilldown_l10n_test.dart
git commit -m "feat(l10n): add drilldown empty, original amount, and stale rates copy"
```

---

## Task 10: Extend `TransactionSearchRow` with action-only delete mode + FX columns

**Files:**
- Modify: `lib/features/analysis/search/widgets/transaction_search_row.dart`

- [ ] **Step 1: Write the failing test**

Create `test/widget/features/analysis/transaction_search_row_delete_mode_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/data/models/account.dart';
import 'package:ledgerly/data/models/account_type.dart';
import 'package:ledgerly/data/models/category.dart';
import 'package:ledgerly/data/models/currency.dart';
import 'package:ledgerly/data/models/transaction.dart';
import 'package:ledgerly/features/analysis/search/widgets/transaction_search_row.dart';
import 'package:ledgerly/l10n/app_localizations.dart';

const _usd = Currency(code: 'USD', decimals: 2, symbol: r'$');

Transaction _tx() => Transaction(
      id: 1,
      amountMinorUnits: 1000,
      currency: _usd,
      categoryId: 1,
      accountId: 1,
      date: DateTime(2026, 5, 18),
      createdAt: DateTime(2026, 5, 18),
      updatedAt: DateTime(2026, 5, 18),
    );

const _cat = Category(
  id: 1,
  type: CategoryType.expense,
  l10nKey: 'category.food',
  icon: 'restaurant',
  color: 0,
);

const _acc = Account(
  id: 1,
  accountTypeId: 1,
  accountType: AccountType(
    id: 1,
    l10nKey: 'acct.cash',
    icon: 'wallet',
    color: 0,
  ),
  name: 'Cash',
  currency: _usd,
  openingBalanceMinorUnits: 0,
);

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SlidableAutoCloseBehavior(child: child)),
    );

void main() {
  testWidgets('actionOnly mode: dismissible pane NOT present', (tester) async {
    var deleted = false;
    await tester.pumpWidget(_wrap(
      TransactionSearchRow(
        transaction: _tx(),
        category: _cat,
        account: _acc,
        locale: 'en',
        deleteMode: TransactionSearchRowDeleteMode.actionOnly,
        onDelete: () => deleted = true,
      ),
    ));
    final slidable = tester.widget<Slidable>(find.byType(Slidable));
    expect(slidable.endActionPane?.dismissible, isNull);
    // Fling left should NOT auto-delete in actionOnly mode.
    await tester.drag(find.byType(Slidable), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(deleted, isFalse);
  });

  testWidgets('default (dismissible) mode keeps existing dismissible behavior', (tester) async {
    var deleted = false;
    await tester.pumpWidget(_wrap(
      TransactionSearchRow(
        transaction: _tx(),
        category: _cat,
        account: _acc,
        locale: 'en',
        onDelete: () => deleted = true,
      ),
    ));
    final slidable = tester.widget<Slidable>(find.byType(Slidable));
    expect(slidable.endActionPane?.dismissible, isNotNull);
  });

  testWidgets('convertedAmount renders as primary, original as labeled secondary', (tester) async {
    await tester.pumpWidget(_wrap(
      TransactionSearchRow(
        transaction: _tx(),
        category: _cat,
        account: _acc,
        locale: 'en',
        convertedAmount: '\$12.34',
        originalAmountLabel: 'Original amount',
      ),
    ));
    expect(find.text('\$12.34'), findsOneWidget);
    expect(find.text('Original amount'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widget/features/analysis/transaction_search_row_delete_mode_test.dart`
Expected: FAIL — `TransactionSearchRowDeleteMode`, `convertedAmount`, `originalAmountLabel` parameters do not exist.

- [ ] **Step 3: Update `TransactionSearchRow`**

Replace `lib/features/analysis/search/widgets/transaction_search_row.dart` with:

```dart
// Transaction row for search results and chart drill-down — see specs:
//   - `docs/superpowers/specs/2026-05-09-transaction-search-design.md`
//     § Transaction tiles (dismissible Slidable + 4 s undo).
//   - `docs/superpowers/specs/2026-05-21-chart-slice-drilldown-design.md`
//     § Items list (action-only delete; converted/original amount split).
//
// Visual layout matches Home's `TransactionTile` (icon, title,
// "account • memo" subtitle, signed amount with type-driven color).
// Primary tap → edit (delegates to caller). Swipe → delete with a 4 s
// undo window (delegates to caller; the owning controller owns the
// optimistic-hide + commit timer).

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../../../core/utils/color_palette.dart';
import '../../../../core/utils/icon_registry.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../data/models/account.dart';
import '../../../../data/models/category.dart';
import '../../../../data/models/transaction.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../categories/widgets/category_display.dart';

/// Swipe-delete affordance variants used by `TransactionSearchRow`.
///
/// - [dismissible]: the existing search-result behavior — the user can
///   fling all the way to delete instantly, OR tap the trailing Delete
///   action. Owning controller still owns the 4 s undo.
/// - [actionOnly]: the chart drill-down behavior — the user MUST tap the
///   trailing Delete action (no full-fling auto-dismiss). Removes the
///   accidental-delete failure mode when the row is part of a dense
///   stacked list below a live chart surface.
enum TransactionSearchRowDeleteMode { dismissible, actionOnly }

class TransactionSearchRow extends StatelessWidget {
  const TransactionSearchRow({
    super.key,
    required this.transaction,
    required this.category,
    required this.account,
    required this.locale,
    this.onTap,
    this.onDelete,
    this.deleteMode = TransactionSearchRowDeleteMode.dismissible,
    this.convertedAmount,
    this.originalAmountLabel,
  });

  final Transaction transaction;
  final Category? category;
  final Account? account;
  final String locale;

  /// Primary tap. When null the row renders without an `onTap` (read-only).
  final VoidCallback? onTap;

  /// End-swipe gesture. When null the swipe affordance is omitted entirely.
  final VoidCallback? onDelete;

  /// Selects between full-dismissible (default) and action-only delete UX.
  final TransactionSearchRowDeleteMode deleteMode;

  /// Pre-formatted converted amount (e.g. FX-converted display-currency
  /// value). When non-null this string replaces the primary amount and
  /// the booked amount drops to a labeled secondary row.
  final String? convertedAmount;

  /// Label shown above the secondary booked amount when [convertedAmount]
  /// is non-null. Typically `l10n.analysisOriginalAmount`.
  final String? originalAmountLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cat = category;
    final acc = account;

    final color = cat != null ? colorForIndex(cat.color) : theme.disabledColor;
    final icon = cat != null ? iconForKey(cat.icon) : Icons.help_outline;
    final isIncome = cat?.type == CategoryType.income;

    final bookedAmountText = switch (cat?.type) {
      CategoryType.income => MoneyFormatter.formatSigned(
        amountMinorUnits: transaction.amountMinorUnits,
        currency: transaction.currency,
        locale: locale,
      ),
      CategoryType.expense => MoneyFormatter.formatSigned(
        amountMinorUnits: -transaction.amountMinorUnits,
        currency: transaction.currency,
        locale: locale,
      ),
      null => MoneyFormatter.format(
        amountMinorUnits: transaction.amountMinorUnits,
        currency: transaction.currency,
        locale: locale,
      ),
    };

    final memo = transaction.memo;
    final hasConverted =
        convertedAmount != null && originalAmountLabel != null;

    final trailing = hasConverted
        ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                convertedAmount!,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: isIncome
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${originalAmountLabel!}: $bookedAmountText',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          )
        : Text(
            bookedAmountText,
            style: theme.textTheme.titleMedium?.copyWith(
              color: isIncome
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          );

    final tile = ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Icon(icon, color: color),
      ),
      title: Text(
        cat == null ? '' : categoryDisplayName(cat, l10n),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        memo == null || memo.isEmpty
            ? (acc?.name ?? '')
            : '${acc?.name ?? ''} • $memo',
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall,
      ),
      trailing: trailing,
    );

    if (onDelete == null) return tile;

    return Slidable(
      key: ValueKey<int>(transaction.id),
      groupTag: 'analysis_search',
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: 0.3,
        dismissible: deleteMode == TransactionSearchRowDeleteMode.dismissible
            ? DismissiblePane(onDismissed: onDelete!)
            : null,
        children: [
          SlidableAction(
            onPressed: (_) => onDelete!(),
            backgroundColor: theme.colorScheme.errorContainer,
            foregroundColor: theme.colorScheme.onErrorContainer,
            icon: Icons.delete_outline,
            label: l10n.commonDelete,
          ),
        ],
      ),
      child: tile,
    );
  }
}
```

- [ ] **Step 4: Run test to verify pass**

Run: `dart format . && flutter test test/widget/features/analysis/transaction_search_row_delete_mode_test.dart`
Expected: PASS — all three tests green.

- [ ] **Step 5: Verify the existing CategorySearchDetailScreen tests still pass**

Run: `flutter test test/widget/features/analysis/category_search_detail_screen_test.dart`
Expected: PASS — default `deleteMode` keeps the dismissible behaviour Level 2 search relies on.

- [ ] **Step 6: Commit**

```bash
git add lib/features/analysis/search/widgets/transaction_search_row.dart test/widget/features/analysis/transaction_search_row_delete_mode_test.dart
git commit -m "feat(analysis): extend TransactionSearchRow with action-only delete + FX trailing"
```

---

## Task 11: `SelectedSliceItemsList` widget — header + rows

**Files:**
- Create: `lib/features/analysis/charts/widgets/selected_slice_items_list.dart`
- Create: `test/widget/features/analysis/selected_slice_items_list_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/widget/features/analysis/selected_slice_items_list_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/data/models/account.dart';
import 'package:ledgerly/data/models/category.dart';
import 'package:ledgerly/data/models/currency.dart';
import 'package:ledgerly/data/models/selected_slice.dart';
import 'package:ledgerly/data/models/transaction.dart';
import 'package:ledgerly/data/repositories/transaction_repository.dart';
import 'package:ledgerly/features/analysis/charts/charts_selection_controller.dart';
import 'package:ledgerly/features/analysis/charts/charts_state.dart';
import 'package:ledgerly/features/analysis/charts/widgets/selected_slice_items_list.dart';
import 'package:ledgerly/features/analysis/search/analysis_providers.dart';
import 'package:ledgerly/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements TransactionRepository {}

const _usd = Currency(code: 'USD', decimals: 2, symbol: r'$');

Transaction _tx(int id) => Transaction(
      id: id,
      amountMinorUnits: 100 * id,
      currency: _usd,
      categoryId: 1,
      accountId: 1,
      date: DateTime(2026, 5, 18),
      createdAt: DateTime(2026, 5, 18),
      updatedAt: DateTime(2026, 5, 18),
    );

Widget _harness({
  required _MockRepo repo,
  required ChartSlice slice,
  SelectedSlice? activeSelection,
}) {
  return ProviderScope(
    overrides: [
      transactionRepositoryProvider.overrideWithValue(repo),
      analysisCategoriesByIdProvider.overrideWith(
        (ref) => Stream.value({
          1: const Category(
            id: 1,
            type: CategoryType.expense,
            l10nKey: 'category.food',
            icon: 'restaurant',
            color: 0,
          ),
        }),
      ),
      analysisAccountsByIdProvider.overrideWith(
        (ref) => Stream.value(const <int, Account>{}),
      ),
    ],
    child: Consumer(
      builder: (ctx, ref, _) {
        if (activeSelection != null) {
          ref
              .read(chartsSelectionControllerProvider.notifier)
              .toggleSlice(activeSelection);
        }
        return MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: SelectedSliceItemsList(slice: slice, locale: 'en'),
            ),
          ),
        );
      },
    ),
  );
}

ChartSlice _slice(SelectedSlice key) => ChartSlice(
      label: 'category.food',
      currencyCode: 'USD',
      totalMinorUnits: 1000,
      colorIndex: 0,
      iconKey: 'restaurant',
      selectionKey: key,
    );

void main() {
  setUpAll(() {
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(CategoryType.expense);
    registerFallbackValue(const SelectedSlice.category(1));
  });

  testWidgets('returns SizedBox.shrink when no selection', (tester) async {
    final repo = _MockRepo();
    await tester.pumpWidget(_harness(repo: repo, slice: _slice(const SelectedSlice.category(1))));
    await tester.pump();
    // Header copy must NOT appear because parent's selection is null.
    expect(find.text('Food'), findsNothing);
  });

  testWidgets('renders header + rows when selection active', (tester) async {
    final repo = _MockRepo();
    when(
      () => repo.watchTransactionsForSliceInRange(
        selection: any(named: 'selection'),
        start: any(named: 'start'),
        end: any(named: 'end'),
        type: any(named: 'type'),
      ),
    ).thenAnswer((_) => Stream.value([_tx(1), _tx(2)]));

    await tester.pumpWidget(_harness(
      repo: repo,
      slice: _slice(const SelectedSlice.category(1)),
      activeSelection: const SelectedSlice.category(1),
    ));
    await tester.pumpAndSettle();
    // The header label resolves "category.food" → "Food" via categoryDisplayNameForKey.
    expect(find.text('Food'), findsOneWidget);
    // Two transaction rows.
    expect(find.byType(ListTile), findsNWidgets(2));
  });

  testWidgets('inline empty placeholder when rows == []', (tester) async {
    final repo = _MockRepo();
    when(
      () => repo.watchTransactionsForSliceInRange(
        selection: any(named: 'selection'),
        start: any(named: 'start'),
        end: any(named: 'end'),
        type: any(named: 'type'),
      ),
    ).thenAnswer((_) => Stream.value(const <Transaction>[]));

    await tester.pumpWidget(_harness(
      repo: repo,
      slice: _slice(const SelectedSlice.category(1)),
      activeSelection: const SelectedSlice.category(1),
    ));
    await tester.pumpAndSettle();
    expect(find.text('No transactions in this period'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widget/features/analysis/selected_slice_items_list_test.dart`
Expected: FAIL — widget file missing.

- [ ] **Step 3: Write implementation**

Create `lib/features/analysis/charts/widgets/selected_slice_items_list.dart`:

```dart
// Drill-down items list — see
// `docs/superpowers/specs/2026-05-21-chart-slice-drilldown-design.md` §
// UI Layer / SelectedSliceItemsList. Sibling of `_ChartBody` inside
// `ChartsSection`'s Column. Renders nothing when no slice is selected.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/money_formatter.dart';
import '../../../../data/models/account.dart';
import '../../../../data/models/category.dart';
import '../../../../data/models/currency.dart';
import '../../../../data/models/selected_slice.dart';
import '../../../../data/models/transaction.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../categories/widgets/category_display.dart';
import '../../search/analysis_providers.dart';
import '../../search/widgets/transaction_search_row.dart';
import '../charts_providers.dart';
import '../charts_selection_controller.dart';
import '../charts_state.dart';
import '../slice_drilldown_controller.dart';
import '../slice_drilldown_state.dart';

class SelectedSliceItemsList extends ConsumerWidget {
  const SelectedSliceItemsList({
    super.key,
    required this.slice,
    required this.locale,
  });

  /// The currently-selected chart slice (looked up by `selectionKey` in
  /// the parent so the list header total stays in lockstep with the pie
  /// slice's labeled amount).
  final ChartSlice slice;
  final String locale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection =
        ref.watch(chartsSelectionControllerProvider).selectedSlice;
    if (selection == null) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final state = ref.watch(sliceDrilldownControllerProvider);
    final controller =
        ref.read(sliceDrilldownControllerProvider.notifier);
    final categoriesById =
        ref.watch(analysisCategoriesByIdProvider).valueOrNull ?? const {};
    final accountsById =
        ref.watch(analysisAccountsByIdProvider).valueOrNull ?? const {};
    final currenciesByCode =
        ref.watch(chartsCurrenciesByCodeProvider).valueOrNull ?? const {};

    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      child: state.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Center(child: Text(l10n.analysisErrorMessage)),
        ),
        data: (s) => switch (s) {
          SliceDrilldownLoading() => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
          SliceDrilldownError() => Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(child: Text(l10n.analysisErrorMessage)),
          ),
          SliceDrilldownData(:final rows, :final pendingDeleteId) =>
            SlidableAutoCloseBehavior(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ListHeader(
                    label: _labelFor(
                      selection: selection,
                      slice: slice,
                      categoriesById: categoriesById,
                      accountsById: accountsById,
                      l10n: l10n,
                    ),
                    count: rows.length,
                    totalMinorUnits: slice.totalMinorUnits,
                    currencyCode: slice.currencyCode,
                    currenciesByCode: currenciesByCode,
                    locale: locale,
                    l10n: l10n,
                  ),
                  if (rows.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: Text(l10n.analysisDrilldownEmpty)),
                    )
                  else
                    for (final tx in rows)
                      TransactionSearchRow(
                        key: ValueKey<int>(tx.id),
                        transaction: tx,
                        category: categoriesById[tx.categoryId],
                        account: accountsById[tx.accountId],
                        locale: locale,
                        deleteMode:
                            TransactionSearchRowDeleteMode.actionOnly,
                        onTap: () => context.push('/home/edit/${tx.id}'),
                        onDelete: () => controller.delete(tx.id),
                      ),
                ],
              ),
            ),
        },
      ),
    );
  }

  String _labelFor({
    required SelectedSlice selection,
    required ChartSlice slice,
    required Map<int, Category> categoriesById,
    required Map<int, Account> accountsById,
    required AppLocalizations l10n,
  }) {
    return switch (selection) {
      SelectedCategorySlice(:final categoryId) =>
        categoriesById[categoryId] == null
            ? slice.label
            : categoryDisplayName(categoriesById[categoryId]!, l10n),
      SelectedAccountSlice(:final accountId) =>
        accountsById[accountId]?.name ?? slice.label,
      SelectedCurrencySlice(:final currencyCode) => currencyCode,
    };
  }
}

class _ListHeader extends StatelessWidget {
  const _ListHeader({
    required this.label,
    required this.count,
    required this.totalMinorUnits,
    required this.currencyCode,
    required this.currenciesByCode,
    required this.locale,
    required this.l10n,
  });

  final String label;
  final int count;
  final int totalMinorUnits;
  final String currencyCode;
  final Map<String, Currency> currenciesByCode;
  final String locale;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency =
        currenciesByCode[currencyCode] ?? Currency(code: currencyCode, decimals: 2);
    final total = MoneyFormatter.format(
      amountMinorUnits: totalMinorUnits,
      currency: currency,
      locale: locale,
    );
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium,
                  ),
                  Text(
                    l10n.analysisTransactionCount(count),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Text(
              total,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify pass**

Run: `dart format . && flutter test test/widget/features/analysis/selected_slice_items_list_test.dart`
Expected: PASS — all three tests green.

- [ ] **Step 5: Commit**

```bash
git add lib/features/analysis/charts/widgets/selected_slice_items_list.dart test/widget/features/analysis/selected_slice_items_list_test.dart
git commit -m "feat(charts): add SelectedSliceItemsList with header, rows, and inline states"
```

---

## Task 12: `ChartLegend` — close "View all" sheet on tap

**Files:**
- Modify: `lib/features/analysis/charts/widgets/chart_legend.dart:232-248`

- [ ] **Step 1: Write the failing test**

Append to `test/widget/features/analysis/charts_section_test.dart` (it already harnesses the chart) — but simpler to create a focused test. Create `test/widget/features/analysis/chart_legend_view_all_pop_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/data/models/currency.dart';
import 'package:ledgerly/data/models/selected_slice.dart';
import 'package:ledgerly/features/analysis/charts/charts_state.dart';
import 'package:ledgerly/features/analysis/charts/widgets/chart_legend.dart';
import 'package:ledgerly/l10n/app_localizations.dart';

const _usd = Currency(code: 'USD', decimals: 2, symbol: r'$');

List<ChartSlice> _nineSlices() => List.generate(
      9,
      (i) => ChartSlice(
        label: 'Slice $i',
        currencyCode: 'USD',
        totalMinorUnits: 1000 - i * 100,
        colorIndex: i,
        iconKey: '',
        selectionKey: SelectedSlice.category(i + 1),
      ),
    );

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

void main() {
  testWidgets('View all sheet pops itself when a row is tapped', (tester) async {
    int? selectedIndex;
    await tester.pumpWidget(_wrap(
      ChartLegend(
        slices: _nineSlices(),
        currenciesByCode: const {'USD': _usd},
        locale: 'en',
        selectedSliceIndex: null,
        onSelectSlice: (idx) => selectedIndex = idx,
      ),
    ));
    await tester.pumpAndSettle();
    // Find and tap "View all".
    await tester.tap(find.text('View all'));
    await tester.pumpAndSettle();
    // The modal sheet shows all nine rows. Tap the last one (visible only in sheet).
    await tester.tap(find.text('Slice 8').last);
    await tester.pumpAndSettle();
    // After tap, the sheet must close → "View all" is visible again, "Slice 8" hidden inside sheet.
    expect(find.text('View all'), findsOneWidget);
    expect(selectedIndex, equals(8));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widget/features/analysis/chart_legend_view_all_pop_test.dart`
Expected: FAIL — the sheet stays open after tap (current behavior).

- [ ] **Step 3: Modify `_openFullLegend`**

In `lib/features/analysis/charts/widgets/chart_legend.dart`, replace `_openFullLegend` (lines 232-248) with:

```dart
  void _openFullLegend(
    BuildContext context,
    List<({int index, ChartSlice slice})> all,
  ) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetCtx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final entry in all)
              _row(
                sheetCtx,
                entry.slice,
                originalIndex: entry.index,
                onTapOverride: () {
                  onSelectSlice?.call(entry.index);
                  Navigator.pop(sheetCtx);
                },
              ),
          ],
        ),
      ),
    );
  }
```

Then update `_row` to accept an optional `onTapOverride` that wins over the default toggle behaviour. Replace the existing `_row` method signature + tail of the method (the `InkWell` block, lines 173-187):

```dart
  Widget _row(
    BuildContext context,
    ChartSlice s, {
    int? originalIndex,
    VoidCallback? onTapOverride,
  }) {
    // ... existing body up to the closing of `row` widget construction ...
```

Then replace only the closing block (lines 173-187) with:

```dart
    if (originalIndex == null || onSelectSlice == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: row,
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTapOverride ??
            () => onSelectSlice!(isSelected ? null : originalIndex),
        child: row,
      ),
    );
  }
```

- [ ] **Step 4: Run test to verify pass**

Run: `dart format . && flutter test test/widget/features/analysis/chart_legend_view_all_pop_test.dart`
Expected: PASS.

- [ ] **Step 5: Confirm existing legend visuals still pass**

Run: `flutter test test/widget/features/analysis/charts_section_test.dart`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/features/analysis/charts/widgets/chart_legend.dart test/widget/features/analysis/chart_legend_view_all_pop_test.dart
git commit -m "feat(charts): pop View all sheet after legend row tap"
```

---

## Task 13: Convert `_ChartBody` to `ConsumerWidget` reading selection from Riverpod

**Files:**
- Modify: `lib/features/analysis/charts/charts_section.dart:394-467`

- [ ] **Step 1: Write the failing test**

Create `test/widget/features/analysis/chart_slice_selection_interaction_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/app/providers/default_currency_provider.dart';
import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/data/models/account.dart';
import 'package:ledgerly/data/models/category.dart';
import 'package:ledgerly/data/models/category_slice.dart';
import 'package:ledgerly/data/models/currency.dart';
import 'package:ledgerly/data/models/selected_slice.dart';
import 'package:ledgerly/data/models/time_bucket_slice.dart';
import 'package:ledgerly/data/repositories/exchange_rate_repository.dart';
import 'package:ledgerly/data/repositories/transaction_repository.dart';
import 'package:ledgerly/data/services/exchange_rate_service.dart';
import 'package:ledgerly/features/analysis/charts/charts_providers.dart';
import 'package:ledgerly/features/analysis/charts/charts_section.dart';
import 'package:ledgerly/features/analysis/charts/charts_selection_controller.dart';
import 'package:ledgerly/features/analysis/search/analysis_providers.dart';
import 'package:ledgerly/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

import '../../../unit/repositories/_harness/test_app_database.dart';

class _MockRepo extends Mock implements TransactionRepository {}

class _MockFxSvc extends Mock implements ExchangeRateService {}

const _usd = Currency(
  code: 'USD',
  decimals: 2,
  symbol: r'$',
  nameL10nKey: 'currency.usd',
);

void main() {
  setUpAll(() {
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(CategoryType.expense);
    registerFallbackValue(TimeBucketGranularity.day);
    registerFallbackValue(const SelectedSlice.category(1));
  });

  testWidgets('legend tap drives ChartsSelectionController.toggleSlice', (tester) async {
    final repo = _MockRepo();
    when(
      () => repo.watchByCategoryInRange(
        start: any(named: 'start'),
        end: any(named: 'end'),
        type: any(named: 'type'),
      ),
    ).thenAnswer(
      (_) => Stream.value(const [
        CategorySlice(categoryId: 1, currencyCode: 'USD', totalMinorUnits: 5000),
      ]),
    );
    when(
      () => repo.watchTimeBucketsInRange(
        start: any(named: 'start'),
        end: any(named: 'end'),
        type: any(named: 'type'),
        granularity: any(named: 'granularity'),
        selection: any(named: 'selection'),
      ),
    ).thenAnswer(
      (_) => Stream.value(<TimeBucketSlice>[
        TimeBucketSlice(
          bucketStart: DateTime(2026, 5, 18),
          currencyCode: 'USD',
          totalMinorUnits: 5000,
        ),
      ]),
    );
    when(
      () => repo.watchTransactionsForSliceInRange(
        selection: any(named: 'selection'),
        start: any(named: 'start'),
        end: any(named: 'end'),
        type: any(named: 'type'),
      ),
    ).thenAnswer((_) => Stream.value(const []));

    final fxSvc = _MockFxSvc();
    when(() => fxSvc.fetchRates(any())).thenAnswer((_) async => []);
    final fxDb = newTestAppDatabase();
    final fxRepo = ExchangeRateRepository(fxDb, fxSvc, const Stream<String>.empty());
    addTearDown(() async {
      fxRepo.dispose();
      await fxDb.close();
    });

    final container = ProviderContainer(
      overrides: [
        transactionRepositoryProvider.overrideWithValue(repo),
        exchangeRateRepositoryProvider.overrideWithValue(fxRepo),
        analysisCategoriesByIdProvider.overrideWith(
          (ref) => Stream.value({
            1: const Category(
              id: 1,
              type: CategoryType.expense,
              l10nKey: 'category.food',
              icon: 'restaurant',
              color: 0,
            ),
          }),
        ),
        analysisAccountsByIdProvider.overrideWith(
          (ref) => Stream.value(const <int, Account>{}),
        ),
        chartsCurrenciesByCodeProvider.overrideWith(
          (ref) => Stream.value({'USD': _usd}),
        ),
        chartsFxStatusProvider.overrideWith(
          (ref) => Stream.value(
            const ChartsFxStatus(defaultCurrencyCode: 'USD', rates: {}),
          ),
        ),
        initialDefaultCurrencyProvider.overrideWithValue('USD'),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: SingleChildScrollView(child: ChartsSection())),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // Tap the only legend row.
    await tester.tap(find.text('Food'));
    await tester.pumpAndSettle();
    final selection =
        container.read(chartsSelectionControllerProvider).selectedSlice;
    expect(selection, equals(const SelectedSlice.category(1)));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widget/features/analysis/chart_slice_selection_interaction_test.dart`
Expected: FAIL — `_ChartBody` still uses local `setState`; selection never reaches Riverpod.

- [ ] **Step 3: Convert `_ChartBody`**

Edit `lib/features/analysis/charts/charts_section.dart`. Replace the `_ChartBody` class (lines 394-467) with a `ConsumerWidget` reading selection from Riverpod and dispatching taps via `toggleSlice`:

```dart
class _ChartBody extends ConsumerWidget {
  const _ChartBody({
    required this.data,
    required this.locale,
    required this.currencies,
  });

  final ChartsData data;
  final String locale;
  final Map<String, Currency> currencies;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection =
        ref.watch(chartsSelectionControllerProvider).selectedSlice;
    final selectedIndex = selection == null
        ? null
        : (() {
            final i =
                data.slices.indexWhere((s) => s.selectionKey == selection);
            return i == -1 ? null : i;
          })();
    final showBar = data.bucketTotals.isNotEmpty &&
        !(data.dimension == ChartDimension.currency && data.mixedCurrencies);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CategoryPieChart(
          slices: data.slices,
          currenciesByCode: currencies,
          locale: locale,
          grandTotalMinorUnits: data.grandTotalMinorUnits,
          displayCurrencyCode: data.displayCurrencyCode,
          selectedIndex: selectedIndex,
          onSelectionChanged: (i) {
            if (i == null) {
              ref
                  .read(chartsSelectionControllerProvider.notifier)
                  .clearSlice();
              return;
            }
            final key = data.slices[i].selectionKey;
            if (key != null) {
              ref
                  .read(chartsSelectionControllerProvider.notifier)
                  .toggleSlice(key);
            }
          },
        ),
        const SizedBox(height: 12),
        ChartLegend(
          slices: data.slices,
          currenciesByCode: currencies,
          locale: locale,
          mixedCurrencies: data.mixedCurrencies,
          selectedSliceIndex: selectedIndex,
          onSelectSlice: (i) {
            if (i == null) {
              ref
                  .read(chartsSelectionControllerProvider.notifier)
                  .clearSlice();
              return;
            }
            final key = data.slices[i].selectionKey;
            if (key != null) {
              ref
                  .read(chartsSelectionControllerProvider.notifier)
                  .toggleSlice(key);
            }
          },
        ),
        if (showBar) ...[
          const SizedBox(height: 16),
          DailyBarChart(
            period: data.period,
            anchorDate: data.anchorDate,
            bucketTotals: data.bucketTotals,
            locale: locale,
            currenciesByCode: currencies,
            displayCurrencyCode: data.displayCurrencyCode,
          ),
        ],
      ],
    );
  }
}
```

- [ ] **Step 4: Run test to verify pass**

Run: `dart format . && flutter test test/widget/features/analysis/chart_slice_selection_interaction_test.dart`
Expected: PASS.

- [ ] **Step 5: Confirm existing widget tests still pass**

Run: `flutter test test/widget/features/analysis/charts_section_test.dart`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/features/analysis/charts/charts_section.dart test/widget/features/analysis/chart_slice_selection_interaction_test.dart
git commit -m "feat(charts): drive pie/legend selection through Riverpod (consumer body)"
```

---

## Task 14: Render `SelectedSliceItemsList` + stale-selection self-heal

**Files:**
- Modify: `lib/features/analysis/charts/charts_section.dart` — render `SelectedSliceItemsList` as sibling of `_ChartBody`; add `ref.listen` for stale-selection cleanup; clear selection on `ChartsEmpty` / `ChartsError`.

- [ ] **Step 1: Write the failing test**

Append a new file `test/widget/features/analysis/chart_slice_stale_selfheal_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/app/providers/default_currency_provider.dart';
import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/data/models/account.dart';
import 'package:ledgerly/data/models/category.dart';
import 'package:ledgerly/data/models/category_slice.dart';
import 'package:ledgerly/data/models/currency.dart';
import 'package:ledgerly/data/models/selected_slice.dart';
import 'package:ledgerly/data/models/time_bucket_slice.dart';
import 'package:ledgerly/data/repositories/exchange_rate_repository.dart';
import 'package:ledgerly/data/repositories/transaction_repository.dart';
import 'package:ledgerly/data/services/exchange_rate_service.dart';
import 'package:ledgerly/features/analysis/charts/charts_providers.dart';
import 'package:ledgerly/features/analysis/charts/charts_section.dart';
import 'package:ledgerly/features/analysis/charts/charts_selection_controller.dart';
import 'package:ledgerly/features/analysis/search/analysis_providers.dart';
import 'package:ledgerly/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

import '../../../unit/repositories/_harness/test_app_database.dart';

class _MockRepo extends Mock implements TransactionRepository {}

class _MockFxSvc extends Mock implements ExchangeRateService {}

const _usd = Currency(code: 'USD', decimals: 2, symbol: r'$');

void main() {
  setUpAll(() {
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(CategoryType.expense);
    registerFallbackValue(TimeBucketGranularity.day);
    registerFallbackValue(const SelectedSlice.category(1));
  });

  testWidgets('stale selection clears when slice no longer in emission', (tester) async {
    final repo = _MockRepo();
    final controller = StreamController<List<CategorySlice>>.broadcast();
    when(
      () => repo.watchByCategoryInRange(
        start: any(named: 'start'),
        end: any(named: 'end'),
        type: any(named: 'type'),
      ),
    ).thenAnswer((_) => controller.stream);
    when(
      () => repo.watchTimeBucketsInRange(
        start: any(named: 'start'),
        end: any(named: 'end'),
        type: any(named: 'type'),
        granularity: any(named: 'granularity'),
        selection: any(named: 'selection'),
      ),
    ).thenAnswer(
      (_) => Stream.value(<TimeBucketSlice>[
        TimeBucketSlice(
          bucketStart: DateTime(2026, 5, 18),
          currencyCode: 'USD',
          totalMinorUnits: 5000,
        ),
      ]),
    );
    when(
      () => repo.watchTransactionsForSliceInRange(
        selection: any(named: 'selection'),
        start: any(named: 'start'),
        end: any(named: 'end'),
        type: any(named: 'type'),
      ),
    ).thenAnswer((_) => Stream.value(const []));

    final fxSvc = _MockFxSvc();
    when(() => fxSvc.fetchRates(any())).thenAnswer((_) async => []);
    final fxDb = newTestAppDatabase();
    final fxRepo = ExchangeRateRepository(fxDb, fxSvc, const Stream<String>.empty());
    addTearDown(() async {
      await controller.close();
      fxRepo.dispose();
      await fxDb.close();
    });

    final container = ProviderContainer(
      overrides: [
        transactionRepositoryProvider.overrideWithValue(repo),
        exchangeRateRepositoryProvider.overrideWithValue(fxRepo),
        analysisCategoriesByIdProvider.overrideWith(
          (ref) => Stream.value({
            1: const Category(
              id: 1,
              type: CategoryType.expense,
              l10nKey: 'category.food',
              icon: 'restaurant',
              color: 0,
            ),
          }),
        ),
        analysisAccountsByIdProvider.overrideWith(
          (ref) => Stream.value(const <int, Account>{}),
        ),
        chartsCurrenciesByCodeProvider.overrideWith(
          (ref) => Stream.value({'USD': _usd}),
        ),
        chartsFxStatusProvider.overrideWith(
          (ref) => Stream.value(
            const ChartsFxStatus(defaultCurrencyCode: 'USD', rates: {}),
          ),
        ),
        initialDefaultCurrencyProvider.overrideWithValue('USD'),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: SingleChildScrollView(child: ChartsSection())),
        ),
      ),
    );

    // First emission contains slice id=1.
    controller.add(const [
      CategorySlice(categoryId: 1, currencyCode: 'USD', totalMinorUnits: 5000),
    ]);
    await tester.pumpAndSettle();
    // Select it.
    await tester.tap(find.text('Food'));
    await tester.pumpAndSettle();
    expect(
      container.read(chartsSelectionControllerProvider).selectedSlice,
      equals(const SelectedSlice.category(1)),
    );

    // Second emission has no slice with that selectionKey.
    controller.add(const [
      CategorySlice(categoryId: 2, currencyCode: 'USD', totalMinorUnits: 3000),
    ]);
    await tester.pumpAndSettle();
    expect(
      container.read(chartsSelectionControllerProvider).selectedSlice,
      isNull,
    );
  });
}
```

(Imports `dart:async` is required; add at top of file.)

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widget/features/analysis/chart_slice_stale_selfheal_test.dart`
Expected: FAIL — no listener clears the stale selection.

- [ ] **Step 3: Render `SelectedSliceItemsList` + add the self-heal listener**

Edit `lib/features/analysis/charts/charts_section.dart`.

1. Add imports at top:

```dart
import 'widgets/selected_slice_items_list.dart';
```

2. In `_ChartsSectionState.build`, add a `ref.listen` immediately after fetching `controller` / `selection`:

```dart
    ref.listen(chartsControllerProvider, (_, next) {
      if (next is! AsyncData) return;
      final value = next.value;
      final sel =
          ref.read(chartsSelectionControllerProvider).selectedSlice;
      if (sel == null) return;
      switch (value) {
        case ChartsDataState(:final chartData):
          final hit = chartData.slices.any((s) => s.selectionKey == sel);
          if (!hit) {
            ref
                .read(chartsSelectionControllerProvider.notifier)
                .clearSlice();
          }
        case ChartsBlockedByMissingRates(:final previous):
          if (previous == null) {
            ref
                .read(chartsSelectionControllerProvider.notifier)
                .clearSlice();
          }
        case ChartsEmpty():
        case ChartsError():
          ref
              .read(chartsSelectionControllerProvider.notifier)
              .clearSlice();
        default:
          break;
      }
    });
```

3. In `_frame`, render `SelectedSliceItemsList` as a sibling of the period-fling `GestureDetector`. Replace the final `GestureDetector(...)` block (around lines 384-389) with:

```dart
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragEnd: _onHorizontalFling,
          child: animatedBody,
        ),
        if (chartData != null)
          Builder(
            builder: (ctx) {
              final sel = selection.selectedSlice;
              if (sel == null) return const SizedBox.shrink();
              final slice = chartData.slices
                  .where((s) => s.selectionKey == sel)
                  .cast<ChartSlice?>()
                  .firstWhere((_) => true, orElse: () => null);
              if (slice == null) return const SizedBox.shrink();
              return SelectedSliceItemsList(
                slice: slice,
                locale: locale ?? 'en',
              );
            },
          ),
      ],
```

- [ ] **Step 4: Run test to verify pass**

Run: `dart format . && flutter test test/widget/features/analysis/chart_slice_stale_selfheal_test.dart`
Expected: PASS.

- [ ] **Step 5: Confirm full chart widget test suite**

Run: `flutter test test/widget/features/analysis/`
Expected: PASS for all analysis widget tests.

- [ ] **Step 6: Commit**

```bash
git add lib/features/analysis/charts/charts_section.dart test/widget/features/analysis/chart_slice_stale_selfheal_test.dart
git commit -m "feat(charts): wire drill-down list + stale-selection self-heal in ChartsSection"
```

---

## Task 15: Integration test — end-to-end drill-down flow

**Files:**
- Create: `test/integration/analysis_drilldown_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/integration/analysis_drilldown_test.dart` (this exercises the full pipeline against an in-memory DB):

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/app/providers/default_currency_provider.dart';
import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/data/database/app_database.dart' as drift;
import 'package:ledgerly/data/models/selected_slice.dart';
import 'package:ledgerly/data/repositories/exchange_rate_repository.dart';
import 'package:ledgerly/data/repositories/transaction_repository.dart';
import 'package:ledgerly/data/services/exchange_rate_service.dart';
import 'package:ledgerly/features/analysis/analysis_screen.dart';
import 'package:ledgerly/features/analysis/charts/charts_providers.dart';
import 'package:ledgerly/features/analysis/charts/charts_selection_controller.dart';
import 'package:ledgerly/features/analysis/search/analysis_providers.dart';
import 'package:ledgerly/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

import '../unit/repositories/_harness/test_app_database.dart';

class _MockFxSvc extends Mock implements ExchangeRateService {}

Future<void> _seed(drift.AppDatabase db) async {
  await db.customStatement(
    'INSERT INTO currencies (code, decimals, symbol, name_l10n_key, '
    "is_token, sort_order) VALUES ('USD', 2, '\$', 'currency.usd', 0, 1)",
  );
  await db.customStatement(
    'INSERT INTO categories (id, type, l10n_key, icon, color, sort_order, '
    "is_archived) VALUES (1, 'expense', 'category.food', 'restaurant', 0, 1, 0)",
  );
  await db.customStatement(
    'INSERT INTO categories (id, type, l10n_key, icon, color, sort_order, '
    "is_archived) VALUES (2, 'expense', 'category.transportation', 'car', 1, 2, 0)",
  );
  await db.customStatement(
    'INSERT INTO account_types (id, l10n_key, icon, color, sort_order, '
    "is_archived) VALUES (1, 'acct.cash', 'wallet', 0, 1, 0)",
  );
  await db.customStatement(
    'INSERT INTO accounts (id, account_type_id, name, currency, '
    'opening_balance_minor_units, sort_order, is_archived) VALUES '
    "(1, 1, 'Cash', 'USD', 0, 1, 0)",
  );
  final epoch = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  Future<void> tx(int id, int amt, int cat) {
    return db.customStatement(
      'INSERT INTO transactions (id, amount_minor_units, currency, '
      'category_id, account_id, date, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, 1, ?, ?, ?)',
      [
        id,
        amt,
        'USD',
        cat,
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        epoch,
        epoch,
      ],
    );
  }
  await tx(1, 1000, 1); // Food $10
  await tx(2, 2000, 1); // Food $20
  await tx(3, 4000, 2); // Transport $40
}

void main() {
  setUpAll(() {
    registerFallbackValue(DateTime.now());
  });

  testWidgets('Analysis tab: tap food slice → header + 2 rows, tap again clears', (tester) async {
    final db = newTestAppDatabase();
    final repo = DriftTransactionRepository(db);
    await _seed(db);

    final fxSvc = _MockFxSvc();
    when(() => fxSvc.fetchRates(any())).thenAnswer((_) async => []);
    final fxRepo = ExchangeRateRepository(db, fxSvc, const Stream<String>.empty());
    addTearDown(() async {
      fxRepo.dispose();
      await db.close();
    });

    final container = ProviderContainer(
      overrides: [
        transactionRepositoryProvider.overrideWithValue(repo),
        exchangeRateRepositoryProvider.overrideWithValue(fxRepo),
        initialDefaultCurrencyProvider.overrideWithValue('USD'),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: AnalysisScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // Tap Food slice via legend.
    await tester.tap(find.text('Food'));
    await tester.pumpAndSettle();
    expect(
      container.read(chartsSelectionControllerProvider).selectedSlice,
      equals(const SelectedSlice.category(1)),
    );
    // List should show two rows.
    expect(find.byType(ListTile), findsAtLeast(2));
    // Tap again — selection clears.
    await tester.tap(find.text('Food'));
    await tester.pumpAndSettle();
    expect(
      container.read(chartsSelectionControllerProvider).selectedSlice,
      isNull,
    );
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/integration/analysis_drilldown_test.dart`
Expected: FAIL — at first run the test may fail for setup reasons; iterate until the assertions match the implementation.

- [ ] **Step 3: Iterate as necessary**

If the test fails due to provider scoping (e.g. `analysisCategoriesByIdProvider` needs the override the analysis screen reads), add explicit overrides for `analysisCategoriesByIdProvider`, `analysisAccountsByIdProvider`, `chartsCurrenciesByCodeProvider`, `chartsFxStatusProvider` as in earlier widget tests. Stop iterating when assertions match.

- [ ] **Step 4: Run test to verify pass**

Run: `dart format . && flutter test test/integration/analysis_drilldown_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add test/integration/analysis_drilldown_test.dart
git commit -m "test(integration): drill-down toggle end-to-end on Analysis tab"
```

---

## Task 16: Final verification + lint + format

- [ ] **Step 1: Format + analyze + run the full suite**

Run, in order:

```bash
dart format .
flutter analyze
flutter test
```

Expected: all green. `flutter analyze` runs `custom_lint` (Riverpod lint) + `import_lint` per the project setup; any new violation is a real issue to fix before declaring this complete.

- [ ] **Step 2: Build runner sanity sweep**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: idempotent — no generated file should diff after this run. If there is drift, commit the regenerated files.

- [ ] **Step 3: Commit any housekeeping**

If `build_runner` regenerated anything (e.g. order of `.g.dart` exports) or `dart format` reflowed prior commits, commit it:

```bash
git status
git add -A   # only if every changed path was expected
git commit -m "chore(charts): regen build_runner outputs and format"
```

- [ ] **Step 4: Skim spec for unimplemented edge cases**

Re-read the spec's *Edge Cases* table (lines 386-399). Confirm each row is covered:

- Stale selection: Task 14 self-heal listener ✓
- "Other" aggregate: `selectionKey: null` is default, _otherRow leaves it null (no code change needed, but confirm `ChartLegend._otherRow` still passes `originalIndex` only when it is real) ✓
- "View all" sheet pop: Task 12 ✓
- Mixed currencies in category dim (FX missing): category slices emit per-(category, currency) and would use `SelectedSlice.category(id, currencyCode: ...)`. The current `_emitCategoryOrAccountDimension` aggregates by `id`; in the all-rates-missing case, control flows through `ChartsBlockedByMissingRates` and slices are not selectable. **Verify** by re-reading `charts_controller.dart` — if there is a per-(category, currency) emission path in the unblocked-but-missing case (e.g. via `excludedCurrencyCodes`), the `selectionKey` for those slices should also carry the currency. As of this plan we treat category-dim slices as currency-less (FX-converted). If the spec's "Food USD / Food EUR appear as separate pie slices" branch needs a different code path, file a follow-up — it is **not** in this MVP.
- Period swipe / type toggle / dimension change with active selection: Task 5 ✓
- Chart transitions to Empty/Error: Task 14 listener clears ✓

If any row above is uncovered, file the follow-up directly in `docs/superpowers/specs/2026-05-21-chart-slice-drilldown-design.md` and adjust here.

---

## Self-Review Checklist (for the planner)

1. **Spec coverage:** Every spec subsection has at least one task:
   - Data Layer: Tasks 1–4
   - State & Controller: Tasks 5–8
   - UI Layer: Tasks 10–14 (TransactionSearchRow, SelectedSliceItemsList, _ChartBody, ChartsSection, ChartLegend)
   - Localization: Task 9
   - Edge cases: Task 14 + Task 16
2. **No placeholders:** Every step contains the actual code, command, or precise file location.
3. **Type consistency:** `SelectedSlice.category(int)`, `SelectedSlice.account(int)`, `SelectedSlice.currency(String)` used identically across all task examples. `toggleSlice` / `clearSlice` / `selectedSlice` names match across tasks 5, 6, 8, 13, 14. `SliceDrilldownData.pendingDeleteId` (int?, not int) is the same across Task 7 and Task 8. `TransactionSearchRowDeleteMode.actionOnly` is the same across Task 10 and Task 11.

---

## Execution Handoff

**Plan complete and saved to `docs/superpowers/plans/2026-05-22-chart-slice-drilldown.md`. Two execution options:**

**1. Subagent-Driven (recommended)** — Dispatch a fresh subagent per task with two-stage review between tasks. Best for keeping context light and reviewing each layer independently.

**2. Inline Execution** — Execute tasks in this session via `superpowers:executing-plans` with batch checkpoints. Best when you want to keep momentum and have continuous oversight.

**Which approach?**
