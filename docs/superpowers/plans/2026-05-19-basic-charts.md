# Basic Charts Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a pie + bar chart surface to the Analysis tab so users can see expense/income breakdowns by category, account, or currency across day/week/month/year periods, with multi-currency auto-conversion and a search-first interaction model.

**Architecture:** A new `charts/` sub-feature beneath `lib/features/analysis/`. Four new range-aware methods on `TransactionRepository` back four `ChartsController` subscription paths (one per `ChartDimension`). State is a Freezed sealed union; the controller is a `StreamNotifier` matching `AnalysisController`'s pattern (private `StreamController` plus generation counter for cancellation). Multi-currency conversion routes through the existing `CurrencyConverter` integer-arithmetic helper.

**Tech Stack:** Flutter 3.41 / Dart 3.11, `fl_chart ^0.70.2` (new), Drift 2.28, Riverpod 2.6, Freezed 3.x, mocktail, fake_async, `intl`.

---

## Spec → Reality Adjustments

The spec at `docs/superpowers/specs/2026-05-18-basic-charts-design.md` is authoritative for product behaviour, but **two implementation details deviate** from the existing codebase. Follow this plan when they conflict:

1. **Exchange-rate storage.** The spec says rates are stored as `numerator/denominator` fractions. They aren't — `lib/data/database/tables/exchange_rates_table.dart` stores `rate_scaled_e9 = round(rate × 10⁹)`. The conversion helper `lib/core/utils/currency_converter.dart` is the SSOT; use `CurrencyConverter.convertMinorUnits(...)` everywhere the spec writes `(originalMinor * rateNumerator) ~/ rateDenominator`. Same direction: `baseCurrency = source`, `quoteCurrency = default`. There is no inverse-rate lookup.
2. **`chartsFxStatusProvider` shape.** The spec describes the provider exposing `per-pair fetchedAt`. Controllers cannot import DAOs (see `import_analysis_options.yaml` → `controllers_forbid_db_and_services`). Task 6 adds a repo-level `watchRatesMetadata()` that exposes `(rateScaledE9, fetchedAt)` pairs; the provider builds `ChartsFxStatus` from that stream + `defaultCurrencyProvider`.

Everything else in the spec is binding — except the warm-start optimization explicitly deferred in Task 13. Blocked-state semantics, "Other" bucket rules, View-all sheet, and adaptive 600dp behaviour remain binding.

---

## File Structure

### New files

```
lib/data/models/
  category_slice.dart          # @freezed CategorySlice
  account_slice.dart           # @freezed AccountSlice
  currency_slice.dart          # @freezed CurrencySlice
  time_bucket_slice.dart       # @freezed TimeBucketSlice + TimeBucketGranularity

lib/features/analysis/charts/
  charts_state.dart            # @freezed ChartsState + ChartsData + ChartSlice + ChartBucketTotal + enums
  charts_providers.dart        # chartsCurrenciesByCodeProvider, chartsFxStatusProvider, ChartsFxStatus
  charts_controller.dart       # StreamNotifier (mirrors AnalysisController pattern)
  charts_section.dart          # Top-level widget composing controls + pie + legend + bar
  widgets/
    period_selector.dart
    type_toggle.dart
    dimension_toggle.dart
    category_pie_chart.dart
    daily_bar_chart.dart
    chart_legend.dart
```

### Modified files

```
pubspec.yaml                                         # + fl_chart ^0.70.2
lib/core/utils/date_helpers.dart                     # + startOfWeek/startOfMonth/startOfYear
lib/data/database/daos/transaction_dao.dart          # + 4 chart query methods
lib/data/repositories/transaction_repository.dart    # + 4 range methods returning Slice streams
lib/data/repositories/exchange_rate_repository.dart  # + watchRatesMetadata()
lib/features/analysis/analysis_screen.dart           # CustomScrollView w/ conditional ChartsSection
l10n/app_en.arb                                      # + chart keys (20)
l10n/app_zh_TW.arb                                   # + chart keys (20)
l10n/app_zh_CN.arb                                   # + chart keys (20)
```

### New test files

```
test/unit/utils/date_helpers_test.dart                          # extend if exists; else new
test/unit/repositories/transaction_repository_charts_test.dart  # 4 range methods
test/unit/repositories/exchange_rate_repository_test.dart       # extend (watchRatesMetadata)
test/unit/controllers/charts_controller_test.dart
test/widget/features/analysis/charts_section_test.dart
test/widget/features/analysis/widgets/period_selector_test.dart # tiny widget tests folded in
test/integration/chart_display_flow_test.dart
```

---

## Layer Boundary Notes (import_lint)

Two rules will bite if ignored — verify after each task that touches affected files:

- `controllers_forbid_db_and_services` (matches `^lib/features/.*_controller\.dart$`): `charts_controller.dart` MUST NOT import from `data/database/...`, `data/services/...`, `package:drift/...`. Conversion uses `core/utils/currency_converter.dart`; FX state goes through `chartsFxStatusProvider` which talks to the repository.
- `widgets_forbid_data_internals` and `widget_helpers_forbid_data_internals` (match `_screen.dart` and `widgets/*.dart`): widgets may not import repositories, DAOs, services, or `package:drift`. `charts_section.dart` reads providers and the controller; the leaf widgets accept plain values via constructor.

Run `flutter analyze` after every task that touches `charts_controller.dart`, `charts_section.dart`, or any file under `widgets/`.

---

## Code-Generation Notes

Every task that adds or modifies a `@freezed`, `@Riverpod`, or Drift `@DataClassName`/`@DriftAccessor` annotation MUST run:

```bash
dart run build_runner build --delete-conflicting-outputs
```

before tests. The plan explicitly calls this out per task; do not skip — `flutter analyze` / `flutter test` will fail loudly on stale generated files.

---

## Task List

### Task 1: Add `fl_chart` dependency

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Add the dependency line**

In `pubspec.yaml`, under `dependencies:`, immediately after the existing `dio: ^5.7.0` line, add:

```yaml
  # Charts (Analysis tab pie + bar charts).
  fl_chart: ^0.70.2
```

- [ ] **Step 2: Resolve dependencies**

Run: `flutter pub get`
Expected: completes without conflict; `fl_chart` appears in `.dart_tool/package_config.json`.

- [ ] **Step 3: Verify analyzer is still green**

Run: `dart format . && flutter analyze`
Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore(deps): add fl_chart for Analysis charts"
```

---

### Task 2: Extend `DateHelpers` with week/month/year boundaries

**Files:**
- Modify: `lib/core/utils/date_helpers.dart`
- Test: `test/unit/utils/date_helpers_test.dart` (new file)

The chart period boundaries need device-local week/month/year math that matches existing `startOfDay` semantics. Weeks are Monday-start (per spec § Period boundaries).

- [ ] **Step 1: Write the failing tests**

Create `test/unit/utils/date_helpers_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/utils/date_helpers.dart';

void main() {
  group('DateHelpers.startOfWeek', () {
    test('Monday returns the same midnight', () {
      // 2026-05-18 is a Monday in any locale.
      final monday = DateTime(2026, 5, 18, 14, 30, 22, 500);
      expect(
        DateHelpers.startOfWeek(monday),
        DateTime(2026, 5, 18),
      );
    });

    test('mid-week returns the previous Monday midnight', () {
      // 2026-05-21 is a Thursday.
      final thursday = DateTime(2026, 5, 21, 9, 0);
      expect(
        DateHelpers.startOfWeek(thursday),
        DateTime(2026, 5, 18),
      );
    });

    test('Sunday returns the previous Monday (six days back)', () {
      // 2026-05-24 is a Sunday.
      final sunday = DateTime(2026, 5, 24, 23, 59);
      expect(
        DateHelpers.startOfWeek(sunday),
        DateTime(2026, 5, 18),
      );
    });

    test('crosses a month boundary correctly', () {
      // 2026-06-03 is a Wednesday → Monday is 2026-06-01.
      // 2026-06-01 is a Monday → still 2026-06-01.
      expect(
        DateHelpers.startOfWeek(DateTime(2026, 6, 3, 12)),
        DateTime(2026, 6, 1),
      );
      expect(
        DateHelpers.startOfWeek(DateTime(2026, 6, 1, 0)),
        DateTime(2026, 6, 1),
      );
    });
  });

  group('DateHelpers.startOfMonth', () {
    test('first-of-month returns same midnight', () {
      expect(
        DateHelpers.startOfMonth(DateTime(2026, 5, 1, 10)),
        DateTime(2026, 5, 1),
      );
    });

    test('mid-month returns first-of-month midnight', () {
      expect(
        DateHelpers.startOfMonth(DateTime(2026, 5, 18, 14, 30)),
        DateTime(2026, 5, 1),
      );
    });
  });

  group('DateHelpers.startOfYear', () {
    test('Jan 1 returns same midnight', () {
      expect(
        DateHelpers.startOfYear(DateTime(2026, 1, 1, 10)),
        DateTime(2026, 1, 1),
      );
    });

    test('arbitrary day returns Jan 1 midnight of that year', () {
      expect(
        DateHelpers.startOfYear(DateTime(2026, 7, 4, 23, 59)),
        DateTime(2026, 1, 1),
      );
    });
  });
}
```

- [ ] **Step 2: Run tests to verify failure**

Run: `flutter test test/unit/utils/date_helpers_test.dart`
Expected: FAIL — `startOfWeek`, `startOfMonth`, `startOfYear` are not defined.

- [ ] **Step 3: Implement the helpers**

In `lib/core/utils/date_helpers.dart`, inside `class DateHelpers`, after the existing `startOfDay` method, add:

```dart
  /// Local-midnight of Monday for the week containing [dt].
  /// `DateTime.weekday` is 1=Mon..7=Sun, so subtracting `(weekday - 1)`
  /// days lands on the Monday. DST-safe: operates on the calendar day
  /// component, not on `Duration`-based subtraction.
  static DateTime startOfWeek(DateTime dt) {
    final base = startOfDay(dt);
    return DateTime(base.year, base.month, base.day - (base.weekday - 1));
  }

  /// Local-midnight of the first day of the month containing [dt].
  static DateTime startOfMonth(DateTime dt) =>
      DateTime(dt.year, dt.month, 1);

  /// Local-midnight of Jan 1 of the year containing [dt].
  static DateTime startOfYear(DateTime dt) => DateTime(dt.year, 1, 1);
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `dart format . && flutter test test/unit/utils/date_helpers_test.dart`
Expected: PASS (all 9 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/core/utils/date_helpers.dart test/unit/utils/date_helpers_test.dart
git commit -m "feat(date_helpers): add startOfWeek/startOfMonth/startOfYear for chart boundaries"
```

---

### Task 3: Add chart-slice domain models

**Files:**
- Create: `lib/data/models/category_slice.dart`
- Create: `lib/data/models/account_slice.dart`
- Create: `lib/data/models/currency_slice.dart`
- Create: `lib/data/models/time_bucket_slice.dart`

Four Freezed value objects returned by the new repository methods. They live alongside existing models in `lib/data/models/`. No tests — Freezed equality / copyWith / fromJson is library-tested, and the layer guard for these files is `models_forbid_non_pure` (no Drift, no repositories, no app/feature imports).

- [ ] **Step 1: Create `category_slice.dart`**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'category_slice.freezed.dart';

/// Per-(category, currency) subtotal emitted by
/// `TransactionRepository.watchByCategoryInRange`. Lives as a separate
/// shape from `CategorySearchResult` because charts care about the
/// `category_id` only (icon/name resolution happens at the controller
/// level via `analysisCategoriesByIdProvider`).
@freezed
abstract class CategorySlice with _$CategorySlice {
  const factory CategorySlice({
    required int categoryId,
    required String currencyCode,
    required int totalMinorUnits,
  }) = _CategorySlice;
}
```

- [ ] **Step 2: Create `account_slice.dart`**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'account_slice.freezed.dart';

/// Per-(account, currency) subtotal emitted by
/// `TransactionRepository.watchByAccountInRange`.
@freezed
abstract class AccountSlice with _$AccountSlice {
  const factory AccountSlice({
    required int accountId,
    required String currencyCode,
    required int totalMinorUnits,
  }) = _AccountSlice;
}
```

- [ ] **Step 3: Create `currency_slice.dart`**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'currency_slice.freezed.dart';

/// Per-currency total emitted by
/// `TransactionRepository.watchByCurrencyInRange`.
@freezed
abstract class CurrencySlice with _$CurrencySlice {
  const factory CurrencySlice({
    required String currencyCode,
    required int totalMinorUnits,
  }) = _CurrencySlice;
}
```

- [ ] **Step 4: Create `time_bucket_slice.dart`**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'time_bucket_slice.freezed.dart';

/// Local-time bucket granularity selected by the chart period:
/// - `hour` — Day view (24 buckets)
/// - `day`  — Week and Month views
/// - `month` — Year view (12 buckets)
enum TimeBucketGranularity { hour, day, month }

/// Per-(bucketStart, currency) subtotal emitted by
/// `TransactionRepository.watchTimeBucketsInRange`. Conversion happens
/// before regrouping into final `ChartBucketTotal`s — so currencies are
/// preserved here, not collapsed.
@freezed
abstract class TimeBucketSlice with _$TimeBucketSlice {
  const factory TimeBucketSlice({
    required DateTime bucketStart,
    required String currencyCode,
    required int totalMinorUnits,
  }) = _TimeBucketSlice;
}
```

- [ ] **Step 5: Generate Freezed files**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: succeeds; `.freezed.dart` files appear next to each of the four new models.

- [ ] **Step 6: Verify analyzer is clean**

Run: `dart format . && flutter analyze`
Expected: no errors.

- [ ] **Step 7: Commit**

```bash
git add lib/data/models/category_slice.dart \
  lib/data/models/category_slice.freezed.dart \
  lib/data/models/account_slice.dart \
  lib/data/models/account_slice.freezed.dart \
  lib/data/models/currency_slice.dart \
  lib/data/models/currency_slice.freezed.dart \
  lib/data/models/time_bucket_slice.dart \
  lib/data/models/time_bucket_slice.freezed.dart
git commit -m "feat(models): add chart slice value objects"
```

---

### Task 4: Add four DAO query methods on `TransactionDao`

**Files:**
- Modify: `lib/data/database/daos/transaction_dao.dart`

These methods return raw Drift result rows. The repository (Task 5) maps them to domain `*Slice` models. DAOs do not own bucketing logic — local-time bucketing for `watchTimeBucketsInRange` happens in the repository (DateHelpers shares semantics with the rest of the app).

The DAO will use Drift's `customSelect` for the GROUP BY queries (matching the existing `_watchNetByCurrency` style in `TransactionRepository`). The "chart rows" stream is a plain typed select since the repository does its own grouping.

- [ ] **Step 1: Read the existing DAO to confirm imports and class shape**

Already confirmed in plan research:
- File has `@DriftAccessor(tables: [Transactions])` annotation and extends `DatabaseAccessor<AppDatabase>` with `_$TransactionDaoMixin`.
- Existing range queries use either typed select APIs or `db.customSelect` from the repository.

- [ ] **Step 2: Add the four methods at the end of `class TransactionDao`**

In `lib/data/database/daos/transaction_dao.dart`, before the closing brace of the class, add:

```dart
  /// Per `(category_id, currency)` subtotal in `[start, end)`, filtered by
  /// `categories.type`. Emits ONE row per pair so the repository can run
  /// currency conversion before regrouping into final chart slices.
  Stream<List<({int categoryId, String currency, int total})>>
  watchCategoryTotalsInRange({
    required DateTime start,
    required DateTime end,
    required String type,
  }) {
    final query = attachedDatabase.customSelect(
      'SELECT t.category_id AS cat_id, t.currency AS code, '
      'SUM(t.amount_minor_units) AS total '
      'FROM transactions t '
      'JOIN categories c ON c.id = t.category_id '
      'WHERE t.date >= ? AND t.date < ? AND c.type = ? '
      'GROUP BY t.category_id, t.currency',
      variables: [
        Variable<DateTime>(start),
        Variable<DateTime>(end),
        Variable<String>(type),
      ],
      readsFrom: {transactions, attachedDatabase.categories},
    );
    return query.watch().map(
      (rows) => rows
          .map(
            (r) => (
              categoryId: r.read<int>('cat_id'),
              currency: r.read<String>('code'),
              total: r.read<int>('total'),
            ),
          )
          .toList(growable: false),
    );
  }

  /// Per `(account_id, currency)` subtotal in `[start, end)`, filtered by
  /// `categories.type`.
  Stream<List<({int accountId, String currency, int total})>>
  watchAccountTotalsInRange({
    required DateTime start,
    required DateTime end,
    required String type,
  }) {
    final query = attachedDatabase.customSelect(
      'SELECT t.account_id AS acct_id, t.currency AS code, '
      'SUM(t.amount_minor_units) AS total '
      'FROM transactions t '
      'JOIN categories c ON c.id = t.category_id '
      'WHERE t.date >= ? AND t.date < ? AND c.type = ? '
      'GROUP BY t.account_id, t.currency',
      variables: [
        Variable<DateTime>(start),
        Variable<DateTime>(end),
        Variable<String>(type),
      ],
      readsFrom: {transactions, attachedDatabase.categories},
    );
    return query.watch().map(
      (rows) => rows
          .map(
            (r) => (
              accountId: r.read<int>('acct_id'),
              currency: r.read<String>('code'),
              total: r.read<int>('total'),
            ),
          )
          .toList(growable: false),
    );
  }

  /// Per `currency` total in `[start, end)`, filtered by `categories.type`.
  Stream<List<({String currency, int total})>> watchCurrencyTotalsInRange({
    required DateTime start,
    required DateTime end,
    required String type,
  }) {
    final query = attachedDatabase.customSelect(
      'SELECT t.currency AS code, SUM(t.amount_minor_units) AS total '
      'FROM transactions t '
      'JOIN categories c ON c.id = t.category_id '
      'WHERE t.date >= ? AND t.date < ? AND c.type = ? '
      'GROUP BY t.currency',
      variables: [
        Variable<DateTime>(start),
        Variable<DateTime>(end),
        Variable<String>(type),
      ],
      readsFrom: {transactions, attachedDatabase.categories},
    );
    return query.watch().map(
      (rows) => rows
          .map(
            (r) => (
              currency: r.read<String>('code'),
              total: r.read<int>('total'),
            ),
          )
          .toList(growable: false),
    );
  }

  /// Raw `(date, currency, amount_minor_units)` rows in `[start, end)`
  /// filtered by `categories.type`, ordered by date ascending. The
  /// repository runs local-time bucket math on top so midnight/DST
  /// semantics stay aligned with `DateHelpers`.
  Stream<List<({DateTime date, String currency, int amountMinorUnits})>>
  watchChartRowsInRange({
    required DateTime start,
    required DateTime end,
    required String type,
  }) {
    final query = attachedDatabase.customSelect(
      'SELECT t.date AS d, t.currency AS code, '
      't.amount_minor_units AS amt '
      'FROM transactions t '
      'JOIN categories c ON c.id = t.category_id '
      'WHERE t.date >= ? AND t.date < ? AND c.type = ? '
      'ORDER BY t.date ASC',
      variables: [
        Variable<DateTime>(start),
        Variable<DateTime>(end),
        Variable<String>(type),
      ],
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

- [ ] **Step 3: Run codegen and verify**

Run: `dart run build_runner build --delete-conflicting-outputs && dart format . && flutter analyze`
Expected: no errors. DAO accessor mixin regenerates if needed.

- [ ] **Step 4: Commit**

```bash
git add lib/data/database/daos/transaction_dao.dart \
  lib/data/database/daos/transaction_dao.g.dart
git commit -m "feat(transaction_dao): add chart range queries (category/account/currency/raw)"
```

---

### Task 5: Add four range methods on `TransactionRepository`

**Files:**
- Modify: `lib/data/repositories/transaction_repository.dart`
- Test: `test/unit/repositories/transaction_repository_charts_test.dart` (new)

Repository owns local-time bucketing (matches the rest of the app's `DateHelpers` usage). All four methods take half-open `[start, end)` ranges and a `CategoryType`. The category-type → SQL value mapping is `enum.name` (`'expense'` / `'income'`) — matches the existing `@JsonValue` annotations on `CategoryType`.

- [ ] **Step 1: Write the failing repository tests**

Create `test/unit/repositories/transaction_repository_charts_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/data/database/app_database.dart';
import 'package:ledgerly/data/models/category.dart';
import 'package:ledgerly/data/models/time_bucket_slice.dart';
import 'package:ledgerly/data/repositories/transaction_repository.dart';

import '_harness/test_app_database.dart';

Future<void> _seedFixtures(AppDatabase db) async {
  await db.customStatement(
    'INSERT INTO currencies (code, decimals, symbol, name_l10n_key, '
    "is_token, sort_order) VALUES ('USD', 2, '\$', 'currency.usd', 0, 1)",
  );
  await db.customStatement(
    'INSERT INTO currencies (code, decimals, symbol, name_l10n_key, '
    "is_token, sort_order) VALUES ('EUR', 2, '€', 'currency.eur', 0, 2)",
  );
  // Two expense categories, one income category.
  await db.customStatement(
    "INSERT INTO categories (id, type, l10n_key, icon, color, sort_order, "
    "is_archived) VALUES (1, 'expense', 'cat.food', 'restaurant', 0, 1, 0)",
  );
  await db.customStatement(
    "INSERT INTO categories (id, type, l10n_key, icon, color, sort_order, "
    "is_archived) VALUES (2, 'expense', 'cat.transport', 'car', 1, 2, 0)",
  );
  await db.customStatement(
    "INSERT INTO categories (id, type, l10n_key, icon, color, sort_order, "
    "is_archived) VALUES (3, 'income', 'cat.salary', 'work', 2, 3, 0)",
  );
  await db.customStatement(
    "INSERT INTO account_types (id, l10n_key, icon, color, sort_order, "
    "is_archived) VALUES (1, 'acct.cash', 'wallet', 0, 1, 0)",
  );
  await db.customStatement(
    "INSERT INTO accounts (id, account_type_id, name, currency, "
    "opening_balance_minor_units, sort_order, is_archived) VALUES "
    "(1, 1, 'Cash', 'USD', 0, 1, 0)",
  );
  await db.customStatement(
    "INSERT INTO accounts (id, account_type_id, name, currency, "
    "opening_balance_minor_units, sort_order, is_archived) VALUES "
    "(2, 1, 'EUR Cash', 'EUR', 0, 2, 0)",
  );
}

Future<void> _insertTx(
  AppDatabase db, {
  required int id,
  required DateTime date,
  required int amountMinorUnits,
  required String currency,
  required int categoryId,
  int accountId = 1,
}) async {
  final epoch = DateTime.utc(2026).millisecondsSinceEpoch ~/ 1000;
  await db.customStatement(
    'INSERT INTO transactions (id, amount_minor_units, currency, '
    'category_id, account_id, date, created_at, updated_at) '
    'VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
    [
      id,
      amountMinorUnits,
      currency,
      categoryId,
      accountId,
      date.millisecondsSinceEpoch ~/ 1000,
      epoch,
      epoch,
    ],
  );
}

void main() {
  late AppDatabase db;
  late TransactionRepository repo;

  setUp(() async {
    db = newTestAppDatabase();
    repo = DriftTransactionRepository(db);
    await _seedFixtures(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('watchByCategoryInRange', () {
    test('groups by (categoryId, currency) within [start, end)', () async {
      // Two USD expenses on food (cat 1), one EUR expense on food.
      await _insertTx(db, id: 1, date: DateTime(2026, 5, 18, 10),
          amountMinorUnits: 500, currency: 'USD', categoryId: 1);
      await _insertTx(db, id: 2, date: DateTime(2026, 5, 19, 12),
          amountMinorUnits: 700, currency: 'USD', categoryId: 1);
      await _insertTx(db, id: 3, date: DateTime(2026, 5, 20, 14),
          amountMinorUnits: 300, currency: 'EUR', categoryId: 1, accountId: 2);
      // One transport (cat 2) in the same week.
      await _insertTx(db, id: 4, date: DateTime(2026, 5, 21, 9),
          amountMinorUnits: 1000, currency: 'USD', categoryId: 2);
      // One outside the range.
      await _insertTx(db, id: 5, date: DateTime(2026, 5, 17, 10),
          amountMinorUnits: 9999, currency: 'USD', categoryId: 1);
      // One income (should be excluded by type filter).
      await _insertTx(db, id: 6, date: DateTime(2026, 5, 19, 10),
          amountMinorUnits: 50000, currency: 'USD', categoryId: 3);

      final slices = await repo.watchByCategoryInRange(
        start: DateTime(2026, 5, 18),
        end: DateTime(2026, 5, 25),
        type: CategoryType.expense,
      ).first;

      // Expected: (1,USD,1200), (1,EUR,300), (2,USD,1000)
      expect(slices, hasLength(3));
      expect(
        slices.firstWhere((s) => s.categoryId == 1 && s.currencyCode == 'USD')
            .totalMinorUnits,
        1200,
      );
      expect(
        slices.firstWhere((s) => s.categoryId == 1 && s.currencyCode == 'EUR')
            .totalMinorUnits,
        300,
      );
      expect(
        slices.firstWhere((s) => s.categoryId == 2 && s.currencyCode == 'USD')
            .totalMinorUnits,
        1000,
      );
    });

    test('emits empty list for ranges with no transactions', () async {
      final slices = await repo.watchByCategoryInRange(
        start: DateTime(2026, 1, 1),
        end: DateTime(2026, 1, 8),
        type: CategoryType.expense,
      ).first;
      expect(slices, isEmpty);
    });
  });

  group('watchByAccountInRange', () {
    test('groups by (accountId, currency)', () async {
      await _insertTx(db, id: 1, date: DateTime(2026, 5, 18, 10),
          amountMinorUnits: 500, currency: 'USD', categoryId: 1, accountId: 1);
      await _insertTx(db, id: 2, date: DateTime(2026, 5, 19, 12),
          amountMinorUnits: 700, currency: 'EUR', categoryId: 1, accountId: 2);

      final slices = await repo.watchByAccountInRange(
        start: DateTime(2026, 5, 18),
        end: DateTime(2026, 5, 25),
        type: CategoryType.expense,
      ).first;

      expect(slices, hasLength(2));
      expect(
        slices.firstWhere((s) => s.accountId == 1).totalMinorUnits,
        500,
      );
      expect(
        slices.firstWhere((s) => s.accountId == 2).totalMinorUnits,
        700,
      );
    });
  });

  group('watchByCurrencyInRange', () {
    test('sums per currency', () async {
      await _insertTx(db, id: 1, date: DateTime(2026, 5, 18, 10),
          amountMinorUnits: 500, currency: 'USD', categoryId: 1);
      await _insertTx(db, id: 2, date: DateTime(2026, 5, 19, 12),
          amountMinorUnits: 700, currency: 'USD', categoryId: 2);
      await _insertTx(db, id: 3, date: DateTime(2026, 5, 20, 14),
          amountMinorUnits: 300, currency: 'EUR', categoryId: 1, accountId: 2);

      final slices = await repo.watchByCurrencyInRange(
        start: DateTime(2026, 5, 18),
        end: DateTime(2026, 5, 25),
        type: CategoryType.expense,
      ).first;

      expect(
        slices.firstWhere((s) => s.currencyCode == 'USD').totalMinorUnits,
        1200,
      );
      expect(
        slices.firstWhere((s) => s.currencyCode == 'EUR').totalMinorUnits,
        300,
      );
    });
  });

  group('watchTimeBucketsInRange', () {
    test('hour granularity buckets by local hour', () async {
      // Same day, two transactions in the 10:xx hour, one in 14:xx.
      await _insertTx(db, id: 1, date: DateTime(2026, 5, 18, 10, 5),
          amountMinorUnits: 500, currency: 'USD', categoryId: 1);
      await _insertTx(db, id: 2, date: DateTime(2026, 5, 18, 10, 45),
          amountMinorUnits: 200, currency: 'USD', categoryId: 1);
      await _insertTx(db, id: 3, date: DateTime(2026, 5, 18, 14, 30),
          amountMinorUnits: 100, currency: 'USD', categoryId: 1);

      final buckets = await repo.watchTimeBucketsInRange(
        start: DateTime(2026, 5, 18),
        end: DateTime(2026, 5, 19),
        type: CategoryType.expense,
        granularity: TimeBucketGranularity.hour,
      ).first;

      final tenAm = buckets.firstWhere(
        (b) => b.bucketStart == DateTime(2026, 5, 18, 10),
      );
      expect(tenAm.totalMinorUnits, 700);
      final twoPm = buckets.firstWhere(
        (b) => b.bucketStart == DateTime(2026, 5, 18, 14),
      );
      expect(twoPm.totalMinorUnits, 100);
    });

    test('day granularity buckets by startOfDay; preserves currency', () async {
      await _insertTx(db, id: 1, date: DateTime(2026, 5, 18, 10),
          amountMinorUnits: 500, currency: 'USD', categoryId: 1);
      await _insertTx(db, id: 2, date: DateTime(2026, 5, 18, 14),
          amountMinorUnits: 300, currency: 'EUR', categoryId: 1, accountId: 2);
      await _insertTx(db, id: 3, date: DateTime(2026, 5, 20, 9),
          amountMinorUnits: 200, currency: 'USD', categoryId: 1);

      final buckets = await repo.watchTimeBucketsInRange(
        start: DateTime(2026, 5, 18),
        end: DateTime(2026, 5, 25),
        type: CategoryType.expense,
        granularity: TimeBucketGranularity.day,
      ).first;

      // 3 (bucketStart, currency) pairs: (5/18 USD), (5/18 EUR), (5/20 USD).
      expect(buckets, hasLength(3));
      final mondayUsd = buckets.firstWhere(
        (b) => b.bucketStart == DateTime(2026, 5, 18) && b.currencyCode == 'USD',
      );
      expect(mondayUsd.totalMinorUnits, 500);
    });

    test('month granularity buckets by startOfMonth', () async {
      await _insertTx(db, id: 1, date: DateTime(2026, 1, 15, 10),
          amountMinorUnits: 500, currency: 'USD', categoryId: 1);
      await _insertTx(db, id: 2, date: DateTime(2026, 1, 31, 23),
          amountMinorUnits: 300, currency: 'USD', categoryId: 1);
      await _insertTx(db, id: 3, date: DateTime(2026, 3, 5, 12),
          amountMinorUnits: 100, currency: 'USD', categoryId: 1);

      final buckets = await repo.watchTimeBucketsInRange(
        start: DateTime(2026, 1, 1),
        end: DateTime(2027, 1, 1),
        type: CategoryType.expense,
        granularity: TimeBucketGranularity.month,
      ).first;

      final jan = buckets.firstWhere(
        (b) => b.bucketStart == DateTime(2026, 1, 1),
      );
      expect(jan.totalMinorUnits, 800);
      final mar = buckets.firstWhere(
        (b) => b.bucketStart == DateTime(2026, 3, 1),
      );
      expect(mar.totalMinorUnits, 100);
    });

    test('reactive: re-emits on insert', () async {
      final stream = repo.watchTimeBucketsInRange(
        start: DateTime(2026, 5, 18),
        end: DateTime(2026, 5, 25),
        type: CategoryType.expense,
        granularity: TimeBucketGranularity.day,
      );

      final emissions = <List<TimeBucketSlice>>[];
      final sub = stream.listen(emissions.add);

      await Future<void>.delayed(Duration.zero);
      expect(emissions, hasLength(1));
      expect(emissions.first, isEmpty);

      await _insertTx(db, id: 1, date: DateTime(2026, 5, 19, 10),
          amountMinorUnits: 500, currency: 'USD', categoryId: 1);
      await Future<void>.delayed(Duration.zero);

      expect(emissions.length, greaterThanOrEqualTo(2));
      expect(emissions.last, hasLength(1));
      expect(emissions.last.first.totalMinorUnits, 500);

      await sub.cancel();
    });
  });
}
```

- [ ] **Step 2: Run tests to verify failure**

Run: `flutter test test/unit/repositories/transaction_repository_charts_test.dart`
Expected: FAIL — `watchByCategoryInRange`, `watchByAccountInRange`, `watchByCurrencyInRange`, `watchTimeBucketsInRange` are not defined on `TransactionRepository`.

- [ ] **Step 3: Add the abstract method declarations to `TransactionRepository`**

In `lib/data/repositories/transaction_repository.dart`, add to the imports block:

```dart
import '../models/account_slice.dart';
import '../models/category.dart' show CategoryType;
import '../models/category_slice.dart';
import '../models/currency_slice.dart';
import '../models/time_bucket_slice.dart';
```

Then inside `abstract class TransactionRepository {`, after `watchByMemo`, add:

```dart
  /// Per-(category, currency) subtotal in `[start, end)` filtered by
  /// transaction type. Emits one row per pair so chart controllers can
  /// run currency conversion before regrouping. See basic-charts spec
  /// § Data Layer / Query Examples.
  Stream<List<CategorySlice>> watchByCategoryInRange({
    required DateTime start,
    required DateTime end,
    required CategoryType type,
  });

  /// Per-(account, currency) subtotal in `[start, end)` filtered by
  /// transaction type.
  Stream<List<AccountSlice>> watchByAccountInRange({
    required DateTime start,
    required DateTime end,
    required CategoryType type,
  });

  /// Per-currency total in `[start, end)` filtered by transaction type.
  Stream<List<CurrencySlice>> watchByCurrencyInRange({
    required DateTime start,
    required DateTime end,
    required CategoryType type,
  });

  /// Per-(bucketStart, currency) subtotal in `[start, end)` filtered by
  /// transaction type, with [granularity] selecting hour/day/month
  /// buckets. Local bucket math uses `DateHelpers` so midnight + DST
  /// behaviour matches the rest of the app.
  Stream<List<TimeBucketSlice>> watchTimeBucketsInRange({
    required DateTime start,
    required DateTime end,
    required CategoryType type,
    required TimeBucketGranularity granularity,
  });
```

- [ ] **Step 4: Implement the methods in `DriftTransactionRepository`**

Add imports if missing (the implementation needs `DateHelpers`):

```dart
import '../../core/utils/date_helpers.dart';
```

(Already imported — confirm.)

Add a small helper near the top of the class for SQL `type` strings:

```dart
  String _typeWire(CategoryType type) => type == CategoryType.expense
      ? 'expense'
      : 'income';
```

Then add the four method implementations inside `final class DriftTransactionRepository`, after `watchByMemo`:

```dart
  @override
  Stream<List<CategorySlice>> watchByCategoryInRange({
    required DateTime start,
    required DateTime end,
    required CategoryType type,
  }) {
    return _dao
        .watchCategoryTotalsInRange(
          start: start,
          end: end,
          type: _typeWire(type),
        )
        .map(
          (rows) => rows
              .map(
                (r) => CategorySlice(
                  categoryId: r.categoryId,
                  currencyCode: r.currency,
                  totalMinorUnits: r.total,
                ),
              )
              .toList(growable: false),
        );
  }

  @override
  Stream<List<AccountSlice>> watchByAccountInRange({
    required DateTime start,
    required DateTime end,
    required CategoryType type,
  }) {
    return _dao
        .watchAccountTotalsInRange(
          start: start,
          end: end,
          type: _typeWire(type),
        )
        .map(
          (rows) => rows
              .map(
                (r) => AccountSlice(
                  accountId: r.accountId,
                  currencyCode: r.currency,
                  totalMinorUnits: r.total,
                ),
              )
              .toList(growable: false),
        );
  }

  @override
  Stream<List<CurrencySlice>> watchByCurrencyInRange({
    required DateTime start,
    required DateTime end,
    required CategoryType type,
  }) {
    return _dao
        .watchCurrencyTotalsInRange(
          start: start,
          end: end,
          type: _typeWire(type),
        )
        .map(
          (rows) => rows
              .map(
                (r) => CurrencySlice(
                  currencyCode: r.currency,
                  totalMinorUnits: r.total,
                ),
              )
              .toList(growable: false),
        );
  }

  @override
  Stream<List<TimeBucketSlice>> watchTimeBucketsInRange({
    required DateTime start,
    required DateTime end,
    required CategoryType type,
    required TimeBucketGranularity granularity,
  }) {
    return _dao
        .watchChartRowsInRange(
          start: start,
          end: end,
          type: _typeWire(type),
        )
        .map((rows) {
          // Bucket locally so DST / midnight semantics match DateHelpers.
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
              TimeBucketGranularity.month =>
                DateHelpers.startOfMonth(r.date),
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
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `dart format . && flutter test test/unit/repositories/transaction_repository_charts_test.dart`
Expected: PASS (all groups).

- [ ] **Step 6: Run the rest of the suite to confirm no regressions**

Run: `flutter test test/unit/repositories/`
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/data/repositories/transaction_repository.dart \
  test/unit/repositories/transaction_repository_charts_test.dart
git commit -m "feat(transaction_repository): add chart range methods (category/account/currency/time-bucket)"
```

---

### Task 6: Expose rate metadata from `ExchangeRateRepository`

**Files:**
- Modify: `lib/data/repositories/exchange_rate_repository.dart`
- Modify: `test/unit/repositories/exchange_rate_repository_test.dart`

The `chartsFxStatusProvider` needs per-pair `fetchedAt` so the warm-start gate (1h freshness) and the "initial refresh complete" signal can be derived. Controllers can't import the DAO, so we expose a new stream of `(rateScaledE9, fetchedAt)` records keyed by `from→to`.

- [ ] **Step 1: Add a failing test in the existing exchange-rate test file**

Open `test/unit/repositories/exchange_rate_repository_test.dart` and append to the existing test groups:

```dart
  group('watchRatesMetadata', () {
    test('emits per-pair (rate, fetchedAt) keyed by from→to', () async {
      // Use the same harness as other tests in this file; insert two rates
      // directly into the DAO.
      // (Adapt to whatever helper this test file already uses; if the file
      // uses `_makeRepo()`, reuse it. Otherwise mirror the in-memory DB
      // setup at the top.)
      final db = newTestAppDatabase();
      addTearDown(() async => db.close());
      // Insert USD currency twice (defaultCurrency seed) and EUR + JPY pairs.
      await db.customStatement(
        'INSERT INTO currencies (code, decimals, name_l10n_key, is_token, '
        "sort_order) VALUES ('USD', 2, 'currency.usd', 0, 1)",
      );
      await db.customStatement(
        'INSERT INTO currencies (code, decimals, name_l10n_key, is_token, '
        "sort_order) VALUES ('EUR', 2, 'currency.eur', 0, 2)",
      );
      await db.customStatement(
        'INSERT INTO currencies (code, decimals, name_l10n_key, is_token, '
        "sort_order) VALUES ('JPY', 0, 'currency.jpy', 0, 3)",
      );

      final eurFetchedAt = DateTime(2026, 5, 19, 10);
      final jpyFetchedAt = DateTime(2026, 5, 19, 11);
      await db.customStatement(
        'INSERT INTO exchange_rates (base_currency, quote_currency, '
        'rate_scaled_e9, fetched_at) VALUES (?, ?, ?, ?)',
        ['EUR', 'USD', 1100000000, eurFetchedAt.millisecondsSinceEpoch ~/ 1000],
      );
      await db.customStatement(
        'INSERT INTO exchange_rates (base_currency, quote_currency, '
        'rate_scaled_e9, fetched_at) VALUES (?, ?, ?, ?)',
        ['JPY', 'USD', 6700000, jpyFetchedAt.millisecondsSinceEpoch ~/ 1000],
      );

      final repo = ExchangeRateRepository(
        db,
        _FakeExchangeRateService(),
        Stream<String>.empty(),
      );
      addTearDown(repo.dispose);

      final snapshot = await repo.watchRatesMetadata().first;
      expect(snapshot['EUR→USD'], isNotNull);
      expect(snapshot['EUR→USD']!.rateScaledE9, 1100000000);
      expect(snapshot['EUR→USD']!.fetchedAt, eurFetchedAt);
      expect(snapshot['JPY→USD']!.rateScaledE9, 6700000);
    });
  });
```

(If `_FakeExchangeRateService` already exists in the test file, reuse it. If not, copy whatever mock the file already uses for `ExchangeRateService`.)

- [ ] **Step 2: Run tests to verify failure**

Run: `flutter test test/unit/repositories/exchange_rate_repository_test.dart`
Expected: FAIL — `watchRatesMetadata` is not defined.

- [ ] **Step 3: Add the public type + method**

In `lib/data/repositories/exchange_rate_repository.dart`, near the top after the class doc-comment block, add a small data class:

```dart
/// Per-pair rate metadata exposed to consumers that need both the rate
/// and the `fetchedAt` timestamp (e.g. the chart warm-start gate). Keyed
/// by `from→to` in the snapshot map returned by [ExchangeRateRepository.watchRatesMetadata].
class ExchangeRateMetadata {
  const ExchangeRateMetadata({
    required this.rateScaledE9,
    required this.fetchedAt,
  });

  final int rateScaledE9;
  final DateTime fetchedAt;
}
```

Then inside `class ExchangeRateRepository`, alongside `watchRates()`, add:

```dart
  /// Stream of `from→to` → `ExchangeRateMetadata` snapshots. Re-emits on
  /// every DAO change (insert / update / delete).
  Stream<Map<String, ExchangeRateMetadata>> watchRatesMetadata() {
    return _dao.watchAll().map((rows) {
      final map = <String, ExchangeRateMetadata>{};
      for (final row in rows) {
        final key = '${row.baseCurrency}→${row.quoteCurrency}';
        map[key] = ExchangeRateMetadata(
          rateScaledE9: row.rateScaledE9,
          fetchedAt: row.fetchedAt,
        );
      }
      return map;
    });
  }
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `dart format . && flutter test test/unit/repositories/exchange_rate_repository_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/data/repositories/exchange_rate_repository.dart \
  test/unit/repositories/exchange_rate_repository_test.dart
git commit -m "feat(exchange_rate_repository): expose per-pair rate metadata stream"
```

---

### Task 7: Add chart state types (Freezed sealed union)

**Files:**
- Create: `lib/features/analysis/charts/charts_state.dart`

State shape mirrors the spec but uses `ChartDimension` / `PeriodType` Dart enums declared in this file. `ChartsData.previousBecomesNull` and `ChartsLoading.previous` carry `ChartsData?` so loading/blocked variants can keep rendering the prior chart body. Per the `states_forbid_data_internals` import_lint rule, this file may import domain models from `data/models/` but nothing from `data/database/...`, `data/services/...`, or `data/repositories/...`.

- [ ] **Step 1: Create the state file**

```dart
// Chart slice state — see
// `docs/superpowers/specs/2026-05-18-basic-charts-design.md` § Controller
// & State and `docs/superpowers/plans/2026-05-19-basic-charts.md`.
//
// `ChartsLoading.previous` and `ChartsBlockedByMissingRates.previous`
// carry the prior `ChartsData` so the UI can keep rendering the previous
// chart body under a spinner or banner without remounting controls.

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../data/models/category.dart' show CategoryType;

part 'charts_state.freezed.dart';

/// Active chart period — drives both the period selector label and the
/// repository range / bar-chart granularity.
enum PeriodType { day, week, month, year }

/// Pie/bar grouping axis. Toggled via the dimension chips.
enum ChartDimension { category, account, currency }

@freezed
sealed class ChartsState with _$ChartsState {
  /// Pre-first-emission. Renders chart-sized loading shimmer beneath the
  /// (already-mounted) control row.
  const factory ChartsState.idle() = ChartsIdle;

  /// New range/dimension/type subscribed; previous data (if any) is kept
  /// visible while the new payload lands. `previous == null` means cold
  /// start.
  const factory ChartsState.loading({ChartsData? previous}) = ChartsLoading;

  /// Latest converted-and-grouped payload.
  const factory ChartsState.data({required ChartsData chartData}) =
      ChartsDataState;

  /// Range has no transactions matching the active type. Shows the
  /// `chartsNoData` copy under the controls.
  const factory ChartsState.empty() = ChartsEmpty;

  /// FX rates missing for category/account dimensions. Keeps the prior
  /// chart visible if any, plus the rates-required banner. See spec
  /// § Empty States.
  const factory ChartsState.blockedByMissingRates({ChartsData? previous}) =
      ChartsBlockedByMissingRates;

  /// Stream error path. Controls stay mounted; chart body shows error +
  /// retry.
  const factory ChartsState.error(Object error, StackTrace stack) =
      ChartsError;
}

@freezed
abstract class ChartsData with _$ChartsData {
  const factory ChartsData({
    required PeriodType period,
    required DateTime anchorDate,
    required CategoryType type,
    required ChartDimension dimension,
    required List<ChartSlice> slices,
    required List<ChartBucketTotal> bucketTotals,

    /// Only set when every active subtotal is comparable in one
    /// display currency. Null in currency-view-with-mixed-rates.
    required int? grandTotalMinorUnits,

    /// Set when slices are unified into one display currency. Null when
    /// each slice keeps its own `currencyCode` (currency dimension with
    /// missing rates).
    required String? displayCurrencyCode,
    @Default(false) bool mixedCurrencies,

    /// True when Task 12's cold-start fallback auto-switched the active
    /// dimension from `category` to `currency` because category view was
    /// blocked by missing FX rates. `ChartsSection` reads this flag to
    /// render an explanatory banner above the chart body. Cleared when
    /// the user manually changes dimension or dismisses the banner.
    @Default(false) bool autoSwitchedFromCategoryDimension,

    /// Currency codes whose subtotals were dropped from this chart
    /// because their FX rate was missing at emit time. Empty in the
    /// all-rates-present case. When non-empty, `ChartsSection` renders
    /// a ribbon listing them above the chart body. Category/account
    /// dimension only — currency dimension shows source amounts inline.
    @Default(<String>[]) List<String> excludedCurrencyCodes,
  }) = _ChartsData;
}

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
  }) = _ChartSlice;
}

@freezed
abstract class ChartBucketTotal with _$ChartBucketTotal {
  const factory ChartBucketTotal({
    required DateTime bucketStart,
    required int totalMinorUnits,
  }) = _ChartBucketTotal;
}
```

- [ ] **Step 2: Generate Freezed files**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: succeeds; `charts_state.freezed.dart` is created.

- [ ] **Step 3: Verify analyzer**

Run: `dart format . && flutter analyze`
Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add lib/features/analysis/charts/charts_state.dart \
  lib/features/analysis/charts/charts_state.freezed.dart
git commit -m "feat(charts): add ChartsState Freezed union + ChartSlice/ChartBucketTotal"
```

---

### Task 8: Add `charts_providers.dart` with FX status + currencies-by-code

**Files:**
- Create: `lib/features/analysis/charts/charts_providers.dart`

Co-located plain `StreamProvider` providers (the same style as `analysis_providers.dart` and `home_providers.dart`). Defines `ChartsFxStatus` and the two providers consumed by `ChartsController`.

- [ ] **Step 1: Create the providers file**

```dart
// Chart slice — co-located Riverpod providers.
//
// `chartsFxStatusProvider` joins the user's default currency with the
// repository's per-pair `(rate, fetchedAt)` snapshot so the controller
// can decide warm-start eligibility, blocked state, and refresh
// triggers without touching the DAO directly.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/default_currency_provider.dart';
import '../../../app/providers/repository_providers.dart';
import '../../../data/models/currency.dart';
import '../../../data/repositories/exchange_rate_repository.dart';

/// FX readiness + freshness snapshot for the active default currency.
class ChartsFxStatus {
  const ChartsFxStatus({
    required this.defaultCurrencyCode,
    required this.rates,
  });

  final String defaultCurrencyCode;

  /// `from→default` keyed snapshot of converted-and-timestamped rates.
  final Map<String, ExchangeRateMetadata> rates;

  /// Forward rate lookup for `from → defaultCurrency`. Returns 1e9 when
  /// `from == defaultCurrency` (identity). Null when no row exists.
  int? scaledRate(String from) {
    if (from == defaultCurrencyCode) return 1000000000;
    return rates['$from→$defaultCurrencyCode']?.rateScaledE9;
  }

  /// Most recent `fetchedAt` across all relevant pairs. Used by the
  /// warm-start gate (1h freshness window). `null` when there are no
  /// rates at all (cold start).
  DateTime? mostRecentFetchedAt() {
    DateTime? latest;
    for (final m in rates.values) {
      if (latest == null || m.fetchedAt.isAfter(latest)) {
        latest = m.fetchedAt;
      }
    }
    return latest;
  }
}

/// Stream of the joined FX status. Re-emits whenever either the default
/// currency or the per-pair rate metadata changes. Uses an internal
/// `StreamController` so both inputs feed the same output without
/// dropping events from whichever input wasn't last awaited.
final chartsFxStatusProvider = StreamProvider.autoDispose<ChartsFxStatus>(
  (ref) {
    final initialDefault = ref.watch(initialDefaultCurrencyProvider);
    final defaultsStream = ref.watch(defaultCurrencyProvider.stream);
    final repo = ref.watch(exchangeRateRepositoryProvider);
    final metadataStream = repo.watchRatesMetadata();

    final controller = StreamController<ChartsFxStatus>();
    var defaultCode = initialDefault;
    var rates = <String, ExchangeRateMetadata>{};

    void emit() {
      if (!controller.isClosed) {
        controller.add(
          ChartsFxStatus(defaultCurrencyCode: defaultCode, rates: rates),
        );
      }
    }

    // Seed immediately so the UI never sits in AsyncValue.loading just
    // because no rates have arrived yet.
    emit();

    final ratesSub = metadataStream.listen((next) {
      rates = next;
      emit();
    });
    final defaultSub = defaultsStream.listen((next) {
      defaultCode = next;
      emit();
    });
    ref.onDispose(() {
      ratesSub.cancel();
      defaultSub.cancel();
      controller.close();
    });

    return controller.stream;
  },
);

/// `code → Currency` for `MoneyFormatter` lookups in chart widgets.
/// Mirrors `homeCurrenciesByCodeProvider` shape so chart code can format
/// amounts identically to the Home summary strip.
final chartsCurrenciesByCodeProvider =
    StreamProvider.autoDispose<Map<String, Currency>>((ref) {
      final repo = ref.watch(currencyRepositoryProvider);
      return repo
          .watchAll(includeTokens: true)
          .map((rows) => {for (final c in rows) c.code: c});
    });
```

**Note:** The chart code reuses `analysisCategoriesByIdProvider` and `analysisAccountsByIdProvider` from `lib/features/analysis/search/analysis_providers.dart` rather than re-exporting them here. The spec calls this out explicitly.

- [ ] **Step 2: Verify analyzer**

Run: `dart format . && flutter analyze`
Expected: no errors (a single intentional `unused_local_variable` ignore is acceptable; if the reviewer prefers a cleaner shape, replace the merge code with `Stream.multi` plumbing in a follow-up).

- [ ] **Step 3: Commit**

```bash
git add lib/features/analysis/charts/charts_providers.dart
git commit -m "feat(charts): add chartsFxStatus + chartsCurrenciesByCode providers"
```

---

### Task 9: Implement `ChartsController` skeleton (build, range computation, period commands)

**Files:**
- Create: `lib/features/analysis/charts/charts_controller.dart`
- Create: `test/unit/controllers/charts_controller_test.dart`

This task lands the controller wiring without conversion or warm-start (those land in tasks 11/12/13). The controller mirrors `AnalysisController`: a `StreamNotifier` that returns a private `StreamController`'s stream and uses a `_generation` counter for cancellation. After Task 9, the controller can: subscribe to the right repository stream for the active dimension, emit `ChartsState.data` with un-converted slices/buckets (one slice per (id, currency) pair for now), and respond to `setPeriod / previousPeriod / nextPeriod`.

- [ ] **Step 1: Write the failing controller test (period + dimension commands)**

Create `test/unit/controllers/charts_controller_test.dart`:

```dart
// ChartsController tests — Tasks 9 + 10 cover period/dimension/type
// commands; Tasks 11–13 add conversion, blocked state, warm-start.
//
// Tests stub the four repository range methods via mocktail and use
// real `analysisCategoriesByIdProvider` / `analysisAccountsByIdProvider`
// stubs so the controller can resolve labels.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:ledgerly/app/providers/default_currency_provider.dart';
import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/data/models/account.dart';
import 'package:ledgerly/data/models/account_slice.dart';
import 'package:ledgerly/data/models/category.dart';
import 'package:ledgerly/data/models/category_slice.dart';
import 'package:ledgerly/data/models/currency.dart';
import 'package:ledgerly/data/models/currency_slice.dart';
import 'package:ledgerly/data/models/time_bucket_slice.dart';
import 'package:ledgerly/data/repositories/transaction_repository.dart';
import 'package:ledgerly/features/analysis/charts/charts_controller.dart';
import 'package:ledgerly/features/analysis/charts/charts_providers.dart';
import 'package:ledgerly/features/analysis/charts/charts_state.dart';
import 'package:ledgerly/features/analysis/search/analysis_providers.dart';

class _MockTxRepo extends Mock implements TransactionRepository {}

const _usd = Currency(
  code: 'USD',
  decimals: 2,
  symbol: r'$',
  nameL10nKey: 'currency.usd',
);

Category _cat(int id, {String? custom}) => Category(
  id: id,
  type: CategoryType.expense,
  l10nKey: 'category.test',
  customName: custom ?? 'Cat $id',
  icon: 'restaurant',
  color: id % 8,
  sortOrder: id,
  isArchived: false,
);

ProviderContainer _container({
  required TransactionRepository repo,
  Map<int, Category> categories = const {1: Category(
    id: 1,
    type: CategoryType.expense,
    l10nKey: 'cat.test',
    customName: 'Food',
    icon: 'restaurant',
    color: 0,
    isArchived: false,
  )},
  Map<int, Account> accounts = const {},
  Map<String, Currency> currencies = const {'USD': _usd},
}) {
  return ProviderContainer(
    overrides: [
      transactionRepositoryProvider.overrideWithValue(repo),
      analysisCategoriesByIdProvider.overrideWith(
        (ref) => Stream.value(categories),
      ),
      analysisAccountsByIdProvider.overrideWith(
        (ref) => Stream.value(accounts),
      ),
      chartsCurrenciesByCodeProvider.overrideWith(
        (ref) => Stream.value(currencies),
      ),
      chartsFxStatusProvider.overrideWith(
        (ref) => Stream.value(
          ChartsFxStatus(defaultCurrencyCode: 'USD', rates: const {}),
        ),
      ),
      initialDefaultCurrencyProvider.overrideWithValue('USD'),
    ],
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(CategoryType.expense);
    registerFallbackValue(TimeBucketGranularity.day);
  });

  group('ChartsController — single-currency category dimension', () {
    late _MockTxRepo repo;

    setUp(() {
      repo = _MockTxRepo();
      when(() => repo.watchByCategoryInRange(
            start: any(named: 'start'),
            end: any(named: 'end'),
            type: any(named: 'type'),
          )).thenAnswer((_) => Stream.value(<CategorySlice>[
                const CategorySlice(
                  categoryId: 1,
                  currencyCode: 'USD',
                  totalMinorUnits: 1000,
                ),
              ]));
      when(() => repo.watchTimeBucketsInRange(
            start: any(named: 'start'),
            end: any(named: 'end'),
            type: any(named: 'type'),
            granularity: any(named: 'granularity'),
          )).thenAnswer((_) => Stream.value(<TimeBucketSlice>[
                TimeBucketSlice(
                  bucketStart: DateTime(2026, 5, 18),
                  currencyCode: 'USD',
                  totalMinorUnits: 1000,
                ),
              ]));
    });

    test('default state is week / expense / category and emits data', () async {
      final container = _container(repo: repo);
      addTearDown(container.dispose);

      // Wait for first non-loading emission.
      ChartsState? latest;
      final sub = container.listen<AsyncValue<ChartsState>>(
        chartsControllerProvider,
        (_, next) => latest = next.valueOrNull,
        fireImmediately: true,
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));
      sub.close();

      expect(latest, isA<ChartsDataState>());
      final data = (latest! as ChartsDataState).chartData;
      expect(data.period, PeriodType.week);
      expect(data.type, CategoryType.expense);
      expect(data.dimension, ChartDimension.category);
      expect(data.slices, hasLength(1));
      expect(data.slices.first.totalMinorUnits, 1000);
    });

    test('setPeriod(day) re-subscribes with a 24h range', () async {
      final container = _container(repo: repo);
      addTearDown(container.dispose);
      container.listen(chartsControllerProvider, (_, _) {});

      // Initial week subscription has already happened in build().
      await Future<void>.delayed(const Duration(milliseconds: 10));
      clearInteractions(repo);

      container.read(chartsControllerProvider.notifier).setPeriod(PeriodType.day);

      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Verify the new subscription used a 24h range.
      final captured = verify(() => repo.watchByCategoryInRange(
            start: captureAny(named: 'start'),
            end: captureAny(named: 'end'),
            type: any(named: 'type'),
          )).captured;
      final start = captured[0] as DateTime;
      final end = captured[1] as DateTime;
      expect(end.difference(start), const Duration(days: 1));
    });

    test('previousPeriod / nextPeriod shift the anchor by one period', () async {
      final container = _container(repo: repo);
      addTearDown(container.dispose);
      container.listen(chartsControllerProvider, (_, _) {});
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Read current anchor.
      final initial = container
          .read(chartsControllerProvider)
          .valueOrNull as ChartsDataState;
      final initialAnchor = initial.chartData.anchorDate;

      container.read(chartsControllerProvider.notifier).previousPeriod();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      final after = (container
          .read(chartsControllerProvider)
          .valueOrNull as ChartsDataState).chartData.anchorDate;
      expect(after.isBefore(initialAnchor), isTrue);
    });

    test('toggleType switches to income and resubscribes', () async {
      final container = _container(repo: repo);
      addTearDown(container.dispose);
      container.listen(chartsControllerProvider, (_, _) {});
      await Future<void>.delayed(const Duration(milliseconds: 10));

      container.read(chartsControllerProvider.notifier).toggleType();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      verify(() => repo.watchByCategoryInRange(
            start: any(named: 'start'),
            end: any(named: 'end'),
            type: CategoryType.income,
          )).called(greaterThanOrEqualTo(1));
    });

    test('toggleDimension(account) re-subscribes to account stream', () async {
      when(() => repo.watchByAccountInRange(
            start: any(named: 'start'),
            end: any(named: 'end'),
            type: any(named: 'type'),
          )).thenAnswer((_) => Stream.value(<AccountSlice>[
                const AccountSlice(
                  accountId: 1,
                  currencyCode: 'USD',
                  totalMinorUnits: 500,
                ),
              ]));

      final container = _container(repo: repo);
      addTearDown(container.dispose);
      container.listen(chartsControllerProvider, (_, _) {});
      await Future<void>.delayed(const Duration(milliseconds: 10));

      container
          .read(chartsControllerProvider.notifier)
          .toggleDimension(ChartDimension.account);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      verify(() => repo.watchByAccountInRange(
            start: any(named: 'start'),
            end: any(named: 'end'),
            type: any(named: 'type'),
          )).called(greaterThanOrEqualTo(1));
    });

    test('empty slices emit ChartsEmpty', () async {
      when(() => repo.watchByCategoryInRange(
            start: any(named: 'start'),
            end: any(named: 'end'),
            type: any(named: 'type'),
          )).thenAnswer((_) => Stream.value(const <CategorySlice>[]));
      when(() => repo.watchTimeBucketsInRange(
            start: any(named: 'start'),
            end: any(named: 'end'),
            type: any(named: 'type'),
            granularity: any(named: 'granularity'),
          )).thenAnswer((_) => Stream.value(const <TimeBucketSlice>[]));

      final container = _container(repo: repo);
      addTearDown(container.dispose);

      final completer = Completer<ChartsState>();
      final sub = container.listen<AsyncValue<ChartsState>>(
        chartsControllerProvider,
        (_, next) {
          final v = next.valueOrNull;
          if (v is ChartsEmpty && !completer.isCompleted) {
            completer.complete(v);
          }
        },
        fireImmediately: true,
      );
      addTearDown(sub.close);

      final result = await completer.future.timeout(
        const Duration(seconds: 1),
      );
      expect(result, isA<ChartsEmpty>());
    });
  });
}
```

- [ ] **Step 2: Run tests to verify failure**

Run: `flutter test test/unit/controllers/charts_controller_test.dart`
Expected: FAIL — `chartsControllerProvider`, `ChartsController`, etc. are undefined.

- [ ] **Step 3: Implement the controller (skeleton — no conversion / warm-start yet)**

Create `lib/features/analysis/charts/charts_controller.dart`:

```dart
// ChartsController — Analysis-tab chart slice owner.
//
// Mirrors `AnalysisController` (search slice) in structure: a private
// `StreamController<ChartsState>` is opened in `build()` and re-opened
// on every Riverpod rebuild; subscriptions use a generation counter so
// stale emissions from a prior period/dimension/type cannot leak into
// the active state.
//
// Tasks 9–10: skeleton (range computation, command surface, raw emission).
// Task 11 layers in currency conversion.
// Tasks 12–13 add blocked-state handling and warm-start reuse.

import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/providers/repository_providers.dart';
import '../../../core/utils/color_palette.dart';
import '../../../core/utils/date_helpers.dart';
import '../../../data/models/account.dart';
import '../../../data/models/account_slice.dart';
import '../../../data/models/category.dart';
import '../../../data/models/category_slice.dart';
import '../../../data/models/currency_slice.dart';
import '../../../data/models/time_bucket_slice.dart';
import '../search/analysis_providers.dart';
import '../../categories/widgets/category_display.dart';
// AppLocalizations is provided by the UI layer; controller resolves
// labels lazily via simple fallback strings to keep this file pure of
// Flutter imports. Category names come from `categoryDisplayName` which
// is a string-returning helper that needs an l10n instance. Since the
// controller cannot reach `BuildContext`, labels resolve to
// `customName ?? l10nKey ?? ''` here and the UI layer overrides at
// render time if necessary. See spec § Legend.
import 'charts_providers.dart';
import 'charts_state.dart';

part 'charts_controller.g.dart';

@Riverpod(
  keepAlive: true,
  dependencies: [
    transactionRepository,
    analysisCategoriesById,
    analysisAccountsById,
    chartsFxStatus,
    chartsCurrenciesByCode,
  ],
)
class ChartsController extends _$ChartsController {
  PeriodType _period = PeriodType.week;
  DateTime _anchor = DateTime.now();
  CategoryType _type = CategoryType.expense;
  ChartDimension _dimension = ChartDimension.category;

  int _generation = 0;
  StreamSubscription<List<Object>>? _sliceSub;
  StreamSubscription<List<TimeBucketSlice>>? _bucketsSub;
  StreamController<ChartsState>? _emitter;

  List<Object>? _lastSlices; // CategorySlice | AccountSlice | CurrencySlice
  List<TimeBucketSlice>? _lastBuckets;
  ChartsData? _lastEmittedData;

  @override
  Stream<ChartsState> build() {
    _emitter?.close();
    _sliceSub?.cancel();
    _bucketsSub?.cancel();

    final controller = StreamController<ChartsState>();
    _emitter = controller;

    // Re-resolve the current chart when FX or label metadata changes.
    ref.listen(chartsFxStatusProvider, (_, __) {
      if (_lastSlices != null && _lastBuckets != null) {
        _emitIfReady();
      }
    });
    ref.listen(chartsCurrenciesByCodeProvider, (_, __) {
      if (_lastSlices != null && _lastBuckets != null) {
        _emitIfReady();
      }
    });
    ref.listen(analysisCategoriesByIdProvider, (_, __) {
      if (_lastSlices != null && _lastBuckets != null) {
        _emitIfReady();
      }
    });
    ref.listen(analysisAccountsByIdProvider, (_, __) {
      if (_lastSlices != null && _lastBuckets != null) {
        _emitIfReady();
      }
    });

    controller.add(const ChartsState.idle());
    _resubscribe();

    ref.onDispose(() {
      _sliceSub?.cancel();
      _bucketsSub?.cancel();
      _sliceSub = null;
      _bucketsSub = null;
      controller.close();
    });

    return controller.stream;
  }

  // ---------- Commands ----------

  void setPeriod(PeriodType period) {
    if (_period == period) return;
    _period = period;
    _anchor = _normalizeAnchor(_anchor, period);
    _resubscribe();
  }

  void previousPeriod() {
    _anchor = _shiftAnchor(_anchor, _period, -1);
    _resubscribe();
  }

  void nextPeriod() {
    if (_isAtCurrentPeriod()) return; // Disabled at current period.
    _anchor = _shiftAnchor(_anchor, _period, 1);
    _resubscribe();
  }

  void toggleType() {
    _type = _type == CategoryType.expense
        ? CategoryType.income
        : CategoryType.expense;
    _resubscribe();
  }

  void toggleDimension(ChartDimension d) {
    if (_dimension == d) return;
    _dimension = d;
    _resubscribe();
  }

  void retry() {
    _resubscribe();
  }

  // ---------- Subscription wiring ----------

  ({DateTime start, DateTime end}) _currentRange() {
    final start = _normalizeAnchor(_anchor, _period);
    final end = _shiftAnchor(start, _period, 1);
    return (start: start, end: end);
  }

  TimeBucketGranularity _granularity() => switch (_period) {
        PeriodType.day => TimeBucketGranularity.hour,
        PeriodType.week => TimeBucketGranularity.day,
        PeriodType.month => TimeBucketGranularity.day,
        PeriodType.year => TimeBucketGranularity.month,
      };

  void _resubscribe() {
    _sliceSub?.cancel();
    _bucketsSub?.cancel();
    _lastSlices = null;
    _lastBuckets = null;
    final myGen = ++_generation;
    _emitter?.add(ChartsState.loading(previous: _lastEmittedData));

    final repo = ref.read(transactionRepositoryProvider);
    final range = _currentRange();

    // Bar-chart subscription.
    _bucketsSub = repo
        .watchTimeBucketsInRange(
          start: range.start,
          end: range.end,
          type: _type,
          granularity: _granularity(),
        )
        .listen(
          (buckets) {
            if (myGen != _generation) return;
            _lastBuckets = buckets;
            _emitIfReady();
          },
          onError: (Object e, StackTrace st) {
            if (myGen != _generation) return;
            _emitter?.add(ChartsState.error(e, st));
          },
        );

    // Pie subscription branches by dimension.
    switch (_dimension) {
      case ChartDimension.category:
        _sliceSub = repo
            .watchByCategoryInRange(
              start: range.start,
              end: range.end,
              type: _type,
            )
            .listen(
              (slices) => _onSlices(myGen, slices),
              onError: (Object e, StackTrace st) {
                if (myGen != _generation) return;
                _emitter?.add(ChartsState.error(e, st));
              },
            );
      case ChartDimension.account:
        _sliceSub = repo
            .watchByAccountInRange(
              start: range.start,
              end: range.end,
              type: _type,
            )
            .listen(
              (slices) => _onSlices(myGen, slices),
              onError: (Object e, StackTrace st) {
                if (myGen != _generation) return;
                _emitter?.add(ChartsState.error(e, st));
              },
            );
      case ChartDimension.currency:
        _sliceSub = repo
            .watchByCurrencyInRange(
              start: range.start,
              end: range.end,
              type: _type,
            )
            .listen(
              (slices) => _onSlices(myGen, slices),
              onError: (Object e, StackTrace st) {
                if (myGen != _generation) return;
                _emitter?.add(ChartsState.error(e, st));
              },
            );
    }
  }

  void _onSlices(int myGen, List<Object> slices) {
    if (myGen != _generation) return;
    _lastSlices = slices;
    _emitIfReady();
  }

  // Task 9 emission path: builds slices directly from un-converted data,
  // one ChartSlice per (id, currency) pair. Task 11 replaces this body
  // with conversion + regrouping logic.
  void _emitIfReady() {
    final slices = _lastSlices;
    final buckets = _lastBuckets;
    if (slices == null || buckets == null) return;
    if (slices.isEmpty && buckets.isEmpty) {
      _lastEmittedData = null;
      _emitter?.add(const ChartsState.empty());
      return;
    }

    final cats = ref.read(analysisCategoriesByIdProvider).valueOrNull ?? const {};
    final accts = ref.read(analysisAccountsByIdProvider).valueOrNull ?? const {};

    final chartSlices = <ChartSlice>[];
    for (final s in slices) {
      final (label, code, total, colorIndex, iconKey) = switch (s) {
        CategorySlice() => (
          _categoryLabel(s.categoryId, cats),
          s.currencyCode,
          s.totalMinorUnits,
          (cats[s.categoryId]?.color) ?? 0,
          cats[s.categoryId]?.icon ?? '',
        ),
        AccountSlice() => (
          _accountLabel(s.accountId, accts),
          s.currencyCode,
          s.totalMinorUnits,
          (accts[s.accountId]?.color) ?? CategoryPaletteIndex.neutralVariant50,
          accts[s.accountId]?.icon ?? '',
        ),
        CurrencySlice() => (
          s.currencyCode,
          s.currencyCode,
          s.totalMinorUnits,
          _currencyColorIndex(s.currencyCode),
          '',
        ),
        _ => ('', 'USD', 0, 0, ''),
      };
      chartSlices.add(ChartSlice(
        label: label,
        currencyCode: code,
        totalMinorUnits: total,
        colorIndex: colorIndex,
        iconKey: iconKey,
        fraction: null, // Task 11 fills this when conversion succeeds.
      ));
    }

    final bucketTotals = <ChartBucketTotal>[
      for (final b in buckets)
        ChartBucketTotal(
          bucketStart: b.bucketStart,
          totalMinorUnits: b.totalMinorUnits,
        ),
    ];

    final data = ChartsData(
      period: _period,
      anchorDate: _normalizeAnchor(_anchor, _period),
      type: _type,
      dimension: _dimension,
      slices: chartSlices,
      bucketTotals: bucketTotals,
      grandTotalMinorUnits: null,
      displayCurrencyCode: null,
      mixedCurrencies: chartSlices
              .map((s) => s.currencyCode)
              .toSet()
              .length >
          1,
    );
    _lastEmittedData = data;
    _emitter?.add(ChartsState.data(chartData: data));
  }

  String _categoryLabel(int id, Map<int, Category> cats) {
    final c = cats[id];
    if (c == null) return '';
    // UI layer can override via AppLocalizations; without context we use
    // customName or raw key as a best-effort label.
    if (c.customName != null && c.customName!.trim().isNotEmpty) {
      return c.customName!;
    }
    return c.l10nKey ?? '';
  }

  String _accountLabel(int id, Map<int, Account> accts) {
    return accts[id]?.name ?? '';
  }

  int _currencyColorIndex(String code) =>
      code.hashCode.abs() % kCategoryColorPalette.length;

  // ---------- Period math ----------

  DateTime _normalizeAnchor(DateTime anchor, PeriodType period) {
    switch (period) {
      case PeriodType.day:
        return DateHelpers.startOfDay(anchor);
      case PeriodType.week:
        return DateHelpers.startOfWeek(anchor);
      case PeriodType.month:
        return DateHelpers.startOfMonth(anchor);
      case PeriodType.year:
        return DateHelpers.startOfYear(anchor);
    }
  }

  DateTime _shiftAnchor(DateTime anchor, PeriodType period, int delta) {
    final base = _normalizeAnchor(anchor, period);
    switch (period) {
      case PeriodType.day:
        return DateTime(base.year, base.month, base.day + delta);
      case PeriodType.week:
        return DateTime(base.year, base.month, base.day + 7 * delta);
      case PeriodType.month:
        return DateTime(base.year, base.month + delta, 1);
      case PeriodType.year:
        return DateTime(base.year + delta, 1, 1);
    }
  }

  bool _isAtCurrentPeriod() {
    final now = DateTime.now();
    final currentAnchor = _normalizeAnchor(now, _period);
    final myAnchor = _normalizeAnchor(_anchor, _period);
    return !myAnchor.isBefore(currentAnchor);
  }
}
```

**Regression note:** Extend the controller test group with a case that changes period or dimension, lets only one of the new streams emit first, and asserts the controller does not combine that emission with stale `_lastSlices` / `_lastBuckets` from the prior subscription.

**Important note on the controller's imports:** `categoryDisplayName` import looks unused above — the controller resolves labels without an `AppLocalizations` instance. If `flutter analyze` flags it as unused, remove the import; otherwise leaving the comment-link to it documents intent.

- [ ] **Step 4: Generate riverpod files**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: `charts_controller.g.dart` appears.

- [ ] **Step 5: Run tests to verify they pass**

Run: `dart format . && flutter test test/unit/controllers/charts_controller_test.dart`
Expected: PASS (all groups under "single-currency category dimension").

- [ ] **Step 6: Commit**

```bash
git add lib/features/analysis/charts/charts_controller.dart \
  lib/features/analysis/charts/charts_controller.g.dart \
  test/unit/controllers/charts_controller_test.dart
git commit -m "feat(charts): add ChartsController skeleton (period/dimension/type commands)"
```

---

### Task 10: Disable `nextPeriod()` at the current period (boundary test)

**Files:**
- Modify: `test/unit/controllers/charts_controller_test.dart`
- (No production change expected — Task 9 already implements `_isAtCurrentPeriod()`.)

A boundary check: at the current week/month/year, `nextPeriod()` must not advance the anchor.

- [ ] **Step 1: Add the test**

Append to `test/unit/controllers/charts_controller_test.dart` inside the existing `main()`:

```dart
  group('ChartsController — boundary', () {
    late _MockTxRepo repo;

    setUp(() {
      repo = _MockTxRepo();
      when(() => repo.watchByCategoryInRange(
            start: any(named: 'start'),
            end: any(named: 'end'),
            type: any(named: 'type'),
          )).thenAnswer((_) => Stream.value(const <CategorySlice>[]));
      when(() => repo.watchTimeBucketsInRange(
            start: any(named: 'start'),
            end: any(named: 'end'),
            type: any(named: 'type'),
            granularity: any(named: 'granularity'),
          )).thenAnswer((_) => Stream.value(const <TimeBucketSlice>[]));
    });

    test('nextPeriod is a no-op when already at the current period', () async {
      final container = _container(repo: repo);
      addTearDown(container.dispose);
      container.listen(chartsControllerProvider, (_, _) {});

      final controller =
          container.read(chartsControllerProvider.notifier);

      // Default anchor is "now"; default period is week → already at the
      // current week.
      controller.nextPeriod();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // After nextPeriod() at current, anchor stays put.
      final state = container
          .read(chartsControllerProvider)
          .valueOrNull;
      // Anchor lives inside ChartsData; an empty range yields ChartsEmpty.
      // Either way, no second subscription with a later range fired.
      // mocktail will let us count calls: only the build-time call.
      final calls = verify(() => repo.watchByCategoryInRange(
            start: any(named: 'start'),
            end: any(named: 'end'),
            type: any(named: 'type'),
          )).callCount;
      expect(calls, 1, reason: 'nextPeriod at current should not resubscribe');
      // Silence unused warning if state is empty:
      expect(state, anyOf(isA<ChartsEmpty>(), isA<ChartsDataState>()));
    });
  });
```

- [ ] **Step 2: Run tests**

Run: `flutter test test/unit/controllers/charts_controller_test.dart`
Expected: PASS.

- [ ] **Step 3: Commit**

```bash
git add test/unit/controllers/charts_controller_test.dart
git commit -m "test(charts): assert nextPeriod no-op at current period"
```

---

### Task 11: Multi-currency conversion + regrouping in `ChartsController`

**Files:**
- Modify: `lib/features/analysis/charts/charts_controller.dart`
- Modify: `test/unit/controllers/charts_controller_test.dart`

Replace `_emitIfReady` so that for `category` / `account` dimensions every `(id, currency)` subtotal is converted via `CurrencyConverter.convertMinorUnits` to the default currency, then regrouped by `id`. For `currency` dimension, slices stay in their source currencies unless every pair has a valid rate. Bucket totals follow the same conversion path.

- [ ] **Step 1: Write the failing multi-currency tests**

Append to `test/unit/controllers/charts_controller_test.dart`:

```dart
  group('ChartsController — multi-currency conversion', () {
    late _MockTxRepo repo;

    setUp(() {
      repo = _MockTxRepo();
    });

    ProviderContainer make({
      required Map<String, int> ratesScaledE9,
      required String defaultCurrency,
    }) {
      final ratesMeta = <String, ExchangeRateMetadata>{};
      for (final entry in ratesScaledE9.entries) {
        ratesMeta[entry.key] = ExchangeRateMetadata(
          rateScaledE9: entry.value,
          fetchedAt: DateTime.now().subtract(const Duration(minutes: 5)),
        );
      }
      return ProviderContainer(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(repo),
          analysisCategoriesByIdProvider.overrideWith(
            (ref) => Stream.value({
              1: Category(
                id: 1,
                type: CategoryType.expense,
                l10nKey: 'cat.test',
                customName: 'Food',
                icon: 'restaurant',
                color: 0,
                isArchived: false,
              ),
            }),
          ),
          analysisAccountsByIdProvider.overrideWith(
            (ref) => Stream.value(const <int, Account>{}),
          ),
          chartsCurrenciesByCodeProvider.overrideWith(
            (ref) => Stream.value({
              'USD': _usd,
              'EUR': const Currency(
                code: 'EUR', decimals: 2, symbol: '€',
                nameL10nKey: 'currency.eur',
              ),
            }),
          ),
          chartsFxStatusProvider.overrideWith(
            (ref) => Stream.value(ChartsFxStatus(
              defaultCurrencyCode: defaultCurrency,
              rates: ratesMeta,
            )),
          ),
          initialDefaultCurrencyProvider.overrideWithValue(defaultCurrency),
        ],
      );
    }

    test('category dimension converts EUR→USD and regroups by id', () async {
      when(() => repo.watchByCategoryInRange(
            start: any(named: 'start'),
            end: any(named: 'end'),
            type: any(named: 'type'),
          )).thenAnswer((_) => Stream.value(<CategorySlice>[
                const CategorySlice(
                  categoryId: 1, currencyCode: 'USD', totalMinorUnits: 1000),
                const CategorySlice(
                  categoryId: 1, currencyCode: 'EUR', totalMinorUnits: 1000),
              ]));
      when(() => repo.watchTimeBucketsInRange(
            start: any(named: 'start'),
            end: any(named: 'end'),
            type: any(named: 'type'),
            granularity: any(named: 'granularity'),
          )).thenAnswer((_) => Stream.value(const <TimeBucketSlice>[]));

      final container = make(
        // 1 EUR = 1.10 USD → rate_scaled_e9 = 1_100_000_000
        ratesScaledE9: {'EUR→USD': 1100000000},
        defaultCurrency: 'USD',
      );
      addTearDown(container.dispose);
      container.listen(chartsControllerProvider, (_, _) {});
      await Future<void>.delayed(const Duration(milliseconds: 30));

      final state = container.read(chartsControllerProvider).valueOrNull;
      expect(state, isA<ChartsDataState>());
      final data = (state! as ChartsDataState).chartData;
      // One slice (category 1), USD display currency, 1000 + 1100 = 2100.
      expect(data.slices, hasLength(1));
      expect(data.slices.first.totalMinorUnits, 2100);
      expect(data.displayCurrencyCode, 'USD');
      expect(data.grandTotalMinorUnits, 2100);
      expect(data.mixedCurrencies, isFalse);
      expect(data.slices.first.fraction, closeTo(1.0, 0.0001));
    });

    test('category dimension blocks only when ALL rates are missing',
        () async {
      // Both slices in non-default currencies with no rates at all →
      // every active currency is unrateable → blocked state.
      when(() => repo.watchByCategoryInRange(
            start: any(named: 'start'),
            end: any(named: 'end'),
            type: any(named: 'type'),
          )).thenAnswer((_) => Stream.value(<CategorySlice>[
                const CategorySlice(
                  categoryId: 1, currencyCode: 'EUR', totalMinorUnits: 1000),
                const CategorySlice(
                  categoryId: 1, currencyCode: 'JPY', totalMinorUnits: 1000),
              ]));
      when(() => repo.watchTimeBucketsInRange(
            start: any(named: 'start'),
            end: any(named: 'end'),
            type: any(named: 'type'),
            granularity: any(named: 'granularity'),
          )).thenAnswer((_) => Stream.value(const <TimeBucketSlice>[]));

      final container = make(
        ratesScaledE9: const {}, // no rates
        defaultCurrency: 'USD',
      );
      addTearDown(container.dispose);

      final completer = Completer<ChartsState>();
      final sub = container.listen<AsyncValue<ChartsState>>(
        chartsControllerProvider,
        (_, next) {
          final v = next.valueOrNull;
          if (v is ChartsBlockedByMissingRates && !completer.isCompleted) {
            completer.complete(v);
          }
        },
        fireImmediately: true,
      );
      addTearDown(sub.close);

      final result = await completer.future.timeout(
        const Duration(seconds: 1),
      );
      expect(result, isA<ChartsBlockedByMissingRates>());
    });

    test(
        'category dimension partial-converts when only some rates missing',
        () async {
      // USD (default → identity) is rateable; EUR has no rate. Expect a
      // ChartsDataState with the USD slice only and excludedCurrencyCodes
      // listing EUR.
      when(() => repo.watchByCategoryInRange(
            start: any(named: 'start'),
            end: any(named: 'end'),
            type: any(named: 'type'),
          )).thenAnswer((_) => Stream.value(<CategorySlice>[
                const CategorySlice(
                  categoryId: 1, currencyCode: 'USD', totalMinorUnits: 1000),
                const CategorySlice(
                  categoryId: 1, currencyCode: 'EUR', totalMinorUnits: 1000),
              ]));
      when(() => repo.watchTimeBucketsInRange(
            start: any(named: 'start'),
            end: any(named: 'end'),
            type: any(named: 'type'),
            granularity: any(named: 'granularity'),
          )).thenAnswer((_) => Stream.value(<TimeBucketSlice>[
                TimeBucketSlice(
                  bucketStart: DateTime(2026, 5, 18),
                  currencyCode: 'USD',
                  totalMinorUnits: 1000,
                ),
                TimeBucketSlice(
                  bucketStart: DateTime(2026, 5, 18),
                  currencyCode: 'EUR',
                  totalMinorUnits: 1000,
                ),
              ]));

      final container = make(
        ratesScaledE9: const {}, // only USD identity works
        defaultCurrency: 'USD',
      );
      addTearDown(container.dispose);
      container.listen(chartsControllerProvider, (_, _) {});
      await Future<void>.delayed(const Duration(milliseconds: 30));

      final state = container.read(chartsControllerProvider).valueOrNull;
      expect(state, isA<ChartsDataState>());
      final data = (state! as ChartsDataState).chartData;
      // Only USD slice survives → fraction is 1.0, total is 1000.
      expect(data.slices, hasLength(1));
      expect(data.slices.first.totalMinorUnits, 1000);
      expect(data.grandTotalMinorUnits, 1000);
      expect(data.excludedCurrencyCodes, equals(<String>['EUR']));
      // Bucket total reflects the convertible bucket only.
      expect(data.bucketTotals, hasLength(1));
      expect(data.bucketTotals.first.totalMinorUnits, 1000);
    });

    test('currency dimension renders source-currency slices when rates missing',
        () async {
      when(() => repo.watchByCurrencyInRange(
            start: any(named: 'start'),
            end: any(named: 'end'),
            type: any(named: 'type'),
          )).thenAnswer((_) => Stream.value(<CurrencySlice>[
                const CurrencySlice(
                  currencyCode: 'USD', totalMinorUnits: 1000),
                const CurrencySlice(
                  currencyCode: 'EUR', totalMinorUnits: 1000),
              ]));
      when(() => repo.watchTimeBucketsInRange(
            start: any(named: 'start'),
            end: any(named: 'end'),
            type: any(named: 'type'),
            granularity: any(named: 'granularity'),
          )).thenAnswer((_) => Stream.value(const <TimeBucketSlice>[]));

      final container = make(
        ratesScaledE9: const {},
        defaultCurrency: 'USD',
      );
      addTearDown(container.dispose);
      // Switch to currency dimension.
      container.listen(chartsControllerProvider, (_, _) {});
      await Future<void>.delayed(const Duration(milliseconds: 10));
      container
          .read(chartsControllerProvider.notifier)
          .toggleDimension(ChartDimension.currency);
      await Future<void>.delayed(const Duration(milliseconds: 30));

      final state = container.read(chartsControllerProvider).valueOrNull;
      expect(state, isA<ChartsDataState>());
      final data = (state! as ChartsDataState).chartData;
      expect(data.slices, hasLength(2));
      expect(data.displayCurrencyCode, isNull);
      expect(data.mixedCurrencies, isTrue);
      // Bar chart hidden in this state → bucketTotals can be empty.
    });
  });
```

(Import `dart:async` and `ExchangeRateMetadata` at the top of the test file if not already.)

Also add a reactive regression test using a `StreamController<ChartsFxStatus>` override so a chart that starts blocked by missing rates transitions to `ChartsDataState` when FX metadata arrives without calling any controller command. This verifies the provider listeners added in Task 9.

- [ ] **Step 2: Run tests to verify failure**

Run: `flutter test test/unit/controllers/charts_controller_test.dart`
Expected: FAIL — `mixedCurrencies` will be `true` for the first test, `grandTotalMinorUnits` will be `null`, and the blocked-state test will time out.

- [ ] **Step 3: Replace `_emitIfReady` in `charts_controller.dart`**

Add the import:

```dart
import '../../../core/utils/currency_converter.dart';
```

Replace the entire `_emitIfReady` method (and add helpers) with:

```dart
  void _emitIfReady() {
    final slices = _lastSlices;
    final buckets = _lastBuckets;
    if (slices == null || buckets == null) return;
    if (slices.isEmpty && buckets.isEmpty) {
      _lastEmittedData = null;
      _emitter?.add(const ChartsState.empty());
      return;
    }

    final fx = ref.read(chartsFxStatusProvider).valueOrNull;
    final currencies =
        ref.read(chartsCurrenciesByCodeProvider).valueOrNull ?? const {};
    if (fx == null) {
      // FX status still resolving — keep prior data visible.
      _emitter?.add(ChartsState.loading(previous: _lastEmittedData));
      return;
    }

    final cats =
        ref.read(analysisCategoriesByIdProvider).valueOrNull ?? const {};
    final accts =
        ref.read(analysisAccountsByIdProvider).valueOrNull ?? const {};

    final activeCurrencies = _activeCurrencies(slices, buckets);
    final missingRate = activeCurrencies.any(
      (code) => fx.scaledRate(code) == null,
    );

    // Trigger a background refresh once when rates needed are missing.
    if (missingRate) {
      final repo = ref.read(exchangeRateRepositoryProvider);
      // Fire-and-forget; the single-flight guard in the repository
      // collapses duplicates.
      unawaited(repo.refreshAll(fx.defaultCurrencyCode));
    }

    if (_dimension == ChartDimension.currency) {
      _emitCurrencyDimension(
        slices: slices.cast<CurrencySlice>(),
        buckets: buckets,
        fx: fx,
        currencies: currencies,
      );
      return;
    }

    // Partial-conversion gate (2026-05-19): block only when EVERY active
    // currency lacks a rate. If at least one is convertible, render that
    // subset and let the ribbon in ChartsSection disclose the excluded
    // currencies. `allMissing` is what Task 12's auto-switch trigger
    // reads — see that task.
    final missingCurrencies = activeCurrencies
        .where((code) => fx.scaledRate(code) == null)
        .toSet();
    final allMissing = activeCurrencies.isNotEmpty &&
        missingCurrencies.length == activeCurrencies.length;

    if (allMissing) {
      _emitter?.add(
        ChartsState.blockedByMissingRates(previous: _lastEmittedData),
      );
      return;
    }

    _emitCategoryOrAccountDimension(
      slices: slices,
      buckets: buckets,
      fx: fx,
      currencies: currencies,
      cats: cats,
      accts: accts,
      missingCurrencies: missingCurrencies,
    );
  }

  Set<String> _activeCurrencies(
    List<Object> slices,
    List<TimeBucketSlice> buckets,
  ) {
    final set = <String>{};
    for (final s in slices) {
      set.add(switch (s) {
        CategorySlice() => s.currencyCode,
        AccountSlice() => s.currencyCode,
        CurrencySlice() => s.currencyCode,
        _ => '',
      });
    }
    for (final b in buckets) {
      set.add(b.currencyCode);
    }
    set.remove('');
    return set;
  }

  void _emitCategoryOrAccountDimension({
    required List<Object> slices,
    required List<TimeBucketSlice> buckets,
    required ChartsFxStatus fx,
    required Map<String, dynamic> currencies,
    required Map<int, Category> cats,
    required Map<int, Account> accts,
    required Set<String> missingCurrencies,
  }) {
    // Step 1 — convert + regroup pie slices. Slices whose currency lacks
    // a rate are skipped here; they are surfaced via
    // ChartsData.excludedCurrencyCodes and shown in the ribbon.
    final regrouped = <int, int>{}; // id → converted minor units
    for (final s in slices) {
      final (id, code, amount) = switch (s) {
        CategorySlice() => (s.categoryId, s.currencyCode, s.totalMinorUnits),
        AccountSlice() => (s.accountId, s.currencyCode, s.totalMinorUnits),
        _ => (-1, '', 0),
      };
      if (id < 0) continue;
      if (missingCurrencies.contains(code)) continue;
      final fromDecimals =
          (currencies[code] as dynamic)?.decimals as int? ?? 2;
      final toDecimals =
          (currencies[fx.defaultCurrencyCode] as dynamic)?.decimals as int? ??
              2;
      final scaled = fx.scaledRate(code)!;
      final converted = CurrencyConverter.convertMinorUnits(
        amountMinorUnits: amount,
        rateScaledE9: scaled,
        fromDecimals: fromDecimals,
        toDecimals: toDecimals,
      );
      regrouped[id] = (regrouped[id] ?? 0) + converted;
    }

    final grandTotal = regrouped.values.fold<int>(0, (a, b) => a + b);

    final chartSlices = <ChartSlice>[];
    regrouped.forEach((id, total) {
      String label;
      int colorIndex;
      String iconKey;
      if (_dimension == ChartDimension.category) {
        final c = cats[id];
        label = _categoryLabel(id, cats);
        colorIndex = c?.color ?? CategoryPaletteIndex.neutralVariant50;
        iconKey = c?.icon ?? '';
      } else {
        label = _accountLabel(id, accts);
        colorIndex = accts[id]?.color ??
            CategoryPaletteIndex.neutralVariant50;
        iconKey = accts[id]?.icon ?? '';
      }
      chartSlices.add(ChartSlice(
        label: label,
        currencyCode: fx.defaultCurrencyCode,
        totalMinorUnits: total,
        colorIndex: colorIndex,
        iconKey: iconKey,
        fraction: grandTotal == 0 ? 0 : total / grandTotal,
      ));
    });
    chartSlices.sort((a, b) => b.totalMinorUnits.compareTo(a.totalMinorUnits));

    // Step 2 — convert + regroup buckets. Same exclusion rule: buckets
    // whose currency lacks a rate are skipped so the bar chart mirrors
    // the pie chart's data.
    final convertedBuckets = <DateTime, int>{};
    for (final b in buckets) {
      if (missingCurrencies.contains(b.currencyCode)) continue;
      final fromDecimals =
          (currencies[b.currencyCode] as dynamic)?.decimals as int? ?? 2;
      final toDecimals =
          (currencies[fx.defaultCurrencyCode] as dynamic)?.decimals as int? ??
              2;
      final scaled = fx.scaledRate(b.currencyCode)!;
      final converted = CurrencyConverter.convertMinorUnits(
        amountMinorUnits: b.totalMinorUnits,
        rateScaledE9: scaled,
        fromDecimals: fromDecimals,
        toDecimals: toDecimals,
      );
      convertedBuckets[b.bucketStart] =
          (convertedBuckets[b.bucketStart] ?? 0) + converted;
    }
    final bucketTotals = [
      for (final e in convertedBuckets.entries)
        ChartBucketTotal(
          bucketStart: e.key,
          totalMinorUnits: e.value,
        ),
    ]..sort((a, b) => a.bucketStart.compareTo(b.bucketStart));

    final data = ChartsData(
      period: _period,
      anchorDate: _normalizeAnchor(_anchor, _period),
      type: _type,
      dimension: _dimension,
      slices: chartSlices,
      bucketTotals: bucketTotals,
      grandTotalMinorUnits: grandTotal,
      displayCurrencyCode: fx.defaultCurrencyCode,
      mixedCurrencies: false,
      // Threaded only by the currency-dimension path; always false for
      // category/account because Task 12's auto-switch only points at
      // currency view.
      autoSwitchedFromCategoryDimension: false,
      // Sorted list of excluded currency codes (deterministic ribbon).
      excludedCurrencyCodes: missingCurrencies.toList()..sort(),
    );
    _lastEmittedData = data;
    _emitter?.add(ChartsState.data(chartData: data));
  }

  void _emitCurrencyDimension({
    required List<CurrencySlice> slices,
    required List<TimeBucketSlice> buckets,
    required ChartsFxStatus fx,
    required Map<String, dynamic> currencies,
  }) {
    final missingRate =
        slices.any((s) => fx.scaledRate(s.currencyCode) == null);

    final chartSlices = <ChartSlice>[];
    int? grandTotal;
    if (!missingRate) {
      grandTotal = 0;
      for (final s in slices) {
        final fromDecimals =
            (currencies[s.currencyCode] as dynamic)?.decimals as int? ?? 2;
        final toDecimals =
            (currencies[fx.defaultCurrencyCode] as dynamic)?.decimals as int? ??
                2;
        final converted = CurrencyConverter.convertMinorUnits(
          amountMinorUnits: s.totalMinorUnits,
          rateScaledE9: fx.scaledRate(s.currencyCode)!,
          fromDecimals: fromDecimals,
          toDecimals: toDecimals,
        );
        grandTotal = grandTotal! + converted;
      }
      for (final s in slices) {
        final fromDecimals =
            (currencies[s.currencyCode] as dynamic)?.decimals as int? ?? 2;
        final toDecimals =
            (currencies[fx.defaultCurrencyCode] as dynamic)?.decimals as int? ??
                2;
        final converted = CurrencyConverter.convertMinorUnits(
          amountMinorUnits: s.totalMinorUnits,
          rateScaledE9: fx.scaledRate(s.currencyCode)!,
          fromDecimals: fromDecimals,
          toDecimals: toDecimals,
        );
        chartSlices.add(ChartSlice(
          label: s.currencyCode,
          currencyCode: fx.defaultCurrencyCode,
          totalMinorUnits: converted,
          colorIndex: _currencyColorIndex(s.currencyCode),
          iconKey: '',
          fraction:
              grandTotal == 0 ? 0 : converted / grandTotal!,
        ));
      }
    } else {
      for (final s in slices) {
        chartSlices.add(ChartSlice(
          label: s.currencyCode,
          currencyCode: s.currencyCode,
          totalMinorUnits: s.totalMinorUnits,
          colorIndex: _currencyColorIndex(s.currencyCode),
          iconKey: '',
          fraction: null,
        ));
      }
    }

    // Bar chart: keep hidden until every bucket currency is convertible.
    final bucketsMissing =
        buckets.any((b) => fx.scaledRate(b.currencyCode) == null);
    final bucketTotals = <ChartBucketTotal>[];
    if (!bucketsMissing) {
      final regrouped = <DateTime, int>{};
      for (final b in buckets) {
        final fromDecimals =
            (currencies[b.currencyCode] as dynamic)?.decimals as int? ?? 2;
        final toDecimals =
            (currencies[fx.defaultCurrencyCode] as dynamic)?.decimals as int? ??
                2;
        final converted = CurrencyConverter.convertMinorUnits(
          amountMinorUnits: b.totalMinorUnits,
          rateScaledE9: fx.scaledRate(b.currencyCode)!,
          fromDecimals: fromDecimals,
          toDecimals: toDecimals,
        );
        regrouped[b.bucketStart] =
            (regrouped[b.bucketStart] ?? 0) + converted;
      }
      for (final e in regrouped.entries) {
        bucketTotals.add(
          ChartBucketTotal(
            bucketStart: e.key,
            totalMinorUnits: e.value,
          ),
        );
      }
      bucketTotals.sort((a, b) => a.bucketStart.compareTo(b.bucketStart));
    }

    chartSlices.sort((a, b) => b.totalMinorUnits.compareTo(a.totalMinorUnits));

    final data = ChartsData(
      period: _period,
      anchorDate: _normalizeAnchor(_anchor, _period),
      type: _type,
      dimension: _dimension,
      slices: chartSlices,
      bucketTotals: bucketTotals,
      grandTotalMinorUnits: missingRate ? null : grandTotal,
      displayCurrencyCode: missingRate ? null : fx.defaultCurrencyCode,
      mixedCurrencies: missingRate,
      // Surfaces Task 12's one-shot fallback to the banner in
      // ChartsSection. Stays sticky until the user toggles dimension or
      // dismisses the banner explicitly.
      autoSwitchedFromCategoryDimension: _autoSwitchedToCurrency,
    );
    _lastEmittedData = data;
    _emitter?.add(ChartsState.data(chartData: data));
  }
```

Also re-declare the controller's `dependencies:` annotation to include `exchangeRateRepository`:

```dart
@Riverpod(
  keepAlive: true,
  dependencies: [
    transactionRepository,
    analysisCategoriesById,
    analysisAccountsById,
    chartsFxStatus,
    chartsCurrenciesByCode,
    exchangeRateRepository,
  ],
)
```

- [ ] **Step 4: Regenerate Riverpod files**

Run: `dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 5: Run tests to verify they pass**

Run: `dart format . && flutter test test/unit/controllers/charts_controller_test.dart`
Expected: PASS (all tests including conversion and blocked-state).

- [ ] **Step 6: Commit**

```bash
git add lib/features/analysis/charts/charts_controller.dart \
  lib/features/analysis/charts/charts_controller.g.dart \
  test/unit/controllers/charts_controller_test.dart
git commit -m "feat(charts): multi-currency conversion + blocked state in ChartsController"
```

---

### Task 12: Auto-switch to Currency dimension on first empty-query render when Week+Category would block

**Files:**
- Modify: `lib/features/analysis/charts/charts_controller.dart`

Spec § Multi-Currency Conversion: "If the active dimension is `category`, automatically select Currency view for the first empty-query render when Week + Category would otherwise open into a blocked state." This is a one-shot fallback that only fires on cold-start.

**Resolved during 2026-05-19 review:** the auto-switch is retained but is no longer silent — the controller now surfaces an `autoSwitchedFromCategoryDimension` flag in `ChartsData`. `ChartsSection` renders a banner explaining why category view is not shown (Task 19). The flag is sticky until the user either toggles dimension manually (cleared automatically) or dismisses the banner via `dismissAutoSwitchBanner()`.

- [ ] **Step 1: Add the fallback flag and trigger**

Inside `class ChartsController`, near the other private fields, add:

```dart
  bool _autoSwitchedToCurrency = false;
```

In `_emitIfReady`, immediately before the `if (allMissing)` block that emits `ChartsBlockedByMissingRates` (Task 11's partial-conversion gate), insert:

```dart
    final shouldAutoSwitch = !_autoSwitchedToCurrency &&
        _dimension == ChartDimension.category &&
        _period == PeriodType.week &&
        allMissing &&
        _lastEmittedData == null;
    if (shouldAutoSwitch) {
      _autoSwitchedToCurrency = true;
      _dimension = ChartDimension.currency;
      _resubscribe();
      return;
    }
```

**Note (partial-conversion interaction):** with Task 11's partial-conversion gate, the auto-switch trigger is `allMissing`, not `missingRate`. The category view now renders a partial chart whenever *any* currency is convertible, so the auto-switch only fires when *every* currency lacks a rate. Users with partial-missing rates see the category chart with an excluded-currencies ribbon (Task 19) instead of being silently moved to currency view.

- [ ] **Step 1b: Clear the flag when the user changes dimension manually**

Modify `toggleDimension` so manually switching dimensions clears the banner — the user has acknowledged the auto-switch by making their own choice:

```dart
  void toggleDimension(ChartDimension d) {
    if (_dimension == d) return;
    _dimension = d;
    _autoSwitchedToCurrency = false; // user took over; banner no longer relevant
    _resubscribe();
  }
```

- [ ] **Step 1c: Add an explicit `dismissAutoSwitchBanner()` command**

Add a public command so the banner's close affordance has a way to clear the flag without changing dimension:

```dart
  void dismissAutoSwitchBanner() {
    if (!_autoSwitchedToCurrency) return;
    _autoSwitchedToCurrency = false;
    // Re-emit the last data so ChartsSection re-reads
    // `autoSwitchedFromCategoryDimension: false`.
    final last = _lastEmittedData;
    if (last != null) {
      final cleared = last.copyWith(
        autoSwitchedFromCategoryDimension: false,
      );
      _lastEmittedData = cleared;
      _emitter?.add(ChartsState.data(chartData: cleared));
    }
  }
```

- [ ] **Step 2: Add the failing test**

Append to `test/unit/controllers/charts_controller_test.dart` inside the existing `'ChartsController — multi-currency conversion'` group:

```dart
    test('auto-switches to currency dimension on cold-start missing rates',
        () async {
      when(() => repo.watchByCategoryInRange(
            start: any(named: 'start'),
            end: any(named: 'end'),
            type: any(named: 'type'),
          )).thenAnswer((_) => Stream.value(<CategorySlice>[
                const CategorySlice(
                  categoryId: 1, currencyCode: 'EUR', totalMinorUnits: 1000),
              ]));
      when(() => repo.watchByCurrencyInRange(
            start: any(named: 'start'),
            end: any(named: 'end'),
            type: any(named: 'type'),
          )).thenAnswer((_) => Stream.value(<CurrencySlice>[
                const CurrencySlice(
                  currencyCode: 'EUR', totalMinorUnits: 1000),
              ]));
      when(() => repo.watchTimeBucketsInRange(
            start: any(named: 'start'),
            end: any(named: 'end'),
            type: any(named: 'type'),
            granularity: any(named: 'granularity'),
          )).thenAnswer((_) => Stream.value(const <TimeBucketSlice>[]));

      final container = make(
        ratesScaledE9: const {},
        defaultCurrency: 'USD',
      );
      addTearDown(container.dispose);

      ChartsState? latest;
      final sub = container.listen<AsyncValue<ChartsState>>(
        chartsControllerProvider,
        (_, next) {
          latest = next.valueOrNull;
        },
        fireImmediately: true,
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      sub.close();

      // After auto-switch, state should be ChartsDataState in currency dim
      // with the banner flag set so ChartsSection can explain the switch.
      expect(latest, isA<ChartsDataState>());
      final data = (latest! as ChartsDataState).chartData;
      expect(data.dimension, ChartDimension.currency);
      expect(data.autoSwitchedFromCategoryDimension, isTrue);
    });

    test('dismissAutoSwitchBanner re-emits with the flag cleared', () async {
      when(() => repo.watchByCategoryInRange(
            start: any(named: 'start'),
            end: any(named: 'end'),
            type: any(named: 'type'),
          )).thenAnswer((_) => Stream.value(<CategorySlice>[
                const CategorySlice(
                  categoryId: 1, currencyCode: 'EUR', totalMinorUnits: 1000),
              ]));
      when(() => repo.watchByCurrencyInRange(
            start: any(named: 'start'),
            end: any(named: 'end'),
            type: any(named: 'type'),
          )).thenAnswer((_) => Stream.value(<CurrencySlice>[
                const CurrencySlice(
                  currencyCode: 'EUR', totalMinorUnits: 1000),
              ]));
      when(() => repo.watchTimeBucketsInRange(
            start: any(named: 'start'),
            end: any(named: 'end'),
            type: any(named: 'type'),
            granularity: any(named: 'granularity'),
          )).thenAnswer((_) => Stream.value(const <TimeBucketSlice>[]));

      final container = make(
        ratesScaledE9: const {},
        defaultCurrency: 'USD',
      );
      addTearDown(container.dispose);
      container.listen(chartsControllerProvider, (_, _) {});
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Sanity: auto-switch happened.
      var data = (container.read(chartsControllerProvider).valueOrNull!
              as ChartsDataState)
          .chartData;
      expect(data.autoSwitchedFromCategoryDimension, isTrue);

      // User dismisses the banner; controller re-emits with flag cleared.
      container
          .read(chartsControllerProvider.notifier)
          .dismissAutoSwitchBanner();
      await Future<void>.delayed(const Duration(milliseconds: 30));
      data = (container.read(chartsControllerProvider).valueOrNull!
              as ChartsDataState)
          .chartData;
      expect(data.autoSwitchedFromCategoryDimension, isFalse);
      // Dimension stays as currency — dismiss doesn't move the user back.
      expect(data.dimension, ChartDimension.currency);
    });
```

- [ ] **Step 3: Run tests**

Run: `dart format . && flutter test test/unit/controllers/charts_controller_test.dart`
Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add lib/features/analysis/charts/charts_controller.dart \
  test/unit/controllers/charts_controller_test.dart
git commit -m "feat(charts): auto-switch to currency dimension on cold-start missing rates"
```

---

### Task 13: Defer warm-start optimization

**Files:**
- _None._ This task is intentionally a no-op stub.

The spec's "warm-start" reuse rule (default currency unchanged + locale unchanged + active period = week + active type = expense + active dimension = category + no transaction/category/account mutations since warm-up + FX freshness < 1h) is an optimization. With Drift's `.watch()` streams driving the controller, the cold-start path is already fast (one DB read per subscription). Implementing the full invalidation matrix is a meaningful amount of bookkeeping and is best deferred until the cold-path is observed to be slow.

- [ ] **Step 1: Add a TODO in the controller**

In `lib/features/analysis/charts/charts_controller.dart`, just above the `build()` method, add:

```dart
  // TODO(charts/warm-start): per the spec, week+expense+category may seed
  // from a warmed snapshot when FX freshness < 1h, default currency
  // unchanged, locale unchanged, and no transaction/category/account
  // mutations occurred since warm-up. Deferred — the cold path is already
  // sub-frame in practice. Revisit if cold-start jank surfaces.
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/analysis/charts/charts_controller.dart
git commit -m "docs(charts): mark warm-start optimization as deferred"
```

---

> **Execution order note:** Complete Task 20 immediately after Task 13, then return to Task 14. Tasks 14-19 assume the chart ARB keys and generated `AppLocalizations` getters already exist.

### Task 14: Period selector widget

**Files:**
- Create: `lib/features/analysis/charts/widgets/period_selector.dart`
- Create: `test/widget/features/analysis/widgets/period_selector_test.dart`

Pure-presentation widget: takes `PeriodType` and anchor `DateTime`, renders prev arrow + period label + next arrow (next disabled at current period) + a 4-way segmented toggle. Calls back to the parent on every interaction.

**Layout (resolved 2026-05-19 review):** the period selector is rendered full-width at **every screen width**. There is no `LayoutBuilder` switch at 600dp for the toggle row — the 4-way `SegmentedButton` always stretches edge-to-edge. The 600dp shell-level adaptivity referenced in `CLAUDE.md` applies to the bottom-nav-vs-NavigationRail switch at the app shell, not to chart controls. Localized labels (zh_TW / zh_CN: 日/週/月/年) are short enough that the segmented control does not overflow at the supported 1.5× text scale on a 320dp viewport.

- [ ] **Step 1: Write the failing widget test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/features/analysis/charts/charts_state.dart';
import 'package:ledgerly/features/analysis/charts/widgets/period_selector.dart';
import 'package:ledgerly/l10n/app_localizations.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) =>
      tester.pumpWidget(MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ));

  testWidgets('renders the week label and calls callbacks', (tester) async {
    var prev = 0, next = 0;
    PeriodType? picked;
    await pump(
      tester,
      PeriodSelector(
        period: PeriodType.week,
        anchorDate: DateTime(2026, 5, 18),
        isAtCurrent: false,
        locale: 'en',
        onPrevious: () => prev++,
        onNext: () => next++,
        onPeriodChanged: (p) => picked = p,
      ),
    );

    expect(find.textContaining('May'), findsWidgets);

    await tester.tap(find.byTooltip('Previous period'));
    await tester.pump();
    expect(prev, 1);

    await tester.tap(find.byTooltip('Next period'));
    await tester.pump();
    expect(next, 1);

    await tester.tap(find.text('Day'));
    await tester.pump();
    expect(picked, PeriodType.day);
  });

  testWidgets('next button disabled at current period', (tester) async {
    var next = 0;
    await pump(
      tester,
      PeriodSelector(
        period: PeriodType.week,
        anchorDate: DateTime(2026, 5, 18),
        isAtCurrent: true,
        locale: 'en',
        onPrevious: () {},
        onNext: () => next++,
        onPeriodChanged: (_) {},
      ),
    );
    await tester.tap(find.byTooltip('Next period'));
    await tester.pump();
    expect(next, 0);
  });
}
```

- [ ] **Step 2: Run tests to verify failure**

Run: `flutter test test/widget/features/analysis/widgets/period_selector_test.dart`
Expected: FAIL — `PeriodSelector` undefined.

- [ ] **Step 3: Implement the widget**

```dart
// Period selector for the charts section. Renders prev/next arrows
// around the period label, plus a 4-way segmented toggle for
// Day/Week/Month/Year. See basic-charts spec § Period Selector.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/date_helpers.dart';
import '../../../../l10n/app_localizations.dart';
import '../charts_state.dart';

class PeriodSelector extends StatelessWidget {
  const PeriodSelector({
    super.key,
    required this.period,
    required this.anchorDate,
    required this.isAtCurrent,
    required this.locale,
    required this.onPrevious,
    required this.onNext,
    required this.onPeriodChanged,
  });

  final PeriodType period;
  final DateTime anchorDate;
  final bool isAtCurrent;
  final String locale;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<PeriodType> onPeriodChanged;

  String _formatLabel(BuildContext context) {
    switch (period) {
      case PeriodType.day:
        return DateHelpers.formatDisplayDate(anchorDate, locale);
      case PeriodType.week:
        final end = DateTime(
          anchorDate.year,
          anchorDate.month,
          anchorDate.day + 6,
        );
        final start = DateFormat.MMMd(locale).format(anchorDate);
        final endStr = DateFormat.MMMd(locale).format(end);
        return '$start–$endStr, ${anchorDate.year}';
      case PeriodType.month:
        return DateFormat.yMMMM(locale).format(anchorDate);
      case PeriodType.year:
        return DateFormat.y(locale).format(anchorDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Previous period',
              icon: const Icon(Icons.chevron_left),
              onPressed: onPrevious,
            ),
            Expanded(
              child: Center(
                child: Text(
                  _formatLabel(context),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Next period',
              icon: const Icon(Icons.chevron_right),
              onPressed: isAtCurrent ? null : onNext,
            ),
          ],
        ),
        const SizedBox(height: 8),
        SegmentedButton<PeriodType>(
          segments: [
            ButtonSegment(
              value: PeriodType.day,
              label: Text(l10n.chartsPeriodDay),
            ),
            ButtonSegment(
              value: PeriodType.week,
              label: Text(l10n.chartsPeriodWeek),
            ),
            ButtonSegment(
              value: PeriodType.month,
              label: Text(l10n.chartsPeriodMonth),
            ),
            ButtonSegment(
              value: PeriodType.year,
              label: Text(l10n.chartsPeriodYear),
            ),
          ],
          selected: {period},
          onSelectionChanged: (s) => onPeriodChanged(s.first),
        ),
      ],
    );
  }
}
```

**Note:** Task 20 is a hard prerequisite for this widget. Complete Task 20 immediately after Task 13, then return here with the generated `chartsPeriod*` getters already available. Do not use placeholder strings or comment out assertions; the intended execution order is Task 20 -> Task 14 -> Task 15.

- [ ] **Step 4: Verify the widget compiles**

Run: `dart format . && flutter analyze`
Expected: clean — Task 20's ARB keys and generated getters are already present.

- [ ] **Step 5: Run the test**

Run: `flutter test test/widget/features/analysis/widgets/period_selector_test.dart`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/features/analysis/charts/widgets/period_selector.dart \
  test/widget/features/analysis/widgets/period_selector_test.dart
git commit -m "feat(charts): add PeriodSelector widget"
```

---

### Task 15: Dimension toggle + Type toggle widgets

**Files:**
- Create: `lib/features/analysis/charts/widgets/dimension_toggle.dart`
- Create: `lib/features/analysis/charts/widgets/type_toggle.dart`

Both are MD3 SegmentedButtons that emit callbacks. Stateless; no tests needed beyond the umbrella `ChartsSection` widget test (Task 19).

**Layout (resolved 2026-05-19 review):** both toggles also render full-width and stacked at every screen width — same rule as the period selector in Task 14. The three control rows (Period, Type, Dimension) form a vertical stack in `ChartsSection` (Task 19) and do not collapse to a row at ≥600dp. Implementers must not add a `LayoutBuilder` here; this layout is intentional and shared across phone and tablet.

- [ ] **Step 1: Create `dimension_toggle.dart`**

```dart
import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../charts_state.dart';

class DimensionToggle extends StatelessWidget {
  const DimensionToggle({
    super.key,
    required this.dimension,
    required this.onChanged,
  });

  final ChartDimension dimension;
  final ValueChanged<ChartDimension> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SegmentedButton<ChartDimension>(
      segments: [
        ButtonSegment(
          value: ChartDimension.category,
          label: Text(l10n.chartsDimensionCategory),
        ),
        ButtonSegment(
          value: ChartDimension.account,
          label: Text(l10n.chartsDimensionAccount),
        ),
        ButtonSegment(
          value: ChartDimension.currency,
          label: Text(l10n.chartsDimensionCurrency),
        ),
      ],
      selected: {dimension},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}
```

- [ ] **Step 2: Create `type_toggle.dart`**

```dart
import 'package:flutter/material.dart';

import '../../../../data/models/category.dart';
import '../../../../l10n/app_localizations.dart';

class TypeToggle extends StatelessWidget {
  const TypeToggle({
    super.key,
    required this.type,
    required this.onChanged,
  });

  final CategoryType type;
  final ValueChanged<CategoryType> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SegmentedButton<CategoryType>(
      segments: [
        ButtonSegment(
          value: CategoryType.expense,
          label: Text(l10n.chartsTypeExpense),
        ),
        ButtonSegment(
          value: CategoryType.income,
          label: Text(l10n.chartsTypeIncome),
        ),
      ],
      selected: {type},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}
```

- [ ] **Step 3: Verify analyzer (after Task 20 l10n keys land)**

Run: `dart format . && flutter analyze`
Expected: clean.

- [ ] **Step 4: Commit**

```bash
git add lib/features/analysis/charts/widgets/dimension_toggle.dart \
  lib/features/analysis/charts/widgets/type_toggle.dart
git commit -m "feat(charts): add DimensionToggle + TypeToggle widgets"
```

---

### Task 16: Pie chart widget (`category_pie_chart.dart`)

**Files:**
- Create: `lib/features/analysis/charts/widgets/category_pie_chart.dart`

Stateless `fl_chart` `PieChart` wrapper. Accepts a list of `ChartSlice` and renders donut sections. Hides percentage labels when `fraction == null`. View-only `PieTouchData`.

**Accessibility (resolved 2026-05-19 review):** the chart canvas is wrapped in a `Semantics` node with a generated `label` that enumerates each slice (display label + percentage when known, otherwise raw amount) and the grand total. Without this, the `fl_chart` canvas is opaque to TalkBack / VoiceOver. The widget takes the parent's `displayCurrencyCode` / `grandTotalMinorUnits` / `currenciesByCode` and a locale so it can format amounts via `MoneyFormatter`. The legend below (Task 18) remains independently readable — it does not need to be excluded from semantics.

- [ ] **Step 1: Create the widget**

```dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/color_palette.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../data/models/currency.dart';
import '../../../../l10n/app_localizations.dart';
import '../charts_state.dart';

class CategoryPieChart extends StatelessWidget {
  const CategoryPieChart({
    super.key,
    required this.slices,
    required this.currenciesByCode,
    required this.locale,
    this.grandTotalMinorUnits,
    this.displayCurrencyCode,
  });

  final List<ChartSlice> slices;
  final Map<String, Currency> currenciesByCode;
  final String locale;
  final int? grandTotalMinorUnits;
  final String? displayCurrencyCode;

  @override
  Widget build(BuildContext context) {
    if (slices.isEmpty) {
      return const SizedBox(height: 200);
    }
    final showLabels = slices.first.fraction != null;
    final l10n = AppLocalizations.of(context);

    return Semantics(
      label: _semanticsLabel(l10n),
      // The canvas itself is not interactive; mark as image so screen
      // readers announce the generated summary instead of trying to
      // traverse fl_chart's internal nodes.
      image: true,
      excludeSemantics: true,
      child: AspectRatio(
        aspectRatio: 1.4,
        child: PieChart(
          PieChartData(
            sectionsSpace: 2,
            centerSpaceRadius: 40,
            // TODO(charts/drill-down): re-enable PieTouchData and route
            // slice taps to a filtered transaction list. View-only for
            // v1 — see plan § Still deferred.
            pieTouchData: PieTouchData(enabled: false),
            sections: [
              for (final s in slices)
                PieChartSectionData(
                  value: s.totalMinorUnits.abs().toDouble(),
                  color: colorForIndex(s.colorIndex),
                  title: showLabels
                      ? '${(s.fraction! * 100).round()}%'
                      : '',
                  radius: 60,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _semanticsLabel(AppLocalizations l10n) {
    final parts = <String>[l10n.chartsPieChart];
    for (final s in slices) {
      final currency = currenciesByCode[s.currencyCode] ??
          Currency(code: s.currencyCode, decimals: 2);
      final amount = MoneyFormatter.format(
        amountMinorUnits: s.totalMinorUnits,
        currency: currency,
        locale: locale,
      );
      if (s.fraction != null) {
        parts.add(
          '${s.label} ${(s.fraction! * 100).round()}%, $amount',
        );
      } else {
        parts.add('${s.label}: $amount');
      }
    }
    if (grandTotalMinorUnits != null && displayCurrencyCode != null) {
      final currency = currenciesByCode[displayCurrencyCode!] ??
          Currency(code: displayCurrencyCode!, decimals: 2);
      final total = MoneyFormatter.format(
        amountMinorUnits: grandTotalMinorUnits!,
        currency: currency,
        locale: locale,
      );
      parts.add('${l10n.chartsTotal} $total');
    }
    return parts.join('. ');
  }
}
```

- [ ] **Step 2: Verify analyzer**

Run: `dart format . && flutter analyze`
Expected: clean.

- [ ] **Step 3: Commit**

```bash
git add lib/features/analysis/charts/widgets/category_pie_chart.dart
git commit -m "feat(charts): add CategoryPieChart fl_chart wrapper"
```

---

### Task 17: Bar chart widget (`daily_bar_chart.dart`)

**Files:**
- Create: `lib/features/analysis/charts/widgets/daily_bar_chart.dart`

Single widget that renders bar charts for all granularities. Caller passes the pre-bucketed `ChartBucketTotal` list plus the `PeriodType` and the period range so the widget can zero-fill missing buckets and dim future ones.

**Accessibility (resolved 2026-05-19 review):** like Task 16, the bar chart canvas is wrapped in a `Semantics` node with a generated `label` that enumerates each populated bucket as `<bucket-label>: <amount>`. Empty (zero-filled) buckets are skipped so the announcement stays manageable on month/year views. The widget takes a `displayCurrencyCode` + `currenciesByCode` so amounts format correctly; future-dated buckets are still skipped because they are always zero.

- [ ] **Step 1: Create the widget**

```dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/money_formatter.dart';
import '../../../../data/models/currency.dart';
import '../../../../l10n/app_localizations.dart';
import '../charts_state.dart';

class DailyBarChart extends StatelessWidget {
  const DailyBarChart({
    super.key,
    required this.period,
    required this.anchorDate,
    required this.bucketTotals,
    required this.locale,
    required this.currenciesByCode,
    this.displayCurrencyCode,
  });

  final PeriodType period;
  final DateTime anchorDate;
  final List<ChartBucketTotal> bucketTotals;
  final String locale;
  final Map<String, Currency> currenciesByCode;
  final String? displayCurrencyCode;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final now = DateTime.now();
    final filledBuckets = _zeroFill(anchorDate, period, bucketTotals);
    final maxY = filledBuckets
        .map((b) => b.totalMinorUnits.abs())
        .fold<int>(0, (a, b) => a > b ? a : b);
    final headroom = (maxY * 1.1).round();
    final l10n = AppLocalizations.of(context);

    return Semantics(
      label: _semanticsLabel(l10n, filledBuckets),
      image: true,
      excludeSemantics: true,
      child: AspectRatio(
      aspectRatio: 1.6,
      child: BarChart(
        BarChartData(
          maxY: headroom == 0 ? 1 : headroom.toDouble(),
          // TODO(charts/drill-down): re-enable BarTouchData and route
          // bucket taps to a transaction list scoped to that bucket.
          // View-only for v1 — see plan § Still deferred.
          barTouchData: BarTouchData(enabled: false),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= filledBuckets.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _axisLabel(filledBuckets[idx].bucketStart),
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < filledBuckets.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: filledBuckets[i].totalMinorUnits.abs().toDouble(),
                    color: filledBuckets[i].bucketStart.isAfter(now)
                        ? color.withValues(alpha: 0.3)
                        : color,
                    width: 8,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ],
              ),
          ],
        ),
      ),
      ),
    );
  }

  String _semanticsLabel(
    AppLocalizations l10n,
    List<ChartBucketTotal> filledBuckets,
  ) {
    final parts = <String>[l10n.chartsBarChart];
    final currency = displayCurrencyCode == null
        ? null
        : (currenciesByCode[displayCurrencyCode!] ??
            Currency(code: displayCurrencyCode!, decimals: 2));
    for (final b in filledBuckets) {
      if (b.totalMinorUnits == 0) continue; // skip zero-filled empties
      final amount = currency == null
          ? b.totalMinorUnits.toString()
          : MoneyFormatter.format(
              amountMinorUnits: b.totalMinorUnits,
              currency: currency,
              locale: locale,
            );
      parts.add('${_axisLabel(b.bucketStart)}: $amount');
    }
    return parts.join('. ');
  }

  List<ChartBucketTotal> _zeroFill(
    DateTime anchor,
    PeriodType period,
    List<ChartBucketTotal> raw,
  ) {
    final map = {for (final b in raw) b.bucketStart: b.totalMinorUnits};
    final out = <ChartBucketTotal>[];
    switch (period) {
      case PeriodType.day:
        for (var h = 0; h < 24; h++) {
          final ts = DateTime(anchor.year, anchor.month, anchor.day, h);
          out.add(ChartBucketTotal(
            bucketStart: ts,
            totalMinorUnits: map[ts] ?? 0,
          ));
        }
      case PeriodType.week:
        for (var d = 0; d < 7; d++) {
          final ts = DateTime(anchor.year, anchor.month, anchor.day + d);
          out.add(ChartBucketTotal(
            bucketStart: ts,
            totalMinorUnits: map[ts] ?? 0,
          ));
        }
      case PeriodType.month:
        var cursor = DateTime(anchor.year, anchor.month, 1);
        while (cursor.month == anchor.month) {
          out.add(ChartBucketTotal(
            bucketStart: cursor,
            totalMinorUnits: map[cursor] ?? 0,
          ));
          cursor = DateTime(cursor.year, cursor.month, cursor.day + 1);
        }
      case PeriodType.year:
        for (var m = 1; m <= 12; m++) {
          final ts = DateTime(anchor.year, m, 1);
          out.add(ChartBucketTotal(
            bucketStart: ts,
            totalMinorUnits: map[ts] ?? 0,
          ));
        }
    }
    return out;
  }

  String _axisLabel(DateTime bucketStart) {
    switch (period) {
      case PeriodType.day:
        return bucketStart.hour.toString().padLeft(2, '0');
      case PeriodType.week:
        return DateFormat.E(locale).format(bucketStart);
      case PeriodType.month:
        return bucketStart.day.toString();
      case PeriodType.year:
        return DateFormat.MMM(locale).format(bucketStart);
    }
  }
}
```

- [ ] **Step 2: Verify analyzer**

Run: `dart format . && flutter analyze`
Expected: clean.

- [ ] **Step 3: Commit**

```bash
git add lib/features/analysis/charts/widgets/daily_bar_chart.dart
git commit -m "feat(charts): add DailyBarChart with zero-fill + future-bucket dimming"
```

---

### Task 18: Legend widget + "View all" bottom sheet

**Files:**
- Create: `lib/features/analysis/charts/widgets/chart_legend.dart`

Legend caps at 8 visible entries (top-7 + "Other"). Tapping the "Other" trailing affordance opens a modal sheet listing every slice.

**"Other" bucket in mixed-currency mode (resolved 2026-05-19 review):** when `mixedCurrencies` is true the legend slices are still denominated in their **source** currencies, so summing leftover slices into one numeric `Other` value would either misstate the total (if labelled as one currency) or be unreadable (if amounts are added across currencies). The legend therefore takes a `mixedCurrencies` flag from the caller (`ChartsSection` passes `ChartsData.mixedCurrencies` through). When the flag is true, the `Other` row renders as a localized item-count (`chartsOtherCount` plural key, e.g. "Other (3 items)") instead of an amount. The "View all" sheet is unchanged — each row in that sheet keeps its own currency code, so it stays correct.

- [ ] **Step 1: Create the legend file**

```dart
import 'package:flutter/material.dart';

import '../../../../core/utils/color_palette.dart';
import '../../../../core/utils/icon_registry.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../data/models/currency.dart';
import '../../../../l10n/app_localizations.dart';
import '../charts_state.dart';

class ChartLegend extends StatelessWidget {
  const ChartLegend({
    super.key,
    required this.slices,
    required this.currenciesByCode,
    required this.locale,
    this.mixedCurrencies = false,
  });

  final List<ChartSlice> slices;
  final Map<String, Currency> currenciesByCode;
  final String locale;

  /// When true, the legend's `Other` bucket renders an item count instead
  /// of a summed amount, because the leftover slices are in different
  /// source currencies and cannot be added meaningfully.
  final bool mixedCurrencies;

  static const int _maxVisible = 8;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sorted = [...slices]
      ..sort((a, b) => b.totalMinorUnits.compareTo(a.totalMinorUnits));

    final visible = <ChartSlice>[];
    int otherTotal = 0;
    int otherCount = 0;
    String otherCurrencyCode = sorted.isNotEmpty
        ? sorted.first.currencyCode
        : 'USD';
    if (sorted.length <= _maxVisible) {
      visible.addAll(sorted);
    } else {
      visible.addAll(sorted.take(_maxVisible - 1));
      for (final s in sorted.skip(_maxVisible - 1)) {
        otherTotal += s.totalMinorUnits;
        otherCount++;
      }
    }
    final hasOther = sorted.length > _maxVisible;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final s in visible) _row(context, s),
        if (hasOther)
          _otherRow(
            context,
            l10n: l10n,
            total: otherTotal,
            count: otherCount,
            currencyCode: otherCurrencyCode,
          ),
        if (hasOther)
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(
              onPressed: () => _openFullLegend(context, sorted),
              child: Text(l10n.chartsViewAll),
            ),
          ),
      ],
    );
  }

  Widget _row(BuildContext context, ChartSlice s) {
    final currency = currenciesByCode[s.currencyCode] ??
        Currency(code: s.currencyCode, decimals: 2);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: colorForIndex(s.colorIndex),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          if (s.iconKey.isNotEmpty)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 6),
              child: Icon(iconForKey(s.iconKey), size: 16),
            ),
          Expanded(child: Text(s.label, overflow: TextOverflow.ellipsis)),
          Text(
            MoneyFormatter.format(
              amountMinorUnits: s.totalMinorUnits,
              currency: currency,
              locale: locale,
            ),
          ),
        ],
      ),
    );
  }

  Widget _otherRow(
    BuildContext context, {
    required AppLocalizations l10n,
    required int total,
    required int count,
    required String currencyCode,
  }) {
    // In mixed-currency mode, summing minor units across different
    // currencies is meaningless. Show a localized item count instead.
    if (mixedCurrencies) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: colorForIndex(CategoryPaletteIndex.neutralVariant50),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.chartsOtherCount(count),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }
    return _row(
      context,
      ChartSlice(
        label: l10n.chartsOther,
        currencyCode: currencyCode,
        totalMinorUnits: total,
        colorIndex: CategoryPaletteIndex.neutralVariant50,
        iconKey: '',
        fraction: null,
      ),
    );
  }

  void _openFullLegend(BuildContext context, List<ChartSlice> all) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetCtx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final s in all) _row(sheetCtx, s),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify analyzer**

Run: `dart format . && flutter analyze`
Expected: clean (assuming Task 20 ARB keys are present).

- [ ] **Step 3: Commit**

```bash
git add lib/features/analysis/charts/widgets/chart_legend.dart
git commit -m "feat(charts): add ChartLegend with Other bucket + View all sheet"
```

---

### Task 19: `ChartsSection` umbrella widget + widget tests

**Files:**
- Create: `lib/features/analysis/charts/charts_section.dart`
- Create: `test/widget/features/analysis/charts_section_test.dart`

Reads the controller state, dispatches to one of the chart bodies (loading / data / empty / blocked / error), and renders the period selector, type toggle, and dimension toggle above the chart body. The chart body itself contains the pie chart, the legend, and the bar chart (the bar chart is hidden in currency-view-mixed mode).

- [ ] **Step 1: Create the section file**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/default_currency_provider.dart';
import '../../../l10n/app_localizations.dart';
import 'charts_controller.dart';
import 'charts_providers.dart';
import 'charts_state.dart';
import 'widgets/category_pie_chart.dart';
import 'widgets/chart_legend.dart';
import 'widgets/daily_bar_chart.dart';
import 'widgets/dimension_toggle.dart';
import 'widgets/period_selector.dart';
import 'widgets/type_toggle.dart';

class ChartsSection extends ConsumerWidget {
  const ChartsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final stateAsync = ref.watch(chartsControllerProvider);
    final controller = ref.read(chartsControllerProvider.notifier);
    final currenciesAsync = ref.watch(chartsCurrenciesByCodeProvider);
    final locale = Localizations.localeOf(context).toLanguageTag();
    // ignore: unused_local_variable
    final defaultCurrency = ref.watch(initialDefaultCurrencyProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: stateAsync.when(
        loading: () => _frame(
          context,
          ref,
          controller,
          body: const Center(child: CircularProgressIndicator()),
          l10n: l10n,
        ),
        error: (e, _) => _frame(
          context,
          ref,
          controller,
          body: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$e'),
              const SizedBox(height: 8),
              TextButton(
                onPressed: controller.retry,
                child: const Text('Retry'),
              ),
            ],
          ),
          l10n: l10n,
        ),
        data: (state) => switch (state) {
          ChartsIdle() => _frame(
              context,
              ref,
              controller,
              body: const Center(child: CircularProgressIndicator()),
              l10n: l10n,
            ),
          ChartsLoading(:final previous) => _frame(
              context,
              ref,
              controller,
              body: previous == null
                  ? const Center(child: CircularProgressIndicator())
                  : Stack(
                      alignment: Alignment.center,
                      children: [
                        _ChartBody(
                          data: previous,
                          locale: locale,
                          currencies: currenciesAsync.valueOrNull ?? const {},
                        ),
                        const Positioned.fill(
                          child: IgnorePointer(
                            child: ColoredBox(color: Color(0x33000000)),
                          ),
                        ),
                        const CircularProgressIndicator(),
                      ],
                    ),
              l10n: l10n,
              chartData: previous,
              locale: locale,
              currencies: currenciesAsync.valueOrNull ?? const {},
            ),
          ChartsEmpty() => _frame(
              context,
              ref,
              controller,
              body: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text(l10n.chartsNoData)),
              ),
              l10n: l10n,
            ),
          ChartsBlockedByMissingRates(:final previous) => _frame(
              context,
              ref,
              controller,
              body: previous == null
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: Text(l10n.chartsRatesRequired)),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        MaterialBanner(
                          content: Text(l10n.chartsRatesRequired),
                          actions: [
                            TextButton(
                              onPressed: controller.retry,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                        _ChartBody(
                          data: previous,
                          locale: locale,
                          currencies: currenciesAsync.valueOrNull ?? const {},
                        ),
                      ],
                    ),
              l10n: l10n,
              chartData: previous,
              locale: locale,
              currencies: currenciesAsync.valueOrNull ?? const {},
            ),
          ChartsDataState(:final chartData) => _frame(
              context,
              ref,
              controller,
              body: _ChartBody(
                data: chartData,
                locale: locale,
                currencies: currenciesAsync.valueOrNull ?? const {},
              ),
              l10n: l10n,
              chartData: chartData,
              locale: locale,
              currencies: currenciesAsync.valueOrNull ?? const {},
            ),
          ChartsError(:final error) => _frame(
              context,
              ref,
              controller,
              body: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$error'),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: controller.retry,
                    child: const Text('Retry'),
                  ),
                ],
              ),
              l10n: l10n,
            ),
        },
      ),
    );
  }

  Widget _frame(
    BuildContext context,
    WidgetRef ref,
    ChartsController controller, {
    required Widget body,
    required AppLocalizations l10n,
    ChartsData? chartData,
    String? locale,
    Map<String, dynamic> currencies = const {},
  }) {
    final dimension = chartData?.dimension ?? ChartDimension.category;
    final type = chartData?.type ?? CategoryType.expense;
    final period = chartData?.period ?? PeriodType.week;
    final anchor = chartData?.anchorDate ?? DateTime.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PeriodSelector(
          period: period,
          anchorDate: anchor,
          isAtCurrent: _isAtCurrent(period, anchor),
          locale: locale ?? 'en',
          onPrevious: controller.previousPeriod,
          onNext: controller.nextPeriod,
          onPeriodChanged: controller.setPeriod,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TypeToggle(
                type: type,
                onChanged: (t) {
                  if (t != type) controller.toggleType();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        DimensionToggle(
          dimension: dimension,
          onChanged: controller.toggleDimension,
        ),
        const SizedBox(height: 16),
        if (chartData?.autoSwitchedFromCategoryDimension ?? false)
          // Banner explaining Task 12's one-shot cold-start fallback.
          // The close action calls dismissAutoSwitchBanner() so users who
          // want to keep the currency view but hide the message can.
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: MaterialBanner(
              content: Text(l10n.chartsAutoSwitchedToCurrency),
              actions: [
                TextButton(
                  onPressed: controller.dismissAutoSwitchBanner,
                  child: Text(MaterialLocalizations.of(context).closeButtonLabel),
                ),
              ],
            ),
          ),
        if ((chartData?.excludedCurrencyCodes ?? const <String>[]).isNotEmpty)
          // Partial-conversion ribbon: lists currencies whose subtotals
          // were dropped because their FX rate was missing. No dismiss
          // action — the ribbon reflects live data state and clears
          // automatically once rates are available.
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: MaterialBanner(
              content: Text(
                l10n.chartsExcludedCurrencies(
                  chartData!.excludedCurrencyCodes.join(', '),
                ),
              ),
              // No actions slot — banner is informational.
              actions: const [SizedBox.shrink()],
            ),
          ),
        if (chartData?.mixedCurrencies ?? false)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              l10n.chartsMixedCurrencies,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        body,
      ],
    );
  }

  bool _isAtCurrent(PeriodType period, DateTime anchor) {
    final now = DateTime.now();
    switch (period) {
      case PeriodType.day:
        return anchor.year == now.year &&
            anchor.month == now.month &&
            anchor.day == now.day;
      case PeriodType.week:
        // Approximate: anchor within the 7-day window ending now.
        return !anchor
            .add(const Duration(days: 7))
            .isBefore(DateTime(now.year, now.month, now.day));
      case PeriodType.month:
        return anchor.year == now.year && anchor.month == now.month;
      case PeriodType.year:
        return anchor.year == now.year;
    }
  }
}

import '../../../data/models/category.dart' show CategoryType;
import '../../../data/models/currency.dart';

class _ChartBody extends StatelessWidget {
  const _ChartBody({
    required this.data,
    required this.locale,
    required this.currencies,
  });

  final ChartsData data;
  final String locale;
  final Map<String, dynamic> currencies;

  @override
  Widget build(BuildContext context) {
    final showBar = data.bucketTotals.isNotEmpty &&
        !(data.dimension == ChartDimension.currency &&
            data.mixedCurrencies);
    final currenciesTyped = <String, Currency>{
      for (final entry in currencies.entries)
        if (entry.value is Currency) entry.key: entry.value as Currency,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CategoryPieChart(
          slices: data.slices,
          currenciesByCode: currenciesTyped,
          locale: locale,
          grandTotalMinorUnits: data.grandTotalMinorUnits,
          displayCurrencyCode: data.displayCurrencyCode,
        ),
        const SizedBox(height: 12),
        ChartLegend(
          slices: data.slices,
          currenciesByCode: currenciesTyped,
          locale: locale,
          mixedCurrencies: data.mixedCurrencies,
        ),
        if (showBar) ...[
          const SizedBox(height: 16),
          DailyBarChart(
            period: data.period,
            anchorDate: data.anchorDate,
            bucketTotals: data.bucketTotals,
            locale: locale,
            currenciesByCode: currenciesTyped,
            displayCurrencyCode: data.displayCurrencyCode,
          ),
        ],
      ],
    );
  }
}
```

**Note on imports:** Dart 3 supports class declarations after top-level imports; the `import '../../../data/models/category.dart' show CategoryType;` line shown above belongs at the top of the file beside the other imports. The plan groups it near `_ChartBody` for clarity, but consolidate all imports at the top during implementation.

- [ ] **Step 2: Write a minimal widget test**

`test/widget/features/analysis/charts_section_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:ledgerly/app/providers/default_currency_provider.dart';
import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/data/models/account.dart';
import 'package:ledgerly/data/models/category.dart';
import 'package:ledgerly/data/models/category_slice.dart';
import 'package:ledgerly/data/models/currency.dart';
import 'package:ledgerly/data/models/time_bucket_slice.dart';
import 'package:ledgerly/data/repositories/transaction_repository.dart';
import 'package:ledgerly/features/analysis/charts/charts_providers.dart';
import 'package:ledgerly/features/analysis/charts/charts_section.dart';
import 'package:ledgerly/features/analysis/search/analysis_providers.dart';
import 'package:ledgerly/l10n/app_localizations.dart';

class _MockTxRepo extends Mock implements TransactionRepository {}

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
  });

  testWidgets('renders pie + legend with single category slice', (tester) async {
    final repo = _MockTxRepo();
    when(() => repo.watchByCategoryInRange(
          start: any(named: 'start'),
          end: any(named: 'end'),
          type: any(named: 'type'),
        )).thenAnswer((_) => Stream.value(<CategorySlice>[
              const CategorySlice(
                categoryId: 1, currencyCode: 'USD', totalMinorUnits: 5000),
            ]));
    when(() => repo.watchTimeBucketsInRange(
          start: any(named: 'start'),
          end: any(named: 'end'),
          type: any(named: 'type'),
          granularity: any(named: 'granularity'),
        )).thenAnswer((_) => Stream.value(<TimeBucketSlice>[
              TimeBucketSlice(
                bucketStart: DateTime(2026, 5, 18),
                currencyCode: 'USD',
                totalMinorUnits: 5000,
              ),
            ]));

    await tester.pumpWidget(ProviderScope(
      overrides: [
        transactionRepositoryProvider.overrideWithValue(repo),
        analysisCategoriesByIdProvider.overrideWith(
          (ref) => Stream.value({
            1: Category(
              id: 1,
              type: CategoryType.expense,
              l10nKey: 'cat.test',
              customName: 'Food',
              icon: 'restaurant',
              color: 0,
              isArchived: false,
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
      child: const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(child: ChartsSection()),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Food'), findsWidgets);
  });
}
```

- [ ] **Step 3: Run analyzer + widget tests**

Run: `dart format . && flutter analyze && flutter test test/widget/features/analysis/charts_section_test.dart`
Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add lib/features/analysis/charts/charts_section.dart \
  test/widget/features/analysis/charts_section_test.dart
git commit -m "feat(charts): add ChartsSection wiring pie + legend + bar"
```

---

### Task 20: Add chart ARB keys for en / zh_TW / zh_CN

**Files:**
- Modify: `l10n/app_en.arb`
- Modify: `l10n/app_zh_TW.arb`
- Modify: `l10n/app_zh_CN.arb`

Twenty new keys (15 from the spec § Localization plus 5 added during the 2026-05-19 review: `chartsAutoSwitchedToCurrency`, `chartsOtherCount`, `chartsPieChart`, `chartsBarChart`, `chartsExcludedCurrencies`). Keep alphabetical-ish grouping consistent with the rest of the ARB file (existing analysis keys cluster together — append the chart keys to that group). The `zh.arb` fallback only carries `appTitle` — no edits required.

**Execution note:** Even though this remains numbered Task 20 for traceability, run it immediately after Task 13 before starting Task 14.

- [ ] **Step 1: Add the keys to `l10n/app_en.arb`**

Append next to the existing `analysis*` keys (preserve the trailing `}` of the JSON object):

```json
  "chartsPeriodDay": "Day",
  "@chartsPeriodDay": {"description": "Charts period toggle — day"},
  "chartsPeriodWeek": "Week",
  "@chartsPeriodWeek": {"description": "Charts period toggle — week (default)"},
  "chartsPeriodMonth": "Month",
  "@chartsPeriodMonth": {"description": "Charts period toggle — month"},
  "chartsPeriodYear": "Year",
  "@chartsPeriodYear": {"description": "Charts period toggle — year"},
  "chartsTypeExpense": "Expense",
  "@chartsTypeExpense": {"description": "Charts type toggle — expense"},
  "chartsTypeIncome": "Income",
  "@chartsTypeIncome": {"description": "Charts type toggle — income"},
  "chartsDimensionCategory": "Category",
  "@chartsDimensionCategory": {"description": "Charts dimension toggle — category"},
  "chartsDimensionAccount": "Account",
  "@chartsDimensionAccount": {"description": "Charts dimension toggle — account"},
  "chartsDimensionCurrency": "Currency",
  "@chartsDimensionCurrency": {"description": "Charts dimension toggle — currency"},
  "chartsNoData": "No transactions yet",
  "@chartsNoData": {"description": "Charts empty state copy"},
  "chartsMixedCurrencies": "Showing original currency amounts",
  "@chartsMixedCurrencies": {"description": "Banner for currency-dimension chart when some FX rates are missing"},
  "chartsRatesRequired": "Waiting for exchange rates",
  "@chartsRatesRequired": {"description": "Blocked-state copy for category/account charts when FX rates are missing"},
  "chartsViewAll": "View all",
  "@chartsViewAll": {"description": "Full-legend bottom sheet affordance"},
  "chartsTotal": "Total",
  "@chartsTotal": {"description": "Grand-total label"},
  "chartsOther": "Other",
  "@chartsOther": {"description": "Aggregated remainder legend entry"},
  "chartsOtherCount": "{count, plural, =1{Other (1 item)} other{Other ({count} items)}}",
  "@chartsOtherCount": {
    "description": "Other-bucket legend label when slices are in mixed currencies and amounts cannot be summed; shows item count instead",
    "placeholders": {"count": {"type": "int"}}
  },
  "chartsAutoSwitchedToCurrency": "Showing by currency — no exchange rates yet for category view.",
  "@chartsAutoSwitchedToCurrency": {"description": "Banner shown when ChartsController auto-switched from category to currency on cold-start because FX rates were missing"},
  "chartsPieChart": "Pie chart",
  "@chartsPieChart": {"description": "Accessibility prefix announced before pie chart contents"},
  "chartsBarChart": "Bar chart",
  "@chartsBarChart": {"description": "Accessibility prefix announced before bar chart contents"},
  "chartsExcludedCurrencies": "Excluded: {codes} — no exchange rate yet",
  "@chartsExcludedCurrencies": {
    "description": "Ribbon shown above a category/account chart when some currencies were dropped because their FX rate was missing. {codes} is a comma-separated currency-code list (e.g. 'EUR, JPY').",
    "placeholders": {"codes": {"type": "String"}}
  },
```

- [ ] **Step 2: Add Traditional Chinese translations to `l10n/app_zh_TW.arb`**

```json
  "chartsPeriodDay": "日",
  "chartsPeriodWeek": "週",
  "chartsPeriodMonth": "月",
  "chartsPeriodYear": "年",
  "chartsTypeExpense": "支出",
  "chartsTypeIncome": "收入",
  "chartsDimensionCategory": "類別",
  "chartsDimensionAccount": "帳戶",
  "chartsDimensionCurrency": "幣別",
  "chartsNoData": "尚無交易",
  "chartsMixedCurrencies": "顯示原始幣別金額",
  "chartsRatesRequired": "等待匯率資料",
  "chartsViewAll": "查看全部",
  "chartsTotal": "總計",
  "chartsOther": "其他",
  "chartsOtherCount": "{count, plural, =1{其他（1 項）} other{其他（{count} 項）}}",
  "chartsAutoSwitchedToCurrency": "改以幣別檢視 — 尚未取得類別檢視所需的匯率。",
  "chartsPieChart": "圓餅圖",
  "chartsBarChart": "長條圖",
  "chartsExcludedCurrencies": "已排除：{codes} — 尚未取得匯率",
```

- [ ] **Step 3: Add Simplified Chinese translations to `l10n/app_zh_CN.arb`**

```json
  "chartsPeriodDay": "日",
  "chartsPeriodWeek": "周",
  "chartsPeriodMonth": "月",
  "chartsPeriodYear": "年",
  "chartsTypeExpense": "支出",
  "chartsTypeIncome": "收入",
  "chartsDimensionCategory": "类别",
  "chartsDimensionAccount": "账户",
  "chartsDimensionCurrency": "币种",
  "chartsNoData": "暂无交易",
  "chartsMixedCurrencies": "显示原始币种金额",
  "chartsRatesRequired": "等待汇率数据",
  "chartsViewAll": "查看全部",
  "chartsTotal": "总计",
  "chartsOther": "其他",
  "chartsOtherCount": "{count, plural, =1{其他（1 项）} other{其他（{count} 项）}}",
  "chartsAutoSwitchedToCurrency": "改用币种视图 — 类别视图所需的汇率尚未就绪。",
  "chartsPieChart": "饼图",
  "chartsBarChart": "条形图",
  "chartsExcludedCurrencies": "已排除：{codes} — 汇率尚未就绪",
```

- [ ] **Step 4: Regenerate localization classes**

Run: `flutter gen-l10n` (or `flutter pub get`, which triggers gen-l10n)
Expected: `lib/l10n/app_localizations*.dart` regenerate with the new getters.

- [ ] **Step 5: Verify ARB audit passes**

Run: `flutter test test/unit/l10n/arb_audit_test.dart`
Expected: PASS — every key present in all three locales.

- [ ] **Step 6: Commit**

```bash
git add l10n/app_en.arb l10n/app_zh_TW.arb l10n/app_zh_CN.arb lib/l10n/
git commit -m "feat(l10n): add chart-section ARB keys for en/zh_TW/zh_CN"
```

---

### Task 21: `AnalysisScreen` integration — search-first sliver layout

**Files:**
- Modify: `lib/features/analysis/analysis_screen.dart`
- Modify: `test/widget/features/analysis/analysis_screen_test.dart`

The body becomes a `CustomScrollView` so the charts can render as a sliver when the query is empty and collapse out when search is active. The existing search bar stays in the `AppBar` and remains the first interactive control on the screen.

- [ ] **Step 1: Add a failing assertion to the existing analysis_screen_test**

Append a test to `test/widget/features/analysis/analysis_screen_test.dart`:

```dart
  testWidgets('charts section shows when query is empty', (tester) async {
    final tx = _MockTransactionRepository();
    when(() => tx.watchByMemo(any())).thenAnswer((_) => Stream.value(const []));
    when(() => tx.watchByCategoryInRange(
          start: any(named: 'start'),
          end: any(named: 'end'),
          type: any(named: 'type'),
        )).thenAnswer((_) => Stream.value(const []));
    when(() => tx.watchTimeBucketsInRange(
          start: any(named: 'start'),
          end: any(named: 'end'),
          type: any(named: 'type'),
          granularity: any(named: 'granularity'),
        )).thenAnswer((_) => Stream.value(const []));
    final cat = _MockCategoryRepository();
    when(() => cat.watchAll(includeArchived: true))
        .thenAnswer((_) => Stream.value(const []));
    final acct = _MockAccountRepository();
    when(() => acct.watchAll(includeArchived: true))
        .thenAnswer((_) => Stream.value(const []));

    await tester.pumpWidget(_harness(tx: tx, cat: cat, acct: acct));
    await tester.pumpAndSettle();

    // ChartsSection's `Week` toggle should render — proves the charts
    // render when there's no query.
    expect(find.text('Week'), findsOneWidget);
  });
```

(Add necessary mock stubs/imports as required.)

- [ ] **Step 2: Run the test to verify failure**

Run: `flutter test test/widget/features/analysis/analysis_screen_test.dart`
Expected: FAIL — `find.text('Week')` finds nothing because the chart section isn't mounted yet.

- [ ] **Step 3: Modify `analysis_screen.dart`**

Rebuild the body so the search-empty state renders charts beneath the bar (the search bar stays in the `AppBar.bottom`):

```dart
@override
Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  final locale = Localizations.localeOf(context).toLanguageTag();
  final state = ref.watch(analysisControllerProvider);
  final isQueryEmpty = _searchController.text.trim().isEmpty;

  final searchBody = state.when(
    loading: () => isQueryEmpty
        ? null
        : const Center(child: CircularProgressIndicator()),
    error: (e, _) => Center(child: Text(l10n.analysisErrorMessage)),
    data: (s) => switch (s) {
      AnalysisIdle() => null,
      AnalysisLoading(:final previous, :final query) =>
        previous == null
            ? const Center(child: CircularProgressIndicator())
            : Stack(
                children: [
                  IgnorePointer(
                    child: ListView.builder(
                      itemCount: previous.length,
                      itemBuilder: (_, i) => CategorySearchTile(
                        result: previous[i],
                        query: query,
                        locale: locale,
                      ),
                    ),
                  ),
                  const Center(child: CircularProgressIndicator()),
                ],
              ),
      AnalysisResults(:final categories, :final query) => ListView.builder(
        itemCount: categories.length,
        itemBuilder: (_, i) => CategorySearchTile(
          result: categories[i],
          query: query,
          locale: locale,
        ),
      ),
      AnalysisEmpty() => Center(child: Text(l10n.analysisNoResults)),
    },
  );

  return Scaffold(
    appBar: AppBar(
      title: Text(l10n.analysisTitle),
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(_searchBarRowHeight(context)),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: _kSearchBarVerticalPadding,
          ),
          child: SearchBar(
            controller: _searchController,
            focusNode: _searchFocus,
            hintText: l10n.analysisSearchHint,
            leading: const Icon(Icons.search),
            trailing: [
              if (_searchController.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: _onClear,
                  tooltip:
                      MaterialLocalizations.of(context).deleteButtonTooltip,
                ),
            ],
            onChanged: _onChanged,
          ),
        ),
      ),
    ),
    body: Semantics(
      liveRegion: true,
      container: true,
      child: isQueryEmpty
          ? const SingleChildScrollView(child: ChartsSection())
          : searchBody!,
    ),
  );
}
```

Add the import to the top of the file:

```dart
import 'charts/charts_section.dart';
```

- [ ] **Step 4: Run the test to verify success**

Run: `dart format . && flutter test test/widget/features/analysis/analysis_screen_test.dart`
Expected: PASS.

- [ ] **Step 5: Run analyzer + full test suite**

Run: `flutter analyze && flutter test`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/features/analysis/analysis_screen.dart \
  test/widget/features/analysis/analysis_screen_test.dart
git commit -m "feat(analysis): mount ChartsSection beneath search bar when query is empty"
```

---

### Task 22: Integration test for chart display flow

**Files:**
- Create: `test/integration/chart_display_flow_test.dart`

End-to-end harness: bootstrap the app with seeded transactions, open Analysis, assert charts render with the right data. Use the existing `test/support/test_app.dart` harness.

- [ ] **Step 1: Create the integration test**

```dart
// End-to-end flow: insert transactions, navigate to Analysis, verify
// charts render with correct totals.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ledgerly/data/database/app_database.dart';
import 'package:ledgerly/data/models/category.dart';

import '../support/test_app.dart';

void main() {
  testWidgets('charts render on Analysis after inserts', (tester) async {
    final db = await launchTestApp(tester);
    addTearDown(() async => db.close());

    await _seedExpense(db);

    // Navigate to Analysis tab.
    await tester.tap(find.byIcon(Icons.analytics_outlined));
    await tester.pumpAndSettle();

    // The default Week + Expense + Category view should render the seeded
    // food category. Test harness uses the seeded l10n key.
    expect(find.textContaining('Week'), findsWidgets);
    expect(find.textContaining('Food'), findsWidgets);
  });
}

Future<void> _seedExpense(AppDatabase db) async {
  // Use the first-run seeded categories; insert a single transaction.
  final cats = await db.categoryDao.watchAll(includeArchived: false).first;
  final foodCategory = cats.firstWhere(
    (c) => c.l10nKey == 'category.food' && c.type == CategoryType.expense.name,
  );
  final accts = await db.accountDao.watchAll(includeArchived: false).first;
  final cash = accts.first;
  final epoch = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  await db.customStatement(
    'INSERT INTO transactions (amount_minor_units, currency, '
    'category_id, account_id, date, created_at, updated_at) '
    'VALUES (?, ?, ?, ?, ?, ?, ?)',
    [1000, cash.currency, foodCategory.id, cash.id, epoch, epoch, epoch],
  );
}
```

**Note:** The exact harness API in `test/support/test_app.dart` will dictate the imports / setup pattern. If `launchTestApp` does not exist, mirror one of the existing integration tests (e.g. `bootstrap_to_home_test.dart`) and adapt. The `category.food` key match assumes the first-run seed inserts that key — verify against `lib/data/seed/first_run_seed.dart`.

- [ ] **Step 2: Run the test**

Run: `dart format . && flutter test test/integration/chart_display_flow_test.dart`
Expected: PASS.

- [ ] **Step 3: Commit**

```bash
git add test/integration/chart_display_flow_test.dart
git commit -m "test(integration): chart display flow on Analysis after insert"
```

---

### Task 23: Final verification + manual smoke

**Files:**
- _None._

- [ ] **Step 1: Full test suite**

Run: `dart format . && flutter analyze && flutter test`
Expected: PASS across unit / widget / integration.

- [ ] **Step 2: Spin up the app**

Run: `flutter run -d <device>`

- [ ] **Step 3: Manual smoke (golden + edges)**

Verify with the running app:
- Analysis tab opens to weekly expense-by-category chart by default.
- Period toggle switches between Day / Week / Month / Year and the label updates.
- Prev / next arrows move the anchor; next is disabled at the current period.
- Dimension toggle switches between Category / Account / Currency without losing the selected period.
- Type toggle swaps between Expense and Income.
- Typing in the search bar hides the charts; clearing the query restores them with the last selection.
- Adding a transaction in another currency without an FX rate puts category/account dimensions into the blocked-state copy; currency dimension still renders the source-currency pie.
- The "Other" bucket appears when more than 8 slices are present, and "View all" opens the full legend sheet.

- [ ] **Step 4: Optional polish or follow-up notes**

Capture any visual or behavioral gaps as TODO comments in `docs/superpowers/specs/2026-05-18-basic-charts-design.md` § Deferred / Open Questions for later iteration (warm-start, chart→transaction drill-down).

---

## Notes on TDD + Verification

- Every controller / repository / pure-helper task follows red→green→commit; widget tasks use widget tests where rendering matters.
- Run `flutter analyze` after **every** task that modifies a `_controller.dart`, a widget, or anything under `data/` — import_lint violations don't always show up via `flutter test`.
- Run `dart run build_runner build --delete-conflicting-outputs` after **every** task that touches a `@freezed`, `@riverpod`, or Drift-annotated file.
- Run `dart format .` before `flutter test` per CLAUDE.md; the formatter sometimes flags whitespace that breaks goldens.

## Open Items (carry forward to the spec's Deferred section)

- Warm-start chart reuse (Task 13).
- Per-period chart→transaction drill-down (spec § Deferred — already tracked; v1 ships view-only with `// TODO(charts/drill-down)` markers in Tasks 16 + 17).

## Deferred / Open Questions

### Resolved during 2026-05-19 review

All P1/P2 questions raised in the 2026-05-19 review (plus one P3 originally tagged for spec § Deferred and resolved in the same pass) have been resolved in this plan revision. Decisions and the tasks where each landed:

1. **Default chart behavior vs. cold-start fallback** (P1) — *Decision: keep Task 12's auto-switch, but make it visible.* `ChartsData` gained an `autoSwitchedFromCategoryDimension` flag; Task 12 sets and threads it; Task 19 renders a `MaterialBanner` above the chart body when it is true, with a Close action that calls a new `dismissAutoSwitchBanner()` controller command. Manually toggling dimension also clears the flag. ARB: `chartsAutoSwitchedToCurrency`. The first-run experience is now predictable on the data side (auto-switch still fires) and on the UX side (the user is told why).

2. **Mixed-currency "Other" bucket sums incompatible currencies** (P1) — *Decision: show count, not amount.* Task 18 takes a new `mixedCurrencies` flag (passed through from `ChartsData.mixedCurrencies` in Task 19's `_ChartBody`). When true, the `Other` legend row renders `Other (N items)` via the new plural ARB key `chartsOtherCount` instead of a misleading summed amount. The "View all" sheet is unchanged — its rows are per-slice and stay in source currencies.

3. **First release scope is broad for a search-secondary surface** (P2) — *Decision: ship full scope as planned.* The user confirmed the current "one chart at a time, three toggles" model is intentional. The page renders one chart based on Period × Dimension × Type, so the visible surface area at any moment is small; the spec already settled the combo matrix. No descope.

4. **Control layout leaves 600dp behavior unspecified** (P2) — *Decision: always stack at all widths.* Tasks 14 and 15 now state explicitly that the period selector, type toggle, and dimension toggle render as a full-width vertical stack at every width. The 600dp shell-level adaptivity (bottom-nav ↔ NavigationRail) does not apply to chart controls. The note at line 20 of this plan (`adaptive 600dp behaviour remain binding`) refers to the existing app-shell behaviour, not to the chart controls.

5. **Charts lack an explicit non-visual summary path** (P2) — *Decision: wrap each chart in `Semantics` with a generated label.* Task 16 wraps `CategoryPieChart` in `Semantics(image: true, excludeSemantics: true)` with a label that lists each slice (with percentage when known) and the grand total. Task 17 does the same for `DailyBarChart`, listing each non-zero bucket. Both widgets now take `currenciesByCode` + locale + an optional `displayCurrencyCode` so amounts format via `MoneyFormatter`. ARB: `chartsPieChart`, `chartsBarChart`. The legend below is independently readable and does not need exclusion.

6. **Graceful degradation when one currency lacks a rate** (P3, originally tagged for spec § Deferred) — *Decision: implement partial conversion + warning ribbon.* The category/account dimension now blocks **only** when every active currency lacks a rate. When at least one is convertible, Task 11's `_emitCategoryOrAccountDimension` emits a `ChartsDataState` whose slices and bucket totals reflect only the convertible currencies, and the excluded codes are surfaced via the new `ChartsData.excludedCurrencyCodes` field. `ChartsSection` renders a `MaterialBanner` ribbon listing the excluded codes (`chartsExcludedCurrencies` ARB key). Task 12's auto-switch trigger was tightened from `missingRate` to `allMissing` so users with partial rates stay on the category view they expected. Bucket totals mirror the same exclusion rule so the bar chart matches the pie chart.

### Still deferred (not in this release)

- **Warm-start optimization** (Task 13) — Sub-frame cold-path performance under Drift `.watch()` makes this an unnecessary complication today. Re-evaluate if cold-start jank is observed in practice.
- **Chart → transaction drill-down** — Tapping a slice / bar to filter the transaction list is intentionally out of scope; `PieTouchData(enabled: false)` and `BarTouchData(enabled: false)` lock both charts to view-only for v1. Tasks 16 and 17 include `// TODO(charts/drill-down)` markers so the extension point is discoverable to future contributors.
